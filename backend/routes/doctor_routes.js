const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// GET /api/doctors — Fetch real verified doctors with filtering
router.get('/', async (req, res) => {
  const { specialty, hospitalId, isRmp, practiceType } = req.query;
  try {
    let query = `
      SELECT d.*, h.name AS hospital_name, h.city AS hospital_location
      FROM doctors d
      LEFT JOIN doctor_hospitals dh ON d.id = dh.doctor_id
      LEFT JOIN hospitals h ON dh.hospital_id = h.id
      WHERE 1=1
    `;
    const params = [];

    if (specialty && specialty !== 'All') {
      query += ' AND d.specialty = ?';
      params.push(specialty);
    }
    if (hospitalId) {
      query += ' AND dh.hospital_id = ?';
      params.push(hospitalId);
    }
    if (isRmp === 'true') {
      query += ' AND d.is_rmp_doctor = TRUE';
    }
    if (practiceType) {
      query += ' AND d.practice_type = ?';
      params.push(practiceType);
    }

    query += ' ORDER BY d.rating DESC, d.experience_years DESC';

    const [rows] = await pool.query(query, params);
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching doctors:', err.message);
    return res.status(500).json({ error: 'Failed to fetch doctors from database' });
  }
});

// GET /api/doctors/:id — Doctor details with schedules and affiliations
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [docRows] = await pool.query('SELECT * FROM doctors WHERE id = ?', [id]);
    if (docRows.length === 0) {
      return res.status(404).json({ error: 'Doctor not found' });
    }
    const [affRows] = await pool.query(
      `SELECT dh.*, h.name AS hospital_name, h.city AS hospital_location 
       FROM doctor_hospitals dh 
       JOIN hospitals h ON dh.hospital_id = h.id 
       WHERE dh.doctor_id = ?`,
      [id]
    );
    const [schedRows] = await pool.query('SELECT * FROM doctor_schedules WHERE doctor_id = ?', [id]);

    const doctor = docRows[0];
    doctor.affiliations = affRows;
    doctor.schedules = schedRows;

    return res.json(doctor);
  } catch (err) {
    console.error('Error fetching doctor detail:', err.message);
    return res.status(500).json({ error: 'Failed to fetch doctor details' });
  }
});

// POST /api/doctors/onboard — Onboard a new Doctor into MySQL
router.post('/onboard', async (req, res) => {
  const { name, specialty, qualification, qualifications, experienceYears, consultationFee, fee, licenseNumber, registrationNumber, practiceType, isRmp, mobile, email } = req.body;
  const docId = `DOC-${Date.now().toString().slice(-4)}`;
  const doctorMobile = mobile || `91${Math.floor(10000000 + Math.random() * 90000000)}`;
  const regNumber = registrationNumber || licenseNumber || `TSMC-${Date.now().toString().slice(-6)}`;
  const doctorQual = qualifications || qualification || 'MBBS, MD';
  const doctorFee = fee || consultationFee || 750.0;
  const pType = ['Independent', 'Hospital', 'Multiple'].includes(practiceType) ? practiceType : 'Hospital';

  if (!name || !specialty) {
    return res.status(400).json({ error: 'Name and Specialty are required.' });
  }

  try {
    await pool.query(
      `INSERT INTO doctors (
        id, name, mobile, email, specialty, qualifications, experience_years, 
        clinic_fee, registration_number, practice_type, is_rmp_doctor, 
        is_online, verification_status, rating, reviews_count
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'Pending', 5.0, 0)`,
      [
        docId,
        name,
        doctorMobile,
        email || `${docId.toLowerCase()}@healthyxpress.in`,
        specialty,
        doctorQual,
        experienceYears || 5,
        doctorFee,
        regNumber,
        pType,
        isRmp ? 1 : 0,
      ]
    );

    // Also register in users table with role 'doctor'
    const userId = `USR-${docId}`;
    await pool.query(
      `INSERT INTO users (id, name, mobile, email, role) VALUES (?, ?, ?, ?, 'doctor')
       ON DUPLICATE KEY UPDATE name=VALUES(name), role='doctor'`,
      [userId, name, doctorMobile, email || `${docId.toLowerCase()}@healthyxpress.in`]
    );

    return res.json({
      success: true,
      message: 'Doctor successfully onboarded and pending admin verification',
      doctor: {
        id: docId,
        name,
        specialty,
        registrationNumber: regNumber,
        verificationStatus: 'pending'
      }
    });
  } catch (err) {
    console.error('Doctor onboarding error:', err.message);
    return res.status(500).json({ error: 'Failed to onboard doctor', details: err.message });
  }
});

module.exports = router;
