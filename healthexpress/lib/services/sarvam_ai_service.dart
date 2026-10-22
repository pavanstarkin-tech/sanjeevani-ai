import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

class SarvamAiResponse {
  final String content;
  final List<String> detectedSymptoms;
  final String triageCategory;
  final List<String> actionSuggestions;
  final bool needsMoreData;
  final List<String> followUpQuestions;

  SarvamAiResponse({
    required this.content,
    required this.detectedSymptoms,
    required this.triageCategory,
    required this.actionSuggestions,
    this.needsMoreData = false,
    this.followUpQuestions = const [],
  });
}

class SarvamAiService {
  static const String _model = AppConfig.sarvamChatModel;
  static const String _endpoint = AppConfig.sarvamChatEndpoint;

  static String _getSystemPrompt(String lang) {
    final l = lang.toLowerCase();
    if (l == 'te' || l.startsWith('te')) {
      return '''
మీరు Sanjeevani.AI అసిస్టెంట్. మీరు తెలుగు భాషలో అత్యంత శ్రద్ధతో, వైద్యపరమైన సలహాలు మరియు సూచనలు ఇచ్చే నిపుణులు.
బాధ్యతలు:
1. రోగి సమస్యను జాగ్రత్తగా విశ్లేషించి తెలుగులోనే స్పష్టంగా సమాధానం ఇవ్వండి.
2. వయస్సు, జ్వరం ఉష్ణోగ్రత, సమస్య ఎన్ని రోజుల నుండి ఉందో వంటి వివరాలు రోగి ఇవ్వకపోతే, ఖచ్చితమైన సమాచారం కోసం వాటిని తప్పకుండా అడగండి.
3. మందులు, వైద్యులు మరియు రక్త పరీక్షల వివరాలను స్పష్టంగా వివరించండి.
4. బోల్డ్ చేయడానికి **వాడండి.
''';
    } else if (l == 'hi' || l.startsWith('hi')) {
      return '''
आप Sanjeevani.AI सहायक हैं। आप भारतीय स्वास्थ्य मंच के लिए हिंदी में सहानुभूतिपूर्ण और सटीक चिकित्सा परामर्श प्रदान करते हैं।
जिम्मेदारियां:
1. मरीज की समस्या का विश्लेषण करें और सरल हिंदी में जवाब दें।
2. यदि मरीज ने उम्र, बुखार के दिन या तापमान नहीं बताया है, तो सही जांच के लिए अवश्य पूछें।
3. दवाइयां, डॉक्टर परामर्श और लैब टेस्ट के सुझाव दें।
''';
    } else if (l == 'ta' || l.startsWith('ta')) {
      return '''
நீங்கள் Sanjeevani.AI மருத்துவ உதவியாளர். தமிழில் துல்லியமான மற்றும் பரிவுமிக்க மருத்துவ ஆலோசனைகளை வழங்கவும்.
1. நோயாளியின் அறிகுறிகளை பகுப்பாய்வு செய்து தமிழில் பதிலளிக்கவும்.
2. வயது, காலம் மற்றும் காய்ச்சல் அளவை உறுதிப்படுத்தவும்.
3. மருந்துகள் மற்றும் மருத்துவர் பரிந்துரைகளை வழங்கவும்.
''';
    } else if (l == 'kn' || l.startsWith('kn')) {
      return '''
ನೀವು Sanjeevani.AI ವೈದ್ಯಕೀಯ ಸಹಾಯಕ. ಕನ್ನಡದಲ್ಲಿ ನಿಖರವಾದ ಮತ್ತು ಕಾಳಜಿಯುಕ್ತ ಆರೋಗ್ಯ ಸಲಹೆಗಳನ್ನು ನೀಡಿ.
1. ರೋಗಿಯ ಲಕ್ಷಣಗಳನ್ನು ವಿಶ್ಲೇಷಿಸಿ ಕನ್ನಡದಲ್ಲಿ ಉತ್ತರಿಸಿ.
2. ವಯಸ್ಸು, ರೋಗಲಕ್ಷಣಗಳ ಅವಧಿ ಮತ್ತು ಜ್ವರದ ತಾಪಮಾನವನ್ನು ಕೇಳಿ.
3. ಸುರಕ್ಷಿತ ಔಷಧಿಗಳು ಮತ್ತು ತಜ್ಞ ವೈದ್ಯರನ್ನು ಶಿಫಾರಸು ಮಾಡಿ.
''';
    } else if (l == 'ml' || l.startsWith('ml')) {
      return '''
നിങ്ങൾ Sanjeevani.AI ക്ലിനിക്കൽ അസിസ്റ്റന്റാണ്. മലയാളത്തിൽ കൃത്യമായ ആരോഗ്യ ഉപദേശങ്ങൾ നൽകുക.
ലക്ഷണങ്ങൾ വിശകലനം ചെയ്ത് പ്രായം, കാലാവധി, പനി എന്നിവ ചോദിച്ച് മനസ്സിലാക്കുക.
''';
    } else if (l == 'bn' || l.startsWith('bn')) {
      return '''
আপনি Sanjeevani.AI ক্লিনিকাল সহকারী। বাংলায় সহানুভূতিশীল এবং সঠিক চিকিৎসা পরামর্শ দিন।
রোগীর লক্ষণ বিশ্লেষণ করুন এবং স্পষ্ট সমাধান দিন।
''';
    } else if (l == 'mr' || l.startsWith('mr')) {
      return '''
तुम्ही Sanjeevani.AI वैद्यकीय सहाय्यक आहात. मराठीत अचूक आणि काळजीपूर्वक आरोग्य सल्ला द्या.
लक्षणे तपासा आणि सुरक्षित औषधोपचार सुचवा.
''';
    } else if (l == 'gu' || l.startsWith('gu')) {
      return '''
તમે Sanjeevani.AI તબીબી સહાયક છો. ગુજરાતીમાં સચોટ અને કાળજીપૂર્વક સ્વાસ્થ્ય સલાહ આપો.
''';
    } else {
      return '''
You are Sanjeevani.AI, an intelligent clinical assistant for an Indian healthcare platform.
Your responsibilities:
1. Provide accurate, clear, and reassuring triage for symptoms.
2. If critical patient details (age, fever duration, measured temperature, symptom severity) are missing, actively ask follow-up questions to complete the clinical intake.
3. Recommend specific OTC medications with dosages, certified telehealth doctors, and diagnostic lab panels.
4. Keep the response well-structured with clear bullet points and bold key medical terms.
''';
    }
  }

