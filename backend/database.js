const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || '147.93.101.73',
  port: parseInt(process.env.DB_PORT || '3306'),
  user: process.env.DB_USER || 'u170253497_healthexpress',
  password: process.env.DB_PASSWORD || 'Healthxpress_1234567',
  database: process.env.DB_NAME || 'u170253497_healthexpress',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  connectTimeout: 10000,
});

async function initDatabaseSchema() {
  console.log('🔄 Initializing normalized multi-table database schema on 147.93.101.73...');
  try {
    const conn = await pool.getConnection();

    // 1. Users Table (Minimal Registration: Name, Mobile)
    await conn.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(64) PRIMARY KEY,
        name VARCHAR(120) NOT NULL,
        mobile VARCHAR(20) NOT NULL UNIQUE,
        email VARCHAR(120),
        profile_picture TEXT,
        dob DATE,
        gender ENUM('Male', 'Female', 'Other'),
        address TEXT,
        city VARCHAR(100) DEFAULT 'Hyderabad',
        state VARCHAR(100) DEFAULT 'Telangana',
        pincode VARCHAR(10) DEFAULT '500081',
        emergency_contact VARCHAR(20),
        role ENUM('user', 'doctor', 'admin') DEFAULT 'user',
        is_profile_completed BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 2. Health Profiles Table (Progressive Patient Health Data)
    await conn.query(`
      CREATE TABLE IF NOT EXISTS health_profiles (
        user_id VARCHAR(64) PRIMARY KEY,
        aarogyasri_id VARCHAR(64) UNIQUE,
        rgis_id VARCHAR(64),
        blood_group VARCHAR(10) DEFAULT 'B+',
        allergies TEXT,
        existing_conditions TEXT,
        current_medications TEXT,
        previous_surgeries TEXT,
        previous_hospitalizations TEXT,
        family_history TEXT,
        lifestyle_notes TEXT,
        height_cm DECIMAL(5,2) DEFAULT 172.0,
        weight_kg DECIMAL(5,2) DEFAULT 72.0,
        temperature_f DECIMAL(4,1) DEFAULT 98.6,
        heart_rate_bpm INT DEFAULT 72,
        oxygen_spo2 INT DEFAULT 99,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 3. Hospitals Table (Identity, Contact, Location, Facilities, Admin)
    await conn.query(`
      CREATE TABLE IF NOT EXISTS hospitals (
        id VARCHAR(64) PRIMARY KEY,
        name VARCHAR(150) NOT NULL,
        logo_url TEXT,
        photos JSON,
        hospital_type ENUM('Super Specialty', 'Multi Specialty', 'General Hospital', 'Clinic', 'Diagnostic Center') DEFAULT 'Super Specialty',
        license_number VARCHAR(100) NOT NULL,
        verification_status ENUM('Verified', 'Pending', 'Suspended') DEFAULT 'Verified',
        established_year INT DEFAULT 1995,
        description TEXT,
        
        primary_phone VARCHAR(20) NOT NULL,
        emergency_phone VARCHAR(20) DEFAULT '1066',
        email VARCHAR(120),
        website VARCHAR(150),
        reception_contact VARCHAR(20),

        address TEXT NOT NULL,
        city VARCHAR(100) DEFAULT 'Hyderabad',
        state VARCHAR(100) DEFAULT 'Telangana',
        pincode VARCHAR(10) DEFAULT '500081',
        latitude DECIMAL(10, 7) DEFAULT 17.4375,
        longitude DECIMAL(10, 7) DEFAULT 78.4482,
        service_area VARCHAR(100) DEFAULT 'Greater Hyderabad & Cyberabad',

        services JSON,
        facilities JSON,
        admin_name VARCHAR(120),
        admin_mobile VARCHAR(20),
        admin_email VARCHAR(120),
        staff_count INT DEFAULT 450,
        rating DECIMAL(3,2) DEFAULT 4.8,
        reviews_count INT DEFAULT 1250,
        working_hours VARCHAR(100) DEFAULT '24/7 Emergency & 08:00 AM - 09:00 PM OPD',
        status ENUM('Active', 'Inactive', 'Under Review') DEFAULT 'Active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 4. Departments Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS departments (
        id VARCHAR(64) PRIMARY KEY,
        hospital_id VARCHAR(64) NOT NULL,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        head_doctor_name VARCHAR(120),
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 5. Doctors Table (Initial Registration + Professional Profile)
    await conn.query(`
      CREATE TABLE IF NOT EXISTS doctors (
        id VARCHAR(64) PRIMARY KEY,
        name VARCHAR(120) NOT NULL,
        mobile VARCHAR(20) NOT NULL UNIQUE,
        email VARCHAR(120),
        photo_url TEXT,
        gender ENUM('Male', 'Female', 'Other'),
        specialty VARCHAR(100) NOT NULL,
        sub_specialty VARCHAR(100),
        qualifications VARCHAR(150) NOT NULL,
        experience_years INT DEFAULT 10,
        languages VARCHAR(150) DEFAULT 'English, Telugu, Hindi',
        registration_number VARCHAR(100) NOT NULL,
        practice_type ENUM('Independent', 'Hospital', 'Multiple') DEFAULT 'Hospital',
        
        clinic_fee DECIMAL(10,2) DEFAULT 800.00,
        video_fee DECIMAL(10,2) DEFAULT 800.00,
        audio_fee DECIMAL(10,2) DEFAULT 600.00,
        home_visit_fee DECIMAL(10,2) DEFAULT 1200.00,
        follow_up_fee DECIMAL(10,2) DEFAULT 400.00,
        
        is_rmp_doctor BOOLEAN DEFAULT FALSE,
        home_visit_radius_km INT DEFAULT 10,
        is_online BOOLEAN DEFAULT TRUE,
        is_emergency_available BOOLEAN DEFAULT TRUE,
        verification_status ENUM('Verified', 'Pending', 'Rejected') DEFAULT 'Verified',
        admin_remarks TEXT,
        rating DECIMAL(3,2) DEFAULT 4.8,
        reviews_count INT DEFAULT 350,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 6. Doctor-Hospital Affiliations (Junction Table for Independent vs Hospital vs Multiple)
    await conn.query(`
      CREATE TABLE IF NOT EXISTS doctor_hospitals (
        id VARCHAR(64) PRIMARY KEY,
        doctor_id VARCHAR(64) NOT NULL,
        hospital_id VARCHAR(64) NOT NULL,
        department_id VARCHAR(64),
        affiliation_type ENUM('Primary', 'Visiting', 'Consultant', 'On-Call') DEFAULT 'Primary',
        is_verified BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE,
        FOREIGN KEY (hospital_id) REFERENCES hospitals(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 7. Doctor Schedules Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS doctor_schedules (
        id VARCHAR(64) PRIMARY KEY,
        doctor_id VARCHAR(64) NOT NULL,
        hospital_id VARCHAR(64),
        day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
        start_time TIME NOT NULL DEFAULT '09:00:00',
        end_time TIME NOT NULL DEFAULT '18:00:00',
        slot_duration_minutes INT DEFAULT 30,
        buffer_minutes INT DEFAULT 5,
        is_available BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 8. Appointments Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS appointments (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64) NOT NULL,
        doctor_id VARCHAR(64) NOT NULL,
        hospital_id VARCHAR(64),
        type ENUM('In-Clinic', 'Video', 'Audio', 'Home-Visit', 'Follow-up') NOT NULL DEFAULT 'In-Clinic',
        appointment_date DATE NOT NULL,
        time_slot VARCHAR(30) NOT NULL,
        fee DECIMAL(10,2) NOT NULL,
        payment_status ENUM('paid', 'pending', 'refunded', 'subsidized') DEFAULT 'paid',
        doctor_status ENUM('pending', 'accepted', 'in_consultation', 'completed', 'rescheduled', 'rejected') DEFAULT 'accepted',
        booking_status ENUM('confirmed', 'rescheduled', 'cancelled', 'completed') DEFAULT 'confirmed',
        cancellation_reason TEXT,
        reschedule_fee_deduction DECIMAL(10,2) DEFAULT 0.00,
        is_aarogyasri_applied BOOLEAN DEFAULT FALSE,
        aarogyasri_id VARCHAR(64),
        symptoms_summary TEXT,
        meeting_room_id VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 9. Prescriptions Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS prescriptions (
        id VARCHAR(64) PRIMARY KEY,
        appointment_id VARCHAR(64) NOT NULL,
        user_id VARCHAR(64) NOT NULL,
        doctor_id VARCHAR(64) NOT NULL,
        diagnosis TEXT NOT NULL,
        medicines JSON NOT NULL,
        clinical_advice TEXT,
        recommended_tests JSON,
        follow_up_date DATE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 10. Health Records Table (OP consultation, Prescriptions, Lab reports, Discharge summary)
    await conn.query(`
      CREATE TABLE IF NOT EXISTS health_records (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64) NOT NULL,
        record_type ENUM('OP Consultation', 'Prescription', 'Lab Report', 'Radiology', 'Discharge Summary', 'Vaccination', 'Surgery Note') NOT NULL,
        title VARCHAR(150) NOT NULL,
        doctor_id VARCHAR(64),
        hospital_id VARCHAR(64),
        file_url TEXT,
        record_date DATE NOT NULL,
        summary TEXT,
        metadata JSON,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 11. AI Sessions & Triage Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS ai_sessions (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64) NOT NULL,
        symptoms JSON NOT NULL,
        duration VARCHAR(50),
        severity ENUM('Mild', 'Moderate', 'Severe', 'Emergency') DEFAULT 'Moderate',
        user_answers JSON,
        ai_summary TEXT NOT NULL,
        recommended_care TEXT,
        recommended_doctor_id VARCHAR(64),
        recommended_hospital_id VARCHAR(64),
        recommended_tests JSON,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 12. QR Consent Tokens Table (Consent-based ABDM Architecture)
    await conn.query(`
      CREATE TABLE IF NOT EXISTS qr_consent_tokens (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64) NOT NULL,
        secure_token VARCHAR(120) NOT NULL UNIQUE,
        expires_at TIMESTAMP NOT NULL,
        is_used BOOLEAN DEFAULT FALSE,
        scanned_by_doctor_id VARCHAR(64),
        consent_status ENUM('Granted', 'Revoked', 'Expired') DEFAULT 'Granted',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 13. Payments & Refunds Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id VARCHAR(64) PRIMARY KEY,
        appointment_id VARCHAR(64),
        user_id VARCHAR(64) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        currency VARCHAR(10) DEFAULT 'INR',
        payment_method ENUM('UPI', 'Card', 'Netbanking', 'Wallet', 'Aarogyasri Subsidized') NOT NULL,
        razorpay_order_id VARCHAR(100),
        razorpay_payment_id VARCHAR(100),
        status ENUM('success', 'pending', 'failed', 'refunded') DEFAULT 'success',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 14. Support Tickets Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS tickets (
        id VARCHAR(64) PRIMARY KEY,
        user_id VARCHAR(64) NOT NULL,
        category VARCHAR(60) NOT NULL,
        subject VARCHAR(200) NOT NULL,
        description TEXT NOT NULL,
        priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
        status ENUM('open', 'in_progress', 'resolved', 'closed') DEFAULT 'open',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    // 15. Audit Logs Table
    await conn.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id VARCHAR(64) PRIMARY KEY,
        actor_id VARCHAR(64) NOT NULL,
        actor_role VARCHAR(30) NOT NULL,
        action VARCHAR(100) NOT NULL,
        entity_type VARCHAR(50) NOT NULL,
        entity_id VARCHAR(64) NOT NULL,
        details JSON,
        ip_address VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    `);

    conn.release();
    console.log('✅ All 15 Normalized MySQL Tables initialized successfully on 147.93.101.73!');
  } catch (err) {
    console.error('❌ Error initializing normalized database schema:', err.message);
  }
}

module.exports = {
  pool,
  initDatabaseSchema,
};
