import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../data/production_database.dart';
import '../models/user_model.dart';
import '../models/doctor_model.dart';
import '../models/hospital_model.dart';
import '../models/medicine_model.dart';
import '../models/appointment_model.dart';
import '../models/lab_test_model.dart';
import '../models/business_product_model.dart';
import '../services/nvidia_ai_service.dart';
import '../services/sarvam_live_stt_service.dart';
import '../services/central_data_service.dart';
import '../services/api_service.dart';
import 'package:healthexpress/services/medical_slm_engine_service.dart';
import 'package:healthexpress/services/model_storage_service.dart';
import 'package:healthexpress/models/offline_medical_models.dart';
import '../services/clinical_rag_service.dart';

class DynamicActionCard {
  final String title;
  final String subtitle;
  final String type; // 'medicine' | 'doctor' | 'hospital' | 'test' | 'emergency' | 'product'
  final IconData icon;
  final Color color;
  final dynamic payload;

  DynamicActionCard({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.icon,
    this.color = const Color(0xFF1E60F6),
    this.payload,
  });
}

class ChatSessionMeta {
  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  int messageCount;
  String lastSnippet;

  ChatSessionMeta({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.lastSnippet = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messageCount': messageCount,
    'lastSnippet': lastSnippet,
  };

  factory ChatSessionMeta.fromJson(Map<String, dynamic> json) => ChatSessionMeta(
    id: json['id'] as String? ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
    title: (json['title'] as String?) ?? 'Clinical Consultation',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    messageCount: (json['messageCount'] as int?) ?? 0,
    lastSnippet: (json['lastSnippet'] as String?) ?? '',
  );
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isAudio;
  final bool isOffline;
  final List<String>? actionSuggestions;
  final List<String>? detectedSymptoms;
  final List<MedicineModel>? suggestedMedicines;
  final List<BusinessProductModel>? recommendedProducts;
  final List<DoctorModel>? suggestedDoctors;
  final List<HospitalModel>? suggestedHospitals;
  final List<LabTestModel>? suggestedLabTests;
  final List<DynamicActionCard>? dynamicCards;
  final bool needsMoreData;
  final InferenceMetrics? metrics;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isAudio = false,
    this.isOffline = false,
    this.actionSuggestions,
    this.detectedSymptoms,
    this.suggestedMedicines,
    this.recommendedProducts,
    this.suggestedDoctors,
    this.suggestedHospitals,
    this.suggestedLabTests,
    this.dynamicCards,
    this.needsMoreData = false,
    this.metrics,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'isAudio': isAudio,
    'isOffline': isOffline,
    'actionSuggestions': actionSuggestions,
    'detectedSymptoms': detectedSymptoms,
    'suggestedMedicineIds': suggestedMedicines?.map((m) => m.id).toList(),
    'suggestedDoctorIds': suggestedDoctors?.map((d) => d.id).toList(),
    'suggestedHospitalIds': suggestedHospitals?.map((h) => h.id).toList(),
    'suggestedLabTestCodes': suggestedLabTests?.map((t) => t.code).toList(),
    'metrics': metrics != null ? {
      'timeToFirstTokenMs': metrics!.timeToFirstTokenMs,
      'totalGenerationMs': metrics!.totalGenerationMs,
      'generatedTokens': metrics!.generatedTokens,
      'tokensPerSecond': metrics!.tokensPerSecond,
      'modelLoadDurationMs': metrics!.modelLoadDurationMs,
    } : null,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    List<MedicineModel>? meds;
    if (json['suggestedMedicineIds'] != null) {
      final ids = List<String>.from(json['suggestedMedicineIds']);
      meds = ProductionDatabase.medicines.where((m) => ids.contains(m.id)).toList();
    }
    List<DoctorModel>? docs;
    if (json['suggestedDoctorIds'] != null) {
      final ids = List<String>.from(json['suggestedDoctorIds']);
      docs = ProductionDatabase.doctors.where((d) => ids.contains(d.id)).toList();
    }
    List<HospitalModel>? hosps;
    if (json['suggestedHospitalIds'] != null) {
      final ids = List<String>.from(json['suggestedHospitalIds']);
      hosps = ProductionDatabase.hospitals.where((h) => ids.contains(h.id)).toList();
    }
    List<LabTestModel>? tests;
    if (json['suggestedLabTestCodes'] != null) {
      final codes = List<String>.from(json['suggestedLabTestCodes']);
      tests = ProductionDatabase.labTests.where((t) => codes.contains(t.code)).toList();
    }

    InferenceMetrics? metrics;
    if (json['metrics'] != null) {
      final m = json['metrics'] as Map<String, dynamic>;
      metrics = InferenceMetrics(
        timeToFirstTokenMs: m['timeToFirstTokenMs'] as int?,
        totalGenerationMs: m['totalGenerationMs'] as int? ?? 0,
        generatedTokens: m['generatedTokens'] as int? ?? 0,
        tokensPerSecond: (m['tokensPerSecond'] as num?)?.toDouble() ?? 0.0,
        modelLoadDurationMs: m['modelLoadDurationMs'] as int?,
        nCtx: 1024,
        maxTokens: 256,
      );
    }

    return ChatMessage(
      id: json['id'] as String? ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      isAudio: json['isAudio'] as bool? ?? false,
      isOffline: json['isOffline'] as bool? ?? false,
      actionSuggestions: json['actionSuggestions'] != null ? List<String>.from(json['actionSuggestions']) : null,
      detectedSymptoms: json['detectedSymptoms'] != null ? List<String>.from(json['detectedSymptoms']) : null,
      suggestedMedicines: meds,
      suggestedDoctors: docs,
      suggestedHospitals: hosps,
      suggestedLabTests: tests,
      metrics: metrics,
    );
  }
}

class AiAssistantProvider extends ChangeNotifier {
  String _selectedLanguage = 'en'; // 'en' | 'te' | 'hi'
  bool _isManualLanguageSelected = false;
  bool _isListening = false;
  bool _isThinking = false;
  bool _isSpeaking = false;
  bool _isLiveVoiceMode = false;
  bool _isOnline = true; // Auto-switched between online and offline
  String _liveTranscription = '';
  Timer? _interimTimer;
  Timer? _callAutoListenTimer;
  Timer? _speechMonitorTimer;

  int? _patientAge;
  String? _patientGender;
  String? _symptomDuration;
  String? _bodyTemperature;
  String? _patientName;
  String? _knownSeverity;
  String? _knownPastHistory;
  String? _knownExistingMeds;
  int _intakeTurnCount = 0;

  String _activeDiagnosis = 'General Health Inquiry';
  String _userInterestSegment = 'Preventive Master Checkups';
  final List<String> _currentSymptoms = [];

  final List<ChatMessage> _messages = [];
  String _currentSessionId = 'session_default';
  List<ChatSessionMeta> _savedSessions = [];

  AiAssistantProvider() {
    _initWelcomeMessage();
    initSessionStorage();
    checkNetworkConnectivity();
  }

  @override
  void dispose() {
    _interimTimer?.cancel();
    _callAutoListenTimer?.cancel();
    _speechMonitorTimer?.cancel();
    SarvamLiveSttService.stopSpeaking();
    super.dispose();
  }

  // Getters
  String get selectedLanguage => _selectedLanguage;
  bool get isManualLanguageSelected => _isManualLanguageSelected;
  bool get isListening => _isListening;
  bool get isThinking => _isThinking;
  bool get isSpeaking => _isSpeaking;
  bool get isLiveVoiceMode => _isLiveVoiceMode;
  bool get isOnline => _isOnline;
  String get liveTranscription => _liveTranscription;
  List<ChatMessage> get messages => _messages;
  String get activeDiagnosis => _activeDiagnosis;
  String get userInterestSegment => _userInterestSegment;
  List<String> get currentSymptoms => _currentSymptoms;
  String? get patientName => _patientName;
  int? get patientAge => _patientAge;
  String? get patientGender => _patientGender;
  String? get symptomDuration => _symptomDuration;
  String? get bodyTemperature => _bodyTemperature;
  String get currentSessionId => _currentSessionId;
  List<ChatSessionMeta> get savedSessions => _savedSessions;

