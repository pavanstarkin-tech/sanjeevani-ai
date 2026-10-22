<?php
/**
 * Standalone Interactive GUI for Sarvam AI Key Pool & Failover Manager
 * Accessible directly at /sarvam-keys or /sarvam-keys.php
 */
require_once __DIR__ . '/middleware/CorsMiddleware.php';
require_once __DIR__ . '/controllers/ApiKeyPoolController.php';

CorsMiddleware::handle();
ApiKeyPoolController::renderUi();
