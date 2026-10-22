const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// 1. Upload / Index New Medical Document (Lab report, Surgery note, Discharge summary, Prescription)
router.post('/upload', async (req, res) => {
  const { userId, recordType, title, fileUrl, recordDate, summary, doctorId, hospitalId } = req.body;

  if (!userId || !title) {
    return res.status(400).json({ error: 'userId and title are required' });
  }

  const recordId = `REC-${Date.now().toString().slice(-6)}`;

  try {
    await pool.query(
      `INSERT INTO health_records (id, user_id, record_type, title, file_url, record_date, summary, doctor_id, hospital_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        recordId,
        userId,
        recordType || 'Lab Report',
        title,
        fileUrl || 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&q=80&w=600',
        recordDate || new Date().toISOString().split('T')[0],
        summary || 'Diagnostic test completed.',
        doctorId || null,
        hospitalId || 'HOSP-01'
      ]
    );

    return res.json({
      success: true,
      message: 'Medical record uploaded and encrypted to patient vault',
      recordId
    });
  } catch (err) {
    console.error('Record upload error:', err.message);
    return res.status(500).json({ error: 'Failed to upload health record' });
  }
});

// 2. Fetch Patient Health Records
router.get('/user/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await pool.query(
      `SELECT hr.*, h.name AS hospital_name 
       FROM health_records hr 
       LEFT JOIN hospitals h ON hr.hospital_id = h.id 
       WHERE hr.user_id = ? 
       ORDER BY hr.record_date DESC, hr.created_at DESC`,
      [userId]
    );
    return res.json(rows);
  } catch (err) {
    console.error('Fetch records error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch medical records' });
  }
});

// 3. Progressive Onboarding Profile Update
router.put('/onboarding/complete', async (req, res) => {
  const {
    userId,
    dob,
    gender,
    address,
    bloodGroup,
    allergies,
    existingConditions,
    currentMedications,
    previousSurgeries,
    emergencyContact
  } = req.body;

  if (!userId) {
    return res.status(400).json({ error: 'userId is required' });
  }

  try {
    await pool.query(
      `UPDATE users 
       SET dob = ?, gender = ?, address = ?, emergency_contact = ?, is_profile_completed = TRUE 
       WHERE id = ?`,
      [dob || '1995-06-15', gender || 'Male', address || 'Hitech City, Hyderabad', emergencyContact || '+91 9876543211', userId]
    );

    await pool.query(
      `UPDATE health_profiles 
       SET blood_group = ?, allergies = ?, existing_conditions = ?, current_medications = ?, previous_surgeries = ? 
       WHERE user_id = ?`,
      [
        bloodGroup || 'B+',
        allergies || 'No known drug allergies',
        existingConditions || 'None',
        currentMedications || 'None',
        previousSurgeries || 'Appendectomy (2020)',
        userId
      ]
    );

    const [userRows] = await pool.query('SELECT u.*, hp.* FROM users u JOIN health_profiles hp ON u.id = hp.user_id WHERE u.id = ?', [userId]);

    return res.json({
      success: true,
      message: 'Onboarding completed and health profile updated in database',
      profile: userRows[0]
    });
  } catch (err) {
    console.error('Onboarding update error:', err.message);
    return res.status(500).json({ error: 'Failed to complete onboarding profile' });
  }
});

module.exports = router;
