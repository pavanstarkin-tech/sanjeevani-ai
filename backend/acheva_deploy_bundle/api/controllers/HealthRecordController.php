<?php
/**
 * HealthExpress AI - Health Record Controller
 * Encrypted Medical Vault Uploads & Progressive Onboarding
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';

class HealthRecordController {
    public static function upload(): void {
        $body = json_decode(file_get_contents('php://input'), true);

        $userId = $body['user_id'] ?? 'USR-101';
        $title = $body['title'] ?? 'Diagnostic Lab Report (CBC & Lipid Profile)';
        $type = $body['record_type'] ?? 'lab_report';
        $fileUrl = $body['file_url'] ?? 'https://storage.healthexpress.ai/vault/reports/cbc_test_8821.pdf';

        $id = 'REC-' . rand(10000, 99999);
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("INSERT INTO health_records (id, user_id, record_type, title, file_url, is_abdm_linked, created_at)
            VALUES (?, ?, ?, ?, ?, 1, NOW())");
        $stmt->execute([$id, $userId, $type, $title, $fileUrl]);

        Response::json([
            'record_id'      => $id,
            'user_id'        => $userId,
            'title'          => $title,
            'record_type'    => $type,
            'file_url'       => $fileUrl,
            'is_abdm_linked' => true,
            'created_at'     => date('Y-m-d H:i:s')
        ], 201, 'Document indexed in encrypted health vault');
    }

    public static function getUserRecords(string $userId): void {
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("SELECT * FROM health_records WHERE user_id = ? ORDER BY created_at DESC");
        $stmt->execute([$userId]);
        $records = $stmt->fetchAll();

        Response::json($records);
    }

    public static function completeOnboarding(): void {
        $body = json_decode(file_get_contents('php://input'), true);
        $userId = $body['user_id'] ?? '';

        if (empty($userId)) {
            Response::error('User ID required', 400);
        }

        $bloodGroup = $body['blood_group'] ?? 'B+';
        $allergies = $body['allergies'] ?? 'Penicillin';
        $surgeries = $body['past_surgeries'] ?? 'Appendectomy (2020 at KIMS Hospitals)';
        $meds = $body['current_medications'] ?? 'None';
        $dob = $body['dob'] ?? '1995-08-15';
        $gender = $body['gender'] ?? 'male';
        $percent = intval($body['completion_percent'] ?? 100);

        $pdo = Database::getConnection();
        $pdo->beginTransaction();
        try {
            $uStmt = $pdo->prepare("UPDATE users SET dob = ?, gender = ? WHERE id = ?");
            $uStmt->execute([$dob, $gender, $userId]);

            $pStmt = $pdo->prepare("UPDATE health_profiles SET 
                blood_group = ?, allergies = ?, past_surgeries = ?, current_medications = ?, completion_percent = ?
                WHERE user_id = ?");
            $pStmt->execute([$bloodGroup, $allergies, $surgeries, $meds, $percent, $userId]);

            $pdo->commit();

            Response::json([
                'user_id'            => $userId,
                'blood_group'        => $bloodGroup,
                'past_surgeries'     => $surgeries,
                'completion_percent' => $percent,
                'message'            => 'Health profile and vitals enriched successfully'
            ]);
        } catch (Exception $e) {
            $pdo->rollBack();
            error_log("Onboarding Error: " . $e->getMessage());
            Response::error('Failed to complete onboarding profile', 500);
        }
    }
}
