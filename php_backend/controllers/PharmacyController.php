<?php
/**
 * HealthExpress AI - Pharmacy Controller
 * 15-Minute Doorstep Medicine Delivery, Store Partner Onboarding & Store Inventory Management
 */

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../helpers/Response.php';
require_once __DIR__ . '/../helpers/MapboxHelper.php';

class PharmacyController {
    /**
     * Get All Medicines with Location-Aware Delivery ETA
     */
    public static function getMedicines(): void {
        $pdo = Database::getConnection();

        $lat = isset($_GET['lat']) ? floatval($_GET['lat']) : (isset($_GET['latitude']) ? floatval($_GET['latitude']) : null);
        $lng = isset($_GET['lng']) ? floatval($_GET['lng']) : (isset($_GET['longitude']) ? floatval($_GET['longitude']) : null);

        $stmt = $pdo->query("SELECT * FROM medicines ORDER BY requires_prescription ASC, name ASC");
        $medicines = $stmt->fetchAll();

        $deliveryEta = 15;
        $fulfillmentHub = 'Central Hyderabad Quick-Delivery Hub';

        if ($lat && $lng) {
            // Check distance to central fulfillment hub (Gachibowli hub @ 17.4400, 78.3489)
            $hubDistance = MapboxHelper::getDistanceKm($lat, $lng, 17.4400, 78.3489);
            $deliveryEta = max(10, min(30, intval(round($hubDistance * 2.2 + 8))));
            $fulfillmentHub = $hubDistance <= 5.0 ? 'Hyperlocal 15-Min Dark Store' : 'City Express Fulfillment Hub';
        }

        foreach ($medicines as &$m) {
            $m['delivery_eta_minutes'] = $deliveryEta;
            $m['delivery_label'] = "{$deliveryEta}-min Doorstep Delivery";
            $m['fulfillment_hub'] = $fulfillmentHub;
            $m['in_stock'] = (bool)($m['in_stock'] ?? true);
            $m['is_prescription_required'] = (bool)($m['requires_prescription'] ?? false);
        }

        Response::json([
            'medicines'       => $medicines,
            'fulfillment_hub' => $fulfillmentHub,
            'eta_minutes'     => $deliveryEta
        ]);
    }

    /**
     * Create 15-Minute Medicine Delivery Order with Single-Store Tracking
     */
    public static function createOrder(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];

        $userId = $body['user_id'] ?? 'USR-101';
        $items = $body['items'] ?? [];
        $totalAmount = floatval($body['total_amount'] ?? 450.00);
        $deliveryAddress = $body['delivery_address'] ?? 'Road No 36, Jubilee Hills, Hyderabad';
        $lat = isset($body['latitude']) ? floatval($body['latitude']) : 17.4400;
        $lng = isset($body['longitude']) ? floatval($body['longitude']) : 78.3489;
        
        // Store Details
        $storeId = $body['store_id'] ?? 'STORE-01';
        $storeName = $body['store_name'] ?? 'Apollo Pharmacy 24x7';
        $storePhone = $body['store_phone'] ?? '+91 40 2360 8888';
        $storeAddress = $body['store_address'] ?? 'Plot 12, Phase 2, Hitech City Main Rd, Hyderabad';
        $storeImage = $body['store_image'] ?? 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400';
        $storeLicense = $body['store_license'] ?? 'TS-HYD-PHARM-2024-8801';

        $orderId = 'MED-ORD-' . rand(10000, 99999);
        $etaMinutes = max(12, min(25, intval(round(MapboxHelper::getDistanceKm($lat, $lng, 17.4400, 78.3489) * 2.2 + 8))));

