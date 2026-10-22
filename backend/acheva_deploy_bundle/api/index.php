<?php
/**
 * HealthExpress AI - PHP 8+ Front Controller & REST Router
 * Hostinger Production Architecture
 */

require_once __DIR__ . '/middleware/CorsMiddleware.php';
require_once __DIR__ . '/helpers/Response.php';

// Apply CORS headers to every request
CorsMiddleware::handle();

// Controllers
require_once __DIR__ . '/controllers/AdminController.php';
require_once __DIR__ . '/controllers/AuthController.php';
require_once __DIR__ . '/controllers/HospitalController.php';
require_once __DIR__ . '/controllers/DoctorController.php';
require_once __DIR__ . '/controllers/AppointmentController.php';
require_once __DIR__ . '/controllers/PaymentController.php';
require_once __DIR__ . '/controllers/TelehealthController.php';
require_once __DIR__ . '/controllers/LiveKitController.php';
require_once __DIR__ . '/controllers/PharmacyController.php';
require_once __DIR__ . '/controllers/ConsentController.php';
require_once __DIR__ . '/controllers/ChatController.php';
require_once __DIR__ . '/controllers/HealthRecordController.php';
require_once __DIR__ . '/controllers/TicketController.php';
require_once __DIR__ . '/controllers/EmergencyController.php';
require_once __DIR__ . '/controllers/AiController.php';
require_once __DIR__ . '/controllers/HealthController.php';
require_once __DIR__ . '/controllers/ApiKeyPoolController.php';

// Parse Request URI and Method
$requestUri = $_SERVER['REQUEST_URI'];
$method = $_SERVER['REQUEST_METHOD'];

// Strip query string and base directory if applicable
$parsedUrl = parse_url($requestUri);
$path = rtrim($parsedUrl['path'], '/');

// Normalize API Path
if (strpos($path, '/api') !== false) {
    $path = substr($path, strpos($path, '/api'));
} elseif (strpos($path, '/sarvam-keys') !== false) {
    $path = '/sarvam-keys';
} elseif (strpos($path, '/healthexpress') === 0) {
    $path = substr($path, strlen('/healthexpress'));
}

// -------------------------------------------------------------
// REST API ROUTING TABLE
// -------------------------------------------------------------

// Interactive Health & Downtime Telemetry Check
if (($path === '/api/health' || $path === '/api' || $path === '') && $method === 'GET') {
    HealthController::check();
}

// 1. Admin Operations & Ledgers
if ($path === '/api/admin/stats' && $method === 'GET') {
    AdminController::getStats();
}
if ($path === '/api/admin/ai-stats' && $method === 'GET') {
    AdminController::getAiStats();
}
if ($path === '/api/admin/ai-sessions' && $method === 'GET') {
    AdminController::getAiSessions();
}
if ($path === '/api/admin/hospital-rankings' && $method === 'GET') {
    AdminController::getHospitalRankings();
}
if ($path === '/api/admin/consultation-distribution' && $method === 'GET') {
    AdminController::getConsultationDistribution();
}
if ($path === '/api/admin/activity-logs' && $method === 'GET') {
    AdminController::getActivityLogs();
}
if ($path === '/api/users' && $method === 'GET') {
    AdminController::getUsers();
}
if ($path === '/api/payments' && $method === 'GET') {
    AdminController::getPayments();
}

// 2. Authentication & Aarogyasri & Onboarding
if ($path === '/api/auth/register' && $method === 'POST') {
    AuthController::register();
}
if ($path === '/api/auth/update-onboarding' && $method === 'POST') {
    AuthController::updateOnboarding();
}
if (preg_match('#^/api/auth/aarogyasri/([^/]+)$#', $path, $matches) && $method === 'GET') {
    AuthController::getAarogyasriProfile($matches[1]);
}

// 3. Hospitals
if ($path === '/api/hospitals' && $method === 'GET') {
    HospitalController::getAll();
}
if ($path === '/api/hospitals/nearby' && $method === 'GET') {
    HospitalController::getNearby();
}
if ($path === '/api/hospitals' && $method === 'POST') {
    HospitalController::create();
}
if (preg_match('#^/api/hospitals/([^/]+)$#', $path, $matches) && $method === 'GET') {
    HospitalController::getById($matches[1]);
}

