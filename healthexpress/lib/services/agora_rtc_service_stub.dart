class AgoraRtcService {
  static bool get isConnected => false;

  static double getLiveAudioVolume() => 0.0;

  static Future<Map<String, dynamic>> joinCall({
    required String channelName,
    bool isVideo = true,
  }) async {
    return {
      'success': true,
      'channel': channelName,
      'mode': 'native_stub',
    };
  }

  static void toggleAudioMute(bool isMuted) {}

  static void toggleVideoMute(bool isVideoOff) {}

  static Future<void> leaveCall() async {}
}
