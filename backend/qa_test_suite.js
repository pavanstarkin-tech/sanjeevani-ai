const http = require('http');
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { pool, initDatabaseSchema } = require('./database');
const authRoutes = require('./routes/auth_routes');
const hospitalRoutes = require('./routes/hospital_routes');
const doctorRoutes = require('./routes/doctor_routes');
const appointmentRoutes = require('./routes/appointment_routes');
const paymentRoutes = require('./routes/payment_routes');
const telehealthRoutes = require('./routes/telehealth_routes');
const pharmacyRoutes = require('./routes/pharmacy_routes');
const ticketRoutes = require('./routes/ticket_routes');
const qrConsentRoutes = require('./routes/qr_consent_routes');
const adminRoutes = require('./routes/admin_routes');
const userRoutes = require('./routes/user_routes');
const aiRoutes = require('./routes/ai_routes');

const app = express();
app.use(cors());
app.use(express.json());

// Mount All Backend Routes
app.use('/api/auth', authRoutes);
app.use('/api/hospitals', hospitalRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/telehealth', telehealthRoutes);
app.use('/api/pharmacy', pharmacyRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/consent', qrConsentRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/ai', aiRoutes);

app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'HealthExpress AI Backend',
    database: 'Connected to MySQL (147.93.101.73)',
    timestamp: new Date().toISOString()
  });
});

let server;
const PORT = 5055; // Dedicated QA port

function makeRequest(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({ statusCode: res.statusCode, headers: res.headers, body: parsed });
        } catch (e) {
          resolve({ statusCode: res.statusCode, headers: res.headers, body: data });
        }
      });
    });

    req.on('error', (err) => reject(err));

    if (postData) {
      req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    }
    req.end();
  });
}