// 4. Doctors
if ($path === '/api/doctors' && $method === 'GET') {
    DoctorController::getAll();
}
if ($path === '/api/doctors/nearby' && $method === 'GET') {
    DoctorController::getNearby();
}
if (preg_match('#^/api/doctors/([^/]+)/status$#', $path, $matches) && $method === 'PUT') {
    DoctorController::toggleStatus($matches[1]);
}
if (preg_match('#^/api/doctors/([^/]+)/verify$#', $path, $matches) && $method === 'PUT') {
    DoctorController::updateVerificationStatus($matches[1]);
}
if (preg_match('#^/api/doctors/([^/]+)$#', $path, $matches) && $method === 'GET') {
    DoctorController::getById($matches[1]);
}

// 5. Appointments
if ($path === '/api/appointments' && $method === 'GET') {
    AdminController::getAllAppointments();
}
if (preg_match('#^/api/appointments/user/([^/]+)$#', $path, $matches) && $method === 'GET') {
    AppointmentController::getUserAppointments($matches[1]);
}
if (preg_match('#^/api/appointments/doctor/([^/]+)$#', $path, $matches) && $method === 'GET') {
    AppointmentController::getDoctorAppointments($matches[1]);
}
if ($path === '/api/appointments/book' && $method === 'POST') {
    AppointmentController::book();
}
if (preg_match('#^/api/appointments/([^/]+)/reschedule$#', $path, $matches) && $method === 'PUT') {
    AppointmentController::reschedule($matches[1]);
}
if (preg_match('#^/api/appointments/([^/]+)/prescription$#', $path, $matches) && $method === 'PUT') {
    AppointmentController::issuePrescription($matches[1]);
}

// 6. Payments
if ($path === '/api/payments/create-order' && $method === 'POST') {
    PaymentController::createOrder();
}
if ($path === '/api/payments/verify' && $method === 'POST') {
    PaymentController::verifySignature();
}

// 7. Telehealth, Agora & LiveKit Voice
if ($path === '/api/telehealth/generate-agora-token' && $method === 'POST') {
    TelehealthController::generateToken();
}
if (($path === '/api/livekit/token' || $path === '/api/telehealth/livekit-token') && ($method === 'GET' || $method === 'POST')) {
    LiveKitController::getToken();
}

// 8. Pharmacy, Store Partners & 15-min Delivery
if ($path === '/api/pharmacy/medicines' && $method === 'GET') {
    PharmacyController::getMedicines();
}
if ($path === '/api/pharmacy/order' && $method === 'POST') {
    PharmacyController::createOrder();
}
if (preg_match('#^/api/pharmacy/orders/user/([^/]+)$#', $path, $matches) && $method === 'GET') {
    PharmacyController::getUserOrders($matches[1]);
}
if ($path === '/api/emergency/dispatch' && $method === 'POST') {
    EmergencyController::dispatch();
}
if ($path === '/api/emergency/active' && $method === 'GET') {
    EmergencyController::getActiveDispatches();
}
if ($path === '/api/pharmacy/stores' && $method === 'GET') {
    PharmacyController::getStores();
}
if ($path === '/api/pharmacy/onboard' && $method === 'POST') {
    PharmacyController::onboardStore();
}
if ($path === '/api/pharmacy/my-store' && $method === 'GET') {
    PharmacyController::getMyStore($_GET['user_id'] ?? 'USR-STORE-101');
}
if (preg_match('#^/api/pharmacy/my-store/([^/]+)$#', $path, $matches) && $method === 'PUT') {
    PharmacyController::updateMyStore($matches[1]);
}
if (preg_match('#^/api/pharmacy/stores/([^/]+)/products$#', $path, $matches) && $method === 'GET') {
    PharmacyController::getStoreProducts($matches[1]);
}
if (preg_match('#^/api/pharmacy/stores/([^/]+)/products$#', $path, $matches) && $method === 'POST') {
    PharmacyController::addStoreProduct($matches[1]);
}
if (preg_match('#^/api/pharmacy/products/([^/]+)/stock$#', $path, $matches) && $method === 'PUT') {
    PharmacyController::toggleProductStock($matches[1]);
}
if ($path === '/api/admin/pending-stores' && $method === 'GET') {
    PharmacyController::getPendingStores();
}
if (preg_match('#^/api/admin/verify-store/([^/]+)$#', $path, $matches) && $method === 'PUT') {
    PharmacyController::verifyStore($matches[1]);
}

