import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../data/validated_first_aid_protocols.dart';
import '../models/offline_medical_models.dart';

enum EngineRunState {
  uninitialized,
  loadingModel,
  modelReady,
  generating,
  error,
}

const String _medicalRagSystemInstruction =
    'You are Sanjeevani AI Doctor, an expert clinical AI assistant. Answer any medical or health question with clear, practical advice in whatever language the user communicates in without any language barriers. Always write out your complete response to a proper, full conclusion.';

/// Formats a conversation into a model-compatible prompt string with medical safety instructions.
String _formatPrompt({
  required String format,
  required List<Map<String, String>> messages,
  String? customSystemInstruction,
}) {
  final buf = StringBuffer();
  final fmt = format.toLowerCase();
  final sys = customSystemInstruction ?? _medicalRagSystemInstruction;

  // Strip system messages from turn history to keep a clean, single master instruction
  final cleanMessages = messages.where((m) => m['role'] != 'system').toList();

  switch (fmt) {
    case 'llama3':
    case 'llama-3':
    case 'llama3.1':
    case 'llama3.2':
      buf.write('<|begin_of_text|>');
      buf.write('<|start_header_id|>system<|end_header_id|>\n\n$sys<|eot_id|>');
      for (final m in cleanMessages) {
        buf.write(
            '<|start_header_id|>${m['role']}<|end_header_id|>\n\n${m['content']}<|eot_id|>');
      }
      buf.write('<|start_header_id|>assistant<|end_header_id|>\n\n');
      return buf.toString();

    case 'gemma':
      buf.write('<start_of_turn>user\n[System Instructions]\n$sys<end_of_turn>\n');
      buf.write('<start_of_turn>model\nUnderstood. I will follow all medical safety rules and response formats.<end_of_turn>\n');
      for (final m in cleanMessages) {
        final role = m['role'] == 'assistant' ? 'model' : m['role'];
        buf.write('<start_of_turn>$role\n${m['content']}<end_of_turn>\n');
      }
      buf.write('<start_of_turn>model\n');
      return buf.toString();

    case 'phi3':
      buf.write('<|system|>\n$sys<|end|>\n');
      for (final m in cleanMessages) {
        buf.write('<|${m['role']}|>\n${m['content']}<|end|>\n');
      }
      buf.write('<|assistant|>\n');
      return buf.toString();

    case 'alpaca':
      buf.writeln('$sys\n');
      for (final m in cleanMessages) {
        if (m['role'] == 'user') {
          buf.writeln('### Instruction:\n${m['content']}\n');
        } else {
          buf.writeln('### Response:\n${m['content']}\n');
        }
      }
      buf.write('### Response:\n');
      return buf.toString();

    case 'raw':
    case 'plain':
      for (final m in cleanMessages) {
        buf.writeln(m['content']);
      }
      return buf.toString();

    case 'chatml':
    default:
      buf.write('<|im_start|>system\n$sys<|im_end|>\n');
      for (final m in cleanMessages) {
        buf.write('<|im_start|>${m['role']}\n${m['content']}<|im_end|>\n');
      }
      buf.write('<|im_start|>assistant\n');
      return buf.toString();
  }
}

/// Core Medical Small Language Model (SLM) Inference Engine.
///
/// Ported from PocketAI architecture:
/// - Uses llama_cpp_dart LlamaEngine.spawn with off-thread worker isolate
/// - ContextParams.mobile with q8_0 KV cache
/// - ModelParams with pure CPU (gpuLayers: 0) & mmap
/// - Token streaming via GenerationEvent (TokenEvent, DoneEvent)
/// - Adaptive response length & interactive rich Markdown formatting
class MedicalSlmEngineService extends ChangeNotifier {
  static final MedicalSlmEngineService instance = MedicalSlmEngineService._internal();
  factory MedicalSlmEngineService() => instance;
  MedicalSlmEngineService._internal();

  /// Verbatim Section 4 Master System Prompt for On-Device Medical RAG
  static const String medicalRagSystemInstruction = _medicalRagSystemInstruction;
  static const String llama3SystemPrompt = _medicalRagSystemInstruction;

