import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../core/config/app_config.dart';

/// Generates valid LiveKit Access Tokens for real-time WebRTC audio rooms.
class LiveKitTokenService {
  /// Positional convenience method matching:
  /// LiveKitTokenService.generateToken(roomName, participantIdentity, [participantName])
  static String generateToken(
    String roomName,
    String participantIdentity, [
    String? participantName,
  ]) {
    return createToken(
      roomName: roomName,
      participantIdentity: participantIdentity,
      participantName: participantName,
    );
  }

  /// Named argument method:
  /// LiveKitTokenService.createToken(roomName: ..., participantIdentity: ...)
  static String createToken({
    required String roomName,
    required String participantIdentity,
    String? participantName,
  }) {
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final jwt = JWT(
      {
        'sub': participantIdentity,
        'name': participantName ?? participantIdentity,
        'nbf': nowSeconds - 5,
        'video': {
          'roomJoin': true,
          'room': roomName,
          'canPublish': true,
          'canSubscribe': true,
          'canPublishData': true,
        },
      },
      issuer: AppConfig.livekitApiKey,
    );

    return jwt.sign(
      SecretKey(AppConfig.livekitApiSecret),
      algorithm: JWTAlgorithm.HS256,
      expiresIn: const Duration(hours: 6),
    );
  }
}
