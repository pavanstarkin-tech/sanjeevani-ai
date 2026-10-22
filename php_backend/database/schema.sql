-- HealthExpress AI - Production Relational MySQL Schema (16 Tables)
-- Compatible with Hostinger MySQL / MariaDB 10.6+

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(150),
    role ENUM('patient', 'doctor', 'hospital_admin', 'super_admin', 'store') DEFAULT 'patient',
    aarogyasri_id VARCHAR(50) UNIQUE,
    dob DATE,
    gender ENUM('male', 'female', 'other'),
    profile_photo_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS health_profiles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50) UNIQUE NOT NULL,
    blood_group VARCHAR(10),
    height_cm DECIMAL(5,2),
    weight_kg DECIMAL(5,2),
    allergies TEXT,
    chronic_conditions TEXT,
    past_surgeries TEXT,
    current_medications TEXT,
    emergency_contact_name VARCHAR(150),
    emergency_contact_phone VARCHAR(20),
    completion_percent INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS hospitals (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    logo_url TEXT,
    cover_image_url TEXT,
    hospital_type VARCHAR(100) NOT NULL,
    license_number VARCHAR(100) UNIQUE NOT NULL,
    verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'verified',
    established_year INT,
    description TEXT,
    primary_phone VARCHAR(20) NOT NULL,
    emergency_phone VARCHAR(20),
    email VARCHAR(150),
    website VARCHAR(200),
    reception_contact VARCHAR(20),
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    pincode VARCHAR(20) NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    services JSON,
    facilities JSON,
    total_beds INT DEFAULT 100,
    icu_beds INT DEFAULT 20,
    emergency_beds INT DEFAULT 10,
    status ENUM('Active', 'Inactive') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS departments (
    id VARCHAR(50) PRIMARY KEY,
    hospital_id VARCHAR(50) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS doctors (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) UNIQUE,
    name VARCHAR(150) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    qualification VARCHAR(150) NOT NULL,
    experience_years INT DEFAULT 0,
    registration_number VARCHAR(100) UNIQUE NOT NULL,
    consultation_fee DECIMAL(10,2) NOT NULL,
    practice_type ENUM('hospital_affiliated', 'independent', 'both') DEFAULT 'hospital_affiliated',
    verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'verified',
    rating DECIMAL(2,1) DEFAULT 5.0,
    reviews_count INT DEFAULT 0,
    is_online TINYINT(1) DEFAULT 1,
    photo_url TEXT,
    about TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS doctor_hospitals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id VARCHAR(50) NOT NULL,
    hospital_id VARCHAR(50) NOT NULL,
    department_id VARCHAR(50),
    is_primary TINYINT(1) DEFAULT 1,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS doctor_schedules (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id VARCHAR(50) NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    slot_duration_minutes INT DEFAULT 30,
    consultation_type ENUM('in_clinic', 'video', 'home_visit', 'all') DEFAULT 'all',
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS appointments (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    doctor_id VARCHAR(50) NOT NULL,
    hospital_id VARCHAR(50),
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    consultation_type ENUM('in_clinic', 'video', 'home_visit', 'audio') DEFAULT 'in_clinic',
    status ENUM('pending', 'confirmed', 'completed', 'cancelled', 'rescheduled') DEFAULT 'confirmed',
    fee DECIMAL(10,2) NOT NULL,
    has_aarogyasri TINYINT(1) DEFAULT 0,
    room_id VARCHAR(100),
    cancellation_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS prescriptions (
    id VARCHAR(50) PRIMARY KEY,
    appointment_id VARCHAR(50) NOT NULL,
    medicines JSON NOT NULL,
    clinical_notes TEXT,
    diagnostic_tests JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS health_records (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    record_type ENUM('consultation', 'prescription', 'lab_report', 'radiology', 'discharge_summary', 'vaccination', 'invoice', 'other') NOT NULL,
    title VARCHAR(200) NOT NULL,
    file_url TEXT NOT NULL,
    is_abdm_linked TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS qr_consent_tokens (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    token VARCHAR(100) UNIQUE NOT NULL,
    expires_at DATETIME NOT NULL,
    is_used TINYINT(1) DEFAULT 0,
    used_by_doctor_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS medicines (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    form VARCHAR(50) NOT NULL,
    pack_size VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    manufacturer VARCHAR(150),
    is_prescription_required TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS tickets (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    subject VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    priority ENUM('low', 'medium', 'high', 'emergency') DEFAULT 'medium',
    status ENUM('open', 'pending', 'resolved', 'closed') DEFAULT 'open',
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50) NOT NULL,
    appointment_id VARCHAR(50),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    status ENUM('paid', 'pending', 'failed', 'refunded') DEFAULT 'paid',
    payment_method VARCHAR(50) DEFAULT 'razorpay',
    razorpay_payment_id VARCHAR(100),
    razorpay_order_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
    id VARCHAR(50) PRIMARY KEY,
    user_id VARCHAR(50),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id VARCHAR(50),
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_messages (
    id VARCHAR(50) PRIMARY KEY,
    appointment_id VARCHAR(50),
    sender_id VARCHAR(50) NOT NULL,
    receiver_id VARCHAR(50) NOT NULL,
    message TEXT,
    media_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

SET FOREIGN_KEY_CHECKS = 1;