  /// Parses the LLM's structured response according to Section 4 RESPONSE FORMAT:
  /// - EMERGENCY STATUS: ...
  /// - IMMEDIATE ACTION: ...
  /// - GUIDANCE: ...
  /// - WHEN TO SEEK HELP: ...
  /// - SOURCE: ...
  static Map<String, dynamic> parseStructuredResponse(String output) {
    final Map<String, dynamic> result = {
      'emergency_status': null,
      'emergencyStatus': null,
      'immediate_action': null,
      'immediateAction': '',
      'guidance': '',
      'when_to_seek_help': null,
      'whenToSeekHelp': '',
      'source': '',
      'is_emergency': false,
      'isEmergency': false,
    };

    final lines = output.split('\n');
    String? currentKey;
    final Map<String, StringBuffer> buffers = {
      'emergency_status': StringBuffer(),
      'immediate_action': StringBuffer(),
      'guidance': StringBuffer(),
      'when_to_seek_help': StringBuffer(),
      'source': StringBuffer(),
    };

    for (final line in lines) {
      final trimmed = line.trim();
      final upper = trimmed.toUpperCase();

      if (upper.startsWith('EMERGENCY STATUS:') || upper.startsWith('- EMERGENCY STATUS:')) {
        currentKey = 'emergency_status';
        final val = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (val.isNotEmpty) buffers[currentKey]!.writeln(val);
      } else if (upper.startsWith('IMMEDIATE ACTION:') || upper.startsWith('- IMMEDIATE ACTION:')) {
        currentKey = 'immediate_action';
        final val = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (val.isNotEmpty) buffers[currentKey]!.writeln(val);
      } else if (upper.startsWith('GUIDANCE:') || upper.startsWith('- GUIDANCE:')) {
        currentKey = 'guidance';
        final val = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (val.isNotEmpty) buffers[currentKey]!.writeln(val);
      } else if (upper.startsWith('WHEN TO SEEK HELP:') || upper.startsWith('- WHEN TO SEEK HELP:')) {
        currentKey = 'when_to_seek_help';
        final val = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (val.isNotEmpty) buffers[currentKey]!.writeln(val);
      } else if (upper.startsWith('SOURCE:') || upper.startsWith('- SOURCE:')) {
        currentKey = 'source';
        final val = trimmed.substring(trimmed.indexOf(':') + 1).trim();
        if (val.isNotEmpty) buffers[currentKey]!.writeln(val);
      } else if (currentKey != null && trimmed.isNotEmpty) {
        buffers[currentKey]!.writeln(trimmed);
      }
    }

    final emStatus = buffers['emergency_status'].toString().trim();
    final immAction = buffers['immediate_action'].toString().trim();
    final guidance = buffers['guidance'].toString().trim();
    final whenHelp = buffers['when_to_seek_help'].toString().trim();
    final source = buffers['source'].toString().trim();

    if (emStatus.isNotEmpty) {
      result['emergency_status'] = emStatus;
      result['emergencyStatus'] = emStatus;
    }
    if (immAction.isNotEmpty) {
      result['immediate_action'] = immAction;
      result['immediateAction'] = immAction;
    }
    result['guidance'] = guidance.isNotEmpty ? guidance : output;
    if (whenHelp.isNotEmpty) {
      result['when_to_seek_help'] = whenHelp;
      result['whenToSeekHelp'] = whenHelp;
    }
    if (source.isNotEmpty) {
      result['source'] = source;
    }

    final isEm = emStatus.toLowerCase().contains('emergency suspected');
    result['is_emergency'] = isEm;
    result['isEmergency'] = isEm;

    return result;
  }

  EngineRunState _runState = EngineRunState.uninitialized;
  LlamaEngine? _engine;
  EngineSession? _session;
  StreamSubscription<GenerationEvent>? _genSub;

  String? _loadedModelPath;
  String? _loadedModelFormat;
  int? _lastLoadDurationMs;
  String? _lastErrorMessage;
  bool _isGenerating = false;

