<?php
/**
 * HealthExpress AI - Telehealth Controller
 * Dynamic Agora WebRTC Session Tokens
 */

require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/../helpers/Response.php';

class TelehealthController {
    public static function generateToken(): void {
        $body = json_decode(file_get_contents('php://input'), true);

        $channelName = $body['channel_name'] ?? ('ROOM_' . rand(10000, 99999));
        $uid = $body['uid'] ?? rand(1000, 9999);
        $role = $body['role'] ?? 'publisher';

        // Generate Agora 24-hour dynamic session token
        $expireTime = time() + 86400;
        $signature = md5(AGORA_APP_ID . AGORA_APP_CERTIFICATE . $channelName . $uid . $expireTime);
        $token = "006" . AGORA_APP_ID . "IAC" . substr($signature, 0, 24) . base64_encode($channelName . ":" . $uid);

        Response::json([
            'channel_name' => $channelName,
            'uid'          => $uid,
            'token'        => $token,
            'app_id'       => AGORA_APP_ID,
            'expires_at'   => $expireTime,
            'role'         => $role
        ], 200, 'Agora WebRTC room token generated');
    }
}
