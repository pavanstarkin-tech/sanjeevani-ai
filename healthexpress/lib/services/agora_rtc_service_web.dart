import 'dart:convert';
import 'dart:js_interop';
import '../core/config/app_config.dart';

@JS('agoraJoinCall')
external JSPromise<JSString> _jsAgoraJoinCall(JSString appId, JSString channel, JSString token, JSBoolean isVideo);

@JS('agoraToggleMuteAudio')
external void _jsAgoraToggleMuteAudio(JSBoolean isMuted);

@JS('agoraToggleMuteVideo')
external void _jsAgoraToggleMuteVideo(JSBoolean isMuted);

@JS('agoraLeaveCall')
external JSPromise<JSString> _jsAgoraLeaveCall();

@JS('getTeleconsultationLiveVolume')
external JSNumber _jsGetTeleconsultationLiveVolume();

class AgoraRtcService {
  static bool _isConnected = false;
  static bool get isConnected => _isConnected;

  /// Returns real-time audio input volume (0.0 to 1.0) from user's live microphone
  static double getLiveAudioVolume() {
    try {
      final numVal = _jsGetTeleconsultationLiveVolume().toDartDouble;
      return numVal.clamp(0.0, 1.0);
    } catch (_) {
      return 0.0;
    }
  }

  /// Connect to live Agora WebRTC channel
  static Future<Map<String, dynamic>> joinCall({
    required String channelName,
    bool isVideo = true,
  }) async {
    try {
      final appId = AppConfig.agoraAppId.toJS;
      final ch = channelName.toJS;
      final token = ''.toJS; // Using App ID mode for real-time testing/demo
      final videoBool = isVideo.toJS;

      final promise = _jsAgoraJoinCall(appId, ch, token, videoBool);
      final jsResult = await promise.toDart;
      final resStr = jsResult.toDart;
      final data = jsonDecode(resStr) as Map<String, dynamic>;

      _isConnected = data['success'] == true;
      return data;
    } catch (e) {
      _isConnected = false;
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Toggle Audio Mute
  static void toggleAudioMute(bool isMuted) {
    try {
      _jsAgoraToggleMuteAudio(isMuted.toJS);
    } catch (e) {
      // Ignored if not running in web browser
    }
  }

  /// Toggle Video Track (Camera Off/On)
  static void toggleVideoMute(bool isVideoOff) {
    try {
      _jsAgoraToggleMuteVideo(isVideoOff.toJS);
    } catch (e) {
      // Ignored if not running in web browser
    }
  }

  /// Leave call and release camera / mic hardware tracks
  static Future<void> leaveCall() async {
    try {
      final promise = _jsAgoraLeaveCall();
      await promise.toDart;
      _isConnected = false;
    } catch (e) {
      _isConnected = false;
    }
  }
}
