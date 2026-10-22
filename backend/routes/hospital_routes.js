const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// GET /api/hospitals — Fetch real hospitals from remote MySQL
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM hospitals ORDER BY rating DESC');
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching hospitals:', err.message);
    return res.status(500).json({ error: 'Failed to fetch hospitals from database' });
  }
});

// GET /api/hospitals/:id — Fetch single hospital with departments
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const [hospRows] = await pool.query('SELECT * FROM hospitals WHERE id = ?', [id]);
    if (hospRows.length === 0) {
      return res.status(404).json({ error: 'Hospital not found' });
    }
    const [deptRows] = await pool.query('SELECT * FROM departments WHERE hospital_id = ?', [id]);
    const hospital = hospRows[0];
    hospital.departmentList = deptRows;
    return res.json(hospital);
  } catch (err) {
    console.error('Error fetching hospital detail:', err.message);
    return res.status(500).json({ error: 'Failed to fetch hospital details' });
  }
});

// POST /api/hospitals — Add new hospital
router.post('/', async (req, res) => {
  const { name, location, address, primary_phone, rating, bed_capacity } = req.body;
  const id = `HOSP-${Date.now().toString().slice(-4)}`;

  try {
    await pool.query(
      `INSERT INTO hospitals (id, name, location, address, primary_phone, rating, license_number)
       VALUES (?, ?, ?, ?, ?, ?, 'TS-LIC-NEW')`,
      [id, name, location, address || location, primary_phone || '+91 40 4488 5000', rating || 4.7]
    );

    const [rows] = await pool.query('SELECT * FROM hospitals WHERE id = ?', [id]);
    return res.json({ message: 'Hospital created successfully', hospital: rows[0] });
  } catch (err) {
    console.error('Error creating hospital:', err.message);
    return res.status(500).json({ error: 'Failed to create hospital' });
  }
});

module.exports = router;
