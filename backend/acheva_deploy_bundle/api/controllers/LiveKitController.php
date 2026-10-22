<?php
/**
 * HealthExpress AI - LiveKit Real-Time Voice Token Controller
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../helpers/Response.php';

class LiveKitController {
    public static function getToken(): void {
        $apiKey = getenv('LIVEKIT_API_KEY') ?: 'API5veVBN62icXT';
        $apiSecret = getenv('LIVEKIT_API_SECRET') ?: '0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA';
        $livekitUrl = getenv('LIVEKIT_URL') ?: 'wss://luca-vsv9whhr.livekit.cloud';

        $roomName = $_GET['room'] ?? ('healthexpress-room-' . time());
        $identity = $_GET['identity'] ?? ('patient-' . rand(1000, 9999));

        $now = time();
        $exp = $now + 3600; // 1 hour validity

        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $payload = json_encode([
            'iss'   => $apiKey,
            'sub'   => $identity,
            'nbf'   => $now,
            'exp'   => $exp,
            'video' => [
                'room'         => $roomName,
                'roomJoin'     => true,
                'canPublish'   => true,
                'canSubscribe' => true
            ]
        ]);

        $base64UrlHeader = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64UrlPayload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));

        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $apiSecret, true);
        $base64UrlSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;

        Response::json([
            'success' => true,
            'token'   => $jwt,
            'room'    => $roomName,
            'url'     => $livekitUrl
        ], 200, 'LiveKit real-time voice access token generated');
    }
}