  List<MedicineModel> get suggestedMedicines => _getMedicinesForContext(_activeDiagnosis, _currentSymptoms, '');
  List<DoctorModel> get suggestedDoctors => _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, '');
  List<HospitalModel> get suggestedHospitals => _getHospitalsForContext(_activeDiagnosis, _currentSymptoms, '');
  List<LabTestModel> get suggestedLabTests => _getLabTestsForContext(_activeDiagnosis, _currentSymptoms, '');
  List<BusinessProductModel> get suggestedBusinessProducts => _getProductsForContext(_activeDiagnosis, _currentSymptoms, '');

  // --------------------------------------------------------------------------
  // Network Connectivity Auto-Detection
  // --------------------------------------------------------------------------
  Future<bool> checkNetworkConnectivity() async {
    bool available = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 1800));
      available = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      available = false;
    }
    if (_isOnline != available) {
      _isOnline = available;
      notifyListeners();
    }
    return available;
  }

  bool toggleOnlineMode({bool hasDownloadedModel = true}) {
    if (_isOnline) {
      if (!hasDownloadedModel) {
        return false;
      }
      _isOnline = false;
      _autoLoadOfflineSlm();
    } else {
      _isOnline = true;
      _autoUnloadOfflineSlm();
    }
    notifyListeners();
    return true;
  }

  bool setOnlineMode(bool online, {bool hasDownloadedModel = true}) {
    if (!online && !hasDownloadedModel) {
      return false;
    }
    _isOnline = online;
    if (!_isOnline) {
      _autoLoadOfflineSlm();
    } else {
      _autoUnloadOfflineSlm();
    }
    notifyListeners();
    return true;
  }

  Future<void> _autoLoadOfflineSlm() async {
    try {
      if (MedicalSlmEngineService.instance.isModelLoaded) return;
      final dirs = await ModelStorageService.candidateDirectories();
      for (final dir in dirs) {
        if (!dir.existsSync()) continue;
        List<File> ggufs = [];
        try {
          ggufs = dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.gguf')).toList();
        } catch (_) {
          continue;
        }

        for (final gguf in ggufs) {
          bool isReadableGguf = false;
          try {
            final raf = await gguf.open(mode: FileMode.read);
            final magic = await raf.read(4);
            await raf.close();
            isReadableGguf = magic.length == 4 &&
                magic[0] == 0x47 && magic[1] == 0x47 && magic[2] == 0x55 && magic[3] == 0x46;
          } catch (e) {
            isReadableGguf = false;
            debugPrint('[AiAssistantProvider] Skipping unreadable model: ${gguf.path}');
          }

          if (isReadableGguf) {
            await MedicalSlmEngineService.instance.loadModel(gguf.path);
            if (MedicalSlmEngineService.instance.isModelLoaded) {
              return;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AiAssistantProvider] autoLoadOfflineSlm notice: $e');
    }
  }

  Future<void> _autoUnloadOfflineSlm() async {
    try {
      if (MedicalSlmEngineService.instance.isModelLoaded) {
        await MedicalSlmEngineService.instance.unloadModel();
      }
    } catch (e) {
      debugPrint('[AiAssistantProvider] autoUnloadOfflineSlm notice: $e');
    }
  }

  // --------------------------------------------------------------------------
  // Session-Wise Chat History Storage
  // --------------------------------------------------------------------------
  Future<void> initSessionStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('sanjeevani_chat_sessions_v2');
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        _savedSessions = decoded.map((s) => ChatSessionMeta.fromJson(s as Map<String, dynamic>)).toList();
        if (_savedSessions.isNotEmpty) {
          _savedSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          await loadSession(_savedSessions.first.id, shouldSaveCurrent: false);
          return;
        }
      }
      _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      final newMeta = ChatSessionMeta(
        id: _currentSessionId,
        title: 'New Consultation',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messageCount: _messages.length,
        lastSnippet: _messages.isNotEmpty ? _messages.last.text : '',
      );
      _savedSessions = [newMeta];
      await _persistSessionsIndex();
      await _persistActiveSessionMessages();
    } catch (e) {
      debugPrint('[AiAssistantProvider] initSessionStorage error: $e');
    }
  }

  Future<void> startNewSession({String? title}) async {
    await saveCurrentSession();
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _currentSymptoms.clear();
    _intakeTurnCount = 0;
    _activeDiagnosis = 'General Health Inquiry';
    _isManualLanguageSelected = false;
    _selectedLanguage = 'en';
    _initWelcomeMessage();

    final newMeta = ChatSessionMeta(
      id: _currentSessionId,
      title: title ?? (_selectedLanguage == 'te' ? 'కొత్త కన్సల్టేషన్' : (_selectedLanguage == 'hi' ? 'नया परामर्श' : 'New Consultation')),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: _messages.length,
      lastSnippet: _messages.isNotEmpty ? _messages.last.text : '',
    );
    _savedSessions.insert(0, newMeta);
    await _persistSessionsIndex();
    await _persistActiveSessionMessages();
    notifyListeners();
  }

  Future<void> loadSession(String sessionId, {bool shouldSaveCurrent = true}) async {
    if (shouldSaveCurrent) {
      await saveCurrentSession();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final msgsJson = prefs.getString('sanjeevani_session_msg_$sessionId');
      if (msgsJson != null && msgsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(msgsJson);
        final loaded = decoded.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>)).toList();
        _currentSessionId = sessionId;
        _messages.clear();
        _messages.addAll(loaded);

        _currentSymptoms.clear();
        for (final m in _messages) {
          if (m.detectedSymptoms != null) {
            for (final s in m.detectedSymptoms!) {
              if (!_currentSymptoms.contains(s)) _currentSymptoms.add(s);
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AiAssistantProvider] loadSession error: $e');
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sanjeevani_session_msg_$sessionId');
      _savedSessions.removeWhere((s) => s.id == sessionId);
      await _persistSessionsIndex();

      if (_currentSessionId == sessionId) {
        if (_savedSessions.isNotEmpty) {
          await loadSession(_savedSessions.first.id, shouldSaveCurrent: false);
        } else {
          await startNewSession();
        }
      } else {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AiAssistantProvider] deleteSession error: $e');
    }
  }

  Future<void> saveCurrentSession() async {
    if (_messages.isEmpty) return;
    try {
      String title = 'Clinical Consultation';
      for (final m in _messages) {
        if (m.isUser && m.text.trim().isNotEmpty) {
          final clean = m.text.trim().replaceAll('\n', ' ');
          title = clean.length > 28 ? '${clean.substring(0, 28)}...' : clean;
          break;
        }
      }

      final idx = _savedSessions.indexWhere((s) => s.id == _currentSessionId);
      final lastText = _messages.last.text.replaceAll('\n', ' ');
      final snippet = lastText.length > 40 ? '${lastText.substring(0, 40)}...' : lastText;

      if (idx != -1) {
        _savedSessions[idx].title = title;
        _savedSessions[idx].updatedAt = DateTime.now();
        _savedSessions[idx].messageCount = _messages.length;
        _savedSessions[idx].lastSnippet = snippet;
      } else {
        _savedSessions.insert(0, ChatSessionMeta(
          id: _currentSessionId,
          title: title,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          messageCount: _messages.length,
          lastSnippet: snippet,
        ));
      }

      await _persistSessionsIndex();
      await _persistActiveSessionMessages();
    } catch (e) {
      debugPrint('[AiAssistantProvider] saveCurrentSession error: $e');
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

  void seedUserContext(UserModel user) {
    if (user.name.isNotEmpty) {
      _patientName = user.name;
    }
    if (user.age > 0) {
      _patientAge = user.age;
    }
    if (user.gender.isNotEmpty) {
      _patientGender = user.gender;
    }
    if (_messages.length <= 1) {
      _initWelcomeMessage();
    }
  }

  void _initWelcomeMessage() {
    _messages.clear();
    _intakeTurnCount = 0;
    _knownSeverity = null;
    _knownPastHistory = null;
    _knownExistingMeds = null;
    final displayName = (_patientName != null && _patientName!.trim().isNotEmpty)
        ? _patientName!.trim().split(' ').first
        : 'there';

    String welcomeText;
    List<String> suggestions;

    if (_selectedLanguage == 'te') {
      welcomeText = 'నమస్కారం $displayName గారు! నేను మీ డాక్టర్ శన్నీ (Dr. Shanni) ని.\n\nమీ ఆరోగ్యం ఎలా ఉంది? మీకు ఏమి ఇబ్బందిగా ఉందో చెప్పండి.';
      suggestions = const [];
    } else if (_selectedLanguage == 'hi') {
      welcomeText = 'नमस्ते $displayName जी! मैं आपकी डॉ. शन्नी (Dr. Shanni) हूँ।\n\nआपकी सेहत कैसी है? कृपया बताएं क्या परेशानी है।';
      suggestions = const [];
    } else {
      welcomeText = 'Hello $displayName! I am Dr. Shanni, your Clinical AI Doctor.\n\nHow are you feeling today? Please tell me what health symptoms you have.';
      suggestions = const [];
    }

    _messages.add(
      ChatMessage(
        id: 'msg-1',
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
        actionSuggestions: suggestions,
      ),
    );
  }

  /// Book a direct slot appointment with a Doctor / Hospital
  Future<AppointmentModel> bookDoctorAppointment(
    DoctorModel doctor, {
    String? timeSlot,
    ConsultationType type = ConsultationType.videoConsult,
    String? slotDate,
  }) async {
    final isTelugu = _selectedLanguage == 'te';
    final isHindi = _selectedLanguage == 'hi';
    final chosenSlot = timeSlot ?? '10:30 AM';
    final chosenDate = slotDate ?? 'Tomorrow';

    final newAppt = AppointmentModel(
      id: '#BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: 'USR-101',
      userName: _patientName ?? 'Venkatesh Murthy',
      userPhone: '9848022338',
      aarogyasriId: 'AROG-TG-44910',
      doctorId: doctor.id,
      doctorName: doctor.name,
      doctorPhoto: doctor.photoUrl,
      doctorSpecialty: doctor.specialty,
      hospitalId: doctor.hospitalId,
      hospitalName: doctor.hospitalName,
      hospitalLocation: doctor.location,
      dateTime: DateTime.now().add(const Duration(days: 1)),
      timeSlot: chosenSlot,
      type: type,
      status: AppointmentStatus.confirmed,
      paymentStatus: PaymentStatus.paid,
      consultationFee: type == ConsultationType.clinicVisit ? doctor.clinicFee : doctor.videoFee,
      platformFee: 49.0,
      discountAmount: 0.0,
      totalAmount: (type == ConsultationType.clinicVisit ? doctor.clinicFee : doctor.videoFee) + 49.0,
      aarogyasriApplied: true,
      symptomsSummary: _currentSymptoms.isNotEmpty ? _currentSymptoms.join(', ') : 'Clinical Consultation',
      meetingRoomId: 'room-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      createdAt: DateTime.now(),
    );

    CentralDataService.instance.addAppointment(newAppt);

    final String resText = isTelugu
        ? '${doctor.name} (${doctor.specialty} • ${doctor.hospitalName}) తో అపాయింట్‌మెంట్ బుక్ చేయబడింది.\n\nతేదీ: $chosenDate, సమయం: $chosenSlot (${type == ConsultationType.clinicVisit ? "ఇన్-పర్సన్ హాస్పిటల్ విజిట్" : "లైవ్ వీడియో కన్సల్ట్"}). ఆరోగ్యశ్రీ డిజిటల్ పాస్ లింక్ చేయబడింది.'
        : (isHindi
            ? '${doctor.name} (${doctor.specialty} • ${doctor.hospitalName}) के साथ अपॉइंटमेंट सफलतापूर्वक बुक हो गया है।\n\nसमय: $chosenDate $chosenSlot (${type == ConsultationType.clinicVisit ? "अस्पताल में व्यक्तिगत परामर्श" : "वीडियो परामर्श"}).'
            : 'Appointment Confirmed with ${doctor.name} (${doctor.specialty})\nat ${doctor.hospitalName}.\n\nSchedule: $chosenDate at $chosenSlot (${type == ConsultationType.clinicVisit ? "In-Person Hospital Visit" : "Video Teleconsult"}). Aarogyasri Card applied.');

    final dynamicCards = [
      DynamicActionCard(
        title: 'Confirmed: ${doctor.name}',
        subtitle: '${doctor.hospitalName} • $chosenDate $chosenSlot • ${type == ConsultationType.clinicVisit ? "In-Person Visit" : "Video Consult"}',
        type: 'doctor',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF10B981),
        payload: newAppt,
      ),
    ];

    final botMsg = ChatMessage(
      id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
      text: resText,
      isUser: false,
      timestamp: DateTime.now(),
      dynamicCards: dynamicCards,
      suggestedDoctors: [doctor],
    );

    _messages.add(botMsg);
    await saveCurrentSession();
    if (_isLiveVoiceMode || _isSpeaking) {
      speakText(resText);
    }
    notifyListeners();
    return newAppt;
  }

  void selectCondition(String condition) {
    _activeDiagnosis = condition;
    if (condition.contains('Cardiac')) {
      _userInterestSegment = 'Cardiology & Hypertension';
    } else if (condition.contains('Fever') || condition.contains('Cold')) {
      _userInterestSegment = 'Preventive Master Checkups';
    }
    notifyListeners();
  }

  /// Auto-Detect Language across all 11 Indic Languages (Telugu, Hindi, Tamil, Kannada, Malayalam, Bengali, Marathi, Gujarati, Punjabi, Odia, English)
  static String detectLanguage(String text, [String currentLang = 'en']) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return currentLang;

    // 1. Native Indic Script Matching (Primary Ground Truth)
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(trimmed)) return 'te'; // Telugu
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(trimmed)) return 'ta'; // Tamil
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(trimmed)) return 'kn'; // Kannada
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(trimmed)) return 'ml'; // Malayalam
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(trimmed)) return 'bn'; // Bengali
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(trimmed)) return 'gu'; // Gujarati
    if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(trimmed)) return 'pa'; // Punjabi
    if (RegExp(r'[\u0B00-\u0B7F]').hasMatch(trimmed)) return 'or'; // Odia
    if (RegExp(r'[\u0900-\u097F]').hasMatch(trimmed)) {
      return currentLang == 'mr' ? 'mr' : 'hi'; // Marathi or Hindi
    }

    // If current language is already an Indic language, do NOT easily revert to English
    if (currentLang != 'en') {
      return currentLang;
    }

    // 2. Pure ASCII / Latin Analysis:
    final lower = ' ${trimmed.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ')} ';

    // High-priority English medical and conversational vocabulary
    final englishKeywords = [
      'personalized', 'home', 'care', 'tips', 'order', 'prescribed', 'medicine', 'medicines',
      'doctor', 'hospital', 'fever', 'headache', 'cold', 'cough', 'pain', 'stomach',
      'throat', 'sore', 'joint', 'knee', 'symptom', 'symptoms', 'tablet', 'tablets',
      'consult', 'consultation', 'appointment', 'emergency', 'treatment', 'prescription',
      'diet', 'exercise', 'water', 'sleep', 'rest', 'blood', 'test', 'tests', 'lab',
      'hello', 'hi', 'hey', 'please', 'help', 'thank', 'thanks', 'thank you',
      'feeling', 'severe', 'mild', 'days', 'yesterday', 'today', 'how', 'what',
      'morning', 'evening', 'night', 'take', 'need', 'give', 'suggest', 'where', 'which',
      'good', 'better', 'worse', 'body', 'head', 'chest', 'back', 'leg', 'arm', 'skin',
      'infection', 'allergy', 'pressure', 'sugar', 'vomiting', 'nausea', 'diarrhea'
    ];

    int englishScore = 0;
    for (final kw in englishKeywords) {
      if (lower.contains(' $kw ')) {
        englishScore += 2;
      }
    }

    // Distinct Indic Romanized keywords
    final teluguKeywords = [
      'naku', 'naaku', 'undhi', 'undi', 'unnanu', 'unnaru', 'unnayi', 'unte',
      'jwaram', 'jvaram', 'thalanoppi', 'kadupulo', 'kadupu noppi',
      'gonthu', 'gonthulo', 'daggu', 'jalubu', 'nerasam', 'mandulu', 'mandhulu',
      'cheppandi', 'cheyali', 'namaskaram', 'taggadam', 'taggadaniki', 'chesukovali',
      'pampandi', 'telusukovali', 'ivvandi', 'kavalenu', 'vastondi', 'vastundi'
    ];

    final hindiKeywords = [
      'mujhe', 'mera', 'meri', 'mere', 'bukhar', 'dard', 'sar dard', 'sir dard',
      'pait', 'pet dard', 'khansi', 'jukham', 'sardi', 'dawa', 'dawaii', 'dawayi',
      'goli', 'chahiye', 'bataiye', 'batao', 'namaste', 'kaise', 'kamzori', 'chakkar',
      'bimar', 'bimari', 'aspatal', 'kripya', 'madad', 'kijiye', 'kya kare',
      'ho raha', 'ho gaya', 'lag raha', 'kuch nahi', 'theek nahi'
    ];

    int teluguScore = 0;
    for (final kw in teluguKeywords) {
      if (lower.contains(' $kw ')) {
        teluguScore += 2;
      }
    }

    int hindiScore = 0;
    for (final kw in hindiKeywords) {
      if (lower.contains(' $kw ')) {
        hindiScore += 2;
      }
    }

    if (teluguScore > 0 && teluguScore > hindiScore && teluguScore > englishScore) {
      return 'te';
    }
    if (hindiScore > 0 && hindiScore > teluguScore && hindiScore > englishScore) {
      return 'hi';
    }

    if (englishScore > 0 && englishScore >= hindiScore && englishScore >= teluguScore) {
      return 'en';
    }

    // Default to current language if already set
    if (currentLang.isNotEmpty) {
      return currentLang;
    }

    return 'en';
  }

  void setLanguage(String lang) {
    _isManualLanguageSelected = true;
    if (_selectedLanguage == lang) return;
    _selectedLanguage = lang;
    SarvamLiveSttService.setLanguage(lang);
    _initWelcomeMessage();
    notifyListeners();
  }

  void toggleLiveVoiceMode([bool? forceState, bool skipGreetingSpeech = false]) async {
    _isLiveVoiceMode = forceState ?? !_isLiveVoiceMode;
    if (_isLiveVoiceMode) {
      SarvamLiveSttService.startLiveKitVoiceSession();
      if (!skipGreetingSpeech && !_isSpeaking && !_isThinking && !SarvamLiveSttService.isSpeakingNow()) {
        if (_messages.isNotEmpty && _messages.length == 1 && !_messages.first.isUser) {
          speakText(_messages.first.text, _selectedLanguage);
        } else {
          _startVoiceRecognition();
        }
      }
    } else {
      _callAutoListenTimer?.cancel();
      _speechMonitorTimer?.cancel();
      _stopVoiceRecognition();
      stopSpeaking();
      SarvamLiveSttService.stopLiveKitVoiceSession();
    }
    notifyListeners();
  }

  void updatePatientIntake({int? age, String? gender, String? duration, String? temp, String? name}) {
    if (age != null) _patientAge = age;
    if (gender != null) _patientGender = gender;
    if (duration != null) _symptomDuration = duration;
    if (temp != null) _bodyTemperature = temp;
    if (name != null) _patientName = name;
    notifyListeners();
  }

  void toggleVoiceListening([String? customSpokenText]) {
    if (_isListening) {
      _stopVoiceRecognition();
    } else {
      if (!_isSpeaking && !_isThinking && !SarvamLiveSttService.isSpeakingNow()) {
        _startVoiceRecognition(customSpokenText);
      }
    }
  }

  void stopSpeaking() {
    _speechMonitorTimer?.cancel();
    SarvamLiveSttService.stopSpeaking();
    _isSpeaking = false;
    notifyListeners();
  }

  void speakText(String text, [String? targetLang]) {
    _callAutoListenTimer?.cancel();
    _interimTimer?.cancel();
    _isListening = false;
    stopSpeaking();
    _isSpeaking = true;
    notifyListeners();

    final voiceLang = targetLang ?? (
      RegExp(r'[\u0C00-\u0C7F]').hasMatch(text)
        ? 'te'
        : (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)
            ? 'ta'
            : (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text)
                ? 'kn'
                : (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)
                    ? 'ml'
                    : (RegExp(r'[\u0980-\u09FF]').hasMatch(text)
                        ? 'bn'
                        : (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)
                            ? 'gu'
                            : (RegExp(r'[\u0A00-\u0A7F]').hasMatch(text)
                                ? 'pa'
                                : (RegExp(r'[\u0B00-\u0B7F]').hasMatch(text)
                                    ? 'or'
                                    : (RegExp(r'[\u0900-\u097F]').hasMatch(text)
                                        ? (_selectedLanguage == 'mr' ? 'mr' : 'hi')
                                        : _selectedLanguage))))))))
    );

    SarvamLiveSttService.speakText(text, voiceLang);

    int elapsedTicks = 0;
    bool hasStartedPlaying = false;
    _speechMonitorTimer?.cancel();
    _speechMonitorTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      elapsedTicks++;
      final isPlaying = SarvamLiveSttService.isSpeakingNow();
      final speechJustEnded = SarvamLiveSttService.isSpeechJustEnded();

      if (isPlaying) {
        hasStartedPlaying = true;
      }

      if (speechJustEnded || (hasStartedPlaying && !isPlaying && elapsedTicks > 2) || elapsedTicks > 350) {
        timer.cancel();
        _isSpeaking = false;
        notifyListeners();

        if (_isLiveVoiceMode) {
          Future.delayed(const Duration(milliseconds: 150), () {
            if (_isLiveVoiceMode && !_isSpeaking && !_isListening && !_isThinking) {
              _startVoiceRecognition();
            }
          });
        }
      }
    });
  }

  void _startVoiceRecognition([String? fallbackText, int retryCount = 0]) async {
    if (_isThinking) return;
    if (_isSpeaking || SarvamLiveSttService.isSpeakingNow()) {
      if (retryCount < 4) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_isLiveVoiceMode && !_isListening && !_isThinking) {
            _startVoiceRecognition(fallbackText, retryCount + 1);
          }
        });
      }
      return;
    }

    _speechMonitorTimer?.cancel();
    SarvamLiveSttService.stopSpeaking();
    _isSpeaking = false;
    _isListening = true;
    _liveTranscription = _selectedLanguage == 'te'
        ? 'వినబడుతోంది... మాట్లాడండి'
        : (_selectedLanguage == 'hi' ? 'सुन रहा हूँ... बोलिए' : 'Listening... Speak now');
    notifyListeners();

    // Start fast real-time VAD silence auto-cut and interim subtitle polling (every 80ms)
    _interimTimer?.cancel();
    _interimTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (_isListening) {
        if (SarvamLiveSttService.isSilenceCutoffTriggered()) {
          _interimTimer?.cancel();
          _stopVoiceRecognition();
          return;
        }

        final interim = SarvamLiveSttService.getLiveInterim();
        if (interim.isNotEmpty && interim != _liveTranscription) {
          _liveTranscription = interim;
          notifyListeners();
        }
      }
    });

    await SarvamLiveSttService.startListening(_selectedLanguage);
  }

  void _stopVoiceRecognition() async {
    _callAutoListenTimer?.cancel();
    _interimTimer?.cancel();
    _isListening = false;
    notifyListeners();

    final transcript = await SarvamLiveSttService.stopAndTranscribe(_selectedLanguage);
    _liveTranscription = '';

    if (transcript != null && transcript.trim().isNotEmpty) {
      final hasNativeScript = RegExp(r'[\u0C00-\u0C7F\u0900-\u097F\u0B80-\u0BFF\u0C80-\u0CFF\u0D00-\u0D7F\u0980-\u09FF\u0A80-\u0AFF\u0A00-\u0A7F\u0B00-\u0B7F]').hasMatch(transcript.trim());
      if (!_isManualLanguageSelected || hasNativeScript) {
        final autoLang = detectLanguage(transcript.trim(), _selectedLanguage);
        if (autoLang != _selectedLanguage) {
          _selectedLanguage = autoLang;
        }
      }
      await addUserMessage(transcript.trim(), isVoice: true);
    } else {
      notifyListeners();
      if (_isLiveVoiceMode && !_isSpeaking && !_isThinking) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_isLiveVoiceMode && !_isSpeaking && !_isListening && !_isThinking) {
            _startVoiceRecognition();
          }
        });
      }
    }
  }

  /// Process User Message with Seamless Auto-Switch (Online LLM <-> On-Device Offline SLM)
  Future<void> addUserMessage(String text, {String? patientName, bool isVoice = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Language detection:
    // If user has manually selected a language via chips, respect it unless an unambiguous native Indic script is detected.
    final hasNativeScript = RegExp(r'[\u0C00-\u0C7F\u0900-\u097F\u0B80-\u0BFF\u0C80-\u0CFF\u0D00-\u0D7F\u0980-\u09FF\u0A80-\u0AFF\u0A00-\u0A7F\u0B00-\u0B7F]').hasMatch(trimmed);
    if (!_isManualLanguageSelected || hasNativeScript) {
      final autoDetected = detectLanguage(trimmed, _selectedLanguage);
      if (autoDetected != _selectedLanguage) {
        _selectedLanguage = autoDetected;
      }
    }

    // 1. Entity Extraction - Name
    final nameRegex = RegExp(
      r'\b(?:my\s+name\s+is|i\s+am|im|this\s+is|call\s+me|name\s*:\s*|నా\s*పేరు\s*|నాపేరు\s*|मेरा\s*नाम\s*)\s*([a-zA-Z\u0C00-\u0C7F\u0900-\u097F]+(?:\s+[a-zA-Z\u0C00-\u0C7F\u0900-\u097F]+)?)',
      caseSensitive: false,
    );
    final nameMatch = nameRegex.firstMatch(trimmed);
    if (nameMatch != null) {
      final parsed = nameMatch.group(1)?.trim();
      if (parsed != null && parsed.length >= 2 && !parsed.toLowerCase().contains('fever')) {
        _patientName = parsed;
      }
    }

    // 2. Entity Extraction - Age
    final explicitAgeMatch = RegExp(
      r'\b(?:age|వయస్సు|उम्र)\s*[:=]?\s*(\d{1,2})\b|\b(\d{1,2})\s*(?:years?|yrs?|y/o|year\s*old|साल|वर्ष|సంవత్సరాలు|ఏళ్ళు)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (explicitAgeMatch != null) {
      final ageStr = explicitAgeMatch.group(1) ?? explicitAgeMatch.group(2);
      final parsedAge = int.tryParse(ageStr ?? '');
      if (parsedAge != null && parsedAge > 0 && parsedAge < 115) {
        _patientAge = parsedAge;
      }
    }

    // 3. Entity Extraction - Gender
    final genderMatch = RegExp(
      r'\b(male|female|man|woman|boy|girl|పురుషుడు|మహిళ|స్త్రీ|पुरुष|महिला)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (genderMatch != null) {
      _patientGender = genderMatch.group(0);
    }

    // 4. Entity Extraction - Duration
    final durationMatch = RegExp(
      r'\b(\d+\s*(?:days?|weeks?|months?|hours?|రోజులు|రోజుల|दिन|घंटे)|since\s+(?:yesterday|morning|last\s+night|\d+\s+days?)|నిన్నటి\s*నుండి|నిన్నటినుండి|कल\s*సే|आज\s*సే|\d+\s*दिनों?\s*సే|\d+\s*రోజులు)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (durationMatch != null) {
      _symptomDuration = durationMatch.group(0);
    }

    // 5. Entity Extraction - Temperature
    final tempMatch = RegExp(
      r'\b((?:9[7-9]|10[0-6])(?:\.\d)?\s*(?:°?[fF]|degrees?|డిగ్రీ|डिग्री)?)\b',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (tempMatch != null) {
      _bodyTemperature = tempMatch.group(1);
    }

    // 6. Entity Extraction - Symptoms
    final extracted = NvidiaAiService.extractSymptoms(trimmed, _selectedLanguage);
    for (final s in extracted) {
      if (!_currentSymptoms.contains(s)) {
        _currentSymptoms.add(s);
      }
    }

    _intakeTurnCount++;

    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: DateTime.now(),
      isAudio: isVoice,
    );
    _messages.add(userMsg);
    _isThinking = true;
    notifyListeners();

    // Check Network Availability in Background
    final networkAvailable = await checkNetworkConnectivity();
    final lower = trimmed.toLowerCase();
    final isTelugu = _selectedLanguage == 'te';
    final isHindi = _selectedLanguage == 'hi';

    // Direct Intent: Emergency 108 Ambulance Dispatch
    final bool isEmergencyIntent = lower.contains('ambulance') ||
        lower.contains('emergency') ||
        lower.contains('108') ||
        lower.contains('అంబులెన్స్') ||
        lower.contains('ఆపత్కాలం') ||
        lower.contains('एम्बुलेंस') ||
        lower.contains('आपातकालीन');

    if (isEmergencyIntent) {
      final dispatch = CentralDataService.instance.triggerEmergencySOS(
        userId: 'USR-101',
        patientName: _patientName ?? 'Verified Patient',
        patientPhone: '9848022338',
        location: 'Live GPS Location (Madhapur, Hyderabad)',
        ambulanceProvider: 'Govt 108 Emergency Service',
        etaMinutes: '6 mins',
        notes: 'Emergency SOS dispatched via Sanjeevani AI Assistant',
      );

      final String resText = isTelugu
          ? '108 అత్యవసర అంబులెన్స్ పంపబడింది. అంబులెన్స్ మీ లైవ్ జీపీఎస్ లొకేషన్‌కు 6 నిమిషాల్లో చేరుకుంటుంది. దయచేసి ప్రశాంతంగా ఉండండి, సహాయక బృందం మార్గంలో ఉంది.'
          : (isHindi
              ? '108 आपातकालीन एम्बुलेंस भेज दी गई है। एम्बुलेंस 6 मिनट में आपकी लाइव लोकेशन पर पहुंचेगी। कृपया शांत रहें, मेडिकल टीम रास्ते में है।'
              : '108 Emergency Ambulance Dispatched. Ambulance #EMERG-108 is en-route to your live GPS location with an ETA of 6 minutes. Please stay calm, paramedics are on the way.');

      final dynamicCards = [
        DynamicActionCard(
          title: isTelugu ? '108 అంబులెన్స్ మార్గంలో ఉంది' : (isHindi ? '108 एम्बुलेंस रास्ते में है' : '108 Ambulance En-Route'),
          subtitle: isTelugu ? 'చేరుకునే సమయం: 6 నిమిషాలు (KIMS ఎమర్జెన్సీ)' : (isHindi ? 'आगमन समय: 6 मिनट (KIMS ट्रॉमा)' : 'Live GPS ETA: 6 mins (KIMS Trauma Hospital)'),
          type: 'emergency',
          icon: Icons.emergency_rounded,
          color: const Color(0xFFEF4444),
          payload: dispatch,
        ),
      ];

      final botMsg = ChatMessage(
        id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
        text: resText,
        isUser: false,
        timestamp: DateTime.now(),
        dynamicCards: dynamicCards,
        actionSuggestions: isTelugu
            ? ['లైవ్ అంబులెన్స్ ట్రాక్ చేయండి', 'డాక్టర్‌తో మాట్లాడండి']
            : (isHindi ? ['लाइव एम्बुलेंस ट्रैक करें', 'डॉक्टर से बात करें'] : ['Track 108 Live GPS', 'Call Trauma Doctor']),
      );

      _messages.add(botMsg);
      await saveCurrentSession();
      _isThinking = false;
      notifyListeners();
      if (isVoice || _isLiveVoiceMode) speakText(resText);
      return;
    }

    // Direct Intent: Book Doctor Appointment
    final bool isBookDoctorIntent = lower.contains('book appointment') ||
        lower.contains('book doctor') ||
        lower.contains('schedule appointment') ||
        lower.contains('see doctor') ||
        lower.contains('consult doctor') ||
        lower.contains('అపాయింట్') ||
        lower.contains('డాక్టర్ బుక్') ||
        lower.contains('డాక్టర్ సంప్రదింపు') ||
        lower.contains('अपॉइंटमेंट') ||
        lower.contains('डॉक्टर बुक');

    if (isBookDoctorIntent) {
      final doctors = _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, trimmed);
      final doctor = doctors.isNotEmpty ? doctors.first : ProductionDatabase.doctors[4]; // Default Dr. Prashant Reddy

      final newAppt = AppointmentModel(
        id: '#BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        userId: 'USR-101',
        userName: _patientName ?? 'Venkatesh Murthy',
        userPhone: '9848022338',
        aarogyasriId: 'AROG-TG-44910',
        doctorId: doctor.id,
        doctorName: doctor.name,
        doctorPhoto: doctor.photoUrl,
        doctorSpecialty: doctor.specialty,
        hospitalId: doctor.hospitalId,
        hospitalName: doctor.hospitalName,
        hospitalLocation: doctor.location,
        dateTime: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '10:30 AM',
        type: ConsultationType.videoConsult,
        status: AppointmentStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        consultationFee: doctor.videoFee > 0 ? doctor.videoFee : 600.0,
        platformFee: 49.0,
        discountAmount: 0.0,
        totalAmount: doctor.videoFee > 0 ? doctor.videoFee + 49.0 : 649.0,
        aarogyasriApplied: true,
        symptomsSummary: _currentSymptoms.isNotEmpty ? _currentSymptoms.join(', ') : 'Clinical Consultation',
        meetingRoomId: 'room-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        createdAt: DateTime.now(),
      );

      CentralDataService.instance.addAppointment(newAppt);

      final String resText = isTelugu
          ? '${doctor.name} (${doctor.specialty}) తో అపాయింట్‌మెంట్ విజయవంతంగా బుక్ చేయబడింది.\n\nసమయం: రేపు ఉదయం 10:30 AM (వీడియో కన్సల్టేషన్). ఆరోగ్యశ్రీ డిజిటల్ పాస్ లింక్ చేయబడింది.'
          : (isHindi
              ? '${doctor.name} (${doctor.specialty}) के साथ अपॉइंटमेंट सफलतापूर्वक बुक हो गया है।\n\nसमय: कल सुबह 10:30 AM (वीडियो परामर्श)। आरोग्यश्री डिजिटल पास लिंक किया गया है।'
              : 'Appointment successfully booked with ${doctor.name} (${doctor.specialty}).\n\nSchedule: Tomorrow at 10:30 AM (Video Consultation). Verified Aarogyasri subsidy pass applied.');

      final dynamicCards = [
        DynamicActionCard(
          title: 'Confirmed Booking: ${doctor.name}',
          subtitle: '${doctor.specialty} • Tomorrow 10:30 AM • Video Consult',
          type: 'doctor',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF10B981),
          payload: newAppt,
        ),
      ];

      final botMsg = ChatMessage(
        id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
        text: resText,
        isUser: false,
        timestamp: DateTime.now(),
        dynamicCards: dynamicCards,
        suggestedDoctors: [doctor],
        actionSuggestions: isTelugu
            ? ['మందులు ఆర్డర్ చేయండి', 'ల్యాబ్ టెస్ట్ బుక్ చేయండి']
            : (isHindi ? ['दवाइयां ऑर्डर करें', 'लैब टेस्ट बुक करें'] : ['Order Suggested Medicines', 'Book Lab Test']),
      );

      _messages.add(botMsg);
      await saveCurrentSession();
      _isThinking = false;
      notifyListeners();
      if (isVoice || _isLiveVoiceMode) speakText(resText);
      return;
    }

    // Determine effective online state
    final bool effectiveOnline = _isOnline && networkAvailable;

    // If Device is OFFLINE: Use on-device Medical SLM Engine with full Indic language support
    if (!effectiveOnline) {
      final history = _messages.take(_messages.length - 1).map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      final bool offlineWantsMeds = lower.contains('medicine') ||
          lower.contains('tablet') ||
          lower.contains('మందులు') ||
          lower.contains('దవా') ||
          lower.contains('treatment') ||
          lower.contains('dolo') ||
          lower.contains('paracetamol');

      final bool offlineWantsDocs = lower.contains('doctor') ||
          lower.contains('hospital') ||
          lower.contains('appointment') ||
          lower.contains('consult') ||
          lower.contains('డాక్టర్') ||
          lower.contains('ఆసుపత్రి') ||
          lower.contains('डॉक्टर') ||
          lower.contains('अस्पताल');

      if (!MedicalSlmEngineService.instance.isModelLoaded) {
        await _autoLoadOfflineSlm();
      }

      if (!MedicalSlmEngineService.instance.isModelLoaded) {
        final notDownloadedMsg = _selectedLanguage == 'te'
            ? '⚠️ స్థానిక SLM మోడల్ పరికరంలో కనుగొనబడలేదు.\n\nఇంటర్నెట్ లేకుండా ఆఫ్‌లైన్ క్లినికల్ ఏఐతో మాట్లాడటానికి, దయచేసి ఎగువన ఉన్న "మోడల్ మేనేజర్" (Model Manager) నుండి డాక్టర్ శన్నీ / మేధా SLM మోడల్‌ను డౌన్‌లోడ్ చేయండి.\n\nడౌన్‌లోడ్ పూర్తయిన తర్వాత, మోడల్ నేరుగా మీ మొబైల్ ప్రాసెసర్‌పై 100% ఆఫ్‌లైన్‌లో రన్ అవుతుంది.'
            : (_selectedLanguage == 'hi'
                ? '⚠️ स्थानीय SLM मॉडल डिवाइस पर नहीं मिला।\n\nबिना इंटरनेट ऑफलाइन परामर्श के लिए कृपया ऊपर दिए गए "मॉडल मैनेजर" (Model Manager) से डॉ. शन्नी / मेधा SLM मॉडल डाउनलोड करें। डाउनलोड होने के बाद यह 100% ऑफलाइन चलेगा।'
                : '⚠️ No On-Device SLM Model Found on Device.\n\nTo consult offline with zero internet, please download a local medical model (e.g. Dr. Medha SLM or Qwen 2.5 1.5B) from the Model Manager above.\n\nOnce downloaded, it runs 100% on your device hardware with real-time generation.');

        final botMsg = ChatMessage(
          id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
          text: notDownloadedMsg,
          isUser: false,
          timestamp: DateTime.now(),
          isOffline: true,
          actionSuggestions: _selectedLanguage == 'te'
              ? ['మోడల్ మేనేజర్ తెరవండి', 'ఆన్‌లైన్ మోడ్‌కు మారండి']
              : (_selectedLanguage == 'hi'
                  ? ['मॉडल मैनेजर खोलें', 'ऑनलाइन AI पर जाएं']
                  : ['Open Model Manager', 'Switch to Online AI']),
        );
        _messages.add(botMsg);
        await saveCurrentSession();
        _isThinking = false;
        notifyListeners();
        return;
      }

      String offlineReply = '';
      InferenceMetrics? offlineMetrics;
      try {
        offlineMetrics = await MedicalSlmEngineService.instance.generateMedicalResponse(
          userQuery: trimmed,
          lang: _selectedLanguage,
          conversationHistory: history,
          intakeTurn: _intakeTurnCount,
          patientName: patientName ?? _patientName,
          currentSymptoms: _currentSymptoms,
          symptomDuration: _symptomDuration,
          bodyTemperature: _bodyTemperature,
          wantsMedicines: offlineWantsMeds,
          wantsDoctor: offlineWantsDocs,
          ragContext: null, // Zero RAG chunks for pure direct model response
          onToken: (tok) {},
          onComplete: (full) {
            offlineReply = full;
          },
          onError: (err) {
            offlineReply = err;
          },
        );
      } catch (e) {
        offlineReply = 'Model generation error: $e';
      }

      if (offlineReply.trim().isEmpty) {
        offlineReply = 'Model generation returned empty response.';
      }

      _activeDiagnosis = _classifyDiagnosisOffline(trimmed);

      // Conversational suggestion pacing:
      // NEVER dump all medicines, doctors, hospitals, and tests at once!
      final bool wantsMeds = lower.contains('medicine') ||
          lower.contains('tablet') ||
          lower.contains('మందులు') ||
          lower.contains('दवा') ||
          lower.contains('treatment') ||
          lower.contains('dolo') ||
          lower.contains('paracetamol');

      final bool wantsDocs = lower.contains('doctor') ||
          lower.contains('hospital') ||
          lower.contains('appointment') ||
          lower.contains('consult') ||
          lower.contains('డాక్టర్') ||
          lower.contains('ఆసుపత్రి') ||
          lower.contains('डॉक्टर') ||
          lower.contains('अस्पताल');

      final matchedMedicines = wantsMeds ? _getMedicinesForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;
      final matchedDoctors = wantsDocs ? _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;
      final matchedHospitals = (wantsDocs && (lower.contains('hospital') || lower.contains('ఆసుపత్రి') || lower.contains('अस्पताल')))
          ? _getHospitalsForContext(_activeDiagnosis, _currentSymptoms, trimmed)
          : null;

      final botMsg = ChatMessage(
        id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
        text: offlineReply,
        isUser: false,
        isOffline: true,
        metrics: offlineMetrics,
        timestamp: DateTime.now(),
        detectedSymptoms: _currentSymptoms,
        actionSuggestions: _getOfflineActionSuggestions(_activeDiagnosis, _selectedLanguage),
        suggestedMedicines: matchedMedicines,
        suggestedDoctors: matchedDoctors,
        suggestedHospitals: matchedHospitals,
      );

      _messages.add(botMsg);
      await saveCurrentSession();
      _isThinking = false;
      notifyListeners();
      if (isVoice || _isLiveVoiceMode) speakText(offlineReply);
      return;
    }

    // Device is ONLINE: Call Cloud NVIDIA/Sarvam LLM
    try {
      final history = _messages.take(_messages.length - 1).map((m) => {
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      // Retrieve related RAG knowledge layer from real-time admin sync
      final onlineRagPrompt = ClinicalRagService.instance.buildRagContextPrompt(
        trimmed,
        symptoms: _currentSymptoms,
      );

      final aiRes = await NvidiaAiService.generateResponse(
        userQuery: trimmed,
        conversationHistory: history,
        lang: _selectedLanguage,
        patientName: patientName ?? _patientName,
        patientAge: _patientAge,
        gender: _patientGender,
        currentSymptoms: _currentSymptoms,
        symptomDuration: _symptomDuration,
        bodyTemperature: _bodyTemperature,
        intakeTurn: _intakeTurnCount,
        knownSeverity: _knownSeverity,
        knownPastHistory: _knownPastHistory,
        knownExistingMeds: _knownExistingMeds,
        isVoiceMode: isVoice,
        ragContext: onlineRagPrompt,
      );

      _activeDiagnosis = aiRes.triageCategory;

      for (final s in aiRes.detectedSymptoms) {
        if (!_currentSymptoms.contains(s)) {
          _currentSymptoms.add(s);
        }
      }

      // Conversational suggestion pacing:
      // Only suggest medicines if the patient asks or accepts tablets
      final bool wantsMeds = aiRes.wantsMedicines ||
          lower.contains('medicine') ||
          lower.contains('tablet') ||
          lower.contains('మందులు') ||
          lower.contains('दवा') ||
          lower.contains('pill') ||
          lower.contains('dolo');

      final bool wantsDocs = lower.contains('doctor') ||
          lower.contains('hospital') ||
          lower.contains('appointment') ||
          lower.contains('consult') ||
          lower.contains('డాక్టర్') ||
          lower.contains('ఆసుపత్రి') ||
          lower.contains('डॉक्टर') ||
          lower.contains('अस्पताल');

      final bool wantsTests = lower.contains('lab test') ||
          lower.contains('blood test') ||
          lower.contains('ల్యాబ్') ||
          lower.contains('टेस्ट');

      final matchedMedicines = wantsMeds ? _getMedicinesForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;
      final matchedDoctors = (wantsDocs || (_intakeTurnCount >= 4 && !wantsMeds))
          ? _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, trimmed)
          : null;
      final matchedHospitals = (wantsDocs && (lower.contains('hospital') || lower.contains('ఆసుపత్రి') || lower.contains('अस्पताल')))
          ? _getHospitalsForContext(_activeDiagnosis, _currentSymptoms, trimmed)
          : null;
      final matchedTests = wantsTests ? _getLabTestsForContext(_activeDiagnosis, _currentSymptoms, trimmed) : null;

      final emergencyCards = _generateDynamicCards(_activeDiagnosis, trimmed);

      final botMsg = ChatMessage(
        id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
        text: aiRes.content,
        isUser: false,
        isOffline: false,
        timestamp: DateTime.now(),
        detectedSymptoms: _currentSymptoms,
        actionSuggestions: aiRes.actionSuggestions,
        suggestedMedicines: matchedMedicines,
        suggestedDoctors: matchedDoctors,
        suggestedHospitals: matchedHospitals,
        suggestedLabTests: matchedTests,
        dynamicCards: emergencyCards.isNotEmpty ? emergencyCards : null,
      );

      _messages.add(botMsg);
      await saveCurrentSession();

      if (isVoice || _isLiveVoiceMode) {
        speakText(aiRes.content);
      }

      if (_currentSymptoms.isNotEmpty || _patientName != null) {
        ApiService.runAiTriageWithMemory(
          userId: 'USR-101',
          symptoms: _currentSymptoms.isNotEmpty ? _currentSymptoms.join(', ') : 'Intake: ${_patientName ?? "Patient"}',
          duration: _symptomDuration ?? '1-2 days',
          language: _selectedLanguage,
        );
      }
    } catch (e) {
      debugPrint('[AiAssistantProvider] Cloud AI failed ($e), falling back to On-Device Offline SLM...');
      _isOnline = false;
      final offlineReply = _generateOfflineClinicalResponse(trimmed, _selectedLanguage);
      final fallbackText = '⚡ *[Offline On-Device SLM Fallback — Network Unavailable]*\n\n$offlineReply';

      final botMsg = ChatMessage(
        id: 'msg-bot-${DateTime.now().millisecondsSinceEpoch}',
        text: fallbackText,
        isUser: false,
        isOffline: true,
        timestamp: DateTime.now(),
        detectedSymptoms: _currentSymptoms,
        suggestedMedicines: _getMedicinesForContext(_activeDiagnosis, _currentSymptoms, trimmed),
        suggestedDoctors: _getDoctorsForContext(_activeDiagnosis, _currentSymptoms, trimmed),
        suggestedHospitals: _getHospitalsForContext(_activeDiagnosis, _currentSymptoms, trimmed),
        suggestedLabTests: _getLabTestsForContext(_activeDiagnosis, _currentSymptoms, trimmed),
      );
      _messages.add(botMsg);
      await saveCurrentSession();
      if (isVoice || _isLiveVoiceMode) speakText(offlineReply);
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // Offline Clinical SLM Engine Fallback
  // --------------------------------------------------------------------------
  String _classifyDiagnosisOffline(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('chest') || lower.contains('heart') || lower.contains('breath') || lower.contains('stroke') || lower.contains('గుండె')) {
      return 'Emergency Cardiac Assessment';
    }
    if (lower.contains('fever') || lower.contains('temperature') || lower.contains('జ్వరం') || lower.contains('बुखार')) {
      return 'Acute Febrile Illness';
    }
    if (lower.contains('stomach') || lower.contains('acidity') || lower.contains('vomit') || lower.contains('కడుపు') || lower.contains('पेट')) {
      return 'Gastrointestinal Distress';
    }
    if (lower.contains('headache') || lower.contains('migraine') || lower.contains('తలనొప్పి')) {
      return 'Cephalea / Headache Protocol';
    }
    if (lower.contains('knee') || lower.contains('joint') || lower.contains('back') || lower.contains('కీళ్ళ')) {
      return 'Musculoskeletal / Orthopedic';
    }
    return 'General Clinical Evaluation';
  }

  String _generateOfflineClinicalResponse(String query, String lang) {
    return MedicalSlmEngineService.instance.generateConversationalDoctorGuidance(
      userQuery: query,
      lang: lang,
      conversationHistory: _messages.map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text}).toList(),
      intakeTurn: _intakeTurnCount,
      patientName: _patientName,
      currentSymptoms: _currentSymptoms,
      symptomDuration: _symptomDuration,
      bodyTemperature: _bodyTemperature,
    );
  }

  List<String> _getOfflineActionSuggestions(String diagnosis, String lang) {
    if (lang == 'te') {
      return ['జ్వరం తగ్గింపు సూచనలు', 'సమీప వైద్యుడిని సంప్రదించండి', 'ల్యాబ్ టెస్ట్ వివరాలు'];
    } else if (lang == 'hi') {
      return ['बुखार में देखभाल', 'डॉक्टर से परामर्श लें', 'लैब टेस्ट की जानकारी'];
    }
    return ['Fever Care Steps', 'Consult General Physician', 'Book CBC Blood Test'];
  }

  // --------------------------------------------------------------------------
  // Strict Clinical Safety Recommendation Matching (NO RANDOM SUGGESTIONS!)
  // --------------------------------------------------------------------------
  List<MedicineModel> _getMedicinesForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    // Safety Rule 1: Empty / Casual greeting -> RETURN EMPTY
    final isGreeting = query.trim().toLowerCase() == 'hi' ||
        query.trim().toLowerCase() == 'hello' ||
        query.trim().toLowerCase() == 'hey' ||
        query.trim().toLowerCase() == 'నమస్తే' ||
        query.trim().toLowerCase() == 'నమస్కారం' ||
        query.trim().toLowerCase() == 'नमस्ते' ||
        query.trim().toLowerCase().contains('how are you') ||
        query.trim().toLowerCase().contains('who are you');

    if (symptoms.isEmpty && (isGreeting || sympText.trim().isEmpty)) {
      return [];
    }

    // Safety Rule 2: Chest Pain / Cardiac / Stroke Emergency -> NEVER suggest oral pills!
    if (sympText.contains('chest') ||
        sympText.contains('cardio') ||
        sympText.contains('heart attack') ||
        sympText.contains('stroke') ||
        sympText.contains('unconscious') ||
        sympText.contains('choking') ||
        sympText.contains('గుండె నొప్పి')) {
      return []; // Must not recommend self-medication during acute emergency
    }

    // Safety Rule 3: Stomach / Gastric / Acidity
    if (sympText.contains('acidity') ||
        sympText.contains('gastric') ||
        sympText.contains('stomach') ||
        sympText.contains('vomit') ||
        sympText.contains('gerd') ||
        sympText.contains('కడుపు') ||
        sympText.contains('ఎసిడిటీ') ||
        sympText.contains('पेट')) {
      return ProductionDatabase.medicines
          .where((m) => m.id == 'MED-08' || m.id == 'MED-04') // Pantoprazole 40mg, ORS Electral
          .toList();
    }

    // Safety Rule 4: Cold / Cough / Sore Throat
    if (sympText.contains('cough') ||
        sympText.contains('cold') ||
        sympText.contains('throat') ||
        sympText.contains('sore throat') ||
        sympText.contains('గొంతు') ||
        sympText.contains('దగ్గు') ||
        sympText.contains('खांसी')) {
      return ProductionDatabase.medicines
          .where((m) => m.id == 'MED-02' || m.id == 'MED-03') // Cetirizine 10mg, Cough Lozenges
          .toList();
    }

    // Safety Rule 5: Headache / Migraine
    if (sympText.contains('headache') ||
        sympText.contains('migraine') ||
        sympText.contains('తలనొప్పి') ||
        sympText.contains('सिरदर्द')) {
      return ProductionDatabase.medicines
          .where((m) => m.id == 'MED-01') // Paracetamol 650mg only
          .toList();
    }

    // Safety Rule 6: Joint / Knee / Ortho Pain
    if (sympText.contains('knee') ||
        sympText.contains('joint') ||
        sympText.contains('back pain') ||
        sympText.contains('ortho') ||
        sympText.contains('మోకాలు') ||
        sympText.contains('కీళ్ళ') ||
        sympText.contains('घुटनों')) {
      return ProductionDatabase.medicines
          .where((m) => m.id == 'MED-06' || m.id == 'MED-01') // Volini Pain Relief Spray, Paracetamol
          .toList();
    }

    // Safety Rule 7: Fever & Viral Infection
    if (sympText.contains('fever') ||
        sympText.contains('chills') ||
        sympText.contains('viral') ||
        sympText.contains('temperature') ||
        sympText.contains('జ్వరం') ||
        sympText.contains('బుఖార్') ||
        sympText.contains('बुखार')) {
      return ProductionDatabase.medicines
          .where((m) => m.id == 'MED-01' || m.id == 'MED-04') // Paracetamol 650mg, ORS Electral
          .toList();
    }

    // For any unspecified inquiry: Return EMPTY list
    return [];
  }

  List<DoctorModel> _getDoctorsForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    final isGreeting = query.trim().toLowerCase() == 'hi' ||
        query.trim().toLowerCase() == 'hello' ||
        query.trim().toLowerCase() == 'hey' ||
        query.trim().toLowerCase() == 'నమస్తే' ||
        query.trim().toLowerCase() == 'నమస్కారం' ||
        query.trim().toLowerCase() == 'नमस्ते';

    if (symptoms.isEmpty && isGreeting) {
      return [];
    }

    // 1. Cardiac / Heart / Chest Pain / Emergency
    if (sympText.contains('cardio') ||
        sympText.contains('chest') ||
        sympText.contains('heart') ||
        sympText.contains('bp') ||
        sympText.contains('రక్తపోటు') ||
        sympText.contains('గుండె')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-01', orElse: () => ProductionDatabase.doctors[0]), // Cardiologist
      ];
    }

    // 2. Headache / Migraine / Neurological
    if (sympText.contains('headache') ||
        sympText.contains('migraine') ||
        sympText.contains('neuro') ||
        sympText.contains('తలనొప్పి') ||
        sympText.contains('सिरदर्द')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-02', orElse: () => ProductionDatabase.doctors[1]), // Neurologist
      ];
    }

    // 3. Orthopedic / Joint / Knee / Spine
    if (sympText.contains('knee') ||
        sympText.contains('joint') ||
        sympText.contains('back') ||
        sympText.contains('ortho') ||
        sympText.contains('మోకాలు') ||
        sympText.contains('కీళ్ళ') ||
        sympText.contains('घुटनों')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-03', orElse: () => ProductionDatabase.doctors[2]), // Orthopedic Surgeon
      ];
    }

    // 4. Throat / Ear / Sinus / Cold / ENT
    if (sympText.contains('throat') ||
        sympText.contains('ear') ||
        sympText.contains('sinus') ||
        sympText.contains('ent') ||
        sympText.contains('గొంతు')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-09', orElse: () => ProductionDatabase.doctors[8]), // ENT Specialist
      ];
    }

    // 5. Child / Pediatric
    if (sympText.contains('child') ||
        sympText.contains('baby') ||
        sympText.contains('kid') ||
        sympText.contains('pediatric') ||
        sympText.contains('పిల్లలు')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-10', orElse: () => ProductionDatabase.doctors[9]), // Pediatrician
      ];
    }

    // 6. Women / Pregnancy / Gynec
    if (sympText.contains('pregnancy') ||
        sympText.contains('period') ||
        sympText.contains('gynec') ||
        sympText.contains('మహిళ') ||
        sympText.contains('గర్భం')) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-04', orElse: () => ProductionDatabase.doctors[3]), // Gynecologist
      ];
    }

    // 7. Fever / General Illness / Stomach
    if (sympText.contains('fever') ||
        sympText.contains('stomach') ||
        sympText.contains('doctor') ||
        symptoms.isNotEmpty) {
      return [
        ProductionDatabase.doctors.firstWhere((d) => d.id == 'DOC-05', orElse: () => ProductionDatabase.doctors[4]), // Dr. Prashant Reddy, General Physician
      ];
    }

    return [];
  }

  List<HospitalModel> _getHospitalsForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    if (symptoms.isEmpty && !sympText.contains('hospital') && !sympText.contains('emergency') && !sympText.contains('ఆసుపత్రి')) {
      return [];
    }

    if (sympText.contains('cardio') || sympText.contains('heart') || sympText.contains('chest') || sympText.contains('emergency')) {
      return ProductionDatabase.hospitals
          .where((h) => h.departments.any((d) => d.toLowerCase().contains('cardio') || d.toLowerCase().contains('emergency')))
          .take(2)
          .toList();
    }

    final sorted = List<HospitalModel>.from(ProductionDatabase.hospitals)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return sorted.take(2).toList();
  }

  List<LabTestModel> _getLabTestsForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    if (symptoms.isEmpty && !sympText.contains('test') && !sympText.contains('checkup')) {
      return [];
    }

    // 1. Fever & Viral Infection -> CBC, Dengue NS1
    if (sympText.contains('fever') || sympText.contains('chills') || sympText.contains('viral') || sympText.contains('జ్వరం')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'CBC' || t.code == 'NS1-ANTIGEN').toList();
    }

    // 2. Cardiac / Chest Pain -> ECG / Lipid Panel
    if (sympText.contains('cardio') || sympText.contains('heart') || sympText.contains('chest') || sympText.contains('bp')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'LIPID-PANEL' || t.code == 'CBC').toList();
    }

    // 3. Diabetes -> HbA1c
    if (sympText.contains('sugar') || sympText.contains('diabetes') || sympText.contains('షుగర్')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'HBA1C-GLUCOSE').toList();
    }

    // 4. Stomach / Acidity / Liver
    if (sympText.contains('stomach') || sympText.contains('acidity') || sympText.contains('liver') || sympText.contains('vomit')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'LFT-KFT').toList();
    }

    // 5. Explicit checkup request
    if (sympText.contains('full body') || sympText.contains('master checkup') || sympText.contains('test')) {
      return ProductionDatabase.labTests.where((t) => t.code == 'FULL-BODY-84').toList();
    }

    return [];
  }

  List<BusinessProductModel> _getProductsForContext(String category, List<String> symptoms, String query) {
    final sympText = '${symptoms.join(' ')} $category $query'.toLowerCase();

    if (symptoms.isEmpty && !sympText.contains('kit') && !sympText.contains('monitor')) {
      return [];
    }

    if (sympText.contains('sugar') || sympText.contains('diabetes') || sympText.contains('షుగర్')) {
      return [ProductionDatabase.businessProducts[0], ProductionDatabase.businessProducts[1]];
    }

    if (sympText.contains('cardio') || sympText.contains('heart') || sympText.contains('bp')) {
      return [ProductionDatabase.businessProducts[2]]; // Digital BP Monitor
    }

    return [];
  }

  List<DynamicActionCard> _generateDynamicCards(String category, String query) {
    final lower = query.toLowerCase();
    List<DynamicActionCard> cards = [];

    if (category.contains('Emergency') || lower.contains('chest') || lower.contains('breath') || lower.contains('unconscious') || lower.contains('గుండె నొప్పి')) {
      cards.add(DynamicActionCard(
        title: _selectedLanguage == 'te' ? 'అంబులెన్స్ (108) పంపించండి' : (_selectedLanguage == 'hi' ? '108 एम्बुलेंस बुलाएं' : 'Dispatch 108 Ambulance'),
        subtitle: _selectedLanguage == 'te' ? '6 నిమిషాల్లో చేరుకుంటుంది' : (_selectedLanguage == 'hi' ? '6 मिनट में आपातकालीन सहायता' : 'GPS emergency dispatch in 6 mins'),
        type: 'emergency',
        icon: Icons.emergency_rounded,
        color: const Color(0xFFEF4444),
      ));
    }
    return cards;
  }
}