// 9. ABDM QR Consent
if ($path === '/api/consent/generate-token' && $method === 'POST') {
    ConsentController::generateToken();
}
if ($path === '/api/consent/doctor-scan' && $method === 'POST') {
    ConsentController::doctorScan();
}

// 10. Chat
if ($path === '/api/chat/send' && $method === 'POST') {
    ChatController::sendMessage();
}
if ($path === '/api/chat/history' && $method === 'GET') {
    ChatController::getHistory();
}

// 11. Health Records & Progressive Onboarding
if ($path === '/api/health-records/upload' && $method === 'POST') {
    HealthRecordController::upload();
}
if (preg_match('#^/api/health-records/user/([^/]+)$#', $path, $matches) && $method === 'GET') {
    HealthRecordController::getUserRecords($matches[1]);
}
if ($path === '/api/health-records/onboarding/complete' && $method === 'PUT') {
    HealthRecordController::completeOnboarding();
}

// 12. Support Tickets
if ($path === '/api/tickets' && $method === 'GET') {
    TicketController::getAll();
}
if ($path === '/api/tickets' && $method === 'POST') {
    TicketController::create();
}

// 13. AI Triage & Clinical Memory
if ($path === '/api/ai/triage' && $method === 'POST') {
    AiController::triage();
}
if ($path === '/api/ai/rag-schemes' && $method === 'GET') {
    AiController::getRagSchemes();
}
if ($path === '/api/ai/rag-chunks' && $method === 'GET') {
    AiController::getRagChunks();
}
if ($path === '/api/ai/rag-chunks' && $method === 'POST') {
    AiController::addRagChunk();
}
if ($path === '/api/ai/rag-chunks/publish' && $method === 'POST') {
    AiController::publishRagUpdates();
}
if ($path === '/api/ai/rag-chunks/latest-version' && $method === 'GET') {
    AiController::getLatestRagVersion();
}
if (preg_match('#^/api/ai/sessions/user/([^/]+)$#', $path, $matches) && $method === 'GET') {
    AiController::getUserSessions($matches[1]);
}

// 14. Diagnostic Lab Tests Catalog
if ($path === '/api/diagnostic/lab-tests' && $method === 'GET') {
    $tests = [
        ['id' => 'TEST-01', 'code' => 'CBC', 'name' => 'Complete Blood Count (CBC)', 'price' => 299.00, 'category' => 'Hematology', 'fasting_required' => false, 'tat_hours' => 6],
        ['id' => 'TEST-02', 'code' => 'LIPID', 'name' => 'Lipid Profile Comprehensive', 'price' => 599.00, 'category' => 'Cardiology', 'fasting_required' => true, 'tat_hours' => 12],
        ['id' => 'TEST-03', 'code' => 'HBA1C', 'name' => 'HbA1c Glycated Hemoglobin', 'price' => 399.00, 'category' => 'Diabetology', 'fasting_required' => false, 'tat_hours' => 4],
        ['id' => 'TEST-04', 'code' => 'LFT', 'name' => 'Liver Function Test (LFT)', 'price' => 499.00, 'category' => 'Gastroenterology', 'fasting_required' => false, 'tat_hours' => 8],
        ['id' => 'TEST-05', 'code' => 'KFT', 'name' => 'Kidney Function Test (KFT)', 'price' => 499.00, 'category' => 'Nephrology', 'fasting_required' => false, 'tat_hours' => 8],
        ['id' => 'TEST-06', 'code' => 'NS1-ANTIGEN', 'name' => 'Dengue NS1 Antigen Rapid', 'price' => 450.00, 'category' => 'Infectious Disease', 'fasting_required' => false, 'tat_hours' => 2],
        ['id' => 'TEST-07', 'code' => 'MAL-AG', 'name' => 'Malaria Antigen Card Test', 'price' => 350.00, 'category' => 'Infectious Disease', 'fasting_required' => false, 'tat_hours' => 2],
        ['id' => 'TEST-08', 'code' => 'THYROID', 'name' => 'Thyroid Profile (T3, T4, TSH)', 'price' => 399.00, 'category' => 'Endocrinology', 'fasting_required' => true, 'tat_hours' => 12]
    ];
    Response::json($tests);
}

