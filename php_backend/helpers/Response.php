<?php
/**
 * HealthExpress AI - JSON Response Helper
 */

class Response {
    public static function json($data, int $statusCode = 200, string $message = ''): void {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');
        header('Pragma: no-cache');
        header('Expires: 0');

        $payload = [
            'success' => ($statusCode >= 200 && $statusCode < 300),
            'data'    => $data,
        ];

        if (!empty($message)) {
            $payload['message'] = $message;
        }

        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function error(string $message, int $statusCode = 400, $errors = null): void {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');

        $payload = [
            'success' => false,
            'error'   => $message,
        ];

        if ($errors !== null) {
            $payload['details'] = $errors;
        }

        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}