        Response::json([
            'order_id'         => $orderId,
            'user_id'          => $userId,
            'items'            => $items,
            'total_amount'     => $totalAmount,
            'delivery_address' => $deliveryAddress,
            'delivery_status'  => 'order_placed',
            'eta_minutes'      => $etaMinutes,
            'store'            => [
                'id'             => $storeId,
                'name'           => $storeName,
                'phone'          => $storePhone,
                'address'        => $storeAddress,
                'image_url'      => $storeImage,
                'license_number' => $storeLicense,
            ],
            'driver'           => [
                'name'           => 'Ravi Kumar',
                'phone'          => '+91 9848123456',
                'vehicle'        => 'Hero Electric Optima (TS 09 EQ 4412)',
            ],
            'timeline'         => [
                ['status' => 'Order Placed', 'time' => date('h:i A'), 'completed' => true],
                ['status' => 'Pharmacy Packed', 'time' => date('h:i A', strtotime('+3 minutes')), 'completed' => false],
                ['status' => 'Rider Dispatched (Mapbox Live GPS)', 'time' => date('h:i A', strtotime('+6 minutes')), 'completed' => false],
                ['status' => 'Delivered to Doorstep', 'time' => date('h:i A', strtotime("+{$etaMinutes} minutes")), 'completed' => false],
            ]
        ], 201, '15-min medicine delivery order initiated');
    }

    /**
     * Get Orders for specific User
     */
    public static function getUserOrders(string $userId): void {
        Response::json([]);
    }

    /**
     * Get Nearby Verified Medical Stores & Dark Stores with Real-Time ETA
     */
    public static function getStores(): void {
        $pdo = Database::getConnection();
        $lat = isset($_GET['lat']) ? floatval($_GET['lat']) : 17.4400;
        $lng = isset($_GET['lng']) ? floatval($_GET['lng']) : 78.3489;

        try {
            $stmt = $pdo->query("SELECT * FROM pharmacy_stores WHERE verification_status = 'verified' ORDER BY is_open DESC, is_24x7 DESC");
            $dbStores = $stmt->fetchAll();
        } catch (\Exception $e) {
            $dbStores = [];
        }

        if (empty($dbStores)) {
            // Default seed stores if DB table empty
            $dbStores = [
                [
                    'id'            => 'STORE-01',
                    'name'          => 'Apollo Pharmacy 24x7',
                    'address'       => 'Plot 12, Phase 2, Hitech City Main Rd, Hyderabad',
                    'area'          => 'Hitech City',
                    'city'          => 'Hyderabad',
                    'pincode'       => '500081',
                    'rating'        => 4.8,
                    'review_count'  => 420,
                    'distance_km'   => 0.8,
                    'eta_minutes'   => 12,
                    'is_24x7'       => 1,
                    'is_open'       => 1,
                    'opening_time'  => '12:00 AM',
                    'closing_time'  => '11:59 PM',
                    'phone'         => '+91 40 2360 8888',
                    'license_number'=> 'TS-HYD-PHARM-2024-8801',
                    'image_url'     => 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400',
                    'verification_status' => 'verified'
                ],
                [
                    'id'            => 'STORE-02',
                    'name'          => 'MedPlus Chemist & Superstore',
                    'address'       => 'Road No 36, Opp. Metro Pillar 1400, Jubilee Hills, Hyderabad',
                    'area'          => 'Jubilee Hills',
                    'city'          => 'Hyderabad',
                    'pincode'       => '500033',
                    'rating'        => 4.7,
                    'review_count'  => 310,
                    'distance_km'   => 1.5,
                    'eta_minutes'   => 15,
                    'is_24x7'       => 1,
                    'is_open'       => 1,
                    'opening_time'  => '06:00 AM',
                    'closing_time'  => '11:30 PM',
                    'phone'         => '+91 40 4455 6677',
                    'license_number'=> 'TS-HYD-PHARM-2024-4421',
                    'image_url'     => 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=80&w=400',
                    'verification_status' => 'verified'
                ]
            ];
        }

        foreach ($dbStores as &$store) {
            $sLat = floatval($store['latitude'] ?? 17.4400);
            $sLng = floatval($store['longitude'] ?? 78.3489);
            $dist = MapboxHelper::getDistanceKm($lat, $lng, $sLat, $sLng);
            $eta = max(10, min(35, intval(round($dist * 2.2 + 8))));
            $store['distance_km'] = round($dist, 1);
            $store['eta_minutes'] = $eta;
            $store['is_24x7'] = (bool)($store['is_24x7'] ?? false);
            $store['is_open'] = (bool)($store['is_open'] ?? true);
        }

        Response::json([
            'stores' => $dbStores,
            'total'  => count($dbStores)
        ]);
    }

    /**
     * Store Partner Onboarding (Registers store with pending verification)
     */
    public static function onboardStore(): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];

        $userId = trim($body['user_id'] ?? '');
        $name = trim($body['name'] ?? '');
        $license = trim($body['license_number'] ?? $body['license'] ?? '');
        $phone = trim($body['phone'] ?? '');
        $email = trim($body['email'] ?? '');
        $address = trim($body['address'] ?? '');
        $area = trim($body['area'] ?? 'Hyderabad');
        $city = trim($body['city'] ?? 'Hyderabad');
        $pincode = trim($body['pincode'] ?? '500081');
        $is24x7 = !empty($body['is_24x7']) ? 1 : 0;
        $openingTime = trim($body['opening_time'] ?? '08:00 AM');
        $closingTime = trim($body['closing_time'] ?? '10:00 PM');
        $imageUrl = trim($body['image_url'] ?? 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400');
        $lat = isset($body['latitude']) ? floatval($body['latitude']) : 17.4400;
        $lng = isset($body['longitude']) ? floatval($body['longitude']) : 78.3489;

        if (empty($name) || empty($license) || empty($phone) || empty($address)) {
            Response::error('Store Name, Drug License, Phone, and Address are required', 400);
        }

        $pdo = Database::getConnection();
        $storeId = 'STORE-' . rand(1000, 9999);

        // Ensure user exists or create fallback store user
        if (empty($userId)) {
            $userId = 'USR-STORE-' . rand(1000, 9999);
            try {
                $userStmt = $pdo->prepare("INSERT IGNORE INTO users (id, name, phone, email, role) VALUES (?, ?, ?, ?, 'store')");
                $userStmt->execute([$userId, $name . ' Partner', $phone, $email]);
            } catch (\Exception $e) {
                // proceed
            }
        }

        try {
            $stmt = $pdo->prepare("INSERT INTO pharmacy_stores 
                (id, user_id, name, license_number, phone, email, address, area, city, pincode, latitude, longitude, is_24x7, opening_time, closing_time, is_open, verification_status, image_url, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'pending', ?, NOW())");
            
            $stmt->execute([
                $storeId, $userId, $name, $license, $phone, $email, $address, $area, $city, $pincode,
                $lat, $lng, $is24x7, $openingTime, $closingTime, $imageUrl
            ]);

            // Seed initial starter medicines for this store
            $starterProducts = [
                ['Paracetamol 650mg (Dolo)', 'Fever & Pain', 30.00, 10],
                ['Azithromycin 500mg', 'Antibiotics', 120.00, 15],
                ['Cetirizine 10mg (Okacet)', 'Allergy & Cold', 25.00, 5],
                ['Omeprazole 20mg (Omez)', 'Gastro / Antacid', 55.00, 10],
                ['Vitamin C + Zinc Chewable', 'Immunity Boost', 75.00, 20]
            ];

            $pStmt = $pdo->prepare("INSERT INTO pharmacy_store_products (id, store_id, name, category, price, discount_percent, in_stock, created_at) VALUES (?, ?, ?, ?, ?, ?, 1, NOW())");
            foreach ($starterProducts as $sp) {
                $pStmt->execute(['PROD-' . rand(10000, 99999), $storeId, $sp[0], $sp[1], $sp[2], $sp[3]]);
            }

            Response::json([
                'id'                  => $storeId,
                'user_id'             => $userId,
                'name'                => $name,
                'license_number'      => $license,
                'phone'               => $phone,
                'email'               => $email,
                'address'             => $address,
                'area'                => $area,
                'city'                => $city,
                'is_24x7'             => (bool)$is24x7,
                'opening_time'        => $openingTime,
                'closing_time'        => $closingTime,
                'is_open'             => true,
                'verification_status' => 'pending',
                'image_url'           => $imageUrl,
                'message'             => 'Store onboarding submitted. Pending Super Admin verification.'
            ], 201, 'Store onboarding submitted for review');
        } catch (\Exception $e) {
            Response::error('Failed to submit store onboarding: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get Store Profile for current user
     */
    public static function getMyStore(string $userId): void {
        $pdo = Database::getConnection();
        try {
            $stmt = $pdo->prepare("SELECT * FROM pharmacy_stores WHERE user_id = ? OR id = ? LIMIT 1");
            $stmt->execute([$userId, $userId]);
            $store = $stmt->fetch();

            if (!$store) {
                // If not in DB, return fallback default store for seamless testing
                Response::json([
                    'id'                  => 'STORE-01',
                    'user_id'             => $userId,
                    'name'                => 'Apollo Pharmacy 24x7',
                    'license_number'      => 'TS-HYD-PHARM-2024-8801',
                    'phone'               => '+91 40 2360 8888',
                    'email'               => 'partner@apollopharmacy.com',
                    'address'             => 'Plot 12, Phase 2, Hitech City Main Rd',
                    'area'                => 'Hitech City',
                    'city'                => 'Hyderabad',
                    'pincode'             => '500081',
                    'is_24x7'             => true,
                    'opening_time'        => '12:00 AM',
                    'closing_time'        => '11:59 PM',
                    'is_open'             => true,
                    'verification_status' => 'verified',
                    'image_url'           => 'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400'
                ]);
                return;
            }

            $store['is_24x7'] = (bool)$store['is_24x7'];
            $store['is_open'] = (bool)$store['is_open'];
            Response::json($store);
        } catch (\Exception $e) {
            Response::error('Failed to fetch store details: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Update Store Details, Timings, Open/Closed Status
     */
    public static function updateMyStore(string $storeId): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $pdo = Database::getConnection();

        $openingTime = $body['opening_time'] ?? null;
        $closingTime = $body['closing_time'] ?? null;
        $is24x7 = isset($body['is_24x7']) ? ($body['is_24x7'] ? 1 : 0) : null;
        $isOpen = isset($body['is_open']) ? ($body['is_open'] ? 1 : 0) : null;
        $phone = $body['phone'] ?? null;
        $email = $body['email'] ?? null;
        $address = $body['address'] ?? null;

        try {
            $fields = [];
            $params = [];

            if ($openingTime !== null) { $fields[] = "opening_time = ?"; $params[] = $openingTime; }
            if ($closingTime !== null) { $fields[] = "closing_time = ?"; $params[] = $closingTime; }
            if ($is24x7 !== null) { $fields[] = "is_24x7 = ?"; $params[] = $is24x7; }
            if ($isOpen !== null) { $fields[] = "is_open = ?"; $params[] = $isOpen; }
            if ($phone !== null) { $fields[] = "phone = ?"; $params[] = $phone; }
            if ($email !== null) { $fields[] = "email = ?"; $params[] = $email; }
            if ($address !== null) { $fields[] = "address = ?"; $params[] = $address; }

            if (empty($fields)) {
                Response::error('No fields provided to update', 400);
            }

            $params[] = $storeId;
            $sql = "UPDATE pharmacy_stores SET " . implode(', ', $fields) . " WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);

            Response::json(['id' => $storeId, 'status' => 'updated'], 200, 'Store settings updated successfully');
        } catch (\Exception $e) {
            Response::error('Failed to update store: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get Store Products / Inventory
     */
    public static function getStoreProducts(string $storeId): void {
        $pdo = Database::getConnection();
        try {
            $stmt = $pdo->prepare("SELECT * FROM pharmacy_store_products WHERE store_id = ? ORDER BY in_stock DESC, name ASC");
            $stmt->execute([$storeId]);
            $products = $stmt->fetchAll();

            if (empty($products)) {
                // Fallback demo product set
                $products = [
                    ['id' => 'PROD-101', 'store_id' => $storeId, 'name' => 'Dolo 650mg Paracetamol Tablets', 'category' => 'Fever & Pain', 'price' => 32.00, 'discount_percent' => 10, 'in_stock' => 1, 'stock_quantity' => 150],
                    ['id' => 'PROD-102', 'store_id' => $storeId, 'name' => 'Azithral 500mg Antibiotic Strip', 'category' => 'Antibiotics', 'price' => 119.00, 'discount_percent' => 15, 'in_stock' => 1, 'stock_quantity' => 80],
                    ['id' => 'PROD-103', 'store_id' => $storeId, 'name' => 'Allegra 120mg Antihistamine', 'category' => 'Allergy & Cold', 'price' => 195.00, 'discount_percent' => 12, 'in_stock' => 1, 'stock_quantity' => 60],
                    ['id' => 'PROD-104', 'store_id' => $storeId, 'name' => 'Pan-D Gastro-Resistant Capsule', 'category' => 'Gastro / Antacid', 'price' => 180.00, 'discount_percent' => 8, 'in_stock' => 1, 'stock_quantity' => 95],
                    ['id' => 'PROD-105', 'store_id' => $storeId, 'name' => 'Volini Pain Relief Gel 50g', 'category' => 'Pain Relief', 'price' => 140.00, 'discount_percent' => 15, 'in_stock' => 0, 'stock_quantity' => 0]
                ];
            }

            foreach ($products as &$p) {
                $p['in_stock'] = (bool)($p['in_stock'] ?? 1);
            }

            Response::json($products);
        } catch (\Exception $e) {
            Response::error('Failed to get store products: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Add Product to Store Inventory
     */
    public static function addStoreProduct(string $storeId): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $name = trim($body['name'] ?? '');
        $category = trim($body['category'] ?? 'General Medicine');
        $price = floatval($body['price'] ?? 0);
        $discount = intval($body['discount_percent'] ?? 0);
        $quantity = intval($body['stock_quantity'] ?? 50);

        if (empty($name) || $price <= 0) {
            Response::error('Product name and valid price are required', 400);
        }

        $pdo = Database::getConnection();
        $prodId = 'PROD-' . rand(10000, 99999);

        try {
            $stmt = $pdo->prepare("INSERT INTO pharmacy_store_products (id, store_id, name, category, price, discount_percent, in_stock, stock_quantity, created_at) VALUES (?, ?, ?, ?, ?, ?, 1, ?, NOW())");
            $stmt->execute([$prodId, $storeId, $name, $category, $price, $discount, $quantity]);

            Response::json([
                'id'               => $prodId,
                'store_id'         => $storeId,
                'name'             => $name,
                'category'         => $category,
                'price'            => $price,
                'discount_percent' => $discount,
                'in_stock'         => true,
                'stock_quantity'   => $quantity
            ], 201, 'Product added to store catalog');
        } catch (\Exception $e) {
            Response::error('Failed to add product: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Toggle Product Stock Availability
     */
    public static function toggleProductStock(string $productId): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $inStock = isset($body['in_stock']) ? ($body['in_stock'] ? 1 : 0) : 1;

        $pdo = Database::getConnection();
        try {
            $stmt = $pdo->prepare("UPDATE pharmacy_store_products SET in_stock = ? WHERE id = ?");
            $stmt->execute([$inStock, $productId]);
            Response::json(['id' => $productId, 'in_stock' => (bool)$inStock], 200, 'Stock status updated');
        } catch (\Exception $e) {
            Response::error('Failed to update stock: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Super Admin: Get All Pending Stores
     */
    public static function getPendingStores(): void {
        $pdo = Database::getConnection();
        try {
            $stmt = $pdo->query("SELECT * FROM pharmacy_stores WHERE verification_status = 'pending' ORDER BY created_at DESC");
            $stores = $stmt->fetchAll();
            Response::json($stores);
        } catch (\Exception $e) {
            Response::json([]);
        }
    }

    /**
     * Super Admin: Verify / Reject Store
     */
    public static function verifyStore(string $storeId): void {
        $body = json_decode(file_get_contents('php://input'), true) ?? [];
        $status = strtolower(trim($body['status'] ?? 'verified'));
        $notes = trim($body['notes'] ?? 'Store verified by Super Admin');

        if (!in_array($status, ['pending', 'verified', 'rejected'])) {
            Response::error('Invalid verification status', 400);
        }

        $pdo = Database::getConnection();
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare("UPDATE pharmacy_stores SET verification_status = ?, rejection_reason = ? WHERE id = ?");
            $stmt->execute([$status, ($status === 'rejected' ? $notes : null), $storeId]);

            $audit = $pdo->prepare("INSERT INTO audit_logs (id, user_id, action, entity_type, entity_id, created_at) VALUES (?, 'SUPER_ADMIN', ?, 'pharmacy_store', ?, NOW())");
            $audit->execute(['LOG-' . rand(100000, 999999), "STORE_KYC_" . strtoupper($status), $storeId]);

            $pdo->commit();
            Response::json(['id' => $storeId, 'verification_status' => $status, 'notes' => $notes], 200, "Store successfully marked as $status");
        } catch (\Exception $e) {
            $pdo->rollBack();
            Response::error('Failed to update store verification: ' . $e->getMessage(), 500);
        }
    }
}
