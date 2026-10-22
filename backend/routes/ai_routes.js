const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// POST /api/ai/triage — AI clinical symptom intake and triage suggestion
router.post('/triage', async (req, res) => {
  const userId = req.body.userId || req.body.user_id;
  const symptoms = req.body.symptoms;
  const age = req.body.age;
  const gender = req.body.gender;
  const duration = req.body.duration;
  const suspectedCondition = req.body.suspectedCondition || req.body.suspected_condition;
  const severity = req.body.severity;
  const recommendedSpecialty = req.body.recommendedSpecialty || req.body.recommended_specialty;
  const medicines = req.body.medicines || req.body.suggested_medicines;
  const tests = req.body.tests || req.body.suggested_tests || req.body.recommended_tests;
  const sessionId = `AI-${Date.now().toString().slice(-6)}`;

  try {
    const symptomsJson = JSON.stringify(Array.isArray(symptoms) ? symptoms : [symptoms || 'General Malaise']);
    const userAnswersJson = JSON.stringify({ age: age || null, gender: gender || null });
    const testsJson = JSON.stringify(tests || ['Complete Blood Count (CBC)']);
    const recommendedCare = JSON.stringify({
      specialty: recommendedSpecialty || 'General Physician',
      medicines: medicines || [
        { id: 'MED-01', name: 'Paracetamol 650mg', dosage: '1 tablet after food', duration: '3 days' },
        { id: 'MED-04', name: 'Electrolyte ORS Sachet', dosage: '1 sachet in 1L water', duration: 'As needed' },
      ]
    });

    await pool.query(`
      INSERT INTO ai_sessions (
        id, user_id, symptoms, duration, severity, user_answers,
        ai_summary, recommended_care, recommended_doctor_id, recommended_tests
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      sessionId,
      userId || 'USR-101',
      symptomsJson,
      duration || '2-3 days',
      severity || 'Moderate',
      userAnswersJson,
      suspectedCondition || 'Clinical Consultation Recommended',
      recommendedCare,
      'DOC-1024',
      testsJson
    ]);

    return res.json({
      success: true,
      sessionId,
      severity: severity || 'Moderate',
      suspectedCondition: suspectedCondition || 'Clinical Consultation Recommended',
      recommendedSpecialty: recommendedSpecialty || 'General Physician',
      suggestedMedicines: medicines || [
        { id: 'MED-01', name: 'Paracetamol 650mg', dosage: '1 tablet after food', duration: '3 days' },
        { id: 'MED-04', name: 'Electrolyte ORS Sachet', dosage: '1 sachet in 1L water', duration: 'As needed' },
      ],
      suggestedLabTests: tests || [
        { name: 'Complete Blood Picture (CBC)', code: 'CBC', price: 350 },
      ],
      message: 'AI Triage completed and synced to clinical database',
    });
  } catch (err) {
    console.error('AI triage error:', err.message);
    return res.status(500).json({ error: 'Failed to record AI triage session', details: err.message });
  }
});

// GET /api/ai/sessions/user/:userId — Retrieve past AI sessions for a patient
router.get('/sessions/user/:userId', async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await pool.query('SELECT * FROM ai_sessions WHERE user_id = ? ORDER BY created_at DESC', [userId]);
    return res.json(rows);
  } catch (err) {
    console.error('AI session fetch error:', err.message);
    return res.status(500).json({ error: 'Failed to fetch AI sessions' });
  }
});

module.exports = router;
