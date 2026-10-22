-- HealthExpress AI - Store Role & Pharmacy Stores Migration
-- Enables store partner accounts, onboarding, verification, and store product management

-- 1. Modify users role enum to support 'store'
ALTER TABLE users MODIFY COLUMN role ENUM('patient', 'doctor', 'hospital_admin', 'super_admin', 'store') DEFAULT 'patient';

-- 2. Create pharmacy_stores table
CREATE TABLE IF NOT EXISTS pharmacy_stores (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    license_number VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(150),
    address TEXT NOT NULL,
    area VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    pincode VARCHAR(20) NOT NULL,
    latitude DECIMAL(10,8) DEFAULT 17.4400,
    longitude DECIMAL(11,8) DEFAULT 78.3489,
    is_24x7 TINYINT(1) DEFAULT 0,
    opening_time VARCHAR(20) DEFAULT '08:00 AM',
    closing_time VARCHAR(20) DEFAULT '10:00 PM',
    is_open TINYINT(1) DEFAULT 1,
    verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'pending',
    rejection_reason TEXT,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Create pharmacy_store_products table
CREATE TABLE IF NOT EXISTS pharmacy_store_products (
    id VARCHAR(50) PRIMARY KEY,
    store_id VARCHAR(50) NOT NULL,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100) DEFAULT 'General Medicine',
    price DECIMAL(10,2) NOT NULL,
    discount_percent INT DEFAULT 0,
    in_stock TINYINT(1) DEFAULT 1,
    stock_quantity INT DEFAULT 100,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (store_id) REFERENCES pharmacy_stores(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Seed initial verified store for instant testing
INSERT IGNORE INTO users (id, name, phone, email, role)
VALUES ('USR-STORE-101', 'Apollo Chemist Partner', '+91 98480 99887', 'store@apollopharmacy.com', 'store');

INSERT IGNORE INTO pharmacy_stores (id, user_id, name, license_number, phone, email, address, area, city, pincode, is_24x7, opening_time, closing_time, is_open, verification_status, image_url)
VALUES (
    'STORE-01',
    'USR-STORE-101',
    'Apollo Pharmacy 24x7',
    'TS-HYD-PHARM-2024-8801',
    '+91 40 2360 8888',
    'support@apollopharmacy.com',
    'Plot 12, Phase 2, Hitech City Main Rd',
    'Hitech City',
    'Hyderabad',
    '500081',
    1,
    '12:00 AM',
    '11:59 PM',
    1,
    'verified',
    'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=400'
);
