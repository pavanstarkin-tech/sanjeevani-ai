import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'medical_slm_engine_service.dart';

class NvidiaAiResponse {
  final String content;
  final List<String> detectedSymptoms;
  final bool wantsMedicines;
  final List<String> actionSuggestions;
  final String triageCategory;

  NvidiaAiResponse({
    required this.content,
    this.detectedSymptoms = const [],
    this.wantsMedicines = false,
    this.actionSuggestions = const [],
    this.triageCategory = 'General Inquiry',
  });
}

class NvidiaAiService {
  static const String _nvidiaEndpoint = '${AppConfig.nvidiaApiBaseUrl}/chat/completions';
  static const String _nvidiaApiKey = AppConfig.nvidiaApiKey;
  static const String _nvidiaModel = AppConfig.nvidiaModel;

  static const String _sarvamEndpoint = AppConfig.sarvamChatEndpoint;
  static const String _sarvamModel = AppConfig.sarvamChatModel;

  /// Generate intelligent clinical response using Sarvam AI (CORS-compliant for Web)
  /// and NVIDIA NIM API (for native/mobile platforms)
  static Future<NvidiaAiResponse> generateResponse({
    required String userQuery,
    List<Map<String, String>> conversationHistory = const [],
    String lang = 'en',
    String? patientName,
    int? patientAge,
    String? gender,
    List<String>? currentSymptoms,
    String? symptomDuration,
    String? bodyTemperature,
    int intakeTurn = 1,
    String? knownSeverity,
    String? knownPastHistory,
    String? knownExistingMeds,
    bool isVoiceMode = false,
    String? ragContext,
  }) async {
    final trimmedQuery = userQuery.trim();
    final qLower = trimmedQuery.toLowerCase();

    // 1. Deterministic Identity Check
    final isIdentity = qLower.contains('who are you') ||
        qLower.contains('what is your name') ||
        qLower.contains('who made you') ||
        qLower.contains('who created you') ||
        qLower.contains('identity') ||
        qLower.contains('మీరు ఎవరు') ||
        qLower.contains('నువ్వు ఎవరు') ||
        qLower.contains('ఆప్ కౌన్') ||
        qLower.contains('आप कौन हैं') ||
        qLower.contains('तुम्हारा नाम क्या');

    if (isIdentity) {
      final identityText = lang == 'te'
          ? 'నమస్కారం! నేను డాక్టర్ శన్నీ (Dr. Shanni) ని, Sanjeevani.ai క్లినికల్ ఏఐ వైద్యుడిని. మీ ఆరోగ్యం ఎలా ఉంది?'
          : (lang == 'hi'
              ? 'नमस्ते! मैं डॉ. शन्नी (Dr. Shanni) हूँ, Sanjeevani.ai से आपकी क्लिनिकल एआई डॉक्टर। आपकी तबीयत कैसी है?'
              : 'Hello! I am Dr. Shanni from Sanjeevani.ai, your clinical AI doctor. How can I help you today?');

      return NvidiaAiResponse(
        content: identityText,
        detectedSymptoms: [],
        wantsMedicines: false,
        actionSuggestions: lang == 'te'
            ? ['లక్షణాల గురించి చెప్పండి', 'డాక్టర్‌ను కలవండి']
            : (lang == 'hi' ? ['लक्षणों के बारे में बताएं', 'डॉक्टर से परामर्श'] : ['Report symptoms', 'Find doctors']),
        triageCategory: 'General',
      );
    }

    // 2. Strict Medical Scope Guardrail (Refuse coding, programming, math, politics)
    final isNonMedical = qLower.contains('python') ||
        qLower.contains('javascript') ||
        qLower.contains('write code') ||
        qLower.contains('write a program') ||
        qLower.contains('flutter') ||
        qLower.contains('java') ||
        qLower.contains('html') ||
        qLower.contains('css') ||
        qLower.contains('prime minister') ||
        qLower.contains('cricket') ||
        qLower.contains('write essay');

    if (isNonMedical) {
      final scopeText = lang == 'te'
          ? 'నేను డాక్టర్ శన్నీని, క్లినికల్ మెడికల్ అసిస్టెంట్‌ని. వైద్య సంబంధిత ఆరోగ్య సమస్యల గురించే నేను సమాధానం ఇవ్వగలను.'
          : (lang == 'hi'
              ? 'मैं डॉ. शन्नी हूँ, क्लिनिकल मेडिकल असिस्टेंट। मैं केवल स्वास्थ्य और चिकित्सा से जुड़े सवालों के जवाब दे सकती हूँ।'
              : 'I am Dr. Shanni, a clinical medical doctor. I only assist with health and medical questions.');

      return NvidiaAiResponse(
        content: scopeText,
        detectedSymptoms: [],
        wantsMedicines: false,
        actionSuggestions: lang == 'te'
            ? ['ఆరోగ్య సమస్యను చెప్పండి', 'సమీప ఆసుపత్రులు']
            : (lang == 'hi' ? ['स्वास्थ्य समस्या बताएं', 'निकटतम अस्पताल'] : ['Describe health issue', 'Nearest hospitals']),
        triageCategory: 'General',
      );
    }

    final isGreeting = _isGreeting(trimmedQuery);
    final userWantsMedicines = _wantsMedicines(trimmedQuery);
    final isShortQuery = trimmedQuery.split(RegExp(r'\s+')).length <= 6;
    final extracted = extractSymptoms(trimmedQuery, lang);
    final allSymptoms = <String>{...?currentSymptoms, ...extracted}.toList();
    final category = _categorizeQuery(trimmedQuery);

    // Direct, conversational response on pure greetings in text chat mode (voice mode delegates to Sarvam AI)
    if (!isVoiceMode && isGreeting && allSymptoms.isEmpty) {
      final greetingContent = lang == 'te'
          ? 'నమస్కారం! మీ ఆరోగ్యం ఎలా ఉంది? మీకు ఎలా సహాయపడగలను?'
          : (lang == 'hi'
              ? 'नमस्ते! आज आपकी तबीयत कैसी है? मैं आपकी क्या मदद कर सकती हूँ?'
              : 'Hello! How can I help you with your health today?');

      return NvidiaAiResponse(
        content: greetingContent,
        detectedSymptoms: [],
        wantsMedicines: false,
        actionSuggestions: [],
        triageCategory: 'General',
      );
    }

    // Dynamic Max Tokens: 1200 for rich clinical responses and full tables, 350 for voice agent
    final maxTokens = isVoiceMode ? 350 : 1200;

    final systemPrompt = _buildSystemPrompt(
      lang: lang,
      isGreeting: isGreeting,
      isShortQuery: isShortQuery,
      patientName: patientName,
      patientAge: patientAge,
      gender: gender,
      symptoms: allSymptoms,
      symptomDuration: symptomDuration,
      bodyTemperature: bodyTemperature,
      intakeTurn: intakeTurn,
      knownSeverity: knownSeverity,
      knownPastHistory: knownPastHistory,
      knownExistingMeds: knownExistingMeds,
      isVoiceMode: isVoiceMode,
      ragContext: ragContext,
    );

    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // Add recent conversation history for context retention (last 8 messages)
    final recentHistory = conversationHistory.length > 8
        ? conversationHistory.sublist(conversationHistory.length - 8)
        : conversationHistory;
    for (final msg in recentHistory) {
      if (msg['role'] != null && msg['content'] != null) {
        messages.add({
          'role': msg['role']!,
          'content': msg['content']!,
        });
      }
    }

    // Add current user turn
    messages.add({
      'role': 'user',
      'content': trimmedQuery,
    });

    // 1. In Voice Call Mode: Prioritize ultra-fast (<1s), conversational Sarvam AI without reasoning token overhead
    if (isVoiceMode) {
      final sarvamContent = await _callSarvam(messages, maxTokens);
      if (sarvamContent != null && sarvamContent.isNotEmpty) {
        final cleaned = _cleanLlmContent(sarvamContent, lang, allSymptoms);
        return NvidiaAiResponse(
          content: cleaned,
          detectedSymptoms: allSymptoms,
          wantsMedicines: userWantsMedicines,
          actionSuggestions: _generateSuggestions(
            lang: lang,
            query: trimmedQuery,
            patientName: patientName,
            symptoms: allSymptoms,
          ),
          triageCategory: category,
        );
      }
    }

    // 2. Primary Engine for Text Chat: NVIDIA NIM API
    final nvidiaContent = await _callNvidia(messages, maxTokens);
    if (nvidiaContent != null && nvidiaContent.isNotEmpty) {
      final cleaned = _cleanLlmContent(nvidiaContent, lang, allSymptoms);
      return NvidiaAiResponse(
        content: cleaned,
        detectedSymptoms: allSymptoms,
        wantsMedicines: userWantsMedicines,
        actionSuggestions: _generateSuggestions(
          lang: lang,
          query: trimmedQuery,
          patientName: patientName,
          symptoms: allSymptoms,
        ),
        triageCategory: category,
      );
    }

    // 3. Fallback Engine: Sarvam AI conversational LLM (if not already tried or for chat fallback)
    if (!isVoiceMode) {
      final sarvamContent = await _callSarvam(messages, maxTokens);
      if (sarvamContent != null && sarvamContent.isNotEmpty) {
        final cleaned = _cleanLlmContent(sarvamContent, lang, allSymptoms);
        return NvidiaAiResponse(
          content: cleaned,
          detectedSymptoms: allSymptoms,
          wantsMedicines: userWantsMedicines,
          actionSuggestions: _generateSuggestions(
            lang: lang,
            query: trimmedQuery,
            patientName: patientName,
            symptoms: allSymptoms,
          ),
          triageCategory: category,
        );
      }
    }

    // Dynamic offline clinical fallback if network is unreachable
    return _buildFallbackResponse(
      userQuery: trimmedQuery,
      lang: lang,
      isGreeting: isGreeting,
      isShortQuery: isShortQuery,
      userWantsMedicines: userWantsMedicines,
      patientName: patientName,
      patientAge: patientAge,
      symptoms: allSymptoms,
      symptomDuration: symptomDuration,
      knownSeverity: knownSeverity,
      knownPastHistory: knownPastHistory,
      knownExistingMeds: knownExistingMeds,
    );
  }

