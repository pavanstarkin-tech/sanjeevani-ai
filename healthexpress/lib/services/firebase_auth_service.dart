import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import 'google_auth_bridge.dart';

class FirebaseUserSession {
  final String uid;
  final String email;
  final String displayName;
  final String idToken;
  final String refreshToken;
  final String? photoUrl;

  FirebaseUserSession({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.idToken,
    required this.refreshToken,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'idToken': idToken,
    'refreshToken': refreshToken,
    'photoUrl': photoUrl,
  };

  factory FirebaseUserSession.fromJson(Map<String, dynamic> json) {
    return FirebaseUserSession(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      idToken: json['idToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }
}

class FirebaseAuthService {
  static const String _apiKey = AppConfig.firebaseApiKey;
  static const String _authUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';

  /// Real Sign In with Google via Firebase Auth Web Popup
  static Future<FirebaseUserSession> signInWithGoogle() async {
    try {
      final res = await GoogleAuthBridge.signInWithGoogleWeb();
      if (res['success'] == true) {
        final uid = res['uid'] as String;
        final email = res['email'] as String;
        final displayName = (res['displayName'] as String?)?.isNotEmpty == true
            ? res['displayName'] as String
            : email.split('@')[0];
        final photoUrl = res['photoURL'] as String?;
        final idToken = res['idToken'] as String? ?? '';

        return FirebaseUserSession(
          uid: uid,
          email: email,
          displayName: displayName,
          idToken: idToken,
          refreshToken: '',
          photoUrl: photoUrl,
        );
      } else {
        final msg = res['message']?.toString() ?? 'Google Sign-In failed.';
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google Sign-In error: $e');
    }
  }

  /// Real Sign In with Email & Password via Firebase Auth API
  static Future<FirebaseUserSession> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final endpoint = Uri.parse('$_authUrl:signInWithPassword?key=$_apiKey');

    try {
      final res = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'returnSecureToken': true,
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final uid = data['localId'] as String;
        final userEmail = data['email'] as String? ?? email;
        final displayName = (data['displayName'] as String?)?.isNotEmpty == true
            ? data['displayName'] as String
            : userEmail.split('@')[0];
        final idToken = data['idToken'] as String;
        final refreshToken = data['refreshToken'] as String;

        return FirebaseUserSession(
          uid: uid,
          email: userEmail,
          displayName: displayName,
          idToken: idToken,
          refreshToken: refreshToken,
        );
      } else {
        final errorMsg = _parseFirebaseError(data);
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error connecting to Firebase Auth: $e');
    }
  }

  /// Real Sign Up with Email & Password via Firebase Auth API
  static Future<FirebaseUserSession> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final endpoint = Uri.parse('$_authUrl:signUp?key=$_apiKey');

    try {
      final res = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
          'returnSecureToken': true,
        }),
      ).timeout(const Duration(seconds: 12));

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final uid = data['localId'] as String;
        final userEmail = data['email'] as String? ?? email;
        final idToken = data['idToken'] as String;
        final refreshToken = data['refreshToken'] as String;

        // Update profile with display name
        if (name.isNotEmpty) {
          try {
            await updateProfile(idToken: idToken, displayName: name.trim());
          } catch (_) {
            // Profile name update is non-fatal
          }
        }

        return FirebaseUserSession(
          uid: uid,
          email: userEmail,
          displayName: name.isNotEmpty ? name.trim() : userEmail.split('@')[0],
          idToken: idToken,
          refreshToken: refreshToken,
        );
      } else {
        final errorMsg = _parseFirebaseError(data);
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error connecting to Firebase Auth: $e');
    }
  }

  /// Update user profile in Firebase (Display Name & Photo)
  static Future<void> updateProfile({
    required String idToken,
    String? displayName,
    String? photoUrl,
  }) async {
    final endpoint = Uri.parse('$_authUrl:update?key=$_apiKey');
    await http.post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        if (displayName != null) 'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'returnSecureToken': true,
      }),
    ).timeout(const Duration(seconds: 8));
  }

  /// Send Password Reset Email via Firebase Auth
  static Future<void> sendPasswordResetEmail({required String email}) async {
    final endpoint = Uri.parse('$_authUrl:sendOobCode?key=$_apiKey');
    final res = await http.post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requestType': 'PASSWORD_RESET',
        'email': email.trim(),
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(_parseFirebaseError(data));
    }
  }

  /// Human-friendly translation of Firebase error codes
  static String _parseFirebaseError(dynamic data) {
    if (data is Map && data.containsKey('error')) {
      final err = data['error'];
      final message = err is Map ? (err['message']?.toString() ?? '') : err.toString();

      if (message.contains('EMAIL_EXISTS')) {
        return 'This email address is already registered in Firebase. Please switch to Sign In.';
      } else if (message.contains('EMAIL_NOT_FOUND')) {
        return 'No account found with this email. Please switch to Sign Up to create one.';
      } else if (message.contains('INVALID_PASSWORD') || message.contains('INVALID_LOGIN_CREDENTIALS')) {
        return 'Incorrect password. Please verify your credentials or reset your password.';
      } else if (message.contains('USER_DISABLED')) {
        return 'This user account has been disabled by an administrator.';
      } else if (message.contains('WEAK_PASSWORD')) {
        return 'The password is too weak. Please choose a password with at least 6 characters.';
      } else if (message.contains('INVALID_EMAIL')) {
        return 'The email address is formatted incorrectly.';
      } else if (message.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
        return 'Access to this account has been temporarily disabled due to many failed attempts. Try again later.';
      }
      return message;
    }
    return 'Authentication failed. Please check your credentials and network connection.';
  }
}