// 15. Business Products & Master Checkup Packages
if ($path === '/api/orders/business-products' && $method === 'GET') {
    $products = [
        ['id' => 'PRD-101', 'title' => 'Accu-Chek Active Blood Glucose Monitor', 'category' => 'Diabetes Care Device', 'price' => 899.00, 'original_price' => 1299.00, 'discount_percent' => 30],
        ['id' => 'PRD-102', 'title' => 'Omron HEM 7120 Digital Blood Pressure Monitor', 'category' => 'Cardio Care Device', 'price' => 1799.00, 'original_price' => 2490.00, 'discount_percent' => 28],
        ['id' => 'PRD-103', 'title' => 'Dr. Ortho Knee Compression Support Belt', 'category' => 'Orthopedic Care', 'price' => 499.00, 'original_price' => 799.00, 'discount_percent' => 37],
        ['id' => 'PRD-104', 'title' => 'Full Body 84-Parameter Master Health Checkup Package', 'category' => 'Diagnostic Lab Package', 'price' => 999.00, 'original_price' => 2499.00, 'discount_percent' => 60],
        ['id' => 'PRD-105', 'title' => 'Immunity Booster Ayurvedic Chyawanprash (1kg)', 'category' => 'Ayurvedic Wellness', 'price' => 349.00, 'original_price' => 450.00, 'discount_percent' => 22],
        ['id' => 'PRD-106', 'title' => 'HealthExpress Gold Family Annual Privilege Pass', 'category' => 'Privilege Care Subscription', 'price' => 1499.00, 'original_price' => 2999.00, 'discount_percent' => 50]
    ];
    Response::json($products);
}

// 16. Aarogyasri Lookup
if ($path === '/api/aarogyasri/lookup' && $method === 'GET') {
    $uhid = $_GET['uhid'] ?? $_GET['id'] ?? 'AROG12345678';
    AuthController::getAarogyasriProfile($uhid);
}

// 17. Public Sarvam AI Multi-Key Pool & Failover Manager (Zero Authentication)
if (($path === '/sarvam-keys' || $path === '/api/public/sarvam-keys-ui') && $method === 'GET') {
    ApiKeyPoolController::renderUi();
    exit;
}
if ($path === '/api/public/sarvam-keys' && $method === 'GET') {
    ApiKeyPoolController::getKeys();
}
if ($path === '/api/public/sarvam-keys/active' && $method === 'GET') {
    ApiKeyPoolController::getActiveKey();
}
if ($path === '/api/public/sarvam-keys' && $method === 'POST') {
    ApiKeyPoolController::addKeys();
}
if ($path === '/api/public/sarvam-keys/mark-exhausted' && $method === 'POST') {
    ApiKeyPoolController::markKeyExhausted();
}
if ($path === '/api/public/sarvam-keys/mark-invalid' && $method === 'POST') {
    ApiKeyPoolController::markKeyInvalid();
}
if ($path === '/api/public/sarvam-keys/set-active' && $method === 'POST') {
    ApiKeyPoolController::setActiveKey();
}
if ($path === '/api/public/sarvam-keys/reactivate' && $method === 'POST') {
    ApiKeyPoolController::reactivateKey();
}
if ($path === '/api/public/sarvam-keys' && $method === 'DELETE') {
    ApiKeyPoolController::deleteKey();
}

// Fallback: 404 Route Not Found
Response::error("Endpoint not found: $method $path", 404);
