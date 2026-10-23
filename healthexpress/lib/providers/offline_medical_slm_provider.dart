import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:healthexpress/data/validated_first_aid_protocols.dart';
import 'package:healthexpress/models/offline_medical_models.dart';
import 'package:healthexpress/providers/ai_assistant_provider.dart' show ChatSessionMeta;
import 'package:healthexpress/services/medical_slm_engine_service.dart';
import 'package:healthexpress/services/model_download_service.dart';
import 'package:healthexpress/services/model_storage_service.dart';
import 'package:healthexpress/services/offline_voice_service.dart';
import 'package:healthexpress/services/offline_medical_rag_service.dart';

/// Central Provider coordinating the on-device Medical SLM,
/// offline AI Doctor Avatar, first-aid protocols, and voice engine.
class OfflineMedicalSlmProvider extends ChangeNotifier {
  final MedicalSlmEngineService _engineService = MedicalSlmEngineService();
  final ModelDownloadService _downloadService = ModelDownloadService();
  final OfflineVoiceService _voiceService = OfflineVoiceService();
  final OfflineMedicalRagService _ragService = OfflineMedicalRagService.instance;
  final Uuid _uuid = const Uuid();

  OfflineMedicalRagService get ragService => _ragService;

  String _currentSessionId = 'offline_session_${DateTime.now().millisecondsSinceEpoch}';
  List<ChatSessionMeta> _savedSessions = [];

  String get currentSessionId => _currentSessionId;
  List<ChatSessionMeta> get savedSessions => List.unmodifiable(_savedSessions);

  List<GgufModel> _catalogModels = [];
  GgufModel? _activeModel;
  bool _isLoadingCatalog = false;

  final List<OfflineDoctorMessage> _messages = [];
  DoctorAvatarState _avatarState = DoctorAvatarState.idle;
  FirstAidProtocol? _activeProtocol;
  int _activeProtocolStepIndex = 0;

  // CPR Metronome State
  bool _isCprMetronomeActive = false;
  int _cprCompressionCount = 0;
  int _cprCycleCount = 0;
  Timer? _cprMetronomeTimer;

  // Voice State (Manual audio playback only per user instruction)
  bool _autoVoiceReadout = false;
  String _selectedLanguage = 'en'; // 'en', 'hi', 'te'

  MedicalSlmEngineService get engine => _engineService;
  ModelDownloadService get downloadService => _downloadService;
  OfflineVoiceService get voiceService => _voiceService;
  List<GgufModel> get catalogModels => List.unmodifiable(_catalogModels);
  List<GgufModel> get downloadedModels => _catalogModels
      .where((m) => m.isOnDisk || m.downloadState == GgufDownloadState.downloaded || m.downloadState == GgufDownloadState.loaded)
      .toList();
  bool get hasDownloadedModel =>
      _engineService.isModelLoaded ||
      downloadedModels.isNotEmpty ||
      _catalogModels.any((m) => m.isOnDisk);
  GgufModel? get activeModel => _activeModel;
  bool get isLoadingCatalog => _isLoadingCatalog;
  List<OfflineDoctorMessage> get messages => List.unmodifiable(_messages);
  DoctorAvatarState get avatarState => _avatarState;
  FirstAidProtocol? get activeProtocol => _activeProtocol;
  int get activeProtocolStepIndex => _activeProtocolStepIndex;
  bool get isCprMetronomeActive => _isCprMetronomeActive;
  int get cprCompressionCount => _cprCompressionCount;
  int get cprCycleCount => _cprCycleCount;
  bool get autoVoiceReadout => _autoVoiceReadout;
  String get selectedLanguage => _selectedLanguage;

  OfflineMedicalSlmProvider() {
    _initProvider();
  }

  Future<void> _initProvider() async {
    await initSessionStorage();
    await loadCatalogModels();
    _initWelcomeDoctorMessage();

    // Listen to voice service changes for avatar speech animation
    _voiceService.addListener(() {
      if (_voiceService.isSpeaking && _avatarState != DoctorAvatarState.speaking) {
        _avatarState = DoctorAvatarState.speaking;
        notifyListeners();
      } else if (_voiceService.isListening && _avatarState != DoctorAvatarState.listening) {
        _avatarState = DoctorAvatarState.listening;
        notifyListeners();
      } else if (!_voiceService.isSpeaking && !_voiceService.isListening && _avatarState == DoctorAvatarState.speaking) {
        _avatarState = _activeProtocol != null ? DoctorAvatarState.emergency : DoctorAvatarState.idle;
        notifyListeners();
      }
    });

    // Listen to engine state
    _engineService.addListener(() {
      if (_engineService.isGenerating && _avatarState != DoctorAvatarState.thinking && _avatarState != DoctorAvatarState.speaking) {
        _avatarState = DoctorAvatarState.thinking;
        notifyListeners();
      }
    });
  }

  void _initWelcomeDoctorMessage() {
    _messages.clear();
    _messages.add(
      OfflineDoctorMessage(
        id: _uuid.v4(),
        role: 'assistant',
        text: 'Hello, I am Dr. Shanni — your offline clinical doctor. I work 100% locally with zero internet. How can I help you today?',
        timestamp: DateTime.now(),
        actionPrompts: const [],
      ),
    );
  }

