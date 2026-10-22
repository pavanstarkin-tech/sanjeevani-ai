const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// GET /api/users — All registered patients and users with clinical profiles
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT u.id, u.name, u.mobile AS phone, u.email, u.role, u.city, u.created_at,
             hp.aarogyasri_id, hp.blood_group, hp.allergies, hp.existing_conditions,
             hp.height_cm, hp.weight_kg, hp.temperature_f, hp.heart_rate_bpm, hp.oxygen_spo2
      FROM users u
      LEFT JOIN health_profiles hp ON u.id = hp.user_id
      ORDER BY u.created_at DESC
    `);
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching users:', err.message);
    return res.status(500).json({ error: 'Failed to fetch patients and users', details: err.message });
  }
});

// GET /api/users/:id — Single patient clinical profile
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await pool.query(`
      SELECT u.id, u.name, u.mobile AS phone, u.email, u.role, u.city, u.created_at,
             hp.aarogyasri_id, hp.blood_group, hp.allergies, hp.existing_conditions,
             hp.current_medications, hp.previous_surgeries, hp.height_cm, hp.weight_kg
      FROM users u
      LEFT JOIN health_profiles hp ON u.id = hp.user_id
      WHERE u.id = ?
    `, [id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }
    return res.json(rows[0]);
  } catch (err) {
    console.error('Error fetching patient profile:', err.message);
    return res.status(500).json({ error: 'Failed to fetch patient profile' });
  }
});

module.exports = router;
