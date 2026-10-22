<?php
/**
 * HealthExpress AI - Hostinger Cron Task: ABDM Consent Token Cleanup
 * Purges expired 15-minute temporary consent tokens
 */

require_once __DIR__ . '/../config/database.php';

$pdo = Database::getConnection();

$stmt = $pdo->prepare("DELETE FROM qr_consent_tokens WHERE expires_at < NOW() AND is_used = 1");
$stmt->execute();
$deleted = $stmt->rowCount();

echo "[" . date('Y-m-d H:i:s') . "] Cleaned up {$deleted} expired ABDM consent tokens.\n";
