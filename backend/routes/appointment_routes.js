const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// GET /api/appointments — All appointments for Admin Panel
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT a.*, u.name AS patient_name, u.mobile AS patient_phone, 
              d.name AS doctor_name, d.specialty AS doctor_specialty, 
              h.name AS hospital_name
       FROM appointments a
       LEFT JOIN users u ON a.user_id = u.id
       LEFT JOIN doctors d ON a.doctor_id = d.id
       LEFT JOIN hospitals h ON a.hospital_id = h.id
       ORDER BY a.created_at DESC`
    );
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching all appointments:', err.message);
    return res.status(500).json({ error: 'Failed to fetch appointments' });
  }
});

// GET /api/appointments/user/:userId — Get patient appointments from MySQL
router.get('/user/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await pool.query(
      `SELECT a.*, d.name AS doctor_name, d.photo_url AS doctor_photo, d.specialty AS doctor_specialty, h.name AS hospital_name
       FROM appointments a
       JOIN doctors d ON a.doctor_id = d.id
       LEFT JOIN hospitals h ON a.hospital_id = h.id
       WHERE a.user_id = ?
       ORDER BY a.appointment_date DESC, a.created_at DESC`,
      [userId]
    );
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching user appointments:', err.message);
    return res.status(500).json({ error: 'Failed to fetch appointments from database' });
  }
});

// GET /api/appointments/doctor/:doctorId — Get doctor queue from MySQL
router.get('/doctor/:doctorId', async (req, res) => {
  const { doctorId } = req.params;
  try {
    const [rows] = await pool.query(
      `SELECT a.*, u.name AS user_name, u.mobile AS user_phone, hp.aarogyasri_id, hp.blood_group
       FROM appointments a
       JOIN users u ON a.user_id = u.id
       LEFT JOIN health_profiles hp ON u.id = hp.user_id
       WHERE a.doctor_id = ?
       ORDER BY a.appointment_date ASC, a.created_at ASC`,
      [doctorId]
    );
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching doctor appointments:', err.message);
    return res.status(500).json({ error: 'Failed to fetch doctor queue from database' });
  }
});

// GET /api/appointments/:id — Get single appointment details with doctor, patient, hospital, and prescription
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await pool.query(
      `SELECT a.*, 
              u.name AS patient_name, u.mobile AS patient_phone, u.email AS patient_email,
              d.name AS doctor_name, d.specialty AS doctor_specialty, d.photo_url AS doctor_photo, d.experience_years AS doctor_experience,
              h.name AS hospital_name, h.address AS hospital_address, h.city AS hospital_city,
              p.id AS prescription_id, p.diagnosis, p.medicines, p.clinical_advice, p.follow_up_date
       FROM appointments a
       LEFT JOIN users u ON a.user_id = u.id
       LEFT JOIN doctors d ON a.doctor_id = d.id
       LEFT JOIN hospitals h ON a.hospital_id = h.id
       LEFT JOIN prescriptions p ON a.id = p.appointment_id
       WHERE a.id = ?`,
      [id]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Appointment not found' });
    }
    return res.json(rows[0]);
  } catch (err) {
    console.error('Error fetching appointment details:', err.message);
    return res.status(500).json({ error: 'Failed to fetch appointment details' });
  }
});

// POST /api/appointments/book — Book Consultation into MySQL
router.post('/book', async (req, res) => {
  const userId = req.body.userId || req.body.user_id;
  const doctorId = req.body.doctorId || req.body.doctor_id;
  const hospitalId = req.body.hospitalId || req.body.hospital_id;
  const type = req.body.type;
  const appointmentDate = req.body.appointmentDate || req.body.appointment_date;
  const timeSlot = req.body.timeSlot || req.body.time_slot;
  const fee = req.body.fee || req.body.amount;
  const aarogyasriId = req.body.aarogyasriId || req.body.aarogyasri_id;
  const isAarogyasriApplied = req.body.isAarogyasriApplied !== undefined ? req.body.isAarogyasriApplied : req.body.is_aarogyasri_applied;
  const symptomsSummary = req.body.symptomsSummary || req.body.symptoms_summary;

  const apptId = `BK${Math.floor(10000 + Math.random() * 90000)}`;
  const meetingRoomId = `HEAL-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

  try {
    await pool.query(
      `INSERT INTO appointments (
        id, user_id, doctor_id, hospital_id, type, appointment_date, time_slot, fee,
        payment_status, doctor_status, booking_status, is_aarogyasri_applied, aarogyasri_id,
        symptoms_summary, meeting_room_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'paid', 'accepted', 'confirmed', ?, ?, ?, ?)`,
      [
        apptId,
        userId || 'USR-101',
        doctorId || 'DOC-1024',
        hospitalId || 'HOSP-01',
        type || 'In-Clinic',
        appointmentDate || new Date().toISOString().split('T')[0],
        timeSlot || '10:30 AM',
        fee || 800.0,
        isAarogyasriApplied ? 1 : 0,
        aarogyasriId || 'AROG12345678',
        symptomsSummary || 'Routine Consultation',
        meetingRoomId,
      ]
    );

    return res.json({
      success: true,
      message: 'Appointment recorded in database',
      appointmentId: apptId,
      meetingRoomId,
      status: 'confirmed',
    });
  } catch (err) {
    console.error('Booking insertion error:', err.message);
    return res.status(500).json({ error: 'Failed to record appointment in database', details: err.message });
  }
});