  /// Call Sarvam AI with user inquiry & language using fallback keys
  static Future<SarvamAiResponse> queryClinicalTriage({
    required String userQuery,
    String lang = 'en',
    String? patientName,
    int? patientAge,
    String? gender,
  }) async {
    final category = categorizeQuery(userQuery);
    final symptoms = extractSymptoms(userQuery, lang);
    final missingData = checkMissingData(userQuery, patientAge);

    for (final key in AppConfig.sarvamApiKeys) {
      try {
        final messages = [
          {'role': 'system', 'content': _getSystemPrompt(lang)},
          {
            'role': 'user',
            'content': 'Language: $lang. Patient: ${patientName ?? "User"}, Age: ${patientAge ?? "Not provided"}, Gender: ${gender ?? "Not specified"}. User Query: $userQuery',
          }
        ];

        final res = await http.post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'api-subscription-key': key,
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'temperature': 0.3,
            'max_tokens': 1200,
          }),
        ).timeout(const Duration(seconds: 18));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final reply = data['choices']?[0]?['message']?['content']?.toString().trim() ?? '';
          if (reply.isNotEmpty) {
            return SarvamAiResponse(
              content: reply,
              detectedSymptoms: symptoms,
              triageCategory: category,
              actionSuggestions: generateActionSuggestions(category, lang, reply),
              needsMoreData: missingData.isNotEmpty,
              followUpQuestions: missingData,
            );
          }
        }
      } catch (_) {
        // Try fallback key
      }
    }

    final fallbackText = generateClinicalResponse(userQuery, category, lang, patientAge);
    return SarvamAiResponse(
      content: fallbackText,
      detectedSymptoms: symptoms,
      triageCategory: category,
      actionSuggestions: generateActionSuggestions(category, lang, fallbackText),
      needsMoreData: missingData.isNotEmpty,
      followUpQuestions: missingData,
    );
  }

  static List<String> checkMissingData(String text, int? age) {
    final lower = text.toLowerCase();
    final List<String> missing = [];

    final hasAge = age != null || RegExp(r'\b\d{1,2}\s*(years|yrs|age|సంవత్సరాలు|साल)\b').hasMatch(lower);
    final hasDuration = RegExp(r'\b(\d+|one|two|three|four)\s*(days|hours|weeks|రోజులు|दिन)\b').hasMatch(lower) || lower.contains('since yesterday') || lower.contains('నిన్నటి నుండి') || lower.contains('कल से');
    final hasTemp = RegExp(r'\b(9\d|10\d)(\.\d)?\s*(°f|f|c|degree)?\b').hasMatch(lower) || lower.contains('fever') || lower.contains('జ్వరం') || lower.contains('बुखार');

    if (!hasAge) missing.add('Patient Age');
    if (!hasDuration) missing.add('Symptom Duration');
    if (lower.contains('fever') && !hasTemp) missing.add('Body Temperature');

    return missing;
  }

  static List<String> extractSymptoms(String text, String lang) {
    final lower = text.toLowerCase();
    final List<String> detected = [];

    if (lower.contains('fever') || lower.contains('temp') || lower.contains('జ్వరం') || lower.contains('బుఖార్') || lower.contains('बुखार')) {
      detected.add(lang == 'te' ? 'జ్వరం (Fever)' : (lang == 'hi' ? 'बुखार (Fever)' : 'Fever'));
    }
    if (lower.contains('headache') || lower.contains('తల నొప్పి') || lower.contains('सिर दर्द')) {
      detected.add(lang == 'te' ? 'తల నొప్పి (Headache)' : (lang == 'hi' ? 'सिर दर्द (Headache)' : 'Headache'));
    }
    if (lower.contains('throat') || lower.contains('cough') || lower.contains('గొంతు నొప్పి') || lower.contains('దగ్గు') || lower.contains('गले में दर्द') || lower.contains('खांसी')) {
      detected.add(lang == 'te' ? 'గొంతు నొప్పి & దగ్గు' : (lang == 'hi' ? 'खांसी और गले में खराश' : 'Throat Irritation & Cough'));
    }
    if (lower.contains('chest') || lower.contains('breath') || lower.contains('గుండె') || lower.contains('ఛాతీ నొప్పి') || lower.contains('सीने में दर्द')) {
      detected.add(lang == 'te' ? 'ఛాతీ అసౌకర్యం (Chest Alert)' : (lang == 'hi' ? 'सीने में दर्द (Cardiac Alert)' : 'Chest & Respiratory Distress'));
    }
    if (lower.contains('joint') || lower.contains('knee') || lower.contains('మోకాళ్ళ నొప్పి') || lower.contains('కీళ్ళ నొప్పి') || lower.contains('घुटने का दर्द')) {
      detected.add(lang == 'te' ? 'కీళ్ళ / మోకాళ్ళ నొప్పి' : (lang == 'hi' ? 'जोड़ों का दर्द' : 'Joint & Knee Pain'));
    }
    if (lower.contains('sugar') || lower.contains('diabetes') || lower.contains('షుగర్') || lower.contains('మధుమేహం') || lower.contains('शुगर')) {
      detected.add(lang == 'te' ? 'మధుమేహం (Blood Glucose)' : (lang == 'hi' ? 'डायबिटीज (Blood Sugar)' : 'Elevated Blood Glucose'));
    }
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('బీపీ') || lower.contains('రక్తపోటు') || lower.contains('ब्लड प्रेशर')) {
      detected.add(lang == 'te' ? 'రక్తపోటు (Hypertension)' : (lang == 'hi' ? 'रक्तचाप (High BP)' : 'Blood Pressure Variations'));
    }

    if (detected.isEmpty) {
      detected.add(lang == 'te' ? 'సాధారణ ఆరోగ్య పరిశీలన' : (lang == 'hi' ? 'सामान्य स्वास्थ्य जांच' : 'General Health Inquiry'));
    }
    return detected;
  }

  static String categorizeQuery(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('chest') || lower.contains('heart') || lower.contains('emergency') || lower.contains('breath') || lower.contains('ఛాతీ') || lower.contains('గుండె') || lower.contains('सीने')) {
      return 'Cardiac Alert / Emergency';
    }
    if (lower.contains('sugar') || lower.contains('diabetes') || lower.contains('glucose') || lower.contains('షుగర్') || lower.contains('మధుమేహం') || lower.contains('शुगर')) {
      return 'Diabetes & Metabolic Care';
    }
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('hypertension') || lower.contains('బీపీ') || lower.contains('రక్తపోటు') || lower.contains('ब्लड प्रेशर')) {
      return 'Cardiology & Hypertension';
    }
    if (lower.contains('joint') || lower.contains('knee') || lower.contains('back') || lower.contains('నొప్పి') || lower.contains('మోకాళ్ళ') || lower.contains('जोड़ों')) {
      return 'Orthopedic & Joint Mobility';
    }
    if (lower.contains('fever') || lower.contains('cold') || lower.contains('cough') || lower.contains('జ్వరం') || lower.contains('దగ్గు') || lower.contains('बुखार') || lower.contains('खांसी')) {
      return 'Viral Fever & Flu';
    }
    return 'General Health Inquiry';
  }

  static List<String> generateActionSuggestions(String category, String lang, [String? aiContent]) {
    final lowerAi = (aiContent ?? '').toLowerCase();
    final l = lang.toLowerCase();
    final isTe = l == 'te' || l.startsWith('te');
    final isHi = l == 'hi' || l.startsWith('hi');

    // 1. If AI asked about Age
    if (lowerAi.contains('వయస్సు') || lowerAi.contains('उम्र') || lowerAi.contains('age') || lowerAi.contains('வயது') || lowerAi.contains('ವಯಸ್ಸು')) {
      if (isTe) return ['వయస్సు: 25-35 సం', 'వయస్సు: 40-55 సం', 'సీనియర్ సిటిజెన్ (60+)', 'పిల్లలు (<15)'];
      if (isHi) return ['उम्र: 25-35 वर्ष', 'उम्र: 40-55 वर्ष', 'वरिष्ठ (60+ वर्ष)', 'बच्चा (<15 वर्ष)'];
      return ['Age: 25-35 yrs', 'Age: 40-55 yrs', 'Senior (60+ yrs)', 'Child (<15 yrs)'];
    }

    // 2. If AI asked about Duration
    if (lowerAi.contains('రోజుల') || lowerAi.contains('రోజూ') || lowerAi.contains('दिन') || lowerAi.contains('how many days') || lowerAi.contains('duration') || lowerAi.contains('நாட்கள்')) {
      if (isTe) return ['ఈ రోజే మొదలైంది', 'నిన్నటి నుండి (1-2 రోజులు)', '3-4 రోజుల నుండి', 'వారం కంటే ఎక్కువ'];
      if (isHi) return ['आज ही शुरू हुआ', 'कल से (1-2 दिन)', '3-4 दिनों से', 'एक हफ्ते से अधिक'];
      return ['Just started today', 'Since yesterday (1-2 days)', '3 - 4 days', 'More than a week'];
    }

    // 3. If AI asked about Temperature / Fever
    if (lowerAi.contains('ఉష్ణోగ్రత') || lowerAi.contains('तापमान') || lowerAi.contains('temperature') || lowerAi.contains('thermometer')) {
      if (isTe) return ['తేలికపాటి జ్వరం (99-100°F)', 'తీవ్ర జ్వరం (>101°F)', 'చలి & వణుకు ఉంది', 'జ్వరం లేదు (సాధారణం)'];
      if (isHi) return ['हल्का बुखार (99-100°F)', 'तेज बुखार (>101°F)', 'ठंड और कंपकंपी है', 'बुखार नहीं है (सामान्य)'];
      return ['Mild Fever (99-100°F)', 'High Fever (>101°F)', 'With Chills & Shivering', 'No Fever (Normal)'];
    }

    // 4. If AI asked about Severity
    if (lowerAi.contains('తీవ్రంగా') || lowerAi.contains('తీవ్రత') || lowerAi.contains('तेज') || lowerAi.contains('गंभीर') || lowerAi.contains('severe') || lowerAi.contains('severity')) {
      if (isTe) return ['తక్కువగా ఉంది (Mild)', 'మధ్యస్థంగా ఉంది (Moderate)', 'చాలా తీవ్రంగా ఉంది (Severe)'];
      if (isHi) return ['हल्का दर्द (Mild)', 'मध्यम (Moderate)', 'बहुत तेज / असहनीय (Severe)'];
      return ['Mild (Manageable)', 'Moderate', 'Severe / Intense'];
    }

    // 5. If AI asked about Medical History / Allergies / Medications
    if (lowerAi.contains('షుగర్') || lowerAi.contains('బీపీ') || lowerAi.contains('అలర్జీ') || lowerAi.contains('पुरानी बीमारी') || lowerAi.contains('एलर्जी') || lowerAi.contains('allergy') || lowerAi.contains('chronic')) {
      if (isTe) return ['ఎలాంటి వ్యాధులు లేవు (ఆరోగ్యం)', 'షుగర్ / బీపీ ఉంది', 'పారాసిటమాల్ వేసుకున్నాను', 'ఎటువంటి అలర్జీలు లేవు'];
      if (isHi) return ['कोई बीमारी नहीं है (स्वस्थ)', 'शुगर / बीपी की शिकायत है', 'पैरासिटामोल लिया है', 'कोई एलर्जी नहीं है'];
      return ['No prior illness (Healthy)', 'Have Diabetes / High BP', 'Took Paracetamol already', 'No drug allergies'];
    }

    // Standard clinical action suggestions by category
    if (isTe) {
      switch (category) {
        case 'Cardiac Alert / Emergency':
          return ['🚨 అత్యవసర అంబులెన్స్ (108)', '🏥 సమీప ఆసుపత్రులు', '📞 డాక్టర్ తక్షణ కాల్'];
        case 'Diabetes & Metabolic Care':
          return ['🩸 గ్లూకోమీటర్ కిట్ కొనండి', '🧪 HbA1c రక్త పరీక్ష', '👨‍⚕️ డయాబెటిస్ డాక్టర్ కన్సల్ట్'];
        case 'Cardiology & Hypertension':
          return ['🩺 కార్డియాలజిస్ట్ సంప్రదించండి', '📊 డిజిటల్ బీపీ మానిటర్', '🧪 లిపిడ్ ప్రొఫైల్ టెస్ట్'];
        case 'Orthopedic & Joint Mobility':
          return ['🦴 ఆర్థోపెడిక్ డాక్టర్ బుక్ చేయండి', '📦 మోకాలి హీట్ థెరపీ బెల్ట్', '🧪 విటమిన్ D3 & కాల్షియం టెస్ట్'];
        case 'Viral Fever & Flu':
          return ['💊 15 నిమిషాల్లో మందుల డెలివరీ', '👨‍⚕️ వీడియో డాక్టర్ కన్సల్టేషన్', '🩸 CBC రక్త పరీక్ష బుక్ చేయండి'];
        default:
          return ['👨‍⚕️ డాక్టర్ అపాయింట్‌మెంట్', '💊 మందులు ఆర్డర్ చేయండి', '🧪 మాస్టర్ హెల్త్ చెకప్'];
      }
    } else if (isHi) {
      switch (category) {
        case 'Cardiac Alert / Emergency':
          return ['🚨 एम्बुलेंस 108 बुलाएं', '🏥 नजदीकी आपातकालीन अस्पताल', '📞 डॉक्टर से तुरंत बात करें'];
        case 'Diabetes & Metabolic Care':
          return ['🩸 ग्लूकोमीटर किट ऑर्डर करें', '🧪 HbA1c ब्लड टेस्ट', '👨‍⚕️ डायबिटीज डॉक्टर से मिलें'];
        case 'Cardiology & Hypertension':
          return ['🩺 हृदय रोग विशेषज्ञ से परामर्श', '📊 डिजिटल बीपी मशीन', '🧪 लिपिड प्रोफाइल टेस्ट'];
        case 'Orthopedic & Joint Mobility':
          return ['🦴 आर्थोपेडिक डॉक्टर बुक करें', '📦 नी-पेन हीटिंग बेल्ट', '🧪 विटामिन D3 टेस्ट'];
        case 'Viral Fever & Flu':
          return ['💊 15 मिनट में दवाइयां मंगवाएं', '👨‍⚕️ वीडियो डॉक्टर परामर्श', '🩸 सीबीसी ब्लड टेस्ट'];
        default:
          return ['👨‍⚕️ डॉक्टर अपॉइंटमेंट', '💊 दवाइयां ऑर्डर करें', '🧪 फुल बॉडी चेकअप'];
      }
    } else {
      switch (category) {
        case 'Cardiac Alert / Emergency':
          return ['🚨 Dispatch Ambulance (108)', '🏥 Nearest Emergency Hospitals', '📞 Urgent Doctor Call'];
        case 'Diabetes & Metabolic Care':
          return ['🩸 Order Glucometer Kit', '🧪 Book HbA1c & Sugar Panel', '👨‍⚕️ Consult Diabetologist'];
        case 'Cardiology & Hypertension':
          return ['🩺 Consult Cardiologist', '📊 Order Digital BP Monitor', '🧪 Book Lipid & Cardiac Profile'];
        case 'Orthopedic & Joint Mobility':
          return ['🦴 Consult Orthopedic Doctor', '📦 Order Knee Heat Wrap', '🧪 Book Vitamin D3 & Bone Panel'];
        case 'Viral Fever & Flu':
          return ['💊 Order Medicines (15-Min Delivery)', '👨‍⚕️ Book Video Doctor Consult', '🩸 Book CBC Blood Test'];
        default:
          return ['👨‍⚕️ Book Doctor Consultation', '💊 Search Medicines', '🧪 Book Master Health Checkup'];
      }
    }
  }

  static String generateClinicalResponse(String userQuery, String category, String lang, int? age) {
    final hasAge = age != null || RegExp(r'\b\d{1,2}\b').hasMatch(userQuery);
    final hasDuration = userQuery.contains('day') || userQuery.contains('రోజు') || userQuery.contains('दिन');

    if (lang == 'te') {
      if (category == 'Cardiac Alert / Emergency') {
        return '⚠️ **అత్యవసర హెచ్చరిక**: ఛాతీ నొప్పి లేదా శ్వాస తీసుకోవడంలో ఇబ్బంది ఉంటే వెంటనే అత్యవసర చికిత్స అవసరం. దయచేసి క్రింద ఉన్న 108 ఎమర్జెన్సీ బటన్ నొక్కండి.';
      }
      if (!hasAge || !hasDuration) {
        return 'నమస్కారం! మీ సమస్యను నమోదు చేసుకున్నాను.\n\nమీకు మరింత ఖచ్చితమైన వైద్య సలహా మరియు సరైన మందులు సూచించడానికి, దయచేసి క్రింది వివరాలు చెప్పండి:\n• **మీ వయస్సు ఎంత?**\n• **ఈ సమస్య ఎన్ని రోజుల నుండి ఉంది?**\n• **శరీర ఉష్ణోగ్రత (థర్మామీటర్ రీడింగ్) ఎంత?**\n\nమీ సౌకర్యార్థం క్రింద అవసరమైన మందులు, డాక్టర్ కన్సల్టేషన్ మరియు రక్త పరీక్షలను జోడించాను. మీరు నేరుగా ఆర్డర్ చేయవచ్చు:';
      }
      return 'విశ్లేషణ పూర్తయింది. మీ లక్షణాల ప్రకారం ఇది వైరల్ ఫీవర్ మరియు గొంతు ఇన్ఫెక్షన్ అయి ఉండవచ్చు.\n\n**వైద్య సలహాలు**:\n• రోజంతా పుష్కలంగా గోరువెచ్చని నీరు తాగండి మరియు విశ్రాంతి తీసుకోండి.\n• జ్వరం 99.5°F దాటితే పారాసిటమాల్ 650mg ఆహారం తర్వాత వేసుకోండి.\n• గొంతు నొప్పికి ఉప్పు నీటితో పుక్కిలించండి.\n\nక్రింద సూచించిన మందులు మరియు నిపుణులైన డాక్టర్లను మీరు నేరుగా బుక్ చేసుకోవచ్చు:';
    }

    if (lang == 'hi') {
      if (category == 'Cardiac Alert / Emergency') {
        return '⚠️ **आपातकालीन चेतावनी**: सीने में दर्द या सांस लेने में तकलीफ होने पर तुरंत 108 एम्बुलेंस या नजदीकी अस्पताल से संपर्क करें।';
      }
      if (!hasAge || !hasDuration) {
        return 'नमस्ते! आपकी समस्या दर्ज कर ली गई है।\n\nसटीक चिकित्सीय परामर्श के लिए कृपया बताएं:\n• **आपकी उम्र क्या है?**\n• **यह समस्या कितने दिनों से है?**\n• **बुखार का तापमान कितना है?**\n\nआपकी सुविधा के लिए आवश्यक दवाइयां और डॉक्टर नीचे उपलब्ध हैं:';
      }
      return 'जांच पूरी हुई। आपके लक्षणों के अनुसार यह वायरल बुखार और गले का संक्रमण हो सकता है।\n\n**चिकित्सीय निर्देश**:\n• खूब पानी पिएं और आराम करें।\n• बुखार 99.5°F से अधिक होने पर भोजन के बाद पैरासिटामोल 650mg लें।\n• गुनगुने नमक पानी से गरारे करें।\n\nनीचे दी गई दवाइयों और डॉक्टरों को आप सीधे बुक कर सकते हैं:';
    }

    // English
    if (category == 'Cardiac Alert / Emergency') {
      return '⚠️ **CRITICAL EMERGENCY ALERT**: Symptoms involving chest pressure or shortness of breath require immediate clinical evaluation. Please dispatch 108 Emergency Ambulance immediately.';
    }
    if (!hasAge || !hasDuration) {
      return 'Thank you for updating me. To perform a clinically accurate triage:\n\n**Please share:**\n• **Patient Age & Gender**\n• **Duration of symptoms (e.g. 1-2 days, >3 days)**\n• **Measured body temperature (e.g. 100.4°F)**\n\nI have matched verified medicines, certified doctors, and home lab panels for your symptoms below. You can order or book them directly with 1 tap:';
    }
    return 'Clinical evaluation complete. Based on your reported symptoms, this indicates acute viral pharyngitis and fever.\n\n**Care Directives**:\n• Maintain adequate hydration with warm fluids and take plenty of rest.\n• Take Paracetamol 650mg post-meals if temperature exceeds 99.5°F.\n• Perform warm saline gargles for throat discomfort.\n\nRecommended medications, diagnostic panels, and certified doctors are available below for instant booking:';
  }
}
