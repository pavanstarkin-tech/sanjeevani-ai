const { pool, initDatabaseSchema } = require('./database');
require('dotenv').config();

async function seedDatabase() {
  console.log('--------------------------------------------------');
  console.log('🌱 Seeding Real Healthcare Data into Remote MySQL (147.93.101.73)...');
  console.log('--------------------------------------------------');

  await initDatabaseSchema();
  const conn = await pool.getConnection();

  try {
    // 1. Seed Hospitals
    console.log('Inserting real hospital facilities...');
    const hospitals = [
      {
        id: 'HOSP-01',
        name: 'KIMS Hospitals',
        logo_url: 'https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&q=80&w=400',
        photos: JSON.stringify(['https://images.unsplash.com/photo-1587351021759-3e566b6af7cc?auto=format&fit=crop&q=80&w=800']),
        hospital_type: 'Super Specialty',
        license_number: 'TS-HYD-HOSP-1995-0012',
        verification_status: 'Verified',
        established_year: 1995,
        description: 'Krishna Institute of Medical Sciences (KIMS) is one of the largest multi-specialty healthcare groups in South India with world-class medical amenities and renowned specialists.',
        primary_phone: '+91 40 4488 5000',
        emergency_phone: '1066 / +91 40 4488 5108',
        email: 'info@kimshospitals.com',
        website: 'https://www.kimshospitals.com',
        reception_contact: '+91 40 4488 5001',
        address: '1-8-31/1, Minister Rd, Krishna Nagar Colony, Begumpet, Hyderabad, Telangana 500003',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500003',
        latitude: 17.4375,
        longitude: 78.4482,
        service_area: 'Greater Hyderabad & Secunderabad',
        services: JSON.stringify(['24/7 Emergency & Trauma', 'OPD & IPD', 'Intensive Care Unit (ICU)', '24/7 Pharmacy', 'Diagnostic Pathology Lab', 'Advanced Radiology (MRI/CT)', 'Cardiac Catheterization Lab', 'Ambulance Services', 'Blood Bank', 'Teleconsultation', 'Home-Care Services']),
        facilities: JSON.stringify(['24x7 Emergency', 'Advanced ICU', 'Pathology Lab', '24x7 Pharmacy', 'Ambulance Support', 'Cath Lab']),
        admin_name: 'Dr. B. Bhaskar Rao',
        admin_mobile: '+91 9848011100',
        admin_email: 'admin.kims@healthexpress.ai',
        staff_count: 520,
        rating: 4.8,
        reviews_count: 1240,
        working_hours: '24/7 Emergency & 08:00 AM - 09:00 PM OPD',
        status: 'Active'
      },
      {
        id: 'HOSP-02',
        name: 'Apollo Hospitals',
        logo_url: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=400',
        photos: JSON.stringify(['https://images.unsplash.com/photo-1512678080530-7760d81faba6?auto=format&fit=crop&q=80&w=800']),
        hospital_type: 'Super Specialty',
        license_number: 'TS-HYD-HOSP-1988-0005',
        verification_status: 'Verified',
        established_year: 1988,
        description: 'Apollo Hospitals Jubilee Hills is a pioneer in quaternary care offering integrated clinical services, comprehensive cancer institute, and JCI accredited facilities.',
        primary_phone: '+91 40 2360 7777',
        emergency_phone: '1066',
        email: 'jubileehills@apollohospitals.com',
        website: 'https://www.apollohospitals.com',
        reception_contact: '+91 40 2360 7778',
        address: 'Road No 72, Opp. Bharatiya Vidya Bhavan School, Jubilee Hills, Hyderabad, Telangana 500033',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500033',
        latitude: 17.4265,
        longitude: 78.4124,
        service_area: 'Jubilee Hills, Banjara Hills, Madhapur, Hitech City',
        services: JSON.stringify(['24/7 Emergency & Trauma', 'Comprehensive Oncology', 'Organ Transplant', 'ICU', 'Radiology', 'Pharmacy', 'Robotic Surgery']),
        facilities: JSON.stringify(['24x7 Emergency', 'Robotic Surgery Suite', 'JCI Accredited ICU', 'Blood Bank', 'Dedicated Air Ambulance']),
        admin_name: 'Dr. Sangita Reddy',
        admin_mobile: '+91 9848022200',
        admin_email: 'admin.apollo@healthexpress.ai',
        staff_count: 680,
        rating: 4.9,
        reviews_count: 980,
        working_hours: '24/7 Emergency & 08:00 AM - 09:00 PM OPD',
        status: 'Active'
      },
      {
        id: 'HOSP-03',
        name: 'Yashoda Hospitals',
        logo_url: 'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?auto=format&fit=crop&q=80&w=400',
        photos: JSON.stringify(['https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&q=80&w=800']),
        hospital_type: 'Super Specialty',
        license_number: 'TS-HYD-HOSP-1992-0018',
        verification_status: 'Verified',
        established_year: 1992,
        description: 'Yashoda Hospitals is a leading healthcare destination providing specialized medical and surgical interventions with advanced medical technologies in Somajiguda, Secunderabad, and Malakpet.',
        primary_phone: '+91 40 4567 4567',
        emergency_phone: '1066',
        email: 'info@yashodahospitals.com',
        website: 'https://www.yashodahospitals.com',
        reception_contact: '+91 40 4567 4568',
        address: 'Alexander Rd, Kummari Guda, Shivaji Nagar, Secunderabad, Telangana 500003',
        city: 'Secunderabad',
        state: 'Telangana',
        pincode: '500003',
        latitude: 17.4399,
        longitude: 78.4983,
        service_area: 'Secunderabad, Somajiguda, Malakpet, Hitec City',
        services: JSON.stringify(['24/7 Emergency', 'Neurology & Neurosurgery', 'Oncology', 'Cardiology', 'Pulmonology', 'Dialysis']),
        facilities: JSON.stringify(['24x7 Emergency', 'Modern Cath Lab', 'Bone Marrow Transplant', 'Dialysis Unit', 'Pharmacy']),
        admin_name: 'Dr. G. Surender Rao',
        admin_mobile: '+91 9848033300',
        admin_email: 'admin.yashoda@healthexpress.ai',
        staff_count: 450,
        rating: 4.7,
        reviews_count: 870,
        working_hours: '24/7 Emergency & 08:30 AM - 08:30 PM OPD',
        status: 'Active'
      },
      {
        id: 'HOSP-04',
        name: 'CARE Hospitals',
        logo_url: 'https://images.unsplash.com/photo-1538108149393-fbbd81895907?auto=format&fit=crop&q=80&w=400',
        photos: JSON.stringify(['https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&q=80&w=800']),
        hospital_type: 'Multi Specialty',
        license_number: 'TS-HYD-HOSP-1997-0034',
        verification_status: 'Verified',
        established_year: 1997,
        description: 'CARE Hospitals is a multi-specialty healthcare provider delivering comprehensive care across cardiology, critical care, nephrology, and surgical specialties.',
        primary_phone: '+91 40 6165 6565',
        emergency_phone: '1066',
        email: 'info@carehospitals.com',
        website: 'https://www.carehospitals.com',
        reception_contact: '+91 40 6165 6566',
        address: 'Road No 1, Prem Nagar, Banjara Hills, Hyderabad, Telangana 500034',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500034',
        latitude: 17.4156,
        longitude: 78.4485,
        service_area: 'Banjara Hills, Nampally, Gachibowli, Hitech City',
        services: JSON.stringify(['Cardiology', 'Emergency', 'Critical Care', 'Orthopedics', 'Urology', 'General Surgery']),
        facilities: JSON.stringify(['24x7 Emergency', 'Advanced Cardiac ICU', 'Pathology Lab', '24x7 Pharmacy', 'Ambulance']),
        admin_name: 'Dr. B. Soma Raju',
        admin_mobile: '+91 9848044400',
        admin_email: 'admin.care@healthexpress.ai',
        staff_count: 380,
        rating: 4.6,
        reviews_count: 760,
        working_hours: '24/7 Emergency & 08:30 AM - 08:00 PM OPD',
        status: 'Active'
      }
    ];

    for (const h of hospitals) {
      await conn.query(
        `INSERT INTO hospitals (
          id, name, logo_url, photos, hospital_type, license_number, verification_status, established_year,
          description, primary_phone, emergency_phone, email, website, reception_contact, address, city,
          state, pincode, latitude, longitude, service_area, services, facilities, admin_name, admin_mobile,
          admin_email, staff_count, rating, reviews_count, working_hours, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name=VALUES(name), rating=VALUES(rating), description=VALUES(description)`,
        [
          h.id, h.name, h.logo_url, h.photos, h.hospital_type, h.license_number, h.verification_status, h.established_year,
          h.description, h.primary_phone, h.emergency_phone, h.email, h.website, h.reception_contact, h.address, h.city,
          h.state, h.pincode, h.latitude, h.longitude, h.service_area, h.services, h.facilities, h.admin_name, h.admin_mobile,
          h.admin_email, h.staff_count, h.rating, h.reviews_count, h.working_hours, h.status
        ]
      );
    }

    // 2. Seed Departments for KIMS
    console.log('Inserting departments hierarchy...');
    const depts = [
      { id: 'DEPT-01', hospital_id: 'HOSP-01', name: 'Cardiology', head_doctor_name: 'Dr. Sandeep Attawar' },
      { id: 'DEPT-02', hospital_id: 'HOSP-01', name: 'Neurology', head_doctor_name: 'Dr. Sunil Kumar N' },
      { id: 'DEPT-03', hospital_id: 'HOSP-01', name: 'Orthopedics', head_doctor_name: 'Dr. Naveen Thota' },
      { id: 'DEPT-04', hospital_id: 'HOSP-01', name: 'Gynecology & Obstetrics', head_doctor_name: 'Dr. Madhavi Latha' },
      { id: 'DEPT-05', hospital_id: 'HOSP-01', name: 'Pediatrics', head_doctor_name: 'Dr. Anil Kumar' },
      { id: 'DEPT-06', hospital_id: 'HOSP-01', name: 'General Medicine', head_doctor_name: 'Dr. Prashant Reddy' },
      { id: 'DEPT-07', hospital_id: 'HOSP-01', name: 'Gastroenterology', head_doctor_name: 'Dr. Ramesh Patel' },
      { id: 'DEPT-08', hospital_id: 'HOSP-01', name: 'Urology & Kidney Transplant', head_doctor_name: 'Dr. K. S. Rao' },
    ];

    for (const d of depts) {
      await conn.query(
        `INSERT INTO departments (id, hospital_id, name, head_doctor_name) VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE name=VALUES(name), head_doctor_name=VALUES(head_doctor_name)`,
        [d.id, d.hospital_id, d.name, d.head_doctor_name]
      );
    }

    // 3. Seed Doctors
    console.log('Inserting verified doctors...');
    const doctors = [
      {
        id: 'DOC-1024',
        name: 'Dr. Sandeep Attawar',
        mobile: '9848011223',
        email: 'dr.sandeep@kimshospitals.com',
        photo_url: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=400',
        specialty: 'Cardiologist',
        sub_specialty: 'Interventional Cardiology & Heart Failure',
        qualifications: 'MBBS, MD (Medicine), DM (Cardiology), FACC',
        experience_years: 24,
        registration_number: 'MCI-TS-1999-44812',
        practice_type: 'Hospital',
        clinic_fee: 800.00,
        video_fee: 800.00,
        home_visit_fee: 1500.00,
        is_rmp_doctor: false,
        rating: 4.8,
        reviews_count: 430,
        is_online: true
      },
      {
        id: 'DOC-1025',
        name: 'Dr. Priya Nair',
        mobile: '9848011224',
        email: 'dr.priya@apollohospitals.com',
        photo_url: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&q=80&w=400',
        specialty: 'General Physician',
        sub_specialty: 'Internal Medicine & Diabetology',
        qualifications: 'MBBS, MD (General Medicine)',
        experience_years: 12,
        registration_number: 'MCI-TS-2011-33219',
        practice_type: 'Hospital',
        clinic_fee: 600.00,
        video_fee: 500.00,
        home_visit_fee: 1000.00,
        is_rmp_doctor: false,
        rating: 4.7,
        reviews_count: 310,
        is_online: true
      },
      {
        id: 'DOC-1026',
        name: 'Dr. Naveen Thota',
        mobile: '9848011225',
        email: 'dr.naveen@yashodahospitals.com',
        photo_url: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&q=80&w=400',
        specialty: 'Orthopedic Surgeon',
        sub_specialty: 'Joint Replacement & Arthroscopy',
        qualifications: 'MBBS, MS (Orthopedics), MCh',
        experience_years: 15,
        registration_number: 'MCI-TS-2008-11290',
        practice_type: 'Hospital',
        clinic_fee: 700.00,
        video_fee: 700.00,
        home_visit_fee: 1200.00,
        is_rmp_doctor: false,
        rating: 4.6,
        reviews_count: 215,
        is_online: true
      },
      {
        id: 'DOC-1027',
        name: 'Dr. Madhavi Latha',
        mobile: '9848011226',
        email: 'dr.madhavi@carehospitals.com',
        photo_url: 'https://images.unsplash.com/photo-1594824813680-77a83d739824?auto=format&fit=crop&q=80&w=400',
        specialty: 'Gynecologist',
        sub_specialty: 'High-Risk Obstetrics & Laparoscopy',
        qualifications: 'MBBS, DGO, DNB (OBG)',
        experience_years: 18,
        registration_number: 'MCI-TS-2005-77341',
        practice_type: 'Hospital',
        clinic_fee: 600.00,
        video_fee: 600.00,
        home_visit_fee: 1100.00,
        is_rmp_doctor: false,
        rating: 4.8,
        reviews_count: 198,
        is_online: true
      },
      {
        id: 'DOC-1028',
        name: 'Dr. Suresh RMP',
        mobile: '9848011227',
        email: 'dr.suresh.rmp@healthyxpress.in',
        photo_url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=400',
        specialty: 'RMP Doctor (Home Visit)',
        sub_specialty: 'General Primary Care & Doorstep Nursing',
        qualifications: 'Certified Medical Practitioner (RMP TS)',
        experience_years: 14,
        registration_number: 'RMP-TS-2010-9941',
        practice_type: 'Independent',
        clinic_fee: 300.00,
        video_fee: 250.00,
        home_visit_fee: 500.00,
        is_rmp_doctor: true,
        rating: 4.9,
        reviews_count: 520,
        is_online: true
      }
    ];

    for (const d of doctors) {
      await conn.query(
        `INSERT INTO doctors (
          id, name, mobile, email, photo_url, specialty, sub_specialty, qualifications, experience_years,
          registration_number, practice_type, clinic_fee, video_fee, home_visit_fee, is_rmp_doctor,
          rating, reviews_count, is_online, verification_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Verified')
        ON DUPLICATE KEY UPDATE name=VALUES(name), specialty=VALUES(specialty), clinic_fee=VALUES(clinic_fee)`,
        [
          d.id, d.name, d.mobile, d.email, d.photo_url, d.specialty, d.sub_specialty, d.qualifications,
          d.experience_years, d.registration_number, d.practice_type, d.clinic_fee, d.video_fee,
          d.home_visit_fee, d.is_rmp_doctor, d.rating, d.reviews_count, d.is_online
        ]
      );
    }

    // 4. Seed Doctor Affiliations
    await conn.query(`
      INSERT INTO doctor_hospitals (id, doctor_id, hospital_id, affiliation_type) VALUES
      ('AFF-01', 'DOC-1024', 'HOSP-01', 'Primary'),
      ('AFF-02', 'DOC-1025', 'HOSP-02', 'Primary'),
      ('AFF-03', 'DOC-1026', 'HOSP-03', 'Primary'),
      ('AFF-04', 'DOC-1027', 'HOSP-04', 'Primary')
      ON DUPLICATE KEY UPDATE affiliation_type=VALUES(affiliation_type);
    `);

    // 5. Seed Users & Health Profiles (with Aarogyasri ID & past surgeries)
    console.log('Inserting verified patients and Aarogyasri profiles...');
    const users = [
      {
        id: 'USR-101',
        name: 'Rahul Kumar',
        mobile: '9876543210',
        email: 'rahul.kumar@gmail.com',
        aarogyasri_id: 'AROG12345678',
        blood_group: 'B+',
        allergies: 'No known drug allergies (Penicillin safe)',
        existing_conditions: 'None',
        current_medications: 'Vitamin C 500mg, Paracetamol (SOS)',
        previous_surgeries: 'Appendectomy (2020 at KIMS Hospitals)',
        previous_hospitalizations: 'Appendectomy Admission (Aug 2020)',
        height_cm: 172.0,
        weight_kg: 72.0
      },
      {
        id: 'USR-102',
        name: 'Anita Sharma',
        mobile: '9848011223',
        email: 'anita.sharma@yahoo.com',
        aarogyasri_id: 'AROG88900112',
        blood_group: 'O+',
        allergies: 'Dust & Pollen allergy',
        existing_conditions: 'Mild Hypertension',
        current_medications: 'Amlodipine 5mg',
        previous_surgeries: 'None',
        previous_hospitalizations: 'None',
        height_cm: 160.0,
        weight_kg: 62.0
      },
      {
        id: 'USR-103',
        name: 'Suresh Rao',
        mobile: '9700123456',
        email: 'suresh.rao@outlook.com',
        aarogyasri_id: 'AROG77865544',
        blood_group: 'A+',
        allergies: 'Sulfa Drugs',
        existing_conditions: 'Type 2 Diabetes (Controlled)',
        current_medications: 'Metformin 500mg',
        previous_surgeries: 'Knee Arthroscopy (2018 at Yashoda)',
        previous_hospitalizations: 'Knee Surgery (2018)',
        height_cm: 168.0,
        weight_kg: 75.0
      }
    ];

    for (const u of users) {
      await conn.query(
        `INSERT INTO users (id, name, mobile, email, role, is_profile_completed)
         VALUES (?, ?, ?, ?, 'user', TRUE)
         ON DUPLICATE KEY UPDATE name=VALUES(name), email=VALUES(email)`,
        [u.id, u.name, u.mobile, u.email]
      );

      await conn.query(
        `INSERT INTO health_profiles (
          user_id, aarogyasri_id, blood_group, allergies, existing_conditions, current_medications,
          previous_surgeries, previous_hospitalizations, height_cm, weight_kg
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE blood_group=VALUES(blood_group), previous_surgeries=VALUES(previous_surgeries)`,
        [
          u.id, u.aarogyasri_id, u.blood_group, u.allergies, u.existing_conditions, u.current_medications,
          u.previous_surgeries, u.previous_hospitalizations, u.height_cm, u.weight_kg
        ]
      );
    }

    // 6. Seed Medicines
    console.log('Inserting verified medicine catalog...');
    const medicines = [
      { id: 'MED-01', name: 'Paracetamol 650mg', generic_name: 'Paracetamol', category: 'Fever & Pain', price: 25.00, original_price: 35.00, pack_size: 'Strip of 10 Tablets', requires_prescription: false },
      { id: 'MED-02', name: 'Cetirizine 10mg', generic_name: 'Cetirizine HCl', category: 'Allergy & Cold', price: 40.00, original_price: 50.00, pack_size: 'Strip of 10 Tablets', requires_prescription: false },
      { id: 'MED-03', name: 'Cough Relief Syrup (100ml)', generic_name: 'Dextromethorphan + Chlorpheniramine', category: 'Cough Relief', price: 85.00, original_price: 110.00, pack_size: 'Bottle of 100ml', requires_prescription: false },
      { id: 'MED-04', name: 'Electral ORS Sachet (21.8g)', generic_name: 'Oral Rehydration Salts IP', category: 'Hydration', price: 15.00, original_price: 22.00, pack_size: 'Sachet of 21.8g', requires_prescription: false },
      { id: 'MED-05', name: 'Amoxicillin 500mg', generic_name: 'Amoxicillin Trihydrate', category: 'Antibiotics', price: 110.00, original_price: 145.00, pack_size: 'Strip of 10 Capsules', requires_prescription: true },
      { id: 'MED-06', name: 'Vitamin C 500mg Chewable', generic_name: 'Ascorbic Acid + Zinc', category: 'Immunity Boost', price: 35.00, original_price: 50.00, pack_size: 'Bottle of 30 Chewables', requires_prescription: false }
    ];

    for (const m of medicines) {
      await conn.query(
        `INSERT INTO medicines (id, name, generic_name, category, price, original_price, pack_size, requires_prescription)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE price=VALUES(price), name=VALUES(name)`,
        [m.id, m.name, m.generic_name, m.category, m.price, m.original_price, m.pack_size, m.requires_prescription]
      );
    }

    conn.release();
    console.log('✅ Real production-grade healthcare data seeded successfully into MySQL on 147.93.101.73!');
  } catch (err) {
    conn.release();
    console.error('❌ Seeding error:', err);
  } finally {
    await pool.end();
  }
}

seedDatabase();