  /// Clean tool calls, thoughts, technical XML tags, and ALL emojis from LLM responses
  static String _cleanLlmContent(String raw, String lang, List<String> symptoms) {
    var text = raw;
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    text = text.replaceAll(RegExp(r'<thought>[\s\S]*?</thought>'), '');
    text = text.replaceAll(RegExp(r'<reasoning>[\s\S]*?</reasoning>'), '');
    text = text.replaceAll(RegExp(r'<system>[\s\S]*?</system>'), '');
    text = text.replaceAll(RegExp(r'<tool_call>[\s\S]*?</tool_call>'), '');
    text = text.replaceAll(RegExp(r'<tool_response>[\s\S]*?</tool_response>'), '');
    text = text.replaceAll(RegExp(r'\[/?TOOL_CALLS?\]'), '');
    text = text.replaceAll(RegExp(r'```json[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'^The user asks:.*?\n', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^User Query:.*?\n', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'^Internal reasoning:.*?\n', caseSensitive: false), '');
    // Strictly strip all Unicode emojis and pictographs
    text = text.replaceAll(
      RegExp(r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}\u{1F900}-\u{1F9FF}\u{1F1E0}-\u{1F1FF}\u{200D}\u{FE0F}]', unicode: true),
      '',
    );
    text = text.trim();
    return text;
  }

  /// Call Sarvam AI conversational LLM (CORS-friendly on Web) with automatic fallback key support
  static Future<String?> _callSarvam(List<Map<String, String>> messages, int maxTokens) async {
    for (final key in AppConfig.sarvamApiKeys) {
      try {
        final response = await http
            .post(
              Uri.parse(_sarvamEndpoint),
              headers: {
                'api-subscription-key': key,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'model': _sarvamModel,
                'messages': messages,
                'temperature': 0.5,
                'max_tokens': maxTokens,
              }),
            )
            .timeout(const Duration(seconds: 14));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final content = choices[0]['message']?['content']?.toString().trim() ?? '';
            if (content.isNotEmpty) {
              return content;
            }
          }
        } else {
          debugPrint('Sarvam AI API status ${response.statusCode} for key: ${response.body}');
        }
      } catch (e) {
        debugPrint('Sarvam AI request notice for key: $e');
      }
    }
    return null;
  }

  /// Call NVIDIA NIM API (for native/mobile environments)
  static Future<String?> _callNvidia(List<Map<String, String>> messages, int maxTokens) async {
    try {
      final response = await http
          .post(
            Uri.parse(_nvidiaEndpoint),
            headers: {
              'Authorization': 'Bearer $_nvidiaApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _nvidiaModel,
              'messages': messages,
              'temperature': 1.0,
              'top_p': 1.0,
              'max_tokens': 4096,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final msg = choices[0]['message'];
          final content = msg?['content']?.toString().trim() ?? '';
          if (content.isNotEmpty) {
            return content;
          }
          final reasoning = msg?['reasoning_content']?.toString().trim();
          if (reasoning != null && reasoning.isNotEmpty) {
            return reasoning;
          }
        }
      } else {
        debugPrint('NVIDIA API status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('NVIDIA API notice: $e');
    }
    return null;
  }

  static bool _isGreeting(String text) {
    final lower = text.toLowerCase().trim();
    return lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'namaste' ||
        lower == 'నమస్కారం' ||
        lower == 'నమస్తే' ||
        lower == 'नमस्ते' ||
        lower.startsWith('hi ') ||
        lower.startsWith('hello ') ||
        lower.startsWith('hey ');
  }

  static bool _wantsMedicines(String text) {
    final lower = text.toLowerCase();
    return lower.contains('medicine') ||
        lower.contains('tablet') ||
        lower.contains('drug') ||
        lower.contains('capsule') ||
        lower.contains('syrup') ||
        lower.contains('dosage') ||
        lower.contains('what should i take') ||
        lower.contains('suggest medicine') ||
        lower.contains('prescribe') ||
        lower.contains('prescription') ||
        lower.contains('what should i do') ||
        lower.contains('what to do') ||
        lower.contains('మందులు') ||
        lower.contains('దవా') ||
        lower.contains('दवा');
  }

  static String _getLanguageDirective(String lang) {
    return 'Respond naturally and fluently in the same language the user is communicating in. Do not forcefully change, translate, or enforce a different language; let the model respond directly in the user language.';
  }

  static String _buildSystemPrompt({
    required String lang,
    required bool isGreeting,
    required bool isShortQuery,
    String? patientName,
    int? patientAge,
    String? gender,
    List<String> symptoms = const [],
    String? symptomDuration,
    String? bodyTemperature,
    int intakeTurn = 1,
    String? knownSeverity,
    String? knownPastHistory,
    String? knownExistingMeds,
    bool isVoiceMode = false,
    String? ragContext,
  }) {
    final languageDirective = _getLanguageDirective(lang);

    final knownProfile = '''
Patient Context:
- Name: ${patientName ?? "Unknown"}
- Age: ${patientAge != null ? "$patientAge years" : "Unknown"}
- Symptoms: ${symptoms.isNotEmpty ? symptoms.join(', ') : "None reported yet"}
- Duration: ${symptomDuration ?? "Unknown"}
''';

    final ragSection = (ragContext != null && ragContext.trim().isNotEmpty)
        ? '''
$ragContext
CRITICAL: Use the above authoritative real-time RAG knowledge layer published by clinical administrators to inform your diagnosis, treatment recommendations, medicine substitutions, and government scheme guidance.
'''
        : '';

    final clinicalOrVoiceRules = isVoiceMode
        ? '''
CRITICAL VOICE CALL RULES (AUDIO ONLY):
1. You are speaking with the caller over a live voice phone call as Dr. Shanni from Sanjeevani.ai.
2. Provide a direct, natural, conversational 2-3 sentence answer suitable for text-to-speech audio.
3. NEVER generate markdown tables, asterisks (**), bullet points, numbers, or technical symbols.
4. The caller may speak in Telugu, Hindi, English, Tamil, Kannada, or any Indian language. Understand their speech and respond naturally, warmly, and fluently in whatever language the caller is speaking according to their convenience as Dr. Shanni.
5. IDENTITY & BRANDING: You are Dr. Shanni from Sanjeevani.ai. NEVER say or mention "Health Express" or "HealthExpress". Always state you are Dr. Shanni or that you are from Sanjeevani.ai.
6. VISUAL INSPECTION / "SEE MY FACE": If the caller asks "See my face", "Look at me", or asks if you can see them through the camera, warmly instruct them: "I am ready to examine you! Please look straight into your camera and tap the camera icon in the top-right corner of your camera box so I can analyze your live video feed in real time."
'''
        : '''
CRITICAL CLINICAL RULES:
1. NO ROBOTIC FILLERS OR UNNECESSARY APOLOGIES: Never say "I'm sorry you're feeling so bad" or waste time with repetitive pleasantries. Speak directly, professionally, and naturally as a clinical doctor in $lang.
2. IDENTITY & BRANDING: You are Dr. Shanni from Sanjeevani.ai. NEVER mention "Health Express" or "HealthExpress". Always identify as Dr. Shanni or state that you are from Sanjeevani.ai.
3. ADAPTIVE RESPONSE LENGTH:
   - For SHORT queries, quick updates, or simple answers (e.g. "Just started today", "High fever", "Headache"): Reply CONCISELY in 1-2 crisp lines. Never write long paragraphs for short answers.
   - For LONG or DETAILED questions asking for explanations, causes, or comprehensive care: Provide a clear, structured clinical explanation.
4. ASK AT MOST ONE QUESTION AT A TIME:
   - NEVER ask multiple questions at once. A doctor asks one question and listens.
   - For greetings or casual conversation: NEVER ask intake questions. Simply ask how you can help.
   - When assessing symptoms: Ask AT MOST ONE single direct question (e.g. "What is your current temperature?").
   - NEVER output a list or bullet points of multiple questions.
5. SAFE CLINICAL GUIDANCE: Give clear, actionable relief, hydration, and safe OTC dosage where appropriate.
6. NO EMOJIS, NO ROBOTIC REPETITION. Jump straight into helpful clinical diagnosis.
7. RICH MARKDOWN FORMATTING & FULL TABLES:
   - When presenting government health schemes (e.g., Aarogyasri, Ayushman Bharat PM-JAY, CGHS, ESIC, NHM), treatment packages, diagnostic panels, or medication comparisons: ALWAYS format them using a COMPLETE, fully-closed Markdown Table with all headers and detailed rows. Never leave a table empty or cut off mid-separator.
   - Use bold text (**Key Term**) for headings, important warnings, and medicines.
   - Use structured bullet lists (- or *) and numbered steps (1., 2.) for sequential advice.
   - Give complete, comprehensive, and helpful answers without cutting short.
''';

    return '''
You are Dr. Shanni from Sanjeevani.ai, an expert clinical doctor speaking directly with a patient. NEVER mention "Health Express" or "HealthExpress". Always state that you are Dr. Shanni or that you are from Sanjeevani.ai.
$languageDirective

$clinicalOrVoiceRules

$knownProfile

$ragSection
''';
  }

  static List<String> _generateSuggestions({
    required String lang,
    required String query,
    String? patientName,
    List<String> symptoms = const [],
  }) {
    // Dynamic Clinical Triage / Follow-up suggestions based on user issue
    final lower = '${query.toLowerCase()} ${symptoms.join(' ').toLowerCase()}';

    // 1. Stomach Ache / Gastric / Acidity
    if (lower.contains('stomach') || lower.contains('gastric') || lower.contains('acidity') || lower.contains('కడుపు') || lower.contains('గ్యాస్') || lower.contains('पेट') || lower.contains('एसिडिटी') || lower.contains('vomit') || lower.contains('వాంతులు') || lower.contains('उल्टी')) {
      if (lang == 'te') {
        return ['Pantoprazole మందు ఆర్డర్ (15 నిమి)', 'ఎసిడిటీ ఇంటి చిట్కాలు', 'గ్యాస్ట్రోఎంటరాలజిస్ట్ అపాయింట్‌మెంట్', 'LFT లివర్ టెస్ట్'];
      } else if (lang == 'hi') {
        return ['Pantoprazole दवा ऑर्डर करें', 'एसिडिटी के घरेलू उपाय', 'पेट रोग विशेषज्ञ से परामर्श', 'LFT लिवर टेस्ट बुक करें'];
      }
      return ['Order Pantoprazole (15 mins)', 'Safe home relief for acidity', 'Consult Gastroenterologist', 'Liver & Kidney Profile (LFT+KFT)'];
    }

    // 2. Headache / Migraine
    if (lower.contains('headache') || lower.contains('migraine') || lower.contains('head pain') || lower.contains('తలనొప్పి') || lower.contains('తల నొప్పి') || lower.contains('सिरदर्द') || lower.contains('माइग्रेन')) {
      if (lang == 'te') {
        return ['పారాసిటమాల్ ఆర్డర్ చేయండి (15 నిమి)', 'మైగ్రేన్ ఉపశమన చిట్కాలు', 'న్యూరాలజిస్ట్ డాక్టర్‌ని సంప్రదించండి', 'రక్తపోటు తనిఖీ'];
      } else if (lang == 'hi') {
        return ['पैरासिटामोल दवा मंगाएं', 'सिरदर्द में तुरंत राहत उपाय', 'न्यूरोलॉजिस्ट डॉक्टर से परामर्श', 'बीपी जांच कराएं'];
      }
      return ['Order Pain Relief Medicine (15 mins)', 'Migraine relief techniques', 'Book Neurologist (Dr. Sunil Kumar)', 'Check Blood Pressure'];
    }

    // 3. Cold, Cough & Sore Throat
    if (lower.contains('cough') || lower.contains('cold') || lower.contains('throat') || lower.contains('దగ్గు') || lower.contains('జలుబు') || lower.contains('గొంతు') || lower.contains('खांसी') || lower.contains('जुकाम') || lower.contains('गला')) {
      if (lang == 'te') {
        return ['కాఫ్ సిరప్ & సెట్రిజిన్ ఆర్డర్', 'గొంతు నొప్పికి గార్గల్ చిట్కాలు', 'ENT స్పెషలిస్ట్‌ని సంప్రదించండి', 'స్టీమ్ ఇన్హేలేషన్ గైడ్'];
      } else if (lang == 'hi') {
        return ['कफ सिरप व सिट्रीजिन ऑर्डर करें', 'गले के दर्द के लिए गरारे के उपाय', 'ईएनटी विशेषज्ञ से परामर्श', 'भाप लेने की विधि'];
      }
      return ['Order Cough Syrup & Cetirizine', 'Throat soothing steam & gargles', 'Book ENT Specialist (Dr. Vikram)', 'Viral Infection Panel'];
    }

    // 4. Joint, Knee & Back Pain
    if (lower.contains('knee') || lower.contains('joint') || lower.contains('back') || lower.contains('spine') || lower.contains('arthritis') || lower.contains('మోకాలు') || lower.contains('కీళ్ళ') || lower.contains('నడుము') || lower.contains('घुटनों') || lower.contains('कमर') || lower.contains('जोड़ों')) {
      if (lang == 'te') {
        return ['హీట్ థెరపీ ర్యాప్ ఆర్డర్', 'కీళ్ళ నొప్పుల వ్యాయామాలు', 'ఆర్థోపెడిక్ డాక్టర్ కన్సల్టేషన్', 'బోన్ డెన్సిటీ & కాల్షియం టెస్ట్'];
      } else if (lang == 'hi') {
        return ['हीट थेरेपी नी-रैप मंगाएं', 'जोड़ों के दर्द के सरल व्यायाम', 'ऑर्थोपेडिक डॉक्टर से परामर्श', 'कैल्शियम व विटामिन डी टेस्ट'];
      }
      return ['Order Heat Therapy Knee Wrap', 'Safe knee joint exercises', 'Consult Orthopedic Surgeon (Dr. Naveen)', 'Calcium & Vitamin D Lab Panel'];
    }

    // 5. Fever & Infection
    if (lower.contains('fever') || lower.contains('temp') || lower.contains('జ్వరం') || lower.contains('బుఖార్') || lower.contains('बुखार')) {
      if (lang == 'te') {
        return ['పారాసిటమాల్ 650mg ఆర్డర్ (15 నిమి)', 'జ్వరం తగ్గించే ఇంటి చిట్కాలు', 'CBC & డెంగ్యూ టెస్ట్ బుక్ చేయండి', 'వైద్యుడిని సంప్రదించండి'];
      } else if (lang == 'hi') {
        return ['पैरासिटामोल 650mg ऑर्डर करें', 'बुखार कम करने के घरेलू उपाय', 'सीबीसी और डेंगू टेस्ट बुक करें', 'डॉक्टर से वीडियो परामर्श'];
      }
      return ['Order Paracetamol 650mg (15 mins)', 'Safe fever home care & hydration', 'Book CBC & Dengue Antigen Test', 'Consult Telehealth Doctor'];
    }

    // Do NOT show suggestions for questions that don't need them
    return [];
  }

  /// Extract clinical symptoms from text across English, Telugu, and Hindi
  static List<String> extractSymptoms(String text, String lang) {
    final lower = text.toLowerCase();
    final List<String> detected = [];

    final map = {
      'Fever & Chills': [
        'fever', 'temperature', 'chills', 'shivering', '100', '101', '102', '103', '104',
        'జ్వరం', 'చలి', 'బుఖార్', 'तापमान', 'बुखार', 'कपकपी',
        'jwaram', 'jvaram', 'bukhar', 'tapman'
      ],
      'Headache & Migraine': [
        'headache', 'head pain', 'migraine', 'throbbing head',
        'తలనొప్పి', 'తల నొప్పి', 'మైగ్రేన్', 'सिरदर्द', 'सिर दर्द', 'माइग्रेन',
        'thalanoppi', 'thala noppi', 'sar dard', 'sir dard'
      ],
      'Cold, Cough & Throat': [
        'throat', 'cough', 'cold', 'sore throat', 'congestion', 'runny nose', 'pharyngitis',
        'గొంతు', 'దగ్గు', 'జలుబు', 'ముక్కు కారడం', 'खांसी', 'जुकाम', 'गले में खराश', 'गला दर्द',
        'gonthu', 'daggu', 'jalubu', 'khansi', 'jukham', 'sardi'
      ],
      'Body Ache & Fatigue': [
        'body pain', 'body ache', 'muscle pain', 'fatigue', 'weakness', 'tiredness',
        'ఒంటి నొప్పులు', 'ఒళ్ళు నొప్పులు', 'నీరసం', 'బలహీనత', 'बदन दर्द', 'कमजोरी', 'थकान',
        'nerasam', 'onti noppulu', 'ollu noppi', 'badan dard', 'kamzori'
      ],
      'Acidity & Gastric': [
        'acidity', 'acid reflux', 'heartburn', 'gas', 'bloating', 'belching', 'gerd',
        'ఎసిడిటీ', 'గ్యాస్', 'మంట', 'छाती में जलन', 'गैस', 'एसिडिटी',
        'kadupulo manta'
      ],
      'Stomach Ache & Nausea': [
        'stomach', 'abdomen', 'cramps', 'vomit', 'nausea', 'loose motions', 'diarrhea',
        'కడుపు నొప్పి', 'వాంతులు', 'విరేచనాలు', 'జీర్ణసమస్య', 'पेट दर्द', 'उल्टी', 'दस्त',
        'kadupu noppi', 'pait dard', 'pet dard'
      ],
      'Joint & Knee Pain': [
        'joint', 'knee', 'backache', 'back pain', 'spine', 'arthritis', 'sciatica',
        'మోకాలు', 'కీళ్ళ', 'నడుము నొప్పి', 'వెన్ను నొప్పి', 'घुटनों में दर्द', 'जोड़ों का दर्द', 'कमर दर्द',
        'mokalu', 'keella', 'nadumu noppi', 'ghutne'
      ],
      'Hypertension & Cardiac': [
        'bp', 'blood pressure', 'chest pain', 'chest tightness', 'palpitations', 'heart rate',
        'రక్తపోటు', 'బ్లడ్ ప్రెషర్', 'ఛాతీ నొప్పి', 'గుండె దడ', 'बीपी', 'रक्तचाप',
        'chathi noppi', 'gunde noppi', 'seene me dard'
      ],
      'Diabetes & High Sugar': [
        'sugar', 'diabetes', 'glucose', 'frequent thirst', 'frequent urination',
        'షుగర్', 'మధుమేహం', 'డయాబెటిస్', 'शुगर', 'मधुमेह'
      ],
      'Skin Allergy & Rash': [
        'rash', 'itching', 'allergy', 'redness', 'hive',
        'దురద', 'అలర్జీ', 'దద్దుర్లు', 'खुजली', 'एलर्जी',
        'durada', 'khujli'
      ],
      'Eye Irritation': [
        'eye pain', 'eye redness', 'burning eyes',
        'కంటి నొప్పి', 'కళ్ళు ఎర్రబడటం', 'आंख में दर्द',
        'kanti noppi', 'aankh dard'
      ],
    };

    map.forEach((symptom, keywords) {
      for (final kw in keywords) {
        if (lower.contains(kw)) {
          if (!detected.contains(symptom)) detected.add(symptom);
          break;
        }
      }
    });

    return detected;
  }

  static String _categorizeQuery(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('chest pain') || lower.contains('unconscious') || lower.contains('severe breath') || lower.contains('heart attack') || lower.contains('గుండె నొప్పి') || lower.contains('chathi noppi') || lower.contains('seene me dard')) {
      return 'Emergency Urgent';
    }
    if (lower.contains('fever') || lower.contains('chills') || lower.contains('101') || lower.contains('102') || lower.contains('జ్వరం') || lower.contains('బుఖార్') || lower.contains('बुखार') || lower.contains('jwaram') || lower.contains('bukhar')) {
      return 'Fever & Viral Infection';
    }
    if (lower.contains('throat') || lower.contains('cough') || lower.contains('cold') || lower.contains('congestion') || lower.contains('గొంతు') || lower.contains('దగ్గు') || lower.contains('खांसी') || lower.contains('gonthu') || lower.contains('daggu') || lower.contains('khansi')) {
      return 'Upper Respiratory & ENT';
    }
    if (lower.contains('headache') || lower.contains('migraine') || lower.contains('తలనొప్పి') || lower.contains('सिरदर्द') || lower.contains('thalanoppi') || lower.contains('sar dard')) {
      return 'Headache & Neurological';
    }
    if (lower.contains('stomach') || lower.contains('acidity') || lower.contains('gas') || lower.contains('vomit') || lower.contains('loose motions') || lower.contains('కడుపు') || lower.contains('ఎసిడిటీ') || lower.contains('पेट') || lower.contains('kadupu') || lower.contains('pait dard') || lower.contains('pet dard')) {
      return 'Gastroenterology & Acidity';
    }
    if (lower.contains('knee') || lower.contains('joint') || lower.contains('back') || lower.contains('arthritis') || lower.contains('మోకాలు') || lower.contains('కీళ్ళ') || lower.contains('घुटनों') || lower.contains('जोड़ों') || lower.contains('mokalu') || lower.contains('ghutne')) {
      return 'Orthopedic & Joint Care';
    }
    if (lower.contains('sugar') || lower.contains('diabetes') || lower.contains('షుగర్') || lower.contains('मधुमेह')) {
      return 'Diabetes & Metabolic Care';
    }
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('palpitations') || lower.contains('రక్తపోటు') || lower.contains('रक्तचाप')) {
      return 'Cardiology & Hypertension';
    }
    if (lower.contains('rash') || lower.contains('itching') || lower.contains('allergy') || lower.contains('దురద') || lower.contains('खुजली')) {
      return 'Dermatology & Allergy';
    }
    return 'General Clinical Inquiry';
  }

  static NvidiaAiResponse _buildFallbackResponse({
    required String userQuery,
    required String lang,
    required bool isGreeting,
    required bool isShortQuery,
    required bool userWantsMedicines,
    String? patientName,
    int? patientAge,
    List<String> symptoms = const [],
    String? symptomDuration,
    String? knownSeverity,
    String? knownPastHistory,
    String? knownExistingMeds,
  }) {
    final reply = MedicalSlmEngineService.instance.generateConversationalDoctorGuidance(
      userQuery: userQuery,
      lang: lang,
      patientName: patientName,
      currentSymptoms: symptoms,
      symptomDuration: symptomDuration,
      wantsMedicines: userWantsMedicines,
    );

    return NvidiaAiResponse(
      content: reply,
      detectedSymptoms: symptoms.isNotEmpty ? symptoms : extractSymptoms(userQuery, lang),
      wantsMedicines: userWantsMedicines,
      actionSuggestions: _generateSuggestions(
        lang: lang,
        query: userQuery,
        patientName: patientName,
        symptoms: symptoms,
      ),
      triageCategory: _categorizeQuery(userQuery),
    );
  }
}
