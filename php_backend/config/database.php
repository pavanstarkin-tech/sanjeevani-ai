<?php
/**
 * HealthExpress AI - Database Connection Singleton (PDO)
 * Connects directly to Hostinger MySQL Database
 */

require_once __DIR__ . '/config.php';

class Database {
    private static ?PDO $instance = null;

    public static function getConnection(): PDO {
        if (self::$instance === null) {
            $hosts = array_unique(['localhost', '127.0.0.1', DB_HOST]);
            $lastException = null;

            foreach ($hosts as $host) {
                try {
                    $dsn = "mysql:host=" . $host . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
                    $options = [
                        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                        PDO::ATTR_EMULATE_PREPARES   => false,
                        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
                    ];

                    self::$instance = new PDO($dsn, DB_USER, DB_PASS, $options);
                    return self::$instance;
                } catch (PDOException $e) {
                    $lastException = $e;
                }
            }

            error_log("Database Connection Error: " . ($lastException ? $lastException->getMessage() : 'Unknown'));
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error'   => 'Database connection failed: ' . ($lastException ? $lastException->getMessage() : 'Unknown')
            ]);
            exit;
        }
        return self::$instance;
    }
}
