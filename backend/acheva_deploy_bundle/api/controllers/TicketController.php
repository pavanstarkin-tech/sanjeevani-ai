<?php
/**
 * HealthExpress AI - Ticket Controller
 * Customer Support Dispute Desk
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';

class TicketController {
    public static function getAll(): void {
        $pdo = Database::getConnection();

        $stmt = $pdo->query("SELECT 
            t.*,
            COALESCE(u.name, 'Patient User') AS user_name,
            COALESCE(u.mobile, '+91 9848011223') AS user_phone
        FROM tickets t
        LEFT JOIN users u ON t.user_id = u.id
        ORDER BY t.created_at DESC");

        $tickets = $stmt->fetchAll();
        Response::json($tickets);
    }

    public static function create(): void {
        $body = json_decode(file_get_contents('php://input'), true);

        $userId = $body['user_id'] ?? 'USR-101';
        $subject = trim($body['subject'] ?? 'Appointment Rescheduling Support');
        $description = trim($body['description'] ?? 'Need assistance changing my in-clinic slot due to travel delay.');
        $priority = $body['priority'] ?? 'medium';

        $id = 'TK' . rand(1000, 9999);
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("INSERT INTO tickets (id, user_id, subject, description, priority, status, created_at)
            VALUES (?, ?, ?, ?, ?, 'open', NOW())");
        $stmt->execute([$id, $userId, $subject, $description, $priority]);

        Response::json([
            'ticket_id'   => $id,
            'user_id'     => $userId,
            'subject'     => $subject,
            'priority'    => $priority,
            'status'      => 'open',
            'created_at'  => date('Y-m-d H:i:s')
        ], 201, 'Support ticket logged');
    }
}