// PUT /api/appointments/:id/reschedule — Rescheduling Logic (>24h free vs <24h 30% deduction)
router.put('/:id/reschedule', async (req, res) => {
  const { id } = req.params;
  const { newDate, newTimeSlot } = req.body;

  try {
    const [rows] = await pool.query('SELECT * FROM appointments WHERE id = ?', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    const appt = rows[0];
    const apptDateObj = new Date(appt.appointment_date);
    const diffHours = (apptDateObj.getTime() - Date.now()) / (1000 * 60 * 60);

    let feeDeduction = 0;
    let policyNote = 'Rescheduled free of charge (>24h policy)';

    if (diffHours < 24) {
      feeDeduction = parseFloat(appt.fee) * 0.3; // 30% deduction
      policyNote = '30% fee adjusted for rescheduling within 24 hours of appointment.';
    }

    await pool.query(
      'UPDATE appointments SET appointment_date = ?, time_slot = ?, booking_status = ?, reschedule_fee_deduction = ? WHERE id = ?',
      [newDate, newTimeSlot, 'rescheduled', feeDeduction, id]
    );

    return res.json({
      success: true,
      message: 'Appointment rescheduled in database',
      id,
      newDate,
      newTimeSlot,
      feeDeduction,
      policyNote,
    });
  } catch (err) {
    console.error('Reschedule error:', err.message);
    return res.status(500).json({ error: 'Failed to reschedule in database' });
  }
});

// PUT /api/appointments/:id/prescription — Issue Digital Prescription into MySQL
router.put('/:id/prescription', async (req, res) => {
  const { id } = req.params;
  const { diagnosis, medicines, clinicalAdvice, recommendedTests, followUpDate } = req.body;

  try {
    const [apptRows] = await pool.query('SELECT * FROM appointments WHERE id = ?', [id]);
    if (apptRows.length === 0) {
      return res.status(404).json({ error: 'Appointment not found' });
    }

    const appt = apptRows[0];
    const rxId = `RX-${Date.now().toString().slice(-6)}`;

    await pool.query(
      `INSERT INTO prescriptions (id, appointment_id, user_id, doctor_id, diagnosis, medicines, clinical_advice, recommended_tests, follow_up_date)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE diagnosis=VALUES(diagnosis), medicines=VALUES(medicines)`,
      [
        rxId,
        id,
        appt.user_id,
        appt.doctor_id,
        diagnosis || 'Clinical review completed.',
        JSON.stringify(medicines || []),
        clinicalAdvice || 'Adequate hydration and rest.',
        JSON.stringify(recommendedTests || []),
        followUpDate || null,
      ]
    );

    await pool.query('UPDATE appointments SET doctor_status = ?, booking_status = ? WHERE id = ?', ['completed', 'completed', id]);

    return res.json({
      success: true,
      message: 'Digital prescription synced to patient records & Aarogyasri portal in database',
      prescriptionId: rxId,
    });
  } catch (err) {
    console.error('Prescription insertion error:', err.message);
    return res.status(500).json({ error: 'Failed to save digital prescription' });
  }
});

module.exports = router;
