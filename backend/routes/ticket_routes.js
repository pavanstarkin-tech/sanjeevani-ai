const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// List Tickets
router.get('/', async (req, res) => {
  try {
    const [rows] = await pool.query(
      `SELECT t.*, u.name AS user_name, u.mobile AS user_phone 
       FROM tickets t 
       JOIN users u ON t.user_id = u.id 
       ORDER BY t.created_at DESC`
    );
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching tickets:', err.message);
    return res.status(500).json({ error: 'Failed to fetch tickets' });
  }
});

// Raise Ticket
router.post('/', async (req, res) => {
  const { userId, category, subject, description, priority } = req.body;
  const ticketId = `TK${Date.now().toString().slice(-4)}`;

  try {
    await pool.query(
      `INSERT INTO tickets (id, user_id, category, subject, description, priority, status)
       VALUES (?, ?, ?, ?, ?, ?, 'open')`,
      [ticketId, userId || 'USR-101', category || 'Booking', subject, description, priority || 'medium']
    );

    return res.json({ message: 'Ticket raised successfully', ticketId });
  } catch (err) {
    console.error('Error raising ticket:', err.message);
    return res.status(500).json({ error: 'Failed to create ticket', details: err.message });
  }
});

module.exports = router;