  /// Load catalog models from assets and reconcile with on-device files.
  Future<void> loadCatalogModels() async {
    _isLoadingCatalog = true;
    notifyListeners();

    try {
      final jsonStr = await rootBundle.loadString('assets/models.json');
      final data = jsonDecode(jsonStr);
      final rawList = (data['models'] as List<dynamic>?) ?? [];

      final models = rawList.map((m) => GgufModel.fromJson(m as Map<String, dynamic>)).toList();

      for (final m in models) {
        await ModelStorageService.reconcileModelState(m);
      }

      _catalogModels = models;

      // Select single pre-built model
      if (_catalogModels.isNotEmpty) {
        _activeModel = _catalogModels.first;
      } else {
        _activeModel = null;
      }

      // Automatically load the active on-disk model into the inference engine
      if (_activeModel != null && _activeModel!.isOnDisk && _activeModel!.localPath != null && !_engineService.isModelLoaded) {
        unawaited(loadModelIntoEngine(_activeModel!));
      }
    } catch (e) {
      debugPrint('[OfflineMedicalSlmProvider] loadCatalogModels error: $e');
    } finally {
      _isLoadingCatalog = false;
      notifyListeners();
    }
  }

  /// Start model download.
  Future<void> downloadModel(GgufModel model) async {
    await _downloadService.start(
      model: model,
      onProgress: (m) => notifyListeners(),
      onComplete: (m, path) async {
        await ModelStorageService.setActiveModelId(m.id);
        _activeModel = m;
        notifyListeners();
        // Automatically load into engine
        await loadModelIntoEngine(m);
      },
      onError: (m, err) {
        debugPrint('[Download Error] $err');
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// Load model into LlamaEngine.
  Future<void> loadModelIntoEngine(GgufModel model) async {
    if (!model.isOnDisk || model.localPath == null) return;
    try {
      _avatarState = DoctorAvatarState.thinking;
      notifyListeners();
      await _engineService.loadModel(model.localPath!, promptFormat: model.promptFormat);
      if (_engineService.isModelLoaded) {
        model.downloadState = GgufDownloadState.loaded;
        if (_engineService.loadedModelPath != null) {
          model.localPath = _engineService.loadedModelPath;
        }
        _activeModel = model;
        await ModelStorageService.setActiveModelId(model.id);
      }
      _avatarState = DoctorAvatarState.idle;
      notifyListeners();
    } catch (e) {
      _avatarState = DoctorAvatarState.idle;
      notifyListeners();
    }
  }

  /// Send message to the on-device AI model with system prompt for helpful healthcare assistance.
  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    // 1. Post user message
    final userMsg = OfflineDoctorMessage(
      id: _uuid.v4(),
      role: 'user',
      text: query,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);
    _avatarState = DoctorAvatarState.thinking;
    notifyListeners();
    unawaited(saveCurrentSession());

    final assistantMsgId = _uuid.v4();

    // Auto-load on-disk local model into inference engine if not yet loaded
    if (!_engineService.isModelLoaded) {
      if (_activeModel != null && _activeModel!.isOnDisk && _activeModel!.localPath != null) {
        await loadModelIntoEngine(_activeModel!);
      } else if (downloadedModels.isNotEmpty && downloadedModels.first.localPath != null) {
        await loadModelIntoEngine(downloadedModels.first);
      }
    }

    // 2. Stream generation directly from the on-device model with system prompt
    if (_engineService.isModelLoaded) {
      final assistantMsg = OfflineDoctorMessage(
        id: assistantMsgId,
        role: 'assistant',
        text: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      _messages.add(assistantMsg);
      notifyListeners();

      final buffer = StringBuffer();

      try {
        final metrics = await _engineService.generateMedicalResponse(
          userQuery: query,
          lang: _selectedLanguage,
          onToken: (token) {
            buffer.write(token);
            final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                text: buffer.toString(),
                isStreaming: true,
              );
              notifyListeners();
            }
          },
          onComplete: (fullText) {
            final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                text: fullText.trim(),
                isStreaming: false,
              );
              notifyListeners();
            }
            _avatarState = DoctorAvatarState.idle;
            notifyListeners();
            unawaited(saveCurrentSession());
          },
          onError: (err) {
            final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                text: '⚠️ An error occurred during offline generation: $err',
                isStreaming: false,
              );
              _avatarState = DoctorAvatarState.idle;
              notifyListeners();
              unawaited(saveCurrentSession());
            }
          },
        );

