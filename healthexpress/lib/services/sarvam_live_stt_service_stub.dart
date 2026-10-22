import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/config/app_config.dart';
import 'nvidia_ai_service.dart';

/// Native Mobile & Desktop implementation of Live Voice STT & TTS.
/// Provides a continuous, hands-free conversational turn cycle:
/// 1. Auto-detects spoken language (Telugu, Hindi, English, Tamil, etc.) in real time.
/// 2. Listens for speech and auto-processes upon natural pause or 5 seconds.
/// 3. Responds with real Sarvam AI bulbul:v3 studio voice in detected language.
/// 4. Once response is done, automatically opens microphone again in an infinite loop.
class SarvamLiveSttService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _tts = FlutterTts();
  static final stt.SpeechToText _speech = stt.SpeechToText();

  static bool _isTtsInitialized = false;
  static bool _isSttInitialized = false;
  static bool _isRecording = false;
  static bool _isSpeaking = false;
  static bool _isLiveKitActive = false;
  static bool _silenceCutoff = false;
  static bool _speechEnded = false;
  static bool _isProcessingAi = false;
  static bool _isStartingListening = false;
  static int _currentTurn = 1;

  static String _sessionLanguage = 'en';
  static String _patientName = 'Patient';
  static String _lastMessage = '';

  static String _liveInterim = '';
  static String _finalTranscript = '';
  static DateTime? _listenStartTime;
  static DateTime? _lastSpeechTime;
  static DateTime? _cooldownUntil;
  static Timer? _sessionLoopTimer;
  static Timer? _vadSilenceTimer;
  static Timer? _rearmTimer;
  static Timer? _ttsSafetyTimer;

  static List<stt.LocaleName>? _cachedLocales;
  static StreamSubscription<void>? _playerCompleteSub;

  static bool get isRecording => _speech.isListening || _isRecording;
  static bool get isSpeaking => _isSpeaking;
  static bool get isLiveKitActive => _isLiveKitActive;
  static int get currentTurn => _currentTurn;

  static bool isSilenceCutoffTriggered() => _silenceCutoff;
  static bool isSpeechJustEnded() => _speechEnded;

  /// Permanent AudioPlayer state subscription so speaking unlocks immediately upon audio finish
  static void _ensureAudioPlayer() {
    if (_playerCompleteSub != null) return;

    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      _handleAudioFinished();
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _handleAudioFinished();
      }
    });
  }

  static void _handleAudioFinished() {
    if (!_isSpeaking) return;
    debugPrint('[SarvamLiveSttService] >>> Audio playback complete. Releasing speaking lock.');
    _isSpeaking = false;
    _speechEnded = true;
    _ttsSafetyTimer?.cancel();
    _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 300));

    try {
      _audioPlayer.stop();
    } catch (_) {}

    // Clean acoustic silence of 300ms before activating microphone so mic opens immediately
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi) {
        _liveInterim = '';
        _finalTranscript = '';
        _lastSpeechTime = null;
        debugPrint('[SarvamLiveSttService] >>> Opening microphone for caller turn...');
        startListening(_sessionLanguage);
      }
    });
  }

  static Future<void> _ensureTts() async {
    if (_isTtsInitialized) return;
    try {
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
        _speechEnded = false;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _speechEnded = true;
        _ttsSafetyTimer?.cancel();
        _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 500));
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi) {
            _liveInterim = '';
            _finalTranscript = '';
            _lastSpeechTime = null;
            startListening(_sessionLanguage);
          }
        });
      });

      _tts.setErrorHandler((_) {
        _isSpeaking = false;
        _speechEnded = true;
        _ttsSafetyTimer?.cancel();
        _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 500));
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi) {
            _liveInterim = '';
            _finalTranscript = '';
            _lastSpeechTime = null;
            startListening(_sessionLanguage);
          }
        });
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('[SarvamLiveSttService] TTS init notice: $e');
    }
  }

  static Future<void> _ensureStt() async {
    if (_isSttInitialized) return;
    try {
      _isSttInitialized = await _speech.initialize(
        onError: (err) {
          debugPrint('[SarvamLiveSttService] STT error: ${err.errorMsg} (permanent: ${err.permanent})');
          _isRecording = false;
          _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 300));
          if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi) {
            _rearmTimer?.cancel();
            _rearmTimer = Timer(const Duration(milliseconds: 500), () {
              if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi && !_speech.isListening) {
                startListening(_sessionLanguage);
              }
            });
          }
        },
        onStatus: (status) {
          debugPrint('[SarvamLiveSttService] STT status: $status');
          if (status == 'notListening' || status == 'done') {
            _isRecording = false;
            final pending = (_finalTranscript.isNotEmpty ? _finalTranscript : _liveInterim).trim();
            if (pending.length >= 2 && !_isProcessingAi && !_isSpeaking && _isLiveKitActive) {
              _vadSilenceTimer?.cancel();
              _triggerVADAutoCut();
            } else if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi) {
              // Seamless continuous listening on Android: auto-rearm microphone after 400ms
              _rearmTimer?.cancel();
              _rearmTimer = Timer(const Duration(milliseconds: 400), () {
                if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi && !_speech.isListening) {
                  startListening(_sessionLanguage);
                }
              });
            }
          } else if (status == 'listening') {
            _isRecording = true;
          }
        },
      );
      if (_isSttInitialized) {
        try {
          _cachedLocales = await _speech.locales();
          debugPrint('[SarvamLiveSttService] Loaded ${_cachedLocales?.length ?? 0} STT locales');
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[SarvamLiveSttService] STT init error: $e');
    }
  }

  static String _formatLocale(String lang) {
    switch (lang.toLowerCase().trim()) {
      case 'te':
        return 'te-IN';
      case 'hi':
        return 'hi-IN';
      case 'ta':
        return 'ta-IN';
      case 'kn':
        return 'kn-IN';
      case 'ml':
        return 'ml-IN';
      case 'bn':
        return 'bn-IN';
      case 'mr':
        return 'mr-IN';
      case 'gu':
        return 'gu-IN';
      case 'pa':
        return 'pa-IN';
      case 'or':
      case 'od':
        return 'or-IN';
      default:
        return 'en-IN';
    }
  }

  static String _resolveBestLocale(String lang) {
    final target = _formatLocale(lang);
    final targetNorm = target.toLowerCase().replaceAll('_', '-');

    if (_cachedLocales != null && _cachedLocales!.isNotEmpty) {
      // 1. Exact match e.g. 'te-IN' or 'te_IN'
      for (final loc in _cachedLocales!) {
        final id = loc.localeId.toLowerCase().replaceAll('_', '-');
        if (id == targetNorm) return loc.localeId;
      }
      // 2. Language prefix match e.g. 'te'
      final prefix = lang.toLowerCase().trim();
      for (final loc in _cachedLocales!) {
        final id = loc.localeId.toLowerCase().replaceAll('_', '-');
        if (id.startsWith('$prefix-') || id == prefix) return loc.localeId;
      }
    }
    // NEVER fall back to en-IN if user requested an Indic language! Pass target directly to Android online recognizer
    return target;
  }

  static String _formatTtsLocale(String lang) {
    switch (lang.toLowerCase()) {
      case 'te':
        return 'te-IN';
      case 'hi':
        return 'hi-IN';
      case 'ta':
        return 'ta-IN';
      case 'kn':
        return 'kn-IN';
      case 'ml':
        return 'ml-IN';
      case 'bn':
        return 'bn-IN';
      case 'mr':
        return 'mr-IN';
      case 'gu':
        return 'gu-IN';
      case 'pa':
        return 'pa-IN';
      case 'or':
      case 'od':
        return 'od-IN';
      default:
        return 'en-IN';
    }
  }

  /// Official Sarvam bulbul:v3 female clinical doctor voice per language
  static String _getSarvamSpeaker(String targetLang) {
    switch (targetLang) {
      case 'te-IN':
        return 'kavitha';
      case 'hi-IN':
        return 'kavya';
      case 'ta-IN':
        return 'shruti';
      case 'kn-IN':
        return 'roopa';
      case 'ml-IN':
        return 'suhani';
      case 'bn-IN':
        return 'shreya';
      case 'mr-IN':
        return 'rupali';
      case 'gu-IN':
        return 'pooja';
      case 'pa-IN':
        return 'simran';
      case 'od-IN':
      case 'or-IN':
        return 'shreya';
      default:
        return 'priya';
    }
  }

  /// Detect the script of Sarvam's generated response to select the matching bulbul:v3 studio voice
  static String detectVoiceLocaleFromText(String text) {
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(text)) return 'te-IN'; // Telugu
    if (RegExp(r'[\u0900-\u097F]').hasMatch(text)) return 'hi-IN'; // Hindi / Marathi
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(text)) return 'ta-IN'; // Tamil
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(text)) return 'kn-IN'; // Kannada
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(text)) return 'ml-IN'; // Malayalam
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(text)) return 'bn-IN'; // Bengali
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(text)) return 'gu-IN'; // Gujarati
    if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(text)) return 'pa-IN'; // Punjabi
    if (RegExp(r'[\u0B00-\u0B7F]').hasMatch(text)) return 'od-IN'; // Odia
    return 'en-IN'; // English / Latin script
  }

  /// Helper for script identification; STT turn-taking loop leaves language understanding directly to Sarvam AI
  static String detectLanguage(String text, [String currentLang = 'en']) {
    final t = text.trim();
    if (t.isEmpty) return currentLang;
    if (RegExp(r'[\u0C00-\u0C7F]').hasMatch(t)) return 'te';
    if (RegExp(r'[\u0900-\u097F]').hasMatch(t)) return 'hi';
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(t)) return 'ta';
    if (RegExp(r'[\u0C80-\u0CFF]').hasMatch(t)) return 'kn';
    if (RegExp(r'[\u0D00-\u0D7F]').hasMatch(t)) return 'ml';
    if (RegExp(r'[\u0980-\u09FF]').hasMatch(t)) return 'bn';
    if (RegExp(r'[\u0A80-\u0AFF]').hasMatch(t)) return 'gu';
    if (RegExp(r'[\u0A00-\u0A7F]').hasMatch(t)) return 'pa';
    if (RegExp(r'[\u0B00-\u0B7F]').hasMatch(t)) return 'or';

    final lower = t.toLowerCase();
    if (lower.contains('naku') || lower.contains('jwaram') || lower.contains('mandulu') || lower.contains('undhi')) return 'te';
    if (lower.contains('mujhe') || lower.contains('bukhar') || lower.contains('dawa') || lower.contains('dard')) return 'hi';

    return 'en';
  }

  /// Fetch true Sarvam AI bulbul:v3 neural studio voice audio from server
  static Future<Uint8List?> _fetchSarvamTtsAudio(String text, String langCode) async {
    final clean = text
        .replaceAll(RegExp(r'\*\*|__|~~|`|#'), '')
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
        .replaceAll(RegExp(r'<reasoning>[\s\S]*?</reasoning>'), '')
        .replaceAll(RegExp(r'<system>[\s\S]*?</system>'), '')
        .replaceAll(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}\u{1F900}-\u{1F9FF}]', unicode: true),
          '',
        )
        .trim();

    if (clean.isEmpty) return null;

    final targetLang = _formatTtsLocale(langCode);
    final speaker = _getSarvamSpeaker(targetLang);

    for (final key in AppConfig.sarvamApiKeys) {
      try {
        final response = await http
            .post(
              Uri.parse('https://api.sarvam.ai/text-to-speech'),
              headers: {
                'api-subscription-key': key,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'inputs': [clean.length > 500 ? clean.substring(0, 500) : clean],
                'target_language_code': targetLang,
                'speaker': speaker,
                'pitch': 0,
                'pace': 1.05,
                'loudness': 1.5,
                'speech_sample_rate': 22050,
                'enable_preprocessing': true,
                'model': 'bulbul:v3',
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final audios = data['audios'] as List<dynamic>?;
          if (audios != null && audios.isNotEmpty && audios[0] is String) {
            return base64Decode(audios[0] as String);
          }
        }
      } catch (e) {
        debugPrint('[SarvamLiveSttService] Sarvam TTS notice: $e');
      }
    }
    return null;
  }

  static Map<String, dynamic> getLiveKitStatus() {
    final listening = _speech.isListening || _isRecording;
    final userSpeaking = listening && _liveInterim.trim().isNotEmpty;

    String displayMsg = _lastMessage;
    if (_isProcessingAi) {
      displayMsg = _sessionLanguage == 'te'
          ? 'విశ్లేషిస్తున్నాను...'
          : (_sessionLanguage == 'hi' ? 'सोच रही हूँ...' : 'Thinking...');
    } else if (listening && !_isSpeaking) {
      displayMsg = _lastMessage.isNotEmpty
          ? _lastMessage
          : (_sessionLanguage == 'te'
              ? 'వింటున్నాను... మాట్లాడండి'
              : (_sessionLanguage == 'hi' ? 'सुन रही हूँ... बोलिए' : 'Listening... Speak naturally'));
    }

    return {
      'isConnected': _isLiveKitActive,
      'isConnecting': _isProcessingAi,
      'isAgentSpeaking': _isSpeaking,
      'isUserSpeaking': userSpeaking,
      'lastMessage': displayMsg,
      'language': _sessionLanguage,
      'turn': _currentTurn,
    };
  }

  static Future<void> setLiveKitMicrophone(bool enabled) async {
    if (!enabled) {
      if (_isRecording || _speech.isListening) {
        await _speech.stop();
        _isRecording = false;
      }
    } else {
      if (!_isSpeaking && !_isProcessingAi && _isLiveKitActive) {
        startListening(_sessionLanguage);
      }
    }
  }

  static void setLiveKitSpeaker(bool enabled) {
    if (!enabled) {
      stopSpeaking();
    }
  }

  static void sendLiveKitData(String data) {
    try {
      final map = jsonDecode(data);
      if (map is Map && map['type'] == 'language_change' && map['language'] is String) {
        setLanguage(map['language'] as String);
      }
    } catch (_) {}
  }

  /// Plays pre-built, studio-quality Sarvam AI audio stored locally in assets.
  static String getWelcomeAudioPath(String lang) {
    switch (lang.toLowerCase()) {
      case 'te':
        return 'audio/welcome_te.mp3';
      case 'hi':
        return 'audio/welcome_hi.mp3';
      case 'ta':
        return 'audio/welcome_ta.mp3';
      case 'kn':
        return 'audio/welcome_kn.mp3';
      case 'ml':
        return 'audio/welcome_ml.mp3';
      case 'bn':
        return 'audio/welcome_bn.mp3';
      case 'mr':
        return 'audio/welcome_mr.mp3';
      case 'gu':
        return 'audio/welcome_gu.mp3';
      case 'pa':
        return 'audio/welcome_pa.mp3';
      case 'or':
      case 'od':
        return 'audio/welcome_or.mp3';
      default:
        return 'audio/welcome_en.mp3';
    }
  }

  static String getInitialGreeting(String lang) {
    switch (lang.toLowerCase()) {
      case 'te':
        return 'నమస్తే! నేను డాక్టర్ శన్నీ (Dr. Shanni) ని, Sanjeevani.ai క్లినికల్ ఏఐ వైద్యుడిని. మీకు ఎలాంటి ఆరోగ్య సమస్య ఉందో చెప్పండి.';
      case 'hi':
        return 'नमस्ते! मैं Sanjeevani.ai से डॉ. शन्नी हूँ। आपको क्या तकलीफ़ है? मुझे बताइए।';
      case 'ta':
        return 'வணக்கம்! நான் டாக்டர் ஷண்முகி. உங்களுக்கு என்ன உடல்நல பிரச்சனை உள்ளது என்று சொல்லுங்கள்.';
      case 'kn':
        return 'ನಮಸ್ಕಾರ! ನಾನು ಡಾ. ಷಣ್ಮುಖಿ. ನಿಮಗೆ ಯಾವ ಆರೋಗ್ಯ ಸಮಸ್ಯೆ ಇದೆ ಎಂದು ತಿಳಿಸಿ.';
      case 'ml':
        return 'നമസ്കാരം! ഞാൻ ഡോക്ടർ ഷൺമുഖി. നിങ്ങൾക്ക് എന്ത് ആരോഗ്യ പ്രശ്നമാണ് ഉള്ളതെന്ന് പറയൂ.';
      case 'bn':
        return 'নমস্কার! আমি ডক্টর ষণ্মুখী। আপনার কি স্বাস্থ্য সমস্যা হচ্ছে আমাকে বলুন।';
      case 'mr':
        return 'नमस्कार! मी डॉक्टर षण्मुखी आहे. आपल्याला काय त्रास होत आहे ते सांगा.';
      case 'gu':
        return 'નમસ્તે! હું ડૉક્ટર શણ્મુખી છું. તમને શું તકલીફ છે તે મને કહો.';
      case 'pa':
        return 'ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ! ਮੈਂ ਡਾਕਟਰ ਸ਼ਣਮੁਖੀ ਹਾਂ। ਤੁਹਾਨੂੰ ਕੀ ਤਕਲੀਫ਼ ਹੈ, ਕਿਰਪਾ ਕਰਕੇ ਦੱਸੋ।';
      case 'or':
      case 'od':
        return 'ନମସ୍କାର! ମୁଁ ଡାକ୍ତର ଷଣ୍ମୁଖୀ। ଆପଣଙ୍କର କଣ ସ୍ୱାସ୍ଥ୍ୟ ସମସ୍ୟା ଅଛି କୁହନ୍ତୁ।';
      default:
        return 'Hello! I am Dr. Shanni from Sanjeevani.ai, your AI Clinical Doctor. Please describe what symptoms you are experiencing.';
    }
  }

  /// Dynamically switch session language across all Indic languages in real time
  static Future<void> setLanguage(String lang) async {
    _sessionLanguage = lang;
    _isSpeaking = true;
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      _isRecording = false;
    } catch (_) {}

    final greeting = getInitialGreeting(lang);
    _lastMessage = greeting;
    final playedPrebuilt = await playPrebuiltWelcomeAudio(lang);
    if (!playedPrebuilt) {
      speakText(greeting, lang);
    }
  }

  /// Plays pre-built, studio-quality Sarvam AI audio stored locally in assets.
  static Future<bool> playPrebuiltWelcomeAudio(String lang) async {
    final assetPath = getWelcomeAudioPath(lang);
    final fullAssetPath = 'assets/$assetPath';

    try {
      _ensureAudioPlayer();
      _ttsSafetyTimer?.cancel();

      _isSpeaking = true;
      _speechEnded = false;

      // Play audio as media so Android does NOT lock microphone in telephony MODE_IN_COMMUNICATION
      try {
        await _audioPlayer.setAudioContext(AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ));
      } catch (_) {}

      await _audioPlayer.setVolume(1.0);

      // Play via native AssetSource for reliable onPlayerComplete events on Android
      try {
        await _audioPlayer.play(AssetSource(assetPath));
      } catch (assetErr) {
        debugPrint('[SarvamLiveSttService] AssetSource fallback to rootBundle: $assetErr');
        final byteData = await rootBundle.load(fullAssetPath);
        final bytes = byteData.buffer.asUint8List();
        await _audioPlayer.play(BytesSource(bytes));
      }

      // Safety fallback: Welcome audios are 5.2 to 6.2 seconds; set 6.5s safety timer so speech completes promptly
      _ttsSafetyTimer = Timer(const Duration(milliseconds: 6500), () {
        if (_isSpeaking) {
          debugPrint('[SarvamLiveSttService] Welcome audio safety timeout: releasing speaking state');
          _handleAudioFinished();
        }
      });

      return true;
    } catch (e) {
      debugPrint('[SarvamLiveSttService] Prebuilt audio play failed: $e');
      _isSpeaking = false;
      return false;
    }
  }

  static Future<bool> startLiveKitVoiceSession({
    String? roomName,
    String? participantName,
    String? language,
    String? patientName,
  }) async {
    _isLiveKitActive = true;
    _currentTurn = 1;
    _sessionLanguage = language ?? 'en';
    _patientName = patientName ?? 'Patient';
    _isProcessingAi = false;
    _isRecording = false;
    _isSpeaking = true; // Lock speaking state immediately so mic cannot activate while greeting is preparing/playing
    _liveInterim = '';
    _finalTranscript = '';
    _listenStartTime = null;
    _lastSpeechTime = null;

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}

    final greeting = getInitialGreeting(_sessionLanguage);
    _lastMessage = greeting;

    _ensureAudioPlayer();

    // 1. PLAY WELCOME AUDIO IMMEDIATELY — ZERO LATENCY!
    playPrebuiltWelcomeAudio(_sessionLanguage).then((playedPrebuilt) {
      if (!playedPrebuilt) {
        speakText(greeting, _sessionLanguage);
      }
    });

    // 2. Concurrently initialize TTS and STT engines in background
    _ensureTts();
    _ensureStt();

    // 3. Continuous Conversational Turn-Taking Watchdog Loop (Runs every 250ms)
    _sessionLoopTimer?.cancel();
    _sessionLoopTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      if (!_isLiveKitActive) {
        timer.cancel();
        return;
      }

      // If doctor is speaking or AI is currently generating response, do not interrupt
      if (_isSpeaking || _isProcessingAi) {
        return;
      }

      // Respect audio cooldown between speaking and listening
      if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
        return;
      }

      final elapsedMs = _listenStartTime != null
          ? DateTime.now().difference(_listenStartTime!).inMilliseconds
          : 0;

      final currentWords = (_finalTranscript.isNotEmpty ? _finalTranscript : _liveInterim).trim();
      final bool hasWords = currentWords.length >= 3;

      // Watchdog check: If user spoke and paused or Android stopped with words:
      final bool stoppedWithWords = (!_speech.isListening && !_isRecording) && hasWords;
      final bool pausedAfterSpeech = hasWords &&
          _lastSpeechTime != null &&
          DateTime.now().difference(_lastSpeechTime!).inMilliseconds > 1500;
      final bool maxSafetyTimeout = elapsedMs >= 25000 && hasWords;

      if (pausedAfterSpeech || stoppedWithWords || maxSafetyTimeout) {
        debugPrint('[SarvamLiveSttService] Watchdog VAD triggered: paused=$pausedAfterSpeech, stopped=$stoppedWithWords, words="$currentWords"');
        _triggerVADAutoCut();
        return;
      }

      // If speech recognizer stopped while idle, auto-rearm smoothly with debounce (1500ms)
      if (!_speech.isListening && !_isRecording && !_isStartingListening) {
        if (_listenStartTime == null || DateTime.now().difference(_listenStartTime!).inMilliseconds > 1500) {
          debugPrint('[SarvamLiveSttService] Watchdog: SpeechRecognizer idle/stopped, rearming mic...');
          await startListening(_sessionLanguage);
          return;
        }
      }

      if (elapsedMs >= 20000 && currentWords.isEmpty) {
        _listenStartTime = DateTime.now();
      }
    });

    return true;
  }

  static Future<void> _triggerVADAutoCut() async {
    if (_isProcessingAi || _isSpeaking || !_isLiveKitActive) return;

    final words = (_finalTranscript.isNotEmpty ? _finalTranscript : _liveInterim).trim();
    if (words.length < 2) return;

    _vadSilenceTimer?.cancel();
    _isProcessingAi = true;
    _silenceCutoff = true;

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
    _isRecording = false;

    _currentTurn++;

    // Update telemetry status immediately so UI displays "Thinking..."
    _lastMessage = 'Analyzing...';

    _liveInterim = '';
    _finalTranscript = '';

    debugPrint('[SarvamLiveSttService] VAD Auto-Cut triggered on Turn $_currentTurn with words: "$words"');
    await _generateAndSpeakDoctorAdvice(words, _sessionLanguage);
  }

  /// Clean reply to concise spoken doctor advice (max 220 chars or 1-2 spoken sentences)
  /// identical to Web implementation for real-time natural dialogue!
  static String _cleanSpokenDoctorAdvice(String reply) {
    var cleaned = reply
        .replaceAll(RegExp(r'\*\*|__|~~|`|#'), '')
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
        .replaceAll(RegExp(r'<reasoning>[\s\S]*?</reasoning>'), '')
        .replaceAll(RegExp(r'<system>[\s\S]*?</system>'), '')
        .replaceAll(RegExp(r'\|[\s\S]*?\|'), '')
        .replaceAll(
          RegExp(r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}\u{1F900}-\u{1F9FF}]', unicode: true),
          '',
        )
        .trim();

    if (cleaned.length > 220) {
      final truncated = cleaned.substring(0, 220);
      final lastBoundary = truncated.lastIndexOf(RegExp(r'[.!?।\n]'));
      if (lastBoundary > 60) {
        cleaned = truncated.substring(0, lastBoundary + 1).trim();
      } else {
        cleaned = '$truncated...';
      }
    }
    return cleaned;
  }

  /// High-speed clinical voice generation powered directly by Sarvam AI LLM.
  /// Sarvam AI automatically understands any Indian language (Telugu, Hindi, English, Tamil, etc.)
  /// and responds naturally in the user's language without rigid hardcoded rules.
  static Future<void> _generateAndSpeakDoctorAdvice(String userSpeech, String lang) async {
    String doctorReply = '';

    try {
      debugPrint('[SarvamLiveSttService] Requesting Sarvam AI clinical response for: "$userSpeech" (lang: $lang)...');
      final aiRes = await NvidiaAiService.generateResponse(
        userQuery: userSpeech,
        lang: lang,
        patientName: _patientName,
        isVoiceMode: true,
      );
      doctorReply = aiRes.content;
      debugPrint('[SarvamLiveSttService] Sarvam AI response received: "$doctorReply"');
    } catch (e) {
      debugPrint('[SarvamLiveSttService] AI response error: $e');
    }

    if (doctorReply.trim().isEmpty) {
      doctorReply = 'I understand. Please tell me more about your symptoms so I can assist you.';
    }

    final spokenText = _cleanSpokenDoctorAdvice(doctorReply);
    _lastMessage = spokenText;

    // Detect the script of Sarvam's generated response to select the matching bulbul:v3 native voice
    final voiceLocale = detectVoiceLocaleFromText(spokenText);
    debugPrint('[SarvamLiveSttService] Speaking text with voice: $voiceLocale');
    speakText(spokenText, voiceLocale);
  }

  static Future<bool> stopLiveKitVoiceSession() async {
    _isLiveKitActive = false;
    _sessionLoopTimer?.cancel();
    _vadSilenceTimer?.cancel();
    _rearmTimer?.cancel();
    _ttsSafetyTimer?.cancel();
    _isProcessingAi = false;
    stopSpeaking();
    if (_isRecording || _speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
      _isRecording = false;
    }
    return true;
  }

  static Future<bool> startListening(String langCode) async {
    if (_isSpeaking || _isProcessingAi || !_isLiveKitActive || _isStartingListening) {
      debugPrint('[SarvamLiveSttService] startListening skipped: speaking=$_isSpeaking, processing=$_isProcessingAi, active=$_isLiveKitActive, starting=$_isStartingListening');
      return false;
    }
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) {
      final waitMs = _cooldownUntil!.difference(DateTime.now()).inMilliseconds;
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs.clamp(20, 500)));
      }
      if (_isSpeaking || _isProcessingAi || !_isLiveKitActive || _isStartingListening) return false;
    }
    if (_speech.isListening) {
      _isRecording = true;
      return true;
    }

    _isStartingListening = true;
    try {
      await _ensureStt();
      if (!_isSttInitialized) {
        debugPrint('[SarvamLiveSttService] STT not initialized, re-running initialization...');
        await _ensureStt();
        if (!_isSttInitialized) return false;
      }

      _liveInterim = '';
      _finalTranscript = '';
      _silenceCutoff = false;
      _lastSpeechTime = null;
      _listenStartTime = DateTime.now();

      final targetLocale = _resolveBestLocale(langCode);
      debugPrint('[SarvamLiveSttService] >>> startListening: requesting mic with targetLocale=$targetLocale');

      void handleSpeechResult(dynamic result) {
        if (_isSpeaking || _isProcessingAi || !_isLiveKitActive) return;

        final words = result.recognizedWords as String? ?? '';
        debugPrint('[SarvamLiveSttService] Speech result received: "$words" (final: ${result.finalResult})');
        if (words.trim().isNotEmpty) {
          _liveInterim = words;
          _lastSpeechTime = DateTime.now();
          if (result.finalResult) {
            _finalTranscript = words;
          }

          // Real-Time Voice Activity Detection (VAD) Auto-Cut:
          // When user pauses for 1.5s or on final speech result, trigger immediately!
          _vadSilenceTimer?.cancel();
          if (result.finalResult) {
            _triggerVADAutoCut();
          } else {
            _vadSilenceTimer = Timer(const Duration(milliseconds: 1500), () {
              _triggerVADAutoCut();
            });
          }
        }
      }

      try {
        await _speech.listen(
          onResult: handleSpeechResult,
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(milliseconds: 1800),
            localeId: targetLocale,
            cancelOnError: false,
            partialResults: true,
          ),
        );
        _isRecording = true;
        debugPrint('[SarvamLiveSttService] >>> _speech.listen initiated with $targetLocale');
        return true;
      } catch (e) {
        debugPrint('[SarvamLiveSttService] Start listening with $targetLocale notice: $e');
        try {
          await _speech.listen(
            onResult: handleSpeechResult,
            listenOptions: stt.SpeechListenOptions(
              listenMode: stt.ListenMode.confirmation,
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(milliseconds: 1800),
              cancelOnError: false,
              partialResults: true,
            ),
          );
          _isRecording = true;
          debugPrint('[SarvamLiveSttService] >>> Fallback default _speech.listen initiated');
          return true;
        } catch (fallbackErr) {
          debugPrint('[SarvamLiveSttService] Fallback speech listen error: $fallbackErr');
          _isRecording = false;
          _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 300));
          return false;
        }
      }
    } finally {
      _isStartingListening = false;
    }
  }

  static Future<String?> stopAndTranscribe(String langCode) async {
    _silenceCutoff = false;
    _vadSilenceTimer?.cancel();
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }
    _isRecording = false;

    final result = _finalTranscript.isNotEmpty ? _finalTranscript : _liveInterim;
    _liveInterim = '';
    _finalTranscript = '';
    _listenStartTime = null;
    _lastSpeechTime = null;
    return result.trim().isNotEmpty ? result.trim() : null;
  }

  /// Speaks text using REAL Sarvam AI bulbul:v3 neural voice, with offline TTS fallback
  static void speakText(String text, String langCode) async {
    if (text.trim().isEmpty) {
      _isProcessingAi = false;
      return;
    }
    _ttsSafetyTimer?.cancel();
    _isSpeaking = true;
    _isProcessingAi = false;
    _speechEnded = false;
    _ensureAudioPlayer();

    // 1. Primary: Fetch & play REAL Sarvam AI bulbul:v3 neural voice from server
    try {
      final audioBytes = await _fetchSarvamTtsAudio(text, langCode);
      if (audioBytes != null && audioBytes.isNotEmpty) {
        // Set AudioContext to media so Android does NOT lock microphone in telephony VoIP mode
        try {
          await _audioPlayer.setAudioContext(AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: false,
              contentType: AndroidContentType.speech,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
          ));
        } catch (_) {}

        // Dynamic safety timer proportional to response length (max 20 seconds)
        final wordCount = text.split(RegExp(r'\s+')).length;
        final safetySeconds = (wordCount / 2.0).ceil().clamp(5, 20);
        _ttsSafetyTimer = Timer(Duration(seconds: safetySeconds), () {
          if (_isSpeaking) {
            debugPrint('[SarvamLiveSttService] TTS safety timeout: resetting speaking state');
            _handleAudioFinished();
          }
        });

        await _audioPlayer.play(BytesSource(audioBytes));
        debugPrint('[SarvamLiveSttService] Playing REAL Sarvam bulbul:v3 neural voice');
        return;
      }
    } catch (e) {
      debugPrint('[SarvamLiveSttService] Sarvam TTS playback failed, falling back to local TTS: $e');
    }

    // 2. Offline Fallback: If network is offline or Sarvam server fails, use local system TTS
    await _fallbackSystemTts(text, langCode);
  }

  /// Fallback offline system synthesizer TTS
  static Future<void> _fallbackSystemTts(String text, String langCode) async {
    await _ensureTts();

    var clean = text;
    clean = clean.replaceAll(RegExp(r'\*\*|__|~~|`|#'), '');
    clean = clean.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    clean = clean.replaceAll(RegExp(r'<reasoning>[\s\S]*?</reasoning>'), '');
    clean = clean.replaceAll(RegExp(r'<system>[\s\S]*?</system>'), '');
    clean = clean.replaceAll(
      RegExp(r'[\u{1F300}-\u{1FAFF}\u{1F600}-\u{1F64F}\u{2600}-\u{27BF}\u{1F900}-\u{1F9FF}]', unicode: true),
      '',
    ).trim();

    try {
      _ttsSafetyTimer?.cancel();
      await _tts.stop();
      final locale = _formatTtsLocale(langCode);
      await _tts.setLanguage(locale);
      _isSpeaking = true;
      _speechEnded = false;

      final wordCount = clean.split(RegExp(r'\s+')).length;
      final safetySeconds = (wordCount / 2.5).ceil().clamp(3, 8);
      _ttsSafetyTimer = Timer(Duration(seconds: safetySeconds), () {
        if (_isSpeaking) {
          debugPrint('[SarvamLiveSttService] Safety timeout fired, resetting TTS speaking state');
          _isSpeaking = false;
          _speechEnded = true;
          _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 200));
          Future.delayed(const Duration(milliseconds: 250), () {
            if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi) {
              startListening(_sessionLanguage);
            }
          });
        }
      });

      await _tts.speak(clean);
    } catch (e) {
      debugPrint('[SarvamLiveSttService] Local TTS speak error: $e');
      _isSpeaking = false;
      _speechEnded = true;
      _ttsSafetyTimer?.cancel();
      _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 200));
    }
  }

  static void stopSpeaking() {
    _ttsSafetyTimer?.cancel();
    try {
      _audioPlayer.stop();
    } catch (_) {}
    _tts.stop();
    _isSpeaking = false;
    _speechEnded = true;
    _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 200));
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_isLiveKitActive && !_isSpeaking && !_isProcessingAi) {
        startListening(_sessionLanguage);
      }
    });
  }

  static bool isSpeakingNow() => _isSpeaking;

  static String getLiveInterim() => _liveInterim;
}
