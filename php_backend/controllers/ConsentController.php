<?php
/**
 * HealthExpress AI - Consent Controller
 * ABDM Temporary QR Consent Generation & Doctor Scanner
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';

class ConsentController {
    public static function generateToken(): void {
        $body = json_decode(file_get_contents('php://input'), true);
        $userId = $body['user_id'] ?? 'USR-101';

        $token = 'HEAL-PASS-' . substr(str_shuffle('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'), 0, 10);
        $expiresAt = date('Y-m-d H:i:s', strtotime('+15 minutes'));

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("INSERT INTO qr_consent_tokens (id, user_id, token, expires_at, created_at)
            VALUES (?, ?, ?, ?, NOW())");
        $stmt->execute(['QR-' . rand(10000, 99999), $userId, $token, $expiresAt]);

        Response::json([
            'consent_token' => $token,
            'user_id'       => $userId,
            'validity'      => '15 minutes',
            'expires_at'    => $expiresAt,
            'compliance'    => 'ABDM / Ayushman Bharat Digital Mission'
        ], 201, 'Temporary consent QR token created');
    }

    public static function doctorScan(): void {
        $body = json_decode(file_get_contents('php://input'), true);
        $token = $body['consent_token'] ?? '';
        $doctorId = $body['doctor_id'] ?? 'DOC-1024';

        if (empty($token)) {
            Response::error('Consent token required for clinical access', 400);
        }

        $pdo = Database::getConnection();

        // Validate token
        $stmt = $pdo->prepare("SELECT * FROM qr_consent_tokens WHERE token = ? AND is_used = 0 AND expires_at > NOW() LIMIT 1");
        $stmt->execute([$token]);
        $consent = $stmt->fetch();

        if (!$consent) {
            Response::error('Invalid or expired QR consent token', 403);
        }

        // Mark used
        $upStmt = $pdo->prepare("UPDATE qr_consent_tokens SET is_used = 1, used_by_doctor_id = ? WHERE id = ?");
        $upStmt->execute([$doctorId, $consent['id']]);

        // Fetch patient health profile & records
        $userStmt = $pdo->prepare("SELECT 
            u.id, u.name, u.phone, u.aarogyasri_id,
            hp.blood_group, hp.allergies, hp.past_surgeries, hp.current_medications
        FROM users u
        LEFT JOIN health_profiles hp ON u.id = hp.user_id
        WHERE u.id = ?");
        $userStmt->execute([$consent['user_id']]);
        $patient = $userStmt->fetch();

        // Audit Log
        $auditStmt = $pdo->prepare("INSERT INTO audit_logs (id, user_id, action, entity_type, entity_id, ip_address, created_at)
            VALUES (?, ?, 'DOCTOR_QR_CONSENT_UNLOCKED', 'patient_vault', ?, ?, NOW())");
        $auditStmt->execute(['AUD-' . rand(10000, 99999), $doctorId, $patient['id'], $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1']);

        Response::json([
            'patient'           => $patient,
            'access_granted_at' => date('Y-m-d H:i:s'),
            'audit_logged'      => true
        ], 200, 'Clinical file unlocked with verified patient consent');
    }
}
