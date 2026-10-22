import 'dart:js_interop';
import 'dart:convert';

@JS('triggerFirebaseGoogleSignIn')
external JSPromise<JSString> triggerFirebaseGoogleSignIn();

class GoogleAuthBridge {
  static Future<Map<String, dynamic>> signInWithGoogleWeb() async {
    try {
      final jsPromise = triggerFirebaseGoogleSignIn();
      final jsStr = await jsPromise.toDart;
      final jsonStr = jsStr.toDart;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to open Google Sign-In popup: $e',
      };
    }
  }
}