async function runQA() {
  console.log('================================================================================');
  console.log('🧪 HEALTHEXPRESS AI — END-TO-END QA TEST SUITE FOR ALL BACKEND API ENDPOINTS');
  console.log('🌐 Remote Database Target: MariaDB 11.8.8 @ 147.93.101.73:3306');
  console.log('================================================================================\n');

  // Initialize DB connection
  await initDatabaseSchema();

  await new Promise((res) => {
    server = app.listen(PORT, () => {
      console.log(`🚀 QA Express Server running on http://localhost:${PORT}\n`);
      res();
    });
  });

  const testResults = [];
  let passedCount = 0;
  let failedCount = 0;

  async function testEndpoint(category, name, fn) {
    const displayName = `[${category}] ${name}`;
    process.stdout.write(`Testing: ${displayName.padEnd(65)} ... `);
    try {
      const result = await fn();
      if (result.pass) {
        console.log(`✅ PASSED (${result.msg || 'OK'})`);
        passedCount++;
        testResults.push({ category, name, status: 'PASS', details: result.msg || 'OK' });
      } else {
        console.log(`❌ FAILED (${result.msg || 'Assertion Error'})`);
        failedCount++;
        testResults.push({ category, name, status: 'FAIL', details: result.msg || 'Assertion Error' });
      }
    } catch (err) {
      console.log(`❌ ERROR (${err.message})`);
      failedCount++;
      testResults.push({ category, name, status: 'ERROR', details: err.message });
    }
  }

  // Record baseline stats from Admin Panel before running mutations
  let baselineStats = {};
  try {
    const [rows] = await pool.query(`
      SELECT 
        (SELECT COUNT(*) FROM users) AS total_users,
        (SELECT COUNT(*) FROM doctors) AS total_doctors,
        (SELECT COUNT(*) FROM appointments) AS total_appointments,
        (SELECT COUNT(*) FROM doctors WHERE LOWER(verification_status) = 'pending') AS pending_doctors
    `);
    baselineStats = rows[0];
    console.log(`📊 Baseline DB State: ${baselineStats.total_users} Users, ${baselineStats.total_doctors} Doctors (${baselineStats.pending_doctors} Pending), ${baselineStats.total_appointments} Appointments\n`);
  } catch (err) {
    console.warn('Could not read baseline stats:', err.message);
  }

  // -------------------------------------------------------------------------
  // 1. API RESPONSES & SYSTEM HEALTH
  // -------------------------------------------------------------------------
  await testEndpoint('API Responses', 'GET /api/health (System Health & DB)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/health',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && res.body.status === 'online',
      msg: `Status: 200, Service: ${res.body.service}, DB: ${res.body.database}`,
    };
  });

  await testEndpoint('API Responses', 'GET /api/hospitals (Empaneled Network)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/hospitals',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && res.body.length > 0,
      msg: `Retrieved ${res.body.length} hospitals (e.g. ${res.body[0]?.name})`,
    };
  });

  // -------------------------------------------------------------------------
  // 2. USER ONBOARDING (Patient Registration)
  // -------------------------------------------------------------------------
  let testUserId;
  let testAarogyasriId;
  const testPhone = `984${Math.floor(1000000 + Math.random() * 9000000)}`;

  await testEndpoint('User Onboarding', 'POST /api/auth/register (Patient Registration)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/auth/register',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        name: 'Sita Devi Sharma',
        phone: testPhone,
        email: `sita.${testPhone}@example.in`,
        role: 'user',
      }
    );
    testUserId = res.body?.user?.id;
    testAarogyasriId = res.body?.user?.aarogyasri_id;
    return {
      pass: res.statusCode === 200 && testUserId && testAarogyasriId,
      msg: `Created Patient ID: ${testUserId}, Aarogyasri ID: ${testAarogyasriId}`,
    };
  });

  await testEndpoint('User Onboarding', 'GET /api/auth/aarogyasri/:id (Health Profile Sync)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/auth/aarogyasri/${testAarogyasriId}`,
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && res.body.name === 'Sita Devi Sharma',
      msg: `Verified Patient: ${res.body.name}, Blood Group: ${res.body.blood_group}`,
    };
  });

  // -------------------------------------------------------------------------
  // 3. DIFFERENT TYPES OF USERS
  // -------------------------------------------------------------------------
  let testDoctorId;
  const docMobile = `912${Math.floor(1000000 + Math.random() * 9000000)}`;
  await testEndpoint('User Types', 'POST /api/doctors/onboard (Doctor User Onboarding)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/doctors/onboard',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        name: 'Dr. V. Rajesh Kumar',
        specialty: 'Cardiologist',
        qualification: 'MBBS, MD, DM (Cardiology)',
        experienceYears: 12,
        consultationFee: 750.0,
        licenseNumber: `MCI-${Date.now().toString().slice(-6)}`,
        practiceType: 'Hospital',
        isRmp: false,
        mobile: docMobile,
        email: `dr.rajesh.${docMobile}@kims.org`,
      }
    );
    testDoctorId = res.body?.doctor?.id;
    return {
      pass: res.statusCode === 200 && testDoctorId && res.body.doctor.verificationStatus === 'pending',
      msg: `Onboarded Doctor: ${testDoctorId} (${res.body.doctor.name}), Status: ${res.body.doctor.verificationStatus}`,
    };
  });

  let testStoreId;
  await testEndpoint('User Types', 'POST /api/pharmacy/onboard (Pharmacy Partner Onboarding)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/pharmacy/onboard',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        name: 'Sanjeevani Express 24x7 Chemist',
        phone: '+91 9848099883',
        email: 'store@sanjeevani.com',
        licenseNumber: `TS-HYD-${Date.now().toString().slice(-5)}`,
        gstin: '36ABCDE1234F1Z5',
        pharmacistName: 'M. Anand Rao (Reg 48912)',
        address: 'Plot 18, Road No. 36, Jubilee Hills, Hyderabad',
      }
    );
    testStoreId = res.body?.store?.id;
    return {
      pass: res.statusCode === 200 && testStoreId && res.body.store.status === 'pending_verification',
      msg: `Onboarded Pharmacy: ${testStoreId}, Status: ${res.body.store.status}`,
    };
  });

  // -------------------------------------------------------------------------
  // 4. ALL THE PATIENTS
  // -------------------------------------------------------------------------
  await testEndpoint('All Patients', 'GET /api/users (Patient Directory & Health Profiles)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/users',
      method: 'GET',
    });
    const foundNewPatient = Array.isArray(res.body) && res.body.some((u) => u.id === testUserId);
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && foundNewPatient,
      msg: `Retrieved ${res.body.length} registered users. Includes new patient ${testUserId}`,
    };
  });

  await testEndpoint('All Patients', 'GET /api/users/:id (Single Patient Clinical Profile)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/users/${testUserId}`,
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && res.body.id === testUserId && res.body.aarogyasri_id === testAarogyasriId,
      msg: `Verified Profile: ${res.body.name}, Phone: ${res.body.phone}, Aarogyasri: ${res.body.aarogyasri_id}`,
    };
  });

  // -------------------------------------------------------------------------
  // 5. SUGGESTIONS (AI Triage & Clinical Intake)
  // -------------------------------------------------------------------------
  let testAiSessionId;
  await testEndpoint('Suggestions', 'POST /api/ai/triage (AI Clinical Triage & Care Suggestion)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/ai/triage',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        userId: testUserId,
        symptoms: ['High fever (102°F)', 'Body chills', 'Headache for 2 days'],
        age: 38,
        gender: 'Female',
        duration: '2 days',
        suspectedCondition: 'Acute Viral Pyrexia / Influenza',
        severity: 'Moderate',
        recommendedSpecialty: 'General Physician',
        medicines: [
          { id: 'MED-01', name: 'Paracetamol 650mg', dosage: '1 tablet after food TDS', duration: '3 days' },
          { id: 'MED-04', name: 'Electrolyte ORS Sachet', dosage: '1 sachet in 1L boiled water', duration: '2 days' },
        ],
        tests: [
          { name: 'Complete Blood Picture (CBC)', code: 'CBC', price: 350 },
          { name: 'Dengue NS1 Antigen Rapid', code: 'DENGUE-NS1', price: 600 },
        ],
      }
    );
    testAiSessionId = res.body?.sessionId;
    return {
      pass: res.statusCode === 200 && res.body.success && testAiSessionId,
      msg: `Session: ${testAiSessionId}, Specialty: ${res.body.recommendedSpecialty}, Meds: ${res.body.suggestedMedicines?.length}`,
    };
  });

  await testEndpoint('Suggestions', 'GET /api/ai/sessions/user/:userId (AI Session History)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/ai/sessions/user/${testUserId}`,
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && res.body.length > 0,
      msg: `Retrieved ${res.body.length} past AI session(s) for user ${testUserId}`,
    };
  });

  // -------------------------------------------------------------------------
  // 6. MEDICINE SUGGESTIONS & PHARMACY CATALOG
  // -------------------------------------------------------------------------
  await testEndpoint('Medicine Suggestions', 'GET /api/pharmacy/medicines (Medicine Catalog)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/pharmacy/medicines',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && res.body.length > 0,
      msg: `Catalog loaded with ${res.body.length} medicine items (e.g. ${res.body[0]?.name})`,
    };
  });

  await testEndpoint('Medicine Suggestions', 'GET /api/pharmacy/suggestions?symptom=fever (Targeted Suggestions)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/pharmacy/suggestions?symptom=fever',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body.suggestions) && res.body.suggestions.length > 0,
      msg: `Found ${res.body.suggestions.length} fever remedies (Top: ${res.body.suggestions[0]?.name})`,
    };
  });

  // -------------------------------------------------------------------------
  // 7. ORDER CREATION (15-Minute Doorstep Delivery)
  // -------------------------------------------------------------------------
  let testPharmacyOrderId;
  await testEndpoint('Order Creation', 'POST /api/pharmacy/orders (15-Min Doorstep Dispatch)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/pharmacy/orders',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        userId: testUserId,
        items: [
          { medicineId: 'MED-01', name: 'Paracetamol 650mg', qty: 2, price: 32.0 },
          { medicineId: 'MED-04', name: 'Electrolyte ORS Sachet', qty: 3, price: 22.0 },
        ],
        totalAmount: 130.0,
        deliveryAddress: 'Flat 304, Fortune Enclave, Madhapur, Hyderabad, Telangana - 500081',
      }
    );
    testPharmacyOrderId = res.body?.orderId;
    return {
      pass: res.statusCode === 200 && testPharmacyOrderId && res.body.status === 'out_for_delivery',
      msg: `Order ID: ${testPharmacyOrderId}, ETA: ${res.body.etaMinutes}, Driver: ${res.body.driverName}`,
    };
  });

  await testEndpoint('Order Creation', 'GET /api/pharmacy/orders/user/:userId (User Order History)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/pharmacy/orders/user/${testUserId}`,
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body),
      msg: `Retrieved past orders for user ${testUserId}`,
    };
  });

  // -------------------------------------------------------------------------
  // 8. USER BOOKING (Consultation Slot Booking)
  // -------------------------------------------------------------------------
  let testBookingId;
  let testMeetingRoomId;
  await testEndpoint('User Booking', 'POST /api/appointments/book (Slot Booking with Aarogyasri)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/appointments/book',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        userId: testUserId,
        doctorId: 'DOC-1024',
        hospitalId: 'HOSP-01',
        type: 'In-Clinic',
        appointmentDate: '2026-09-12',
        timeSlot: '11:00 AM',
        fee: 800.0,
        aarogyasriId: testAarogyasriId,
        isAarogyasriApplied: true,
        symptomsSummary: 'Persistent fever and body chills for 2 days',
      }
    );
    testBookingId = res.body?.appointmentId;
    testMeetingRoomId = res.body?.meetingRoomId;
    return {
      pass: res.statusCode === 200 && testBookingId && res.body.status === 'confirmed',
      msg: `Booking ID: ${testBookingId}, Room: ${testMeetingRoomId}, Status: ${res.body.status}`,
    };
  });

  await testEndpoint('User Booking', 'PUT /api/appointments/:id/reschedule (Reschedule Policy Check)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: `/api/appointments/${testBookingId}/reschedule`,
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        newDate: '2026-09-14',
        newTimeSlot: '03:00 PM',
      }
    );
    return {
      pass: res.statusCode === 200 && res.body.newDate === '2026-09-14',
      msg: `Policy: ${res.body.policyNote}, Reschedule Fee: ₹${res.body.feeDeduction}`,
    };
  });

  // -------------------------------------------------------------------------
  // 9. BOOKING DETAILS & CLINICAL QUEUE
  // -------------------------------------------------------------------------
  await testEndpoint('Booking Details', 'GET /api/appointments/:id (Single Booking Full Details)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/appointments/${testBookingId}`,
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && res.body.id === testBookingId && res.body.patient_name === 'Sita Devi Sharma',
      msg: `Doctor: ${res.body.doctor_name}, Patient: ${res.body.patient_name}, Hospital: ${res.body.hospital_name}`,
    };
  });

  await testEndpoint('Booking Details', 'GET /api/appointments/user/:userId (Patient Appointments List)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/appointments/user/${testUserId}`,
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && res.body.length > 0,
      msg: `Found ${res.body.length} appointment(s) for patient ${testUserId}`,
    };
  });

  await testEndpoint('Booking Details', 'GET /api/appointments/doctor/:doctorId (Doctor Clinical Queue)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/appointments/doctor/DOC-1024',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body),
      msg: `Doctor queue has ${res.body.length} consultation(s)`,
    };
  });

  await testEndpoint('Booking Details', 'PUT /api/appointments/:id/prescription (Digital Rx Issuance)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: `/api/appointments/${testBookingId}/prescription`,
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
      },
      {
        diagnosis: 'Viral Fever with Mild Dehydration',
        medicines: [
          { name: 'Paracetamol 650mg', dosage: '1 tab TDS for 3 days', timing: 'After food' },
          { name: 'Electrolyte Powder', dosage: '1 sachet daily in water', timing: 'Morning' },
        ],
        clinicalAdvice: 'Maintain bed rest and drink minimum 2.5L water daily.',
        recommendedTests: ['Complete Blood Count (CBC) in 48 hours if fever persists'],
        followUpDate: '2026-09-18',
      }
    );
    return {
      pass: res.statusCode === 200 && res.body.prescriptionId,
      msg: `Prescription Generated: ${res.body.prescriptionId}`,
    };
  });

  // -------------------------------------------------------------------------
  // 10. REFLECTING IN ADMIN PANEL (KPI Metrics & Sync)
  // -------------------------------------------------------------------------
  let updatedStats = {};
  await testEndpoint('Admin Reflection', 'GET /api/admin/stats (Live Dashboard KPI Sync)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/admin/stats',
      method: 'GET',
    });
    updatedStats = res.body;

    const userIncremented = updatedStats.total_users >= baselineStats.total_users;
    const apptIncremented = updatedStats.total_appointments >= baselineStats.total_appointments;
    const doctorReflected = updatedStats.pending_doctors >= baselineStats.pending_doctors;

    return {
      pass: res.statusCode === 200 && userIncremented && apptIncremented,
      msg: `Users: ${updatedStats.total_users} (▲), Appointments: ${updatedStats.total_appointments} (▲), Pending Docs: ${updatedStats.pending_doctors} (▲)`,
    };
  });

  await testEndpoint('Admin Reflection', 'GET /api/admin/ai-stats (AI Triage Metrics Reflection)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/admin/ai-stats',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && res.body.total_ai_sessions > 0,
      msg: `Total AI Sessions: ${res.body.total_ai_sessions}, Moderates: ${res.body.moderate_cases}`,
    };
  });

  await testEndpoint('Admin Reflection', 'GET /api/admin/hospital-rankings (Top Ranked Hospitals)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/admin/hospital-rankings',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && res.body.length > 0,
      msg: `Top Hospital: ${res.body[0]?.name} (${res.body[0]?.bookings} bookings)`,
    };
  });

  await testEndpoint('Admin Reflection', 'GET /api/admin/consultation-distribution (By Care Modality)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/admin/consultation-distribution',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && res.body.length > 0,
      msg: `Retrieved ${res.body.length} consultation modalities`,
    };
  });

  await testEndpoint('Admin Reflection', 'GET /api/admin/activity-logs (Audit Trail Verification)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/admin/activity-logs',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body),
      msg: `Audit log entries retrieved: ${res.body.length}`,
    };
  });

  await testEndpoint('Admin Reflection', 'GET /api/admin/pending-stores (Store Partner Approvals)', async () => {
    const res = await makeRequest({
      hostname: 'localhost',
      port: PORT,
      path: '/api/admin/pending-stores',
      method: 'GET',
    });
    return {
      pass: res.statusCode === 200 && Array.isArray(res.body) && res.body.length > 0,
      msg: `Pending store approvals: ${res.body.length} stores awaiting review`,
    };
  });

  // -------------------------------------------------------------------------
  // 11. PAYMENTS, TELEHEALTH & CONSENT SECURITY
  // -------------------------------------------------------------------------
  await testEndpoint('Telehealth & Consent', 'POST /api/payments/create-order (Razorpay Live Order)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/payments/create-order',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      { amount: 800.0, receipt: `rcpt_qa_${Date.now()}` }
    );
    return {
      pass: res.statusCode === 200 && res.body.success && res.body.orderId,
      msg: `Razorpay Order: ${res.body.orderId}, Currency: ${res.body.currency}`,
    };
  });

  await testEndpoint('Telehealth & Consent', 'POST /api/telehealth/generate-agora-token (RTC Video Token)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/telehealth/generate-agora-token',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      { channelName: `ROOM_${testBookingId}`, uid: 1001 }
    );
    return {
      pass: res.statusCode === 200 && res.body.token && res.body.appId,
      msg: `Agora Channel: ${res.body.channelName}`,
    };
  });

  let qrToken;
  await testEndpoint('Telehealth & Consent', 'POST /api/consent/generate-token (ABDM 15-Min QR Token)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/consent/generate-token',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      { userId: testUserId }
    );
    qrToken = res.body?.qrData;
    return {
      pass: res.statusCode === 200 && res.body.success && qrToken,
      msg: `Consent Token Generated: ${qrToken.slice(0, 35)}...`,
    };
  });

  await testEndpoint('Telehealth & Consent', 'POST /api/consent/doctor-scan (Doctor QR Consent Unlock)', async () => {
    const res = await makeRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/consent/doctor-scan',
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
      },
      { qrToken, doctorId: 'DOC-1024' }
    );
    return {
      pass: res.statusCode === 200 && res.body.success && res.body.healthProfile,
      msg: `Records Unlocked for: ${res.body.user?.name}`,
    };
  });

  // -------------------------------------------------------------------------
  // FINAL SUMMARY
  // -------------------------------------------------------------------------
  console.log('\n================================================================================');
  console.log(`📊 QA TEST SUMMARY:`);
  console.log(`   TOTAL TESTS EXECUTED : ${passedCount + failedCount}`);
  console.log(`   TOTAL TESTS PASSED   : ${passedCount}`);
  console.log(`   TOTAL TESTS FAILED   : ${failedCount}`);
  const passRate = ((passedCount / (passedCount + failedCount)) * 100).toFixed(1);
  console.log(`   SUCCESS RATE         : ${passRate}%`);
  console.log('================================================================================\n');

  // Breakdown by Category
  const categories = [...new Set(testResults.map((r) => r.category))];
  console.log('📋 CATEGORY BREAKDOWN:');
  for (const cat of categories) {
    const catTests = testResults.filter((r) => r.category === cat);
    const catPass = catTests.filter((r) => r.status === 'PASS').length;
    console.log(`   • ${cat.padEnd(25)}: ${catPass}/${catTests.length} Passed`);
  }
  console.log('================================================================================');

  server.close();
  await pool.end();
  process.exit(failedCount > 0 ? 1 : 0);
}

runQA().catch((err) => {
  console.error('Fatal QA Runner error:', err);
  process.exit(1);
});
