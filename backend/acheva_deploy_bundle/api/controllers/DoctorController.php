<?php
/**
 * HealthExpress AI - Doctor Controller
 * Live Doctor Discovery, Credentialing, Approvals, Schedules & Proximity Search
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';
require_once __DIR__ . '/../helpers/MapboxHelper.php';

class DoctorController {
    /**
     * Get All Doctors with Hospital Affiliation and Proximity Sorting
     */
    public static function getAll(): void {
        $pdo = Database::getConnection();

        $lat = isset($_GET['lat']) ? floatval($_GET['lat']) : (isset($_GET['latitude']) ? floatval($_GET['latitude']) : null);
        $lng = isset($_GET['lng']) ? floatval($_GET['lng']) : (isset($_GET['longitude']) ? floatval($_GET['longitude']) : null);
        $specialty = trim($_GET['specialty'] ?? '');
        $city = trim($_GET['city'] ?? '');

        $query = "SELECT 
            d.*,
            COALESCE(h.name, 'Independent Practice') AS hospital_name,
            h.id AS hospital_id,
            h.city AS hospital_city,
            h.latitude AS hospital_latitude,
            h.longitude AS hospital_longitude
        FROM doctors d
        LEFT JOIN doctor_hospitals dh ON d.id = dh.doctor_id
        LEFT JOIN hospitals h ON dh.hospital_id = h.id
        WHERE 1=1";

        if (!empty($specialty) && $specialty !== 'All') {
            $query .= " AND d.specialty LIKE " . $pdo->quote("%$specialty%");
        }

        if (!empty($city)) {
            $query .= " AND h.city LIKE " . $pdo->quote("%$city%");
        }

        $query .= " ORDER BY d.created_at DESC";

        $stmt = $pdo->query($query);
        $doctors = $stmt->fetchAll();

        foreach ($doctors as &$d) {
            $hLat = floatval($d['hospital_latitude'] ?? 17.4265);
            $hLng = floatval($d['hospital_longitude'] ?? 78.4124);

            if ($lat && $lng) {
                $dist = MapboxHelper::getDistanceKm($lat, $lng, $hLat, $hLng);
                $eta = MapboxHelper::getEtaMinutes($dist);
                $d['distance_km'] = $dist;
                $d['eta_minutes'] = $eta;
                $d['proximity_label'] = "{$dist} km • {$eta} mins travel";
            } else {
                $d['distance_km'] = 2.8;
                $d['eta_minutes'] = 10;
                $d['proximity_label'] = "Available Nearby";
            }
        }

        // Sort by proximity if user coordinates provided
        if ($lat && $lng) {
            usort($doctors, fn($a, $b) => $a['distance_km'] <=> $b['distance_km']);
        }

        Response::json($doctors);
    }

    /**
     * Get Nearby Doctors Endpoint
     */
    public static function getNearby(): void {
        self::getAll();
    }

    /**
     * Get Doctor Details by ID
     */
    public static function getById(string $id): void {
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("SELECT 
            d.*,
            COALESCE(h.name, 'Independent Practice') AS hospital_name,
            h.id AS hospital_id,
            h.address AS hospital_address,
            h.city AS hospital_city
        FROM doctors d
        LEFT JOIN doctor_hospitals dh ON d.id = dh.doctor_id AND dh.is_primary = 1
        LEFT JOIN hospitals h ON dh.hospital_id = h.id
        WHERE d.id = ?
        LIMIT 1");

        $stmt->execute([$id]);
        $doctor = $stmt->fetch();

        if (!$doctor) {
            Response::error('Doctor not found', 404);
        }

        // Fetch schedules
        $schedStmt = $pdo->prepare("SELECT * FROM doctor_schedules WHERE doctor_id = ? ORDER BY day_of_week ASC");
        $schedStmt->execute([$id]);
        $doctor['schedules'] = $schedStmt->fetchAll();

        Response::json($doctor);
    }

    /**
     * Toggle Doctor Online Status
     */
    public static function toggleStatus(string $id): void {
        $body = json_decode(file_get_contents('php://input'), true);
        $isOnline = isset($body['isOnline']) ? ($body['isOnline'] ? 1 : 0) : 1;

        $pdo = Database::getConnection();
        $stmt = $pdo->prepare("UPDATE doctors SET is_online = ? WHERE id = ?");
        $stmt->execute([$isOnline, $id]);

        Response::json(['id' => $id, 'is_online' => (bool)$isOnline], 200, 'Status updated');
    }

    /**
     * Verify & Approve Doctor (Super Admin Action)
     */
    public static function updateVerificationStatus(string $id): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $status = strtolower(trim($body['status'] ?? 'verified'));
        $notes = trim($body['notes'] ?? 'Verification reviewed by Super Admin');

        if (!in_array($status, ['pending', 'verified', 'rejected'])) {
            Response::error('Invalid verification status', 400);
        }

        $pdo = Database::getConnection();
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("UPDATE doctors SET verification_status = ? WHERE id = ?");
            $stmt->execute([$status, $id]);

            // Insert audit log
            $audit = $pdo->prepare("INSERT INTO audit_logs (id, user_id, action, entity_type, entity_id, created_at) VALUES (?, 'SUPER_ADMIN', ?, 'doctor', ?, NOW())");
            $audit->execute(['LOG-' . rand(100000, 999999), "DOCTOR_STATUS_UPDATE: " . strtoupper($status), $id]);

            $pdo->commit();
            Response::json(['id' => $id, 'verification_status' => $status, 'notes' => $notes], 200, "Doctor verification updated to $status");
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Failed to update verification status', 500);
        }
    }
}
