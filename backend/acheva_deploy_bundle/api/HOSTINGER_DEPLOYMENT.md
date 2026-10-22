# HealthExpress AI — Hostinger Production Deployment Guide

This guide describes how to deploy the **HealthExpress AI PHP 8+ REST API** to Hostinger Web Hosting via SSH or File Manager.

---

## 📁 1. Directory Setup on Hostinger

1. Upload all contents of the [`php_backend/`](file:///c:/Users/shese/Desktop/healthyxpress_medha/php_backend) folder into your domain's `public_html/` folder on Hostinger:

```
public_html/
├── .htaccess                      # Enables Apache mod_rewrite for clean REST URLs
├── index.php                      # Front Controller & REST Router
├── .env                           # Server-side environment secrets (Optional)
├── config/
│   ├── config.php                 # Environment & API Key loader
│   └── database.php               # PDO Database Singleton
├── middleware/
│   ├── CorsMiddleware.php         # CORS Header handler
│   └── AuthMiddleware.php         # Token & role verification
├── helpers/
│   └── Response.php               # JSON output formatter
├── controllers/
│   ├── AdminController.php        # Real-time computed SQL KPI statistics
│   ├── AuthController.php         # Registration & Aarogyasri Lookup
│   ├── HospitalController.php     # Hospital directory & empanelment
│   ├── DoctorController.php       # Doctor directory, credentialing & status
│   ├── AppointmentController.php  # Booking, rescheduling & prescription
│   ├── PaymentController.php      # Razorpay Live integration
│   ├── TelehealthController.php   # Agora WebRTC dynamic room tokens
│   ├── PharmacyController.php     # 15-min medicine delivery catalog & orders
│   ├── ConsentController.php      # ABDM 15-min QR consent tokens
│   ├── ChatController.php         # 2-way patient/doctor messaging
│   ├── HealthRecordController.php # Medical vault uploads & progressive onboarding
│   ├── TicketController.php       # Support tickets desk
│   └── AiController.php           # Gemini AI clinical triage
├── cron/
│   ├── appointment_reminders.php  # Automated consultation reminders
│   └── token_cleanup.php          # Purge expired 15-min consent tokens
└── database/
    └── schema.sql                 # MySQL schema reference
```

---

## 🗄️ 2. Database Connection

The database connection is configured in [`config/config.php`](file:///c:/Users/shese/Desktop/healthyxpress_medha/php_backend/config/config.php) to connect to your live MySQL database:
- **Host**: `147.93.101.73`
- **Port**: `3306`
- **Database**: `u170253497_healthexpress`
- **User**: `u170253497_healthexpress`

If running on the same Hostinger server locally, you can change `DB_HOST` in `.env` or `config.php` to `localhost`.

---

## ⏰ 3. Cron Tasks Setup on Hostinger hPanel

In **Hostinger hPanel → Advanced → Cron Jobs**, configure the following 2 tasks:

### Task 1: Appointment Reminders (Every 15 minutes)
```bash
* /15 * * * * /usr/bin/php /home/u170253497/domains/YOUR_DOMAIN/public_html/cron/appointment_reminders.php > /dev/null 2>&1
```

### Task 2: Expired ABDM Consent Token Cleanup (Daily at midnight)
```bash
0 0 * * * /usr/bin/php /home/u170253497/domains/YOUR_DOMAIN/public_html/cron/token_cleanup.php > /dev/null 2>&1
```

---

## 🧪 4. Live Health Check

Once uploaded, verify your deployment in browser or cURL:
```bash
curl https://YOUR_DOMAIN/api/health
```

Expected Response:
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "database": "connected_live_mysql",
    "host": "147.93.101.73",
    "time": "2026-09-03 10:00:00"
  }
}
```
