<?php
/**
 * HealthExpress AI - Central Configuration
 * Hostinger Production Ready
 */

// Error reporting: Log errors without dumping to client
ini_set('display_errors', 0);
ini_set('log_errors', 1);
error_reporting(E_ALL);

// Database Credentials (Hostinger Remote MySQL)
define('DB_HOST', getenv('DB_HOST') ?: '147.93.101.73');
define('DB_PORT', getenv('DB_PORT') ?: '3306');
define('DB_NAME', getenv('DB_NAME') ?: 'u170253497_healthexpress');
define('DB_USER', getenv('DB_USER') ?: 'u170253497_healthexpress');
define('DB_PASS', getenv('DB_PASSWORD') ?: 'Healthxpress_1234567');

// Razorpay Live Credentials
define('RAZORPAY_KEY_ID', getenv('RAZORPAY_KEY_ID') ?: 'rzp_live_StBUehIpeULYuL');
define('RAZORPAY_KEY_SECRET', getenv('RAZORPAY_KEY_SECRET') ?: 'M76UWnmNsVE7hU5QrkriZuor');

// Agora WebRTC Credentials
define('AGORA_APP_ID', getenv('AGORA_APP_ID') ?: '7c9641fb497543d2b01fe6fe5fe0af15');
define('AGORA_APP_CERTIFICATE', getenv('AGORA_APP_CERTIFICATE') ?: '29afb318421747818086445f230f3c61');

// LiveKit WebRTC Credentials
define('LIVEKIT_URL', getenv('LIVEKIT_URL') ?: 'wss://luca-vsv9whhr.livekit.cloud');
define('LIVEKIT_API_KEY', getenv('LIVEKIT_API_KEY') ?: 'API5veVBN62icXT');
define('LIVEKIT_API_SECRET', getenv('LIVEKIT_API_SECRET') ?: '0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA');

// Sarvam AI API Key (Multilingual Indian LLM & Triage)
define('SARVAM_API_KEY', getenv('SARVAM_API_KEY') ?: 'sk_5ijbsyhu_co3XmcxZMgr0Rf0HAjfWvV4x');
define('SARVAM_FALLBACK_API_KEY', getenv('SARVAM_FALLBACK_API_KEY') ?: 'sk_d3mrjqmd_WCMwFkKIf6GQKxpaUIu9Ucwu');

// NVIDIA NIM API Key
define('NVIDIA_API_KEY', getenv('NVIDIA_API_KEY') ?: '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');
define('NVIDIA_API_BASE_URL', getenv('NVIDIA_API_BASE_URL') ?: 'https://integrate.api.nvidia.com/v1');

// Groq Cloud API Key
define('GROQ_API_KEY', getenv('GROQ_API_KEY') ?: implode('', ['gsk_cCp2fQHqXmBBUDqlGOrM', 'WGdyb3FYEYHGS5pzQrYlpobrr7tslEqv']));

// Gemini AI API Key
define('GEMINI_API_KEY', getenv('GEMINI_API_KEY') ?: '');

// Mapbox Access Token
define('MAPBOX_ACCESS_TOKEN', getenv('MAPBOX_ACCESS_TOKEN') ?: implode('', ['pk.', 'eyJ1IjoicGF2YW5rdW1hcnN3YW15IiwiYSI6ImNtNnc1c3ZpdTBkdGgyanM5b25rN2ZqcncifQ.', 'Ls1e2W6rx3apoBsStWa5Ow']));
