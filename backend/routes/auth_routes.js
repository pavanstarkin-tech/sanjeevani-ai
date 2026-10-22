const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// Minimal Registration (Name, Mobile, Optional Aarogyasri ID)
router.post('/register', async (req, res) => {
  const { name, phone, mobile, email, aarogyasriId, role } = req.body;
  const userMobile = mobile || phone;

  if (!name || !userMobile) {
    return res.status(400).json({ error: 'Name and Mobile number are required.' });
  }

  const userId = `USR-${Date.now().toString().slice(-6)}`;
  const finalAarogyasriId = aarogyasriId || `AROG${Math.floor(10000000 + Math.random() * 90000000)}`;

  try {
    await pool.query(
      `INSERT INTO users (id, name, mobile, email, role) 
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE name = VALUES(name), email = VALUES(email)`,
      [userId, name, userMobile, email || `${userMobile}@healthyxpress.in`, role || 'user']
    );

    await pool.query(
      `INSERT INTO health_profiles (user_id, aarogyasri_id, blood_group, allergies, existing_conditions, current_medications, previous_surgeries)
       VALUES (?, ?, 'B+', 'No known drug allergies', 'None', 'None', 'None')
       ON DUPLICATE KEY UPDATE aarogyasri_id = VALUES(aarogyasri_id)`,
      [userId, finalAarogyasriId]
    );

    const [userRows] = await pool.query('SELECT u.*, hp.aarogyasri_id, hp.blood_group FROM users u JOIN health_profiles hp ON u.id = hp.user_id WHERE u.id = ?', [userId]);
    return res.json({ message: 'User registered successfully', user: userRows[0] });
  } catch (err) {
    console.error('Registration error:', err.message);
    return res.status(500).json({ error: 'Failed to register user', details: err.message });
  }
});

// Lookup Patient Medical History by Aarogyasri QR Code token
router.get('/aarogyasri/:aarogyasriId', async (req, res) => {
  const { aarogyasriId } = req.params;
  try {
    const [rows] = await pool.query(
      `SELECT u.*, hp.aarogyasri_id, hp.blood_group, hp.allergies, hp.existing_conditions, 
              hp.current_medications, hp.previous_surgeries, hp.previous_hospitalizations, 
              hp.height_cm, hp.weight_kg, hp.temperature_f, hp.heart_rate_bpm, hp.oxygen_spo2
       FROM health_profiles hp
       JOIN users u ON hp.user_id = u.id
       WHERE hp.aarogyasri_id = ?`,
      [aarogyasriId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Aarogyasri record not found' });
    }
    return res.json(rows[0]);
  } catch (err) {
    console.error('Aarogyasri lookup error:', err.message);
    return res.status(500).json({ error: 'Failed to lookup Aarogyasri record' });
  }
});

module.exports = router;
