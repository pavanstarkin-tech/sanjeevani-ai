const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// GET /api/admin/stats — Overall KPI stats for Admin Dashboard
router.get('/stats', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        (SELECT COUNT(*) FROM users) AS total_users,
        (SELECT COUNT(*) FROM doctors) AS total_doctors,
        (SELECT COUNT(*) FROM hospitals) AS total_hospitals,
        (SELECT COUNT(*) FROM appointments) AS total_appointments,
        (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status IN ('success', 'paid')) AS gross_revenue,
        (SELECT COUNT(*) FROM doctors WHERE LOWER(verification_status) = 'pending') AS pending_doctors,
        (SELECT COUNT(*) FROM hospitals WHERE LOWER(status) IN ('under review', 'pending')) AS pending_hospitals,
        (SELECT COUNT(*) FROM tickets WHERE status = 'open') AS open_tickets
    `);
    return res.json(rows[0]);
  } catch (err) {
    console.error('Admin stats error:', err.message);
    return res.status(500).json({ error: 'Failed to compute admin stats', details: err.message });
  }
});

// GET /api/admin/ai-stats — AI Assistant & Triage Metrics
router.get('/ai-stats', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT 
        (SELECT COUNT(*) FROM ai_sessions) AS total_ai_sessions,
        (SELECT COUNT(*) FROM ai_sessions WHERE duration LIKE '%min%' OR symptoms LIKE '%voice%') AS voice_consultations,
        (SELECT COUNT(*) FROM ai_sessions WHERE severity = 'Emergency') AS emergency_escalations,
        (SELECT COUNT(*) FROM ai_sessions WHERE severity = 'Moderate') AS moderate_cases,
        (SELECT COUNT(*) FROM ai_sessions WHERE severity = 'Mild') AS mild_cases
    `);
    return res.json(rows[0]);
  } catch (err) {
    console.error('AI stats error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch AI stats' });
  }
});

// GET /api/admin/ai-sessions — Recent AI Sessions with Patient details
router.get('/ai-sessions', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT s.*, u.name AS patient_name, u.city AS patient_city,
             d.name AS recommended_doctor_name, d.specialty AS recommended_doctor_specialty
      FROM ai_sessions s
      LEFT JOIN users u ON s.user_id = u.id
      LEFT JOIN doctors d ON s.recommended_doctor_id = d.id
      ORDER BY s.created_at DESC
      LIMIT 20
    `);
    return res.json(rows);
  } catch (err) {
    console.error('AI sessions error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch AI sessions' });
  }
});

// GET /api/admin/hospital-rankings — Top Hospitals by Bookings
router.get('/hospital-rankings', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT h.id, h.name, COUNT(a.id) AS bookings 
      FROM hospitals h
      LEFT JOIN appointments a ON h.id = a.hospital_id
      GROUP BY h.id, h.name
      ORDER BY bookings DESC
      LIMIT 5
    `);
    return res.json(rows);
  } catch (err) {
    console.error('Hospital rankings error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch hospital rankings' });
  }
});

// GET /api/admin/consultation-distribution
router.get('/consultation-distribution', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT type, COUNT(*) AS count 
      FROM appointments 
      GROUP BY type
    `);
    return res.json(rows);
  } catch (err) {
    console.error('Consultation distribution error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch consultation distribution' });
  }
});

// GET /api/admin/activity-logs — Audit Logs
router.get('/activity-logs', async (req, res) => {
  try {
    const [rows] = await pool.query(`
      SELECT * FROM audit_logs 
      ORDER BY created_at DESC 
      LIMIT 25
    `);
    return res.json(rows);
  } catch (err) {
    console.error('Activity logs error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch activity logs' });
  }
});

// GET /api/admin/pending-stores — Pharmacy Partner Applications
router.get('/pending-stores', async (req, res) => {
  try {
    return res.json([
      {
        id: 'STORE-101',
        name: 'MedPlus Express Hub',
        owner: 'K. Venkatesh',
        license: 'TS-HYD-PHARM-2026-9421',
        area: 'Madhapur, Hyderabad',
        status: 'pending',
      },
      {
        id: 'STORE-102',
        name: 'Apollo 24x7 Quick Chemist',
        owner: 'S. Narayana',
        license: 'TS-HYD-PHARM-2026-8812',
        area: 'Gachibowli, Hyderabad',
        status: 'approved',
      }
    ]);
  } catch (err) {
    return res.status(500).json({ error: 'Failed to fetch pending stores' });
  }
});

// PUT /api/admin/verify-store/:id
router.put('/verify-store/:id', (req, res) => {
  const { id } = req.params;
  const { status, notes } = req.body;
  return res.json({
    success: true,
    storeId: id,
    status: status || 'approved',
    notes: notes || 'Store verified successfully',
    updatedAt: new Date().toISOString()
  });
});

module.exports = router;
