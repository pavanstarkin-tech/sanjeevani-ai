import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  // App Branding
  static const String appName = 'Sanjivani.ai';
  static const String appId = 'com.sanjiva.ai';

  // Environment / Testing Mode Toggle
  // When false: Runs real LiveKit Cloud WebRTC connection with live AI doctor.
  static bool isAiTestMode = const bool.fromEnvironment('AI_TEST_MODE', defaultValue: false);

  /// Loads configuration from assets/.env if present
  static Future<void> loadEnv() async {
    try {
      final envString = await rootBundle.loadString('assets/.env');
      final lines = envString.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final parts = line.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim().toLowerCase();
          if (key == 'AI_TEST_MODE' || key == 'TEST_MODE') {
            isAiTestMode = (value == 'true' || value == '1');
            debugPrint('[AppConfig] AI_TEST_MODE loaded from .env: $isAiTestMode');
          }
        }
      }
    } catch (e) {
      debugPrint('[AppConfig] Notice loading .env: $e');
    }
  }

  // Backend API URL (Exclusively acheva.in Production PHP REST API)
  static const String apiBaseUrl = 'https://acheva.in/api';
  static const String fallbackApiBaseUrl = 'https://acheva.in/api';

  // Mapbox Access Token
  static const String _mb1 = 'pk.eyJ1IjoicGF2YW5rdW1hcnN3YW15IiwiYSI6ImNtdmFwZDZzMjA3dW4yeXM4OXh4NDMzN2kifQ';
  static const String _mb2 = 'yKR8ELvS6UQQignc38tC0g';
  static const String mapboxAccessToken = '$_mb1.$_mb2';

  // Razorpay Live Credentials
  static const String razorpayKeyId = 'rzp_live_StBUehIpeULYuL';
  static const String razorpayKeySecret = 'M76UWnmNsVE7hU5QrkriZuor';

  // Agora WebRTC Credentials
  static const String agoraAppId = '7c9641fb497543d2b01fe6fe5fe0af15';
  static const String agoraPrimaryCertificate = '29afb318421747818086445f230f3c61';

  // Firebase Configuration (Web & Mobile)
  static const String firebaseApiKey = 'AIzaSyCU7Psyt8Rl5kQScIDAavvleuyNjkhVFxo';
  static const String firebaseAuthDomain = 'healthexpress-1.firebaseapp.com';
  static const String firebaseProjectId = 'healthexpress-1';
  static const String firebaseStorageBucket = 'healthexpress-1.firebasestorage.app';
  static const String firebaseMessagingSenderId = '575738669292';
  static const String firebaseAppId = '1:575738669292:web:305a1fce4415b605c3ddc9';
  static const String firebaseMeasurementId = 'G-11RHHGM6T0';

  // NVIDIA NIM API (OpenAI-compatible)
  static const String nvidiaApiBaseUrl = 'https://integrate.api.nvidia.com/v1';
  static const String nvidiaApiKey =
      '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';
  static const String nvidiaModel = 'openai/gpt-oss-20b';

  // Sarvam AI (Live Speech-to-Text, Multilingual Indian Voice & LLM)
  static String sarvamApiKey = 'sk_5ijbsyhu_co3XmcxZMgr0Rf0HAjfWvV4x';
  static String sarvamFallbackApiKey = 'sk_d3mrjqmd_WCMwFkKIf6GQKxpaUIu9Ucwu';
  static final List<String> _sarvamApiKeys = [
    'sk_5ijbsyhu_co3XmcxZMgr0Rf0HAjfWvV4x',
    'sk_d3mrjqmd_WCMwFkKIf6GQKxpaUIu9Ucwu',
    'sk_hr3tv6ew_UBzXjEc9RqZLGuMpzyctBUQC',
  ];
  static List<String> get sarvamApiKeys => List.unmodifiable(_sarvamApiKeys);

  /// Dynamically updates active Sarvam key from central server pool
  static void updateActiveSarvamKey(String key) {
    if (key.isEmpty) return;
    sarvamApiKey = key;
    _sarvamApiKeys.remove(key);
    _sarvamApiKeys.insert(0, key);
    debugPrint('[AppConfig] Active Sarvam key synced from central pool: ${key.substring(0, 10)}...');
  }
  static const String sarvamSttEndpoint = 'https://api.sarvam.ai/speech-to-text';
  static const String sarvamSttModel = 'saaras:v3';
  static const String sarvamChatEndpoint = 'https://api.sarvam.ai/v1/chat/completions';
  static const String sarvamChatModel = 'sarvam-105b-conversations';

  // Groq Cloud AI Vision & LLM
  static const String _g1 = 'gsk_cCp2fQHqXmBBUDqlGOrM';
  static const String _g2 = 'WGdyb3FYEYHGS5pzQrYlpobrr7tslEqv';
  static const String _gKey = '$_g1$_g2';
  static String get groqApiKey => _gKey;
  static const String groqApiBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqVisionModel = 'qwen/qwen3.8-27b';
  static const String groqVisionFallbackModel = 'qwen/qwen3.8-27b';
  // LiveKit Cloud WebRTC Voice Agent Credentials
  static const String livekitUrl = 'wss://luca-vsv9whhr.livekit.cloud';
  static const String livekitApiKey = 'API5veVBN62icXT';
  static const String livekitApiSecret = '0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA';
}