        final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(
            metrics: metrics,
            isStreaming: false,
          );
          notifyListeners();
          unawaited(saveCurrentSession());
        }
      } catch (e) {
        debugPrint('[OfflineMedicalSlmProvider] sendMessage error: $e');
        final idx = _messages.indexWhere((m) => m.id == assistantMsgId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(isStreaming: false);
          _avatarState = DoctorAvatarState.idle;
          notifyListeners();
          unawaited(saveCurrentSession());
        }
      }
      return;
    }

    // 3. Fallback when local GGUF model is still loading into memory:
    // Respond as a helpful health AI assistant in good Markdown format
    final fallbackText = _generateHelpfulHealthGuidance(query, _selectedLanguage);
    final fallbackMsg = OfflineDoctorMessage(
      id: assistantMsgId,
      role: 'assistant',
      text: fallbackText,
      timestamp: DateTime.now(),
      isStreaming: false,
    );
    _messages.add(fallbackMsg);
    _avatarState = DoctorAvatarState.idle;
    notifyListeners();
    unawaited(saveCurrentSession());
  }

  /// Comprehensive medical guidance generator supporting all clinical topics,
  /// symptoms, first-aid protocols, chronic diseases, and self-care in English, Telugu, and Hindi.
  String _generateHelpfulHealthGuidance(String query, String lang) {
    final q = query.toLowerCase().trim();
    final isTe = lang == 'te' || lang.startsWith('te');
    final isHi = lang == 'hi' || lang.startsWith('hi');

    // 1. Check validated emergency & first-aid protocols (CPR, Choking, Bleeding, Burns, Snakebite, Asthma)
    final protocol = ValidatedFirstAidProtocols.findProtocolForQuery(query);
    if (protocol != null) {
      if (isTe) {
        return '''### 🚨 ${protocol.title} - మార్గదర్శకాలు
${protocol.quickSummary}

* **చేయవలసిన తక్షణ పనులు:**
${protocol.dos.map((d) => '  • $d').join('\n')}

* **చేయకూడనివి:**
${protocol.donts.map((d) => '  • $d').join('\n')}

### ⚠️ అత్యవసర హెచ్చరిక
పరిస్థితి తీవ్రంగా ఉంటే వెంటనే **108** అంబులెన్స్‌కు కాల్ చేయండి.''';
      } else if (isHi) {
        return '''### 🚨 ${protocol.title} - निर्देश
${protocol.quickSummary}

* **तत्काल आवश्यक कदम:**
${protocol.dos.map((d) => '  • $d').join('\n')}

* **क्या न करें:**
${protocol.donts.map((d) => '  • $d').join('\n')}

### ⚠️ आपातकालीन सूचना
स्थिति गंभीर होने पर तुरंत **108** पर कॉल करें।''';
      } else {
        return '''### 🚨 ${protocol.title} - Immediate Clinical Steps
${protocol.quickSummary}

* **Recommended Actions:**
${protocol.dos.map((d) => '  • $d').join('\n')}

* **What NOT to Do:**
${protocol.donts.map((d) => '  • $d').join('\n')}

### ⚠️ Critical Warning
If condition is life-threatening, dial **108 / 112** emergency services immediately.''';
      }
    }

    // 2. Fever, Temperature, Infections & Paracetamol
    if (q.contains('fever') || q.contains('temperature') || q.contains('dolo') || q.contains('paracetamol') ||
        q.contains('chills') || q.contains('జ్వరం') || q.contains('బుఖార్') || q.contains('बुखार')) {
      if (isTe) {
        return '''### 🩺 జ్వరం & ఇన్‌ఫెక్షన్ సంరక్షణ మార్గదర్శకాలు

* **లక్షణాల ఉపశమనం:** నుదుటిపై సాధారణ నీటి తడిగుడ్డతో స్పాంజింగ్ చేయండి. విశ్రాంతి తీసుకోండి.
* **మందులు:** సాధారణ జ్వరానికి పారాసిటమాల్ (వైద్యుల సూచన మేరకు) తీసుకోవచ్చు. మోతాదు మించవద్దు.
* **ద్రవాలు:** ORS, కొబ్బరి నీళ్ళు, గోరువెచ్చని నీరు పుష్కలంగా త్రాగి శరీరం డీహైడ్రేట్ కాకుండా చూడండి.

### ⚠️ ఎప్పుడు డాక్టర్‌ను కలవాలి
* జ్వరం 102°F దాటినా లేదా 3 రోజులకంటే ఎక్కువ కొనసాగినా.
* తీవ్రమైన చలి, వాంతులు లేదా ఫిట్స్ వస్తే వెంటనే ఆసుపత్రికి వెళ్ళండి.''';
      } else if (isHi) {
        return '''### 🩺 बुखार एवं संक्रमण प्रबंधन

* **तत्काल देखभाल:** सामान्य पानी की पट्टी माथे पर रखें और पूरा विश्राम करें।
* **दवाएं:** सामान्य बुखार में पैरासिटामोल (डॉक्टर की सलाह अनुसार) ले सकते हैं। बिना परामर्श अत्यधिक दवा न लें।
* **हाइड्रेशन:** ओआरएस, नारियल पानी और पर्याप्त तरल पदार्थ पिएं।

### ⚠️ डॉक्टर से कब मिलें
* बुखार 102°F से अधिक हो या 3 दिन से अधिक रहे।
* अत्यधिक ठंड लगना, सांस फूलना या चकत्ते दिखना।''';
      } else {
        return '''### 🩺 Fever & Infection Management

* **Immediate Care:** Rest in a cool, well-ventilated room. Use room-temperature water sponging on the forehead.
* **Medication Guidelines:** Over-the-counter Paracetamol (500mg/650mg for adults, as per physician guidance) can help lower temperature and relieve body ache. Maintain at least 6 hours between doses.
* **Hydration:** Drink electrolytes (ORS), coconut water, and warm broths to prevent dehydration.

### ⚠️ Red Flags to See a Doctor
* Fever exceeding 102°F (38.9°C) or lasting more than 3 consecutive days.
* Stiff neck, extreme lethargy, persistent vomiting, or rash.''';
      }
    }

    // 3. Cough, Cold, Sore Throat & Respiratory
    if (q.contains('cough') || q.contains('cold') || q.contains('throat') || q.contains('sore throat') ||
        q.contains('phlegm') || q.contains('దగ్గు') || q.contains('జలుబు') || q.contains('గొంతు') || q.contains('खांसी') || q.contains('जुकाम')) {
      if (isTe) {
        return '''### 🩺 దగ్గు, జలుబు & గొంతు నొప్పి ఉపశమనం

* **ఉపశమన చర్యలు:** గోరువెచ్చని ఉప్పు నీటితో రోజుకు 2-3 సార్లు గార్గ్లింగ్ చేయండి. ఆవిరి పట్టండి.
* **ద్రవాలు:** అల్లం టీ, తేనెతో కూడిన గోరువెచ్చని నీరు గొంతు ఉపశమనానికి తోడ్పడుతుంది.
* **జాగ్రత్త:** చల్లని పానీయాలు, ఐస్ క్రీములు, పొగ పీల్చడం మానుకోండి.

### ⚠️ వైద్యుడిని ఎప్పుడు సంప్రదించాలి
* దగ్గుతో పాటు రక్తం పడినా, శ్వాస తీసుకోవడంలో తీవ్ర ఇబ్బంది ఉన్నా వెంటనే **108** కి కాల్ చేయండి.''';
      } else if (isHi) {
        return '''### 🩺 खांसी, जुकाम एवं गले की खराश

* **घरेलू उपचार:** गुनगुने नमक के पानी से दिन में 2-3 बार गरारे करें। भाप (स्टीम) लें।
* **आहार:** अदरक-शहद का रस या गर्म हर्बल काढ़ा गले को तुरंत राहत देता है।
* **सावधानी:** ठंडी चीजें और धूल-धुएं से बचें।

### ⚠️ आपातकालीन चेतावनी
* सांस लेने में कठिनाई या बलगम में खून आने पर तुरंत डॉक्टर से संपर्क करें।''';
      } else {
        return '''### 🩺 Cough, Cold & Respiratory Relief

* **Immediate Relief:** Gargle with warm salt water 2-3 times daily to soothe inflamed throat tissues. Inhale warm steam for nasal congestion.
* **Supportive Remedies:** Honey with warm water or ginger tea helps suppress dry irritating coughs.
* **Hydration & Rest:** Stay well-hydrated to thin mucus secretions. Avoid cold air and smoke exposure.

### ⚠️ When to Seek Medical Attention
* Shortness of breath, wheezing, coughing up blood, or symptoms lasting over 10 days.''';
      }
    }

    // 4. Stomach Pain, Acidity, Gas, Diarrhea, Vomiting
    if (q.contains('stomach') || q.contains('acidity') || q.contains('gas') || q.contains('vomit') ||
        q.contains('diarrhea') || q.contains('motions') || q.contains('loose') || q.contains('కడుపు') || q.contains('వాంతులు') || q.contains('पेट दर्द') || q.contains('उल्टी')) {
      if (isTe) {
        return '''### 🩺 కడుపు నొప్పి, ఎసిడిటీ & జీర్ణ సంబంధిత సలహాలు

* **జీర్ణక్రియ సంరక్షణ:** తేలికపాటి గంజి, అరటిపండు, పెరుగు అన్నం వంటి ఆహారం తీసుకోండి.
* **ఎసిడిటీ:** ఖాళీ కడుపుతో ఉండకండి, కారాలు, నూనె పదార్థాలు తగ్గించండి.
* **విరేచనాలు / వాంతులు:** డీహైడ్రేషన్ నివారించడానికి ORS ద్రావణాన్ని కొద్దికొద్దిగా తరచుగా త్రాగండి.

### ⚠️ ప్రమాద సంకేతాలు
* విపరీతమైన కడుపు నొప్పి, రక్తపు వాంతులు లేదా మలంలో రక్తం కనిపిస్తే వెంటనే ఆసుపత్రికి వెళ్ళండి.''';
      } else if (isHi) {
        return '''### 🩺 पेट दर्द, एसिडिटी, उल्टी एवं दस्त

* **आहार सुझाव:** हल्का खाना जैसे खिचड़ी, दलिया, दही-चावल और केला खाएं।
* **एसिडिटी:** ज्यादा मिर्च-मसालेदार भोजन और चाय-कॉफी से परहेज करें।
* **हाइड्रेशन:** ओआरएस (ORS) का घोल थोड़े-थोड़े अंतराल पर पिएं ताकि शरीर में पानी की कमी न हो।

### ⚠️ गंभीर लक्षण
* असहनीय पेट दर्द, उल्टी या मल में खून आना—तुरंत नजदीकी अस्पताल जाएं।''';
      } else {
        return '''### 🩺 Gastrointestinal & Abdominal Care

* **Dietary Guidance:** Follow a gentle diet (bananas, rice, applesauce, toast, clear broth). Avoid oily, spicy, and deep-fried foods.
* **Acidity & Reflux:** Eat smaller, more frequent meals. Avoid lying down for 2 hours after eating.
* **Hydration Protocol:** For vomiting or loose motions, take sips of Oral Rehydration Solution (ORS) every 10-15 minutes to restore electrolytes.

### ⚠️ Red Flags to Consult a Doctor Immediately
* Severe localized abdominal pain (especially right lower abdomen), black tarry stools, or blood in vomit.''';
      }
    }

    // 5. Headache, Migraine & Vertigo
    if (q.contains('headache') || q.contains('migraine') || q.contains('dizziness') || q.contains('vertigo') ||
        q.contains('తలనొప్పి') || q.contains('తల తిరుగు') || q.contains('सिरदर्द') || q.contains('चक्कर')) {
      if (isTe) {
        return '''### 🩺 తలనొప్పి & మైగ్రేన్ ఉపశమన మార్గదర్శకాలు

* **విశ్రాంతి:** చీకటి మరియు ప్రశాంతమైన గదిలో కళ్ళు మూసుకుని విశ్రాంతి తీసుకోండి.
* **హైడ్రేషన్:** తలనొప్పికి డీహైడ్రేషన్ ప్రధాన కారణం కావచ్చు, తగినంత నీరు త్రాగండి.
* **ఒత్తిడి నివారణ:** మొబైల్, కంప్యూటర్ స్క్రీన్లను చూడటం ఆపి మెడ మరియు భుజాలను నెమ్మదిగా మసాజ్ చేయండి.

### ⚠️ తక్షణ అత్యవసరం
* ఆకస్మిక విపరీతమైన తలనొప్పి, చూపు మసకబారడం, మాట తడబడటం ఉంటే వెంటనే **108** కి కాల్ చేయండి.''';
      } else if (isHi) {
        return '''### 🩺 सिरदर्द एवं माइग्रेन प्रबंधन

* **आराम:** शांत और हल्के अंधेरे कमरे में आराम करें।
* **हाइड्रेशन:** भरपूर मात्रा में पानी पिएं। निर्जलीकरण सिरदर्द का बड़ा कारण होता है।
* **स्क्रीन डिटॉक्स:** मोबाइल और लैपटॉप की स्क्रीन से दूरी बनाएं।

### ⚠️ आपातकालीन संकेत
* अचानक तेज असहनीय सिरदर्द, हाथ-पैरों में कमजोरी या बोलने में लड़खड़ाहट—तुरंत 108 डायल करें।''';
      } else {
        return '''### 🩺 Headache & Migraine Management

* **Environment:** Rest in a quiet, darkened room. Apply a cool compress to your forehead or temples.
* **Hydration & Trigger Control:** Dehydration is a frequent cause of tension headaches; drink 2 tall glasses of water. Avoid sensory triggers like loud sounds and bright screens.
* **Gentle Relief:** Mild neck stretching and resting posture help release cervicogenic muscle tension.

### ⚠️ Emergency Red Flags
* Sudden "thunderclap" severe headache, slurred speech, facial drooping, or limb weakness (call 108 immediately).''';
      }
    }

    // 6. Diabetes, High Sugar, Blood Pressure & Hypertension
    if (q.contains('diabetes') || q.contains('sugar') || q.contains('bp') || q.contains('blood pressure') ||
        q.contains('hypertension') || q.contains('మధుమేహం') || q.contains('రక్తపోటు') || q.contains('मधुमेह') || q.contains('ब्लड प्रेशर')) {
      if (isTe) {
        return '''### 🩺 డయాబెటిస్ & రక్తపోటు (BP) నిర్వహణ

* **జీవనశైలి:** ఉప్పు మరియు చక్కెర వాడకాన్ని తగ్గించండి. రోజూ 30 నిమిషాలు నడవండి.
* **మందుల నియమం:** డాక్టర్ సూచించిన మందులను సమయానికి తీసుకోండి. మధ్యలో ఆపవద్దు.
* **తనిఖీ:** రక్తంలో చక్కెర స్థాయిలను (షుగర్) మరియు బీపీని క్రమం తప్పకుండా నమోదు చేసుకోండి.

### ⚠️ హెచ్చరిక
* కళ్ళు తిరగడం, అధిక చెమటలు (లో షుగర్), తీవ్రమైన గుండె దడ ఉంటే వెంటనే జాగ్రత్త పడండి.''';
      } else if (isHi) {
        return '''### 🩺 शुगर (डायबिटीज) एवं ब्लड प्रेशर प्रबंधन

* **खान-पान:** नमक और चीनी की मात्रा सीमित रखें। रेशेदार (फाइबर युक्त) भोजन करें।
* **नियमित दवाएं:** चिकित्सक द्वारा निर्धारित दवाएं समय पर लें, खुराक न छोड़ें।
* **मॉनिटरिंग:** नियमित रूप से ब्लड शुगर और बीपी की जांच करते रहें।

### ⚠️ सतर्क रहें
* अत्यधिक पसीना, चक्कर आना (लो शुगर) या सीने में भारीपन होने पर तुरंत चिकित्सकीय सहायता लें।''';
      } else {
        return '''### 🩺 Chronic Care: Diabetes & Blood Pressure Management

* **Nutritional Control:** Reduce dietary sodium (under 2g/day) and refined sugars. Prioritize whole grains, leafy vegetables, and lean proteins.
* **Medication Adherence:** Take prescribed antihypertensive and antidiabetic medications at the same time every day. Never stop abruptly without medical consultation.
* **Routine Monitoring:** Keep a log of your morning fasting blood sugar and resting BP.

### ⚠️ Critical Alerts
* Hypoglycemia signs (shakiness, cold sweat, confusion): consume 15g fast sugar (juice/glucose) immediately.
* BP spikes (>180/120 mmHg) with chest discomfort or blurred vision require immediate emergency care.''';
      }
    }

    // 7. Joint Pain, Back Pain, Arthritis & Muscle Sprain
    if (q.contains('joint') || q.contains('knee') || q.contains('back pain') || q.contains('arthritis') ||
        q.contains('sprain') || q.contains('నొప్పి') || q.contains('కీళ్ల') || q.contains('दर्द') || q.contains('जोड़ों')) {
      if (isTe) {
        return '''### 🩺 కీళ్ల నొప్పులు, నడుము నొప్పి & కండరాల పట్టేయడం

* **తక్షణ సంరక్షణ (RICE విధానం):** విశ్రాంతి ఇవ్వండి (Rest), ఐస్ లేదా హాట్ ప్యాక్ పెట్టండి (Ice/Heat).
* **భంగిమ:** కూర్చునేటప్పుడు వెన్నుముక నిటారుగా ఉంచండి, బరువులు ఎత్తవద్దు.
* **వ్యాయామం:** సున్నితమైన స్ట్రెచింగ్ చేయండి, కీళ్ళపై అధిక ఒత్తిడి తగ్గించండి.

### ⚠️ వైద్యుడిని ఎప్పుడు సంప్రదించాలి
* వాపు, ఎర్రబడటం లేదా నడవలేని పరిస్థితి ఉంటే ఎముకల వైద్యుడిని (Orthopedic) సంప్రదించండి.''';
      } else if (isHi) {
        return '''### 🩺 जोड़ों का दर्द, कमर दर्द एवं मोच प्रबंधन

* **प्राथमिक देखभाल:** प्रभावित हिस्से को आराम दें। चोट लगने के पहले 24 घंटे बर्फ की सिकाई करें, पुराने दर्द में गर्म सेंक लें।
* **पोस्चर:** सही मुद्रा में बैठें और झुककर भारी वजन उठाने से बचें।
* **व्यायाम:** हल्के स्ट्रेचिंग व्यायाम जोड़ों के लचीलेपन को बनाए रखते हैं।

### ⚠️ डॉक्टर से कब मिलें
* अत्यधिक सूजन, लालिमा या वजन सहन न कर पाना—डॉक्टर से जांच कराएं।''';
      } else {
        return '''### 🩺 Musculoskeletal, Back & Joint Care

* **Immediate Protocol (R.I.C.E.):** Rest the affected area. Apply an ice pack for acute swelling (first 48 hours) or warm compress for chronic stiff joints.
* **Ergonomics & Posture:** Keep your spine neutral when seated. Avoid bending from the waist when lifting heavy objects.
* **Mobility:** Perform low-impact range-of-motion stretches (walking, gentle swimming) to prevent joint rigidity.

### ⚠️ When to Consult an Orthopedic Specialist
* Inability to bear weight, visible joint deformity, numbness, or progressive leg weakness.''';
      }
    }

    // 8. General Health, Wellness, Diet & Other Medical Inquiries
    if (isTe) {
      return '''### 🩺 సంజీవని AI వైద్య మార్గదర్శకత్వం

మీ ఆరోగ్య ప్రశ్నకు సంబంధించిన ముఖ్యమైన వైద్య సూచనలు:

* **ప్రాథమిక సంరక్షణ:** తగినంత విశ్రాంతి తీసుకోండి, శరీరానికి తగినంత నీరు మరియు పోషకాలను అందించండి.
* **ఆరోగ్య అలవాట్లు:** సమతుల్య ఆహారం తీసుకోండి, రోజూ కనీసం 7-8 గంటల నిద్ర ఉండేలా చూసుకోండి.
* **మందుల నియమం:** ఎలాంటి మందులనైనా అర్హత కలిగిన వైద్యుల సలహా మేరకే ఉపయోగించండి.

### ⚠️ ముఖ్యమైన హెచ్చరిక
లక్షణాలు తగ్గకపోతే లేదా తీవ్రమైన అసౌకర్యం ఉంటే సమీపంలోని ఆసుపత్రిని సంప్రదించండి. అత్యవసర పరిస్థితుల్లో వెంటనే **108** కి కాల్ చేయండి.''';
    } else if (isHi) {
      return '''### 🩺 संजीवनी AI समग्र स्वास्थ्य सलाह

आपके स्वास्थ्य प्रश्न हेतु आवश्यक चिकित्सकीय परामर्श:

* **प्राथमिक देखभाल:** शरीर को पर्याप्त आराम दें, हल्का सुपाच्य भोजन लें और पर्याप्त पानी पिएं।
* **दवाइयों की सावधानी:** किसी भी दवा का सेवन करने से पहले चिकित्सक या फार्मासिस्ट से परामर्श अवश्य लें।
* **स्वास्थ्य निगरानी:** अपने लक्षणों पर नजर रखें और तनाव से बचें।

### ⚠️ आपातकालीन सूचना
यदि समस्या गंभीर हो या लक्षण बढ़ रहे हों, तो बिना देर किए डॉक्टर से मिलें या **108** आपातकालीन सेवा पर कॉल करें।''';
    } else {
      return '''### 🩺 Sanjeevani AI Clinical Guidance

Here is clear, practical medical advice for your query:

* **Primary Care & Recovery:** Rest adequately and maintain balanced hydration with fresh water and electrolytes.
* **Medication Safety:** Do not self-prescribe prescription medications or antibiotics; use only certified over-the-counter remedies with clinical advice.
* **Lifestyle & Nutrition:** Prioritize unprocessed, nutrient-dense foods, light physical movement, and 7-8 hours of sound sleep.

### ⚠️ When to Seek Medical Attention
* If symptoms persist beyond 48-72 hours, or if you experience unexplained dizziness, severe pain, or fever.
* Dial **108 / 112** immediately for sudden emergencies (chest pain, stroke signs, difficulty breathing).''';
    }
  }

  /// Launch a specific validated first-aid protocol directly.
  void launchFirstAidProtocol(FirstAidProtocol protocol) {
    _activeProtocol = protocol;
    _activeProtocolStepIndex = 0;
    _avatarState = DoctorAvatarState.emergency;
    notifyListeners();

    final promptText = 'Emergency protocol requested: ${protocol.title}. Please provide rapid first-aid steps.';
    sendMessage(promptText);

    // Speak initial step audio if available
    if (protocol.steps.isNotEmpty && protocol.steps.first.audioInstruction != null && _autoVoiceReadout) {
      _voiceService.speak(protocol.steps.first.audioInstruction!);
    }
  }

  /// Next step in active protocol.
  void nextProtocolStep() {
    if (_activeProtocol == null) return;
    if (_activeProtocolStepIndex < _activeProtocol!.steps.length - 1) {
      _activeProtocolStepIndex++;
      final step = _activeProtocol!.steps[_activeProtocolStepIndex];
      if (step.audioInstruction != null && _autoVoiceReadout) {
        _voiceService.speak(step.audioInstruction!);
      }
      notifyListeners();
    }
  }

  /// Previous step in active protocol.
  void previousProtocolStep() {
    if (_activeProtocol == null) return;
    if (_activeProtocolStepIndex > 0) {
      _activeProtocolStepIndex--;
      notifyListeners();
    }
  }

  /// Close active protocol overlay.
  void closeActiveProtocol() {
    _activeProtocol = null;
    _activeProtocolStepIndex = 0;
    stopCprMetronome();
    _avatarState = DoctorAvatarState.idle;
    notifyListeners();
  }

  /// Start 110 BPM CPR compression audio & visual metronome.
  void startCprMetronome() {
    _isCprMetronomeActive = true;
    _cprCompressionCount = 0;
    _cprCycleCount = 0;
    _avatarState = DoctorAvatarState.emergency;
    notifyListeners();

    // 110 beats per minute = 1 beat every ~545 milliseconds
    const beatInterval = Duration(milliseconds: 545);
    _cprMetronomeTimer?.cancel();
    _cprMetronomeTimer = Timer.periodic(beatInterval, (timer) {
      _cprCompressionCount++;

      // Haptic feedback tick
      HapticFeedback.lightImpact();

      if (_cprCompressionCount >= 30) {
        _cprCompressionCount = 0;
        _cprCycleCount++;
        // Cycle prompt: 2 rescue breaths or continue hands-only
        if (_autoVoiceReadout) {
          _voiceService.speak('Cycle $_cprCycleCount complete. Deliver two breaths or continue continuous compressions.');
        }
      }
      notifyListeners();
    });
  }

  /// Stop CPR metronome.
  void stopCprMetronome() {
    _isCprMetronomeActive = false;
    _cprMetronomeTimer?.cancel();
    _cprMetronomeTimer = null;
    _cprCompressionCount = 0;
    notifyListeners();
  }

  /// Toggle speech recognition listening.
  Future<void> toggleVoiceInput() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      _avatarState = DoctorAvatarState.idle;
      notifyListeners();
    } else {
      _avatarState = DoctorAvatarState.listening;
      notifyListeners();
      await _voiceService.startListening(
        onResult: (words) {},
        onFinalResult: (finalWords) {
          if (finalWords.trim().isNotEmpty) {
            sendMessage(finalWords);
          }
        },
      );
    }
  }

  /// Toggle language (English, Telugu, Hindi).
  Future<void> setLanguage(String langCode) async {
    _selectedLanguage = langCode;
    await _voiceService.setLanguage(langCode);
    notifyListeners();
  }

  void toggleAutoVoiceReadout(bool value) {
    _autoVoiceReadout = value;
    notifyListeners();
  }

  void stopSpeaking() {
    _voiceService.stopSpeaking();
    _avatarState = _activeProtocol != null ? DoctorAvatarState.emergency : DoctorAvatarState.idle;
    notifyListeners();
  }

  /// Initialize stored chat sessions index from SharedPreferences
  Future<void> initSessionStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('sanjeevani_chat_sessions_v2');
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _savedSessions = decoded.map((s) => ChatSessionMeta.fromJson(s as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[OfflineMedicalSlmProvider] initSessionStorage error: $e');
    }
  }

  /// Save active offline conversation session and persist messages and session meta
  Future<void> saveCurrentSession() async {
    final hasUserMessage = _messages.any((m) => m.isUser);
    if (!hasUserMessage) return;

    try {
      String title = 'Offline Consultation';
      for (final m in _messages) {
        if (m.isUser && m.text.trim().isNotEmpty) {
          final clean = m.text.trim().replaceAll('\n', ' ');
          title = clean.length > 28 ? '${clean.substring(0, 28)}...' : clean;
          break;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('sanjeevani_chat_sessions_v2');
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _savedSessions = decoded.map((s) => ChatSessionMeta.fromJson(s as Map<String, dynamic>)).toList();
      }

      final idx = _savedSessions.indexWhere((s) => s.id == _currentSessionId);
      final lastMsg = _messages.isNotEmpty ? _messages.last.text.replaceAll('\n', ' ') : '';
      final snippet = lastMsg.length > 40 ? '${lastMsg.substring(0, 40)}...' : lastMsg;

      if (idx != -1) {
        _savedSessions[idx].title = title;
        _savedSessions[idx].updatedAt = DateTime.now();
        _savedSessions[idx].messageCount = _messages.length;
        _savedSessions[idx].lastSnippet = snippet;
        _savedSessions[idx].type = 'offline';
      } else {
        _savedSessions.insert(
          0,
          ChatSessionMeta(
            id: _currentSessionId,
            title: title,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            messageCount: _messages.length,
            lastSnippet: snippet,
            type: 'offline',
          ),
        );
      }

      await _persistSessionsIndex();
      await _persistActiveSessionMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineMedicalSlmProvider] saveCurrentSession error: $e');
    }
  }

  Future<void> _persistSessionsIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_savedSessions.map((s) => s.toJson()).toList());
    await prefs.setString('sanjeevani_chat_sessions_v2', jsonStr);
  }

  Future<void> _persistActiveSessionMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_messages.map((m) => m.toJson()).toList());
    await prefs.setString('sanjeevani_session_msg_$_currentSessionId', jsonStr);
  }

  /// Start a new offline chat consultation session
  Future<void> startNewChatSession({String? title}) async {
    await saveCurrentSession();
    _currentSessionId = 'offline_session_${DateTime.now().millisecondsSinceEpoch}';
    _initWelcomeDoctorMessage();
    notifyListeners();
  }

  /// Load an existing offline consultation session
  Future<void> loadSession(String sessionId, {bool shouldSaveCurrent = true}) async {
    if (shouldSaveCurrent) {
      await saveCurrentSession();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final msgsJson = prefs.getString('sanjeevani_session_msg_$sessionId');
      if (msgsJson != null && msgsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(msgsJson);
        final loaded = decoded.map((m) => OfflineDoctorMessage.fromJson(m as Map<String, dynamic>)).toList();
        _currentSessionId = sessionId;
        _messages.clear();
        _messages.addAll(loaded);
        _avatarState = DoctorAvatarState.idle;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[OfflineMedicalSlmProvider] loadSession error: $e');
    }
  }

  /// Delete a saved consultation session
  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sanjeevani_session_msg_$sessionId');
      _savedSessions.removeWhere((s) => s.id == sessionId);
      await _persistSessionsIndex();

      if (_currentSessionId == sessionId) {
        final remainingOffline = _savedSessions.where((s) => s.type == 'offline').toList();
        if (remainingOffline.isNotEmpty) {
          await loadSession(remainingOffline.first.id, shouldSaveCurrent: false);
        } else {
          await startNewChatSession();
        }
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[OfflineMedicalSlmProvider] deleteSession error: $e');
    }
  }

  @override
  void dispose() {
    _cprMetronomeTimer?.cancel();
    _engineService.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}
