<?php
/**
 * HealthExpress AI - Hospital Controller
 * Live Partner Hospital Discovery, Empanelment & Mapbox Proximity Search
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';
require_once __DIR__ . '/../helpers/MapboxHelper.php';

class HospitalController {
    /**
     * Get All Empaneled Hospitals with Proximity Sorting
     */
    public static function getAll(): void {
        $pdo = Database::getConnection();

        $lat = isset($_GET['lat']) ? floatval($_GET['lat']) : (isset($_GET['latitude']) ? floatval($_GET['latitude']) : null);
        $lng = isset($_GET['lng']) ? floatval($_GET['lng']) : (isset($_GET['longitude']) ? floatval($_GET['longitude']) : null);
        $city = trim($_GET['city'] ?? '');

        $query = "SELECT 
            h.*,
            (SELECT COUNT(*) FROM doctor_hospitals dh WHERE dh.hospital_id = h.id) AS staff_count
        FROM hospitals h";

        if (!empty($city)) {
            $query .= " WHERE h.city LIKE " . $pdo->quote("%$city%");
        }

        $query .= " ORDER BY h.created_at DESC";

        $stmt = $pdo->query($query);
        $hospitals = $stmt->fetchAll();

        // Calculate proximity if coordinates provided
        foreach ($hospitals as &$h) {
            if (isset($h['services']) && is_string($h['services'])) {
                $h['services'] = json_decode($h['services'], true) ?: [];
            }

            $hLat = floatval($h['latitude'] ?? 17.4265);
            $hLng = floatval($h['longitude'] ?? 78.4124);

            if ($lat && $lng) {
                $dist = MapboxHelper::getDistanceKm($lat, $lng, $hLat, $hLng);
                $eta = MapboxHelper::getEtaMinutes($dist);
                $h['distance_km'] = $dist;
                $h['eta_minutes'] = $eta;
                $h['proximity_label'] = "{$dist} km • {$eta} mins away";
            } else {
                $h['distance_km'] = 3.5;
                $h['eta_minutes'] = 12;
                $h['proximity_label'] = "Nearby Facility";
            }
        }

        // Sort by distance if user location is available
        if ($lat && $lng) {
            usort($hospitals, fn($a, $b) => $a['distance_km'] <=> $b['distance_km']);
        }

        Response::json($hospitals);
    }

    /**
     * Get Nearby Hospitals sorted by GPS Distance
     */
    public static function getNearby(): void {
        self::getAll();
    }

    /**
     * Get Hospital Facility by ID
     */
    public static function getById(string $id): void {
        $pdo = Database::getConnection();

        $stmt = $pdo->prepare("SELECT * FROM hospitals WHERE id = ? LIMIT 1");
        $stmt->execute([$id]);
        $hospital = $stmt->fetch();

        if (!$hospital) {
            Response::error('Hospital facility not found', 404);
        }

        // Fetch affiliated departments
        $deptStmt = $pdo->prepare("SELECT * FROM departments WHERE hospital_id = ?");
        $deptStmt->execute([$id]);
        $hospital['departments'] = $deptStmt->fetchAll();

        // Fetch affiliated doctors
        $docStmt = $pdo->prepare("SELECT 
            d.id, d.name, d.specialty, d.experience_years, d.consultation_fee, d.photo_url, d.verification_status
        FROM doctors d
        JOIN doctor_hospitals dh ON d.id = dh.doctor_id
        WHERE dh.hospital_id = ?");
        $docStmt->execute([$id]);
        $hospital['doctors'] = $docStmt->fetchAll();

        Response::json($hospital);
    }

    /**
     * 8-Step Hospital Empanelment
     */
    public static function create(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];

        $name = trim($body['name'] ?? '');
        if (empty($name)) {
            Response::error('Hospital name is required', 400);
        }

        $id = 'HOSP-' . rand(100, 999);
        $type = $body['hospital_type'] ?? 'Super Specialty';
        $license = $body['license_number'] ?? ('TS-HYD-HOSP-' . rand(1000, 9999));
        $phone = $body['primary_phone'] ?? '+91 40 4488 5000';
        $emergencyPhone = $body['emergency_phone'] ?? '1066';
        $email = $body['email'] ?? 'contact@hospital.in';
        $address = $body['address'] ?? 'Hyderabad, Telangana';
        $city = $body['city'] ?? 'Hyderabad';
        $state = $body['state'] ?? 'Telangana';
        $pincode = $body['pincode'] ?? '500033';
        $lat = floatval($body['latitude'] ?? 17.4265);
        $lng = floatval($body['longitude'] ?? 78.4124);
        $services = json_encode($body['services'] ?? ['Emergency', 'ICU', 'Pharmacy', 'Lab', 'Radiology']);

        $pdo = Database::getConnection();
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("INSERT INTO hospitals 
                (id, name, hospital_type, license_number, primary_phone, emergency_phone, email, address, city, state, pincode, latitude, longitude, services, verification_status, status, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'verified', 'Active', NOW())");

            $stmt->execute([$id, $name, $type, $license, $phone, $emergencyPhone, $email, $address, $city, $state, $pincode, $lat, $lng, $services]);

            // Insert departments if provided
            if (!empty($body['departments']) && is_array($body['departments'])) {
                $dStmt = $pdo->prepare("INSERT INTO departments (id, hospital_id, name) VALUES (?, ?, ?)");
                foreach ($body['departments'] as $dName) {
                    $dStmt->execute(['DEPT-' . rand(1000, 9999), $id, $dName]);
                }
            }

            $pdo->commit();

            Response::json([
                'id'       => $id,
                'name'     => $name,
                'location' => "$city, $state",
                'status'   => 'Active',
            ], 201, 'Hospital empaneled successfully');
        } catch (Exception $e) {
            $pdo->rollBack();
            error_log("Hospital Creation Error: " . $e->getMessage());
            Response::error('Failed to empanel hospital', 500);
        }
    }
}
