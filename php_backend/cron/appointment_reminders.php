<?php
/**
 * HealthExpress AI - Hostinger Cron Task: Appointment Reminders
 * Execute via Hostinger Cron: /usr/bin/php /home/u170253497/domains/healthexpress.ai/public_html/cron/appointment_reminders.php
 */

require_once __DIR__ . '/../config/database.php';

$pdo = Database::getConnection();

// Find confirmed appointments scheduled within next 60 minutes
$stmt = $pdo->query("SELECT a.id, a.user_id, a.doctor_id, a.appointment_time, u.name as patient_name, d.name as doctor_name
    FROM appointments a
    JOIN users u ON a.user_id = u.id
    JOIN doctors d ON a.doctor_id = d.id
    WHERE a.appointment_date = CURDATE() 
      AND a.status = 'confirmed'
      AND a.appointment_time BETWEEN CURTIME() AND ADDTIME(CURTIME(), '01:00:00')");

$upcoming = $stmt->fetchAll();

foreach ($upcoming as $appt) {
    // In production, dispatch FCM push notification
    echo "[" . date('Y-m-d H:i:s') . "] Reminder triggered for Appointment #{$appt['id']} (Patient: {$appt['patient_name']} with {$appt['doctor_name']})\n";
}

echo "Appointment reminder cron completed successfully.\n";
