const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { initDatabaseSchema } = require('./database');

const authRoutes = require('./routes/auth_routes');
const hospitalRoutes = require('./routes/hospital_routes');
const doctorRoutes = require('./routes/doctor_routes');
const appointmentRoutes = require('./routes/appointment_routes');
const paymentRoutes = require('./routes/payment_routes');
const telehealthRoutes = require('./routes/telehealth_routes');
const pharmacyRoutes = require('./routes/pharmacy_routes');
const ticketRoutes = require('./routes/ticket_routes');
const qrConsentRoutes = require('./routes/qr_consent_routes');
const chatRoutes = require('./routes/chat_routes');
const healthRecordRoutes = require('./routes/health_record_routes');
const adminRoutes = require('./routes/admin_routes');
const userRoutes = require('./routes/user_routes');
const aiRoutes = require('./routes/ai_routes');

const app = express();
const PORT = process.env.PORT || 5000;

// Middlewares
app.use(cors());
app.use(express.json());

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/hospitals', hospitalRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/telehealth', telehealthRoutes);
app.use('/api/pharmacy', pharmacyRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/consent', qrConsentRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/health-records', healthRecordRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/ai', aiRoutes);

// Health Check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'HealthExpress AI Backend',
    database: 'Connected to MySQL (147.93.101.73)',
    timestamp: new Date().toISOString(),
  });
});

// Start Server
app.listen(PORT, async () => {
  console.log(`==================================================`);
  console.log(`🚀 HealthExpress AI Backend running on port ${PORT}`);
  console.log(`🌐 Database: Remote MySQL (147.93.101.73)`);
  console.log(`💳 Razorpay Key: ${process.env.RAZORPAY_KEY_ID || 'Configured'}`);
  console.log(`📹 Agora WebRTC: ${process.env.AGORA_APP_ID || 'Configured'}`);
  console.log(`==================================================`);

  // Initialize Schema Tables
  await initDatabaseSchema();
});
