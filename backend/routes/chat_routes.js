const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// Ensure chat_messages table exists
async function ensureChatTable() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id VARCHAR(64) PRIMARY KEY,
      appointment_id VARCHAR(64),
      sender_id VARCHAR(64) NOT NULL,
      sender_role ENUM('user', 'doctor', 'system') NOT NULL,
      receiver_id VARCHAR(64) NOT NULL,
      message TEXT NOT NULL,
      attachment_url TEXT,
      attachment_type VARCHAR(50),
      is_read BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
  `);
}

// 1. Send Chat Message (User <-> Doctor)
router.post('/send', async (req, res) => {
  await ensureChatTable();
  const { appointmentId, senderId, senderRole, receiverId, message, attachmentUrl, attachmentType } = req.body;

  if (!senderId || !receiverId || !message) {
    return res.status(400).json({ error: 'senderId, receiverId, and message are required' });
  }

  const messageId = `MSG-${Date.now().toString().slice(-6)}`;

  try {
    await pool.query(
      `INSERT INTO chat_messages (id, appointment_id, sender_id, sender_role, receiver_id, message, attachment_url, attachment_type)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [messageId, appointmentId || null, senderId, senderRole || 'user', receiverId, message, attachmentUrl || null, attachmentType || null]
    );

    return res.json({
      success: true,
      messageId,
      sentAt: new Date().toISOString(),
      message: 'Message sent successfully'
    });
  } catch (err) {
    console.error('Chat sending error:', err.message);
    return res.status(500).json({ error: 'Failed to send message' });
  }
});

// 2. Fetch Chat History between two participants
router.get('/history', async (req, res) => {
  await ensureChatTable();
  const { user1, user2, appointmentId } = req.query;

  try {
    let query = `
      SELECT * FROM chat_messages 
      WHERE ((sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?))
    `;
    const params = [user1, user2, user2, user1];

    if (appointmentId) {
      query += ' AND appointment_id = ?';
      params.push(appointmentId);
    }

    query += ' ORDER BY created_at ASC';

    const [rows] = await pool.query(query, params);
    return res.json(rows);
  } catch (err) {
    console.error('Chat history fetch error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch chat history' });
  }
});

module.exports = router;
