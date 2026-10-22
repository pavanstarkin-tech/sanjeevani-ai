import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Offline Voice Interaction Service providing on-device Text-to-Speech (TTS),
/// Speech Recognition (STT), and audio visualizer amplitude levels.
class OfflineVoiceService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isTtsInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  bool _isSttAvailable = false;
  String _currentLanguage = 'en'; // 'en', 'hi', 'te'
  double _soundLevel = 0.0;
  Timer? _simulatedVoiceTimer;

  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get isSttAvailable => _isSttAvailable;
  String get currentLanguage => _currentLanguage;
  double get soundLevel => _soundLevel;

  OfflineVoiceService() {
    _initTts();
    _initStt();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.48); // Natural medical cadence
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _startVoiceWaveSimulation();
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _stopVoiceWaveSimulation();
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _stopVoiceWaveSimulation();
        notifyListeners();
      });

      await setLanguage(_currentLanguage);
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('[OfflineVoiceService] TTS init error: $e');
    }
  }

  Future<void> _initStt() async {
    try {
      _isSttAvailable = await _speechToText.initialize(
        onError: (val) {
          _isListening = false;
          _stopVoiceWaveSimulation();
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _stopVoiceWaveSimulation();
            notifyListeners();
          }
        },
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineVoiceService] STT init error: $e');
      _isSttAvailable = false;
    }
  }

  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    try {
      String ttsLang = 'en-US';
      if (langCode == 'hi') ttsLang = 'hi-IN';
      if (langCode == 'te') ttsLang = 'te-IN';
      await _flutterTts.setLanguage(ttsLang);
      notifyListeners();
    } catch (e) {
      debugPrint('[OfflineVoiceService] Set language error: $e');
    }
  }

  /// Speak clinical guidance aloud using on-device synthesis.
  Future<void> speak(String text) async {
    if (!_isTtsInitialized) await _initTts();

    // Clean markdown symbols for natural speech
    final cleanText = text
        .replaceAll(RegExp(r'#|\*|_|`|>'), '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .trim();

    if (cleanText.isEmpty) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = true;
      _startVoiceWaveSimulation();
      notifyListeners();
      await _flutterTts.speak(cleanText);
    } catch (e) {
      _isSpeaking = false;
      _stopVoiceWaveSimulation();
      notifyListeners();
    }
  }

  /// Stop active TTS speech.
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _stopVoiceWaveSimulation();
      notifyListeners();
    } catch (_) {}
  }

  /// Start on-device voice recognition.
  Future<void> startListening({
    required void Function(String words) onResult,
    required void Function(String finalWords) onFinalResult,
  }) async {
    if (!_isSttAvailable) {
      final initialized = await _speechToText.initialize();
      if (!initialized) return;
      _isSttAvailable = true;
    }

    if (_isSpeaking) {
      await stopSpeaking();
    }

    _isListening = true;
    _startVoiceWaveSimulation();
    notifyListeners();

    String localeId = 'en_US';
    if (_currentLanguage == 'hi') localeId = 'hi_IN';
    if (_currentLanguage == 'te') localeId = 'te_IN';

    try {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            _stopVoiceWaveSimulation();
            notifyListeners();
            onFinalResult(result.recognizedWords);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: localeId,
          onDevice: true,
        ),
        onSoundLevelChange: (level) {
          _soundLevel = (level / 10).clamp(0.0, 1.0);
          notifyListeners();
        },
      );
    } catch (e) {
      _isListening = false;
      _stopVoiceWaveSimulation();
      notifyListeners();
    }
  }

  /// Stop microphone listening.
  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      _stopVoiceWaveSimulation();
      notifyListeners();
    } catch (_) {}
  }

  void _startVoiceWaveSimulation() {
    _simulatedVoiceTimer?.cancel();
    _simulatedVoiceTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isSpeaking && !_isListening) {
        timer.cancel();
        _soundLevel = 0.0;
        notifyListeners();
        return;
      }
      // Pulsing wave simulation between 0.3 and 0.95
      final base = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
      _soundLevel = 0.3 + 0.6 * (0.5 * (1 + (base * 6.28).abs() % 1));
      notifyListeners();
    });
  }

  void _stopVoiceWaveSimulation() {
    _simulatedVoiceTimer?.cancel();
    _simulatedVoiceTimer = null;
    _soundLevel = 0.0;
  }

  @override
  void dispose() {
    _simulatedVoiceTimer?.cancel();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }
}
