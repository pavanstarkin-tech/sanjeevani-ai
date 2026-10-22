<?php
/**
 * HealthExpress AI - Chat Controller
 * 2-Way Real-time Patient <-> Doctor Messaging
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';

class ChatController {
    public static function sendMessage(): void {
        $body = json_decode(file_get_contents('php://input'), true);

        $senderId = $body['sender_id'] ?? '';
        $receiverId = $body['receiver_id'] ?? '';
        $message = trim($body['message'] ?? '');
        $mediaUrl = $body['media_url'] ?? null;
        $appointmentId = $body['appointment_id'] ?? null;

        if (empty($senderId) || empty($receiverId) || (empty($message) && empty($mediaUrl))) {
            Response::error('Sender ID, Receiver ID and message/media required', 400);
        }

        $id = 'MSG-' . rand(10000, 99999);
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("INSERT INTO chat_messages (id, appointment_id, sender_id, receiver_id, message, media_url, created_at)
            VALUES (?, ?, ?, ?, ?, ?, NOW())");
        $stmt->execute([$id, $appointmentId, $senderId, $receiverId, $message, $mediaUrl]);

        Response::json([
            'id'             => $id,
            'sender_id'      => $senderId,
            'receiver_id'    => $receiverId,
            'message'        => $message,
            'media_url'      => $mediaUrl,
            'appointment_id' => $appointmentId,
            'created_at'     => date('Y-m-d H:i:s')
        ], 201, 'Message delivered');
    }

    public static function getHistory(): void {
        $user1 = $_GET['user1'] ?? '';
        $user2 = $_GET['user2'] ?? '';

        if (empty($user1) || empty($user2)) {
            Response::error('Both user1 and user2 query parameters required', 400);
        }

        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("SELECT * FROM chat_messages 
            WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)
            ORDER BY created_at ASC");
        $stmt->execute([$user1, $user2, $user2, $user1]);
        $messages = $stmt->fetchAll();

        Response::json($messages);
    }
}
