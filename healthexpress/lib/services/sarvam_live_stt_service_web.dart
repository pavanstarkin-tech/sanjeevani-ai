import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import 'api_service.dart';

@JS('startSarvamLiveRecording')
external JSPromise<JSString> _jsStartSarvamLiveRecording(JSString lang);

@JS('stopSarvamLiveRecording')
external JSPromise<JSString> _jsStopSarvamLiveRecording(JSString apiKey, JSString lang);

@JS('healthExpressSpeech.speakText')
external void _jsSpeakText(JSString text, JSString lang, JSString apiKey);

@JS('healthExpressSpeech.stopSpeaking')
external void _jsStopSpeaking();

@JS('healthExpressSpeech.getLiveInterim')
external JSString _jsGetLiveInterim();

@JS('healthExpressSpeech.isSpeakingNow')
external JSBoolean _jsIsSpeakingNow();

@JS('healthExpressSpeech.isSilenceCutoffTriggered')
external JSBoolean _jsIsSilenceCutoffTriggered();

@JS('healthExpressSpeech.isSpeechJustEnded')
external JSBoolean _jsIsSpeechJustEnded();

@JS('healthExpressLiveKit.startVoiceSession')
external JSPromise<JSString> _jsStartLiveKitVoiceSession(JSString optionsJson);

@JS('healthExpressLiveKit.stopVoiceSession')
external JSPromise<JSString> _jsStopLiveKitVoiceSession();

@JS('healthExpressLiveKit.getLiveKitStatus')
external JSString _jsGetLiveKitStatus();

@JS('healthExpressLiveKit.setMicrophoneEnabled')
external JSPromise<JSBoolean> _jsSetLiveKitMicrophone(JSBoolean enabled);

@JS('healthExpressLiveKit.setSpeakerEnabled')
external JSBoolean _jsSetLiveKitSpeaker(JSBoolean enabled);

@JS('healthExpressLiveKit.sendData')
external JSBoolean _jsSendLiveKitData(JSString data);

class SarvamLiveSttService {
  static bool _isRecording = false;
  static bool _isLiveKitActive = false;
  static bool get isRecording => _isRecording;
  static bool get isSpeaking => _jsIsSpeakingNow().toDart;
  static bool get isLiveKitActive => _isLiveKitActive;

  /// Check if speech pause/silence VAD has triggered an instant auto-cut
  static bool isSilenceCutoffTriggered() {
    try {
      return _jsIsSilenceCutoffTriggered().toDart;
    } catch (_) {
      return false;
    }
  }

  /// Check if AI TTS audio playback has just finished
  static bool isSpeechJustEnded() {
    try {
      return _jsIsSpeechJustEnded().toDart;
    } catch (_) {
      return false;
    }
  }

  /// Get real-time LiveKit Agent status (isConnected, isAgentSpeaking, isUserSpeaking, lastMessage)
  static Map<String, dynamic> getLiveKitStatus() {
    try {
      final jsonStr = _jsGetLiveKitStatus().toDart;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {'isConnected': false, 'isAgentSpeaking': false, 'isUserSpeaking': false};
    }
  }

  /// Mute or un-mute microphone in LiveKit room
  static Future<void> setLiveKitMicrophone(bool enabled) async {
    try {
      await _jsSetLiveKitMicrophone(enabled.toJS).toDart;
    } catch (_) {}
  }

  /// Mute or un-mute audio speaker output in LiveKit room
  static void setLiveKitSpeaker(bool enabled) {
    try {
      _jsSetLiveKitSpeaker(enabled.toJS);
    } catch (_) {}
  }

  /// Send clinical context or vision diagnostic data to LiveKit room
  static void sendLiveKitData(String data) {
    try {
      _jsSendLiveKitData(data.toJS);
    } catch (_) {}
  }

  /// Plays pre-built welcome audio (falls back to TTS on web)
  static Future<bool> playPrebuiltWelcomeAudio(String lang) async {
    return false;
  }

