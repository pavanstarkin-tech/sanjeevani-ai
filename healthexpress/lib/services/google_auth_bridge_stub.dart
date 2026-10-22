class GoogleAuthBridge {
  static Future<Map<String, dynamic>> signInWithGoogleWeb() async {
    return {
      'success': false,
      'message': 'Google Sign-In is only active in web mode.',
    };
  }
}