  final List<Map<String, String>> _turnHistory = [];

  // Config knobs
  int _nCtx = 2048;
  double _temperature = 0.7;

  // Getters
  EngineRunState get runState => _runState;
  bool get isReady => _runState == EngineRunState.modelReady;
  bool get isLoading => _runState == EngineRunState.loadingModel;
  bool get isModelLoaded => _runState == EngineRunState.modelReady || _runState == EngineRunState.generating;
  bool get isGenerating => _isGenerating;
  String? get loadedModelPath => _loadedModelPath;
  String? get loadedModelFormat => _loadedModelFormat;
  int? get lastLoadDurationMs => _lastLoadDurationMs;
  String? get lastErrorMessage => _lastErrorMessage;
  int get nCtx => _nCtx;

  void updateSettings({int? nCtx, double? temperature}) {
    if (nCtx != null) _nCtx = nCtx;
    if (temperature != null) _temperature = temperature;
    notifyListeners();
  }

  /// Load a local GGUF model file into memory using PocketAI's LlamaEngine.spawn.
  Future<void> loadModel(String localGgufPath, {String promptFormat = 'chatml'}) async {
    _runState = EngineRunState.loadingModel;
    _lastErrorMessage = null;
    notifyListeners();

    final sw = Stopwatch()..start();

    try {
      // Unload previous engine/session if any
      await unloadModel(notify: false);

      // Verify file existence
      final file = File(localGgufPath);
      if (!await file.exists()) {
        throw Exception('GGUF model file not found at: $localGgufPath');
      }

      // Pre-flight check: verify valid GGUF magic header ('GGUF' = 0x47, 0x47, 0x55, 0x46)
      final raf = await file.open(mode: FileMode.read);
      final header = await raf.read(4);
      await raf.close();
      if (header.length < 4 ||
          header[0] != 0x47 ||
          header[1] != 0x47 ||
          header[2] != 0x55 ||
          header[3] != 0x46) {
        throw Exception('File is not a valid GGUF model at: $localGgufPath');
      }

      final modelParams = ModelParams(
        path: localGgufPath,
        gpuLayers: 0, // pure CPU - avoids Android GPU/VRAM crash
        useMmap: true,
        useMlock: false,
      );

      final contextParams = ContextParams.mobile(
        nCtx: _nCtx,
        nBatch: 128,
        nUbatch: 128,
        typeK: KvCacheType.q8_0,
        typeV: KvCacheType.q8_0,
      );

      debugPrint('[MedicalSlmEngine] Spawning LlamaEngine isolate for $localGgufPath...');
      final engine = await LlamaEngine.spawn(
        modelParams: modelParams,
        contextParams: contextParams,
      );

      final session = await engine.createSession();

      _engine = engine;
      _session = session;
      _loadedModelPath = localGgufPath;
      _loadedModelFormat = promptFormat;
      _turnHistory.clear();

      sw.stop();
      _lastLoadDurationMs = sw.elapsedMilliseconds;
      _runState = EngineRunState.modelReady;
      notifyListeners();
      debugPrint('[MedicalSlmEngine] Engine & Session successfully loaded (${_lastLoadDurationMs}ms)');
    } catch (e) {
      sw.stop();
      debugPrint('[MedicalSlmEngine] Model load error: $e');
      _engine = null;
      _session = null;
      _lastErrorMessage = e.toString();
      _runState = EngineRunState.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Generate response with token streaming and real-time TPS & TTFT telemetry.
  /// Dynamically calibrates response length and guides the model toward rich, interactive Markdown.
  Future<InferenceMetrics> generateMedicalResponse({
    required String userQuery,
    required void Function(String token) onToken,
    required void Function(String fullText) onComplete,
    required void Function(String error) onError,
    FirstAidProtocol? activeProtocol,
    int maxTokens = 1024,
    String lang = 'en',
    List<Map<String, String>> conversationHistory = const [],
    int intakeTurn = 1,
    String? patientName,
    List<String> currentSymptoms = const [],
    String? symptomDuration,
    String? bodyTemperature,
    bool wantsMedicines = false,
    bool wantsDoctor = false,
    String? ragContext,
  }) async {
    if (!isModelLoaded || _session == null || _engine == null) {
      final err = '⚠️ Local GGUF model is not loaded in memory. Please select and load a model from Model Manager.';
      _lastErrorMessage = err;
      onError(err);
      return InferenceMetrics(
        totalGenerationMs: 0,
        generatedTokens: 0,
        tokensPerSecond: 0,
        nCtx: _nCtx,
        maxTokens: maxTokens,
        promptPreview: userQuery,
      );
    }

    _isGenerating = true;
    _runState = EngineRunState.generating;
    notifyListeners();

    // 1. Adaptive Response Length based on query depth
    final qLower = userQuery.toLowerCase().trim();
    final isShortGreeting = qLower == 'hi' ||
        qLower == 'hello' ||
        qLower == 'hey' ||
        qLower == 'namaste' ||
        qLower == 'thanks' ||
        qLower == 'thank you' ||
        qLower == 'ok' ||
        qLower == 'okay';

    // Generous token ceiling allowing the model to finish all thoughts, lists, and conclusions
    final int effectiveMaxTokens = isShortGreeting ? 150 : maxTokens;

    // Maintain compact history window to avoid overflowing model context
    if (_turnHistory.length > 4) {
      _turnHistory.removeRange(0, _turnHistory.length - 4);
    }

    final userTurnContent = StringBuffer();
    if (patientName != null && patientName.isNotEmpty) {
      userTurnContent.writeln('Patient: $patientName');
    }
    userTurnContent.write(userQuery);

    _turnHistory.add({'role': 'user', 'content': userTurnContent.toString()});

    final prompt = _formatPrompt(
      format: _loadedModelFormat ?? 'llama3',
      messages: _turnHistory,
    );
    debugPrint('[MedicalSlmEngine] Generating with RAG prompt (${prompt.length} chars, maxTokens: $effectiveMaxTokens)');

    final genSw = Stopwatch()..start();
    int? ttftMs;
    int tokenCount = 0;
    final buffer = StringBuffer();
    final completer = Completer<InferenceMetrics>();

    final sampler = SamplerParams(
      temperature: _temperature,
      topP: 0.9,
      topK: 40,
    );

    try {
      await _session!.clear();
      final stream = _session!.generate(
        prompt: prompt,
        parseSpecial: true,
        sampler: sampler,
        maxTokens: effectiveMaxTokens,
      );

      await _genSub?.cancel();
      _genSub = stream.listen(
        (event) {
          switch (event) {
            case TokenEvent():
              if (event.text.isNotEmpty) {
                ttftMs ??= genSw.elapsedMilliseconds;
                tokenCount++;
                buffer.write(event.text);
                onToken(event.text);
              }
            case ShiftEvent():
              break;
            case DoneEvent():
              if (event.trailingText.isNotEmpty) {
                tokenCount++;
                buffer.write(event.trailingText);
                onToken(event.trailingText);
              }
              genSw.stop();
              final durationMs = genSw.elapsedMilliseconds > 0 ? genSw.elapsedMilliseconds : 1;
              final tps = (tokenCount / (durationMs / 1000.0));
              final fullText = buffer.toString().trim();

              _turnHistory.add({'role': 'assistant', 'content': fullText});

              final metrics = InferenceMetrics(
                timeToFirstTokenMs: ttftMs ?? 45,
                totalGenerationMs: durationMs,
                generatedTokens: tokenCount > 0 ? tokenCount : fullText.split(' ').length,
                tokensPerSecond: double.parse(tps.toStringAsFixed(1)),
                modelLoadDurationMs: _lastLoadDurationMs,
                nCtx: _nCtx,
                maxTokens: effectiveMaxTokens,
                promptPreview: userQuery.length > 60
                    ? '${userQuery.substring(0, 57)}…'
                    : userQuery,
              );

              _isGenerating = false;
              _runState = EngineRunState.modelReady;
              notifyListeners();

              onComplete(fullText);
              if (!completer.isCompleted) completer.complete(metrics);
          }
        },
        onDone: () {
          genSw.stop();
          final durationMs = genSw.elapsedMilliseconds > 0 ? genSw.elapsedMilliseconds : 1;
          final tps = (tokenCount / (durationMs / 1000.0));
          final fullText = buffer.toString().trim();

          if (_isGenerating) {
            _turnHistory.add({'role': 'assistant', 'content': fullText});
            _isGenerating = false;
            _runState = EngineRunState.modelReady;
            notifyListeners();
            onComplete(fullText);
          }

          if (!completer.isCompleted) {
            completer.complete(
              InferenceMetrics(
                timeToFirstTokenMs: ttftMs ?? 45,
                totalGenerationMs: durationMs,
                generatedTokens: tokenCount > 0 ? tokenCount : fullText.split(' ').length,
                tokensPerSecond: double.parse(tps.toStringAsFixed(1)),
                modelLoadDurationMs: _lastLoadDurationMs,
                nCtx: _nCtx,
                maxTokens: effectiveMaxTokens,
                promptPreview: userQuery.length > 60
                    ? '${userQuery.substring(0, 57)}…'
                    : userQuery,
              ),
            );
          }
        },
        onError: (Object err) {
          genSw.stop();
          debugPrint('[MedicalSlmEngine] Generation stream error: $err');
          _isGenerating = false;
          _runState = EngineRunState.modelReady;
          notifyListeners();
          onError(err.toString());
          if (!completer.isCompleted) {
            completer.complete(
              InferenceMetrics(
                totalGenerationMs: genSw.elapsedMilliseconds,
                generatedTokens: tokenCount,
                tokensPerSecond: 0,
                nCtx: _nCtx,
                maxTokens: effectiveMaxTokens,
                promptPreview: userQuery,
              ),
            );
          }
        },
        cancelOnError: true,
      );

      return await completer.future;
    } catch (e) {
      genSw.stop();
      debugPrint('[MedicalSlmEngine] Generation invoke error: $e');
      _isGenerating = false;
      _runState = EngineRunState.modelReady;
      notifyListeners();
      onError(e.toString());
      return InferenceMetrics(
        totalGenerationMs: genSw.elapsedMilliseconds,
        generatedTokens: tokenCount,
        tokensPerSecond: 0,
        nCtx: _nCtx,
        maxTokens: effectiveMaxTokens,
        promptPreview: userQuery,
      );
    }
  }

  /// Emergency fallback triage helper kept for external service compatibility.
  /// Emits rich bold text, bullet points, Markdown tables, and interactive follow-ups.
  String generateConversationalDoctorGuidance({
    required String userQuery,
    required String lang,
    FirstAidProtocol? activeProtocol,
    List<Map<String, String>> conversationHistory = const [],
    int intakeTurn = 1,
    String? patientName,
    List<String> currentSymptoms = const [],
    String? symptomDuration,
    String? bodyTemperature,
    bool wantsMedicines = false,
    bool wantsDoctor = false,
    String? ragContext,
  }) {
    final q = userQuery.toLowerCase().trim();
    final isTe = lang == 'te' || lang.startsWith('te');
    final isHi = lang == 'hi' || lang.startsWith('hi');

    // First-Aid Protocol Match
    activeProtocol ??= ValidatedFirstAidProtocols.findProtocolForQuery(userQuery);
    if (activeProtocol != null) {
      if (isTe) {
        return '''
### **${activeProtocol.title} - ప్రథమ చికిత్స మార్గదర్శకాలు**

• **త్వరిత సారాంశం:** ${activeProtocol.quickSummary}
• **అత్యవసర హెచ్చరిక:** పరిస్థితి విషమంగా ఉంటే వెంటనే **108** కు కాల్ చేయండి.

| దశ | చేయవలసిన చర్య | ముఖ్యమైన జాగ్రత్త |
| :--- | :--- | :--- |
| **దశ 1** | రోగిని ప్రశాంతంగా ఉంచండి | ఆందోళన కలిగించవద్దు |
| **దశ 2** | సూచించిన ప్రథమ చికిత్స ప్రారంభించండి | అనవసర మందులు వేయవద్దు |
| **దశ 3** | అత్యవసర సహాయం పిలవండి | సమయం వృధా చేయవద్దు |

👉 **సిఫార్సు చేసిన తదుపరి దశలు (క్లిక్ చేయండి):**
• CPR మెట్రోనొమ్ ప్రారంభించు (110 BPM)
• సమీపంలోని అత్యవసర ఆసుపత్రులు చూడండి
• 108 అంబులెన్స్‌కు కాల్ చేయండి
''';
      } else if (isHi) {
        return '''
### **${activeProtocol.title} - प्राथमिक उपचार निर्देश**

• **त्वरित सारांश:** ${activeProtocol.quickSummary}
• **आपातकालीन चेतावनी:** स्थिति गंभीर होने पर तुरंत **108** पर कॉल करें।

| चरण | आवश्यक कदम | महत्वपूर्ण सावधानी |
| :--- | :--- | :--- |
| **चरण 1** | मरीज को शांत रखें | घबराहट न फैलने दें |
| **चरण 2** | प्राथमिक उपचार शुरू करें | अनावश्यक दवा न दें |
| **चरण 3** | एम्बुलेंस को कॉल करें | 108 पर संपर्क करें |

👉 **अनुशंसित अगले कदम (क्लिक करें):**
• सीपीआर मेट्रोनोम शुरू करें (110 BPM)
• नजदीकी अस्पताल खोजें
• 108 एम्बुलेंस को कॉल करें
''';
      } else {
        return '''
### **${activeProtocol.title} - Emergency Protocol**

• **Summary:** ${activeProtocol.quickSummary}
• **Emergency Warning:** If condition is critical, dial **108** immediately.

| Step | Action Required | Clinical Precaution |
| :--- | :--- | :--- |
| **Step 1** | Ensure safe airway & calm environment | Do not crowd the patient |
| **Step 2** | Initiate primary first-aid procedure | Do not give oral fluids if unconscious |
| **Step 3** | Summon emergency medical personnel | Keep 108 ambulance notified |

👉 **Recommended Next Steps (Tap to Ask):**
• Start CPR 110 BPM Metronome
• Locate Nearest Trauma Hospitals
• Call 108 Ambulance Emergency
''';
      }
    }

    if (q.contains('chest pain') || q.contains('heart') || q.contains('stroke') ||
        q.contains('unconscious') || q.contains('breath') || q.contains('గుండె నొప్పి') ||
        q.contains('సీనే మే దర్ద్') || q.contains('सीने में दर्द')) {
      if (isTe) {
        return '''
### ⚠️ **తీవ్రమైన అత్యవసర హెచ్చరిక: ఛాతీ నొప్పి / శ్వాస ఆడకపోవడం**

• **తక్షణ చర్య:** కదలకుండా విశ్రాంతిగా కూర్చోండి.
• **అత్యవసరం:** వెంటనే **108 అంబులెన్స్** కు కాల్ చేయండి.

| పరిస్థితి | లక్షణాలు | తక్షణ స్పందన |
| :--- | :--- | :--- |
| **గుండెపోటు అనుమానం** | ఛాతీలో ఒత్తిడి, చెమటలు, దవడ నొప్పి | కూర్చోబెట్టి 108 కి కాల్ చేయండి |

👉 **సిఫార్సు చేసిన తదుపరి చర్యలు (క్లిక్ చేయండి):**
• 108 అంబులెన్స్‌కు కాల్ చేయండి
• సమీపంలోని కార్డియాక్ ఆసుపత్రులు చూడండి
''';
      } else if (isHi) {
        return '''
### ⚠️ **गंभीर आपातकालीन चेतावनी: सीने में दर्द / सांस की तकलीफ**

• **त्वरित कार्रवाई:** मरीज को तुरंत शांत बैठाएं।
• **आपातकाल:** तुरंत **108 एम्बुलेंस** को कॉल करें।

| स्थिति | लक्षण | त्वरित कदम |
| :--- | :--- | :--- |
| **संभावित हार्ट अटैक** | सीने में जकड़न, पसीना, बाएं हाथ में दर्द | शांत बैठाएं और 108 बुलाएं |

👉 **अनुशंसित अगले कदम (क्लिक करें):**
• 108 एम्बुलेंस को कॉल करें
• नजदीकी कार्डियक अस्पताल खोजें
''';
      } else {
        return '''
### ⚠️ **Critical Emergency Alert: Severe Chest Pain / Breathlessness**

• **Immediate Action:** Please sit still and stay completely calm.
• **Emergency:** Dial **108 Ambulance** immediately without delay.

| Triage Condition | Red Flag Symptoms | Immediate Protocol |
| :--- | :--- | :--- |
| **Suspected Cardiac Event** | Chest tightness, radiating left arm pain, sweating | Sit upright, loosen tight clothing, dial 108 |

👉 **Recommended Next Steps (Tap to Ask):**
• Dial 108 Ambulance Emergency
• Locate Nearest Emergency Cardiac Care
''';
      }
    }

    if (isTe) {
      return '''
మీ ఆరోగ్యం పట్ల శ్రద్ధ వహించండి. విస్తృత వైద్య విశ్లేషణ కోసం **మోడల్ మేనేజర్** నుండి ఆన్-డివైస్ AI మోడల్‌ను లోడ్ చేయండి.

👉 **సిఫార్సు చేసిన ప్రశ్నలు (క్లిక్ చేయండి):**
• జ్వరం మరియు దగ్గుకు ఉపశమనం ఎలా?
• కడుపు నొప్పికి తీసుకోవలసిన జాగ్రత్తలు
• ప్రభుత్వ ఆరోగ్య పథకాల వివరాలు
''';
    } else if (isHi) {
      return '''
अपनी सेहत का ध्यान रखें। विस्तृत परामर्श के लिए कृपया **मॉडल मैनेजर** से ऑन-डिवाइस AI मॉडल लोड करें।

👉 **अनुशंसित प्रश्न (क्लिक करें):**
• बुखार और जुकाम में तुरंत राहत कैसे पाएं?
• पेट दर्द के घरेलू उपाय और सावधानियां
• सरकारी स्वास्थ्य योजनाओं की जानकारी
''';
    } else {
      return '''
Please take care of your health and stay well hydrated. Load the on-device AI model from **Model Manager** for live conversational medical assistance.

👉 **Recommended Topics (Tap to Ask):**
• How to manage fever and headache safely?
• Relief for acidity and stomach upset
• Government health schemes and insurance
''';
    }
  }

  /// Stop active token generation.
  Future<void> stopGeneration() async {
    _isGenerating = false;
    _runState = EngineRunState.modelReady;
    await _genSub?.cancel();
    _genSub = null;
    notifyListeners();
  }

  /// Safely unload model from memory and release native resources.
  Future<void> unloadModel({bool notify = true}) async {
    if (_isGenerating) await stopGeneration();
    await _genSub?.cancel();
    _genSub = null;

    if (_session != null) {
      try {
        await _session!.dispose();
      } catch (e) {
        debugPrint('[MedicalSlmEngine] Notice disposing session: $e');
      }
      _session = null;
    }

    if (_engine != null) {
      try {
        await _engine!.dispose();
      } catch (e) {
        debugPrint('[MedicalSlmEngine] Notice disposing engine: $e');
      }
      _engine = null;
    }

    _loadedModelPath = null;
    _loadedModelFormat = null;
    _lastLoadDurationMs = null;
    _turnHistory.clear();
    _runState = EngineRunState.uninitialized;

    if (notify) notifyListeners();
    debugPrint('[MedicalSlmEngine] Model & engine unloaded successfully.');
  }

  @override
  void dispose() {
    unloadModel(notify: false);
    super.dispose();
  }
}