  /// Start Full-Duplex Real-Time LiveKit Voice Session
  static Future<bool> startLiveKitVoiceSession({
    String? roomName,
    String? participantName,
    String? language,
    String? patientName,
  }) async {
    try {
      final actualRoom = roomName ?? 'healthexpress-room-${DateTime.now().millisecondsSinceEpoch}';
      final actualPart = participantName ?? 'patient-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      // Fetch server-signed LiveKit JWT directly from Hostinger PHP Backend
      String? serverToken;
      try {
        final tokenRes = await ApiService.fetchLiveKitToken(
          room: actualRoom,
          identity: actualPart,
          name: patientName,
        );
        if (tokenRes != null && tokenRes['token'] != null) {
          serverToken = tokenRes['token'].toString();
        }
      } catch (_) {}

      final optsMap = <String, dynamic>{
        'url': 'wss://luca-vsv9whhr.livekit.cloud',
        'apiKey': 'API5veVBN62icXT',
        'apiSecret': '0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA',
        'roomName': actualRoom,
        'participantName': actualPart,
        'language': language ?? 'en',
        'patientName': patientName ?? 'Patient',
      };
      if (serverToken != null && serverToken.isNotEmpty) {
        optsMap['token'] = serverToken;
      }

      final opts = jsonEncode(optsMap);
      final promise = _jsStartLiveKitVoiceSession(opts.toJS);
      final jsResult = await promise.toDart;
      final jsonStr = jsResult.toDart;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _isLiveKitActive = data['success'] == true;
      return _isLiveKitActive;
    } catch (e) {
      debugPrint('Error starting LiveKit voice session: $e');
      _isLiveKitActive = false;
      return false;
    }
  }

  /// Stop LiveKit WebRTC Voice Session
  static Future<bool> stopLiveKitVoiceSession() async {
    try {
      final promise = _jsStopLiveKitVoiceSession();
      final jsResult = await promise.toDart;
      final jsonStr = jsResult.toDart;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _isLiveKitActive = false;
      return data['success'] == true;
    } catch (e) {
      debugPrint('Error stopping LiveKit voice session: $e');
      _isLiveKitActive = false;
      return false;
    }
  }

  /// Start real-time microphone capture for Sarvam STT
  static Future<bool> startListening(String langCode) async {
    try {
      final formattedLang = _formatLanguageCode(langCode);
      final promise = _jsStartSarvamLiveRecording(formattedLang.toJS);
      final jsResult = await promise.toDart;
      final jsonStr = jsResult.toDart;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _isRecording = data['success'] == true;
      return _isRecording;
    } catch (e) {
      debugPrint('Error starting Sarvam live recording: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Stop recording, encode WAV, and query Sarvam Live STT API (saaras:v4)
  static Future<String?> stopAndTranscribe(String langCode) async {
    try {
      final formattedLang = _formatLanguageCode(langCode);
      final combinedKeys = AppConfig.sarvamApiKeys.join(',');
      final promise = _jsStopSarvamLiveRecording(
        combinedKeys.toJS,
        formattedLang.toJS,
      );
      final jsResult = await promise.toDart;
      final jsonStr = jsResult.toDart;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _isRecording = false;

      if (data['success'] == true) {
        final transcript = (data['transcript'] as String?)?.trim() ?? '';
        return transcript;
      } else {
        debugPrint('Sarvam STT note: ${data['error']}');
        return null;
      }
    } catch (e) {
      debugPrint('Error stopping and transcribing Sarvam: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Speak out medical response aloud using real Indian voice synthesis (Telugu/Hindi/English) through device speaker
  static void speakText(String text, String langCode) {
    try {
      final formatted = _formatLanguageCode(langCode);
      final combinedKeys = AppConfig.sarvamApiKeys.join(',');
      _jsSpeakText(text.toJS, formatted.toJS, combinedKeys.toJS);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  /// Stop ongoing voice speech synthesis
  static void stopSpeaking() {
    try {
      _jsStopSpeaking();
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Check whether TTS audio is actively speaking right now
  static bool isSpeakingNow() {
    try {
      return _jsIsSpeakingNow().toDart;
    } catch (_) {
      return false;
    }
  }

  /// Get live interim transcription subtitle string while user is speaking
  static String getLiveInterim() {
    try {
      return _jsGetLiveInterim().toDart;
    } catch (_) {
      return '';
    }
  }

  static String _formatLanguageCode(String lang) {
    switch (lang.toLowerCase()) {
      case 'te':
      case 'telugu':
        return 'te-IN';
      case 'hi':
      case 'hindi':
        return 'hi-IN';
      case 'ta':
      case 'tamil':
        return 'ta-IN';
      case 'kn':
      case 'kannada':
        return 'kn-IN';
      case 'ml':
      case 'malayalam':
        return 'ml-IN';
      case 'bn':
      case 'bengali':
        return 'bn-IN';
      case 'mr':
      case 'marathi':
        return 'mr-IN';
      case 'gu':
      case 'gujarati':
        return 'gu-IN';
      case 'pa':
      case 'punjabi':
        return 'pa-IN';
      case 'or':
      case 'od':
      case 'odia':
        return 'od-IN';
      case 'en':
      case 'english':
      default:
        return 'en-IN';
    }
  }
}
