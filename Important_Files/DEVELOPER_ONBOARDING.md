# 🏥 HealthExpress AI — Master Developer Onboarding & Architecture Guide

> **START HERE**: This is the primary entry point for any developer working on, deploying, or extending the **HealthExpress AI** full-stack healthcare ecosystem.

---

## ⚡ 1. Quick-Start Onboarding (For New Developers)

Follow these 3 simple steps to get this entire project up and running in minutes:

### 🔹 Step A: Create a GitHub Personal Access Token (PAT)
1. Go to [https://github.com/settings/tokens](https://github.com/settings/tokens) (or click **Profile Photo** -> **Settings** -> **Developer settings** -> **Personal access tokens** -> **Tokens (classic)**).
2. Click **Generate new token** -> **Generate new token (classic)**.
3. In **Note**, enter `HealthExpress Deployer`.
4. In **Expiration**, choose `No expiration` or `90 days`.
5. Under **Select scopes**, check the **`repo`** checkbox (Full control of private repositories).
6. Click **Generate token** at the bottom and copy the token (starts with `ghp_...`).

---

### 🔹 Step B: Repository Extraction & Setup
1. **Clone or Extract the Codebase**:
   ```bash
   git clone https://github.com/pavanstarkin-tech/healthyxpress_medha.git
   cd healthyxpress_medha
   ```
2. **Automated Migration / Deployment to Your Own GitHub Repository**:
   Run the universal migration script and paste your token:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File push_to_new_repo.ps1
   ```
   *(For Mac/Linux: `./push_to_new_repo.sh`)*
   - The script will automatically create a new repo on your GitHub account, push all code to `main`, compile both Flutter & React apps, and deploy live to `gh-pages`!

---

### 🔹 Step C: Master Anti-Gravity IDE / AI Assistant Prompt
Whenever you open this repository in **Antigravity IDE** or an AI assistant, paste this prompt to immediately onboard the agent:

```markdown
You are working on the HealthExpress AI production repository. 
Read `DEVELOPER_ONBOARDING.md` as your primary architectural ground truth.

Key Context:
1. Flutter Web App (`/healthexpress`) runs the patient/doctor/store frontend with live GPS geolocation, Mapbox GL JS & Leaflet vector maps, and Sarvam AI voice assistant (Telugu/Hindi/English).
2. Operations Dashboard (`/admin_panel`) is a React 18 + Vite application connecting to Hostinger MySQL REST API (`https://vedvaidyam.com/healthexpress/api`).
3. Dual-deployment is handled via `deploy.ps1` which builds Flutter for `/` and React Admin for `/admin` and deploys to `gh-pages`.
4. All active API keys (Mapbox, Sarvam AI, LiveKit, Agora, Firebase, MySQL, Razorpay) are documented in `DEVELOPER_ONBOARDING.md` and `apis.txt`.

Please inspect the active workspace, verify all dependencies, and help me with my next task.
```

---

## 📌 2. Project Overview & Architecture

HealthExpress AI is an end-to-end intelligent healthcare platform featuring:
- **Patient / Doctor / Pharmacy Multi-Role Flutter App** (`/healthexpress`): Telehealth, 15-minute emergency pharmacy delivery, ABDM Aarogyasri health records, live hospital discovery, and AI triage.
- **Admin & Pharmacy Operational Dashboard** (`/admin_panel`): Real-time inventory manager, doctor approvals, telemedicine session audits, and live order tracking.
- **Voice-First Indian AI Medical Assistant**: Real-time clinical AI conversational agent with Sarvam AI (`sarvam-105b-conversations` LLM, `saaras:v3` Speech-to-Text, and `bulbul:v3` 22kHz clinical TTS supporting Telugu, Hindi, and Indian English), with LiveKit WebRTC and Agora RTC teleconsultations.
- **Live Vector Tile Mapping Engine**: Dual Mapbox GL JS & Leaflet CartoDB engine with live GPS auto-detection, teardrop pin pointer markers, and real-time POI hospital discovery.
- **Cloud Backend & Database**: Production MySQL database hosted on Hostinger VPS with PHP 8.2 REST API endpoints.

---

## 🔑 2. Master Credentials & API Keys Table

All API keys are fully configured, tested, and embedded in the codebase ([AppConfig](file:///c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/lib/core/config/app_config.dart), `web/index.html`, and `admin_panel/.env`).

| Service | Active Key / Credential | Secondary / Fallback Key | Notes & Purpose |
| :--- | :--- | :--- | :--- |
| **Groq Multimodal Vision AI** | `Configured in AppConfig.groqApiKey` | Models: `qwen/qwen3.6-27b`, `qwen/qwen3.8-27b`, `openai/gpt-oss-20b`, `groq/compound` | Food calorie estimation, infection diagnostics, medicine Rx analysis & interactive follow-up |
| **Backend REST API** | `https://vedvaidyam.com/healthexpress/api` | N/A | Production PHP REST API on Hostinger |
| **MySQL Database** | Host: `147.93.101.73` (port: `3306`)<br>DB: `u170253497_healthexpress`<br>User: `u170253497_healthexpress`<br>Pass: `Healthxpress_1234567` | N/A | Remote MySQL production database |
| **SSH VPS Access** | `ssh -p 65002 u170253497@147.93.101.73`<br>Pass: `Honey_comb@@#$%^&d1` | N/A | Server administration & PHP backend |
| **Mapbox GL JS & POI** | `Configured in AppConfig.mapboxAccessToken` | OpenStreetMap / CartoDB Fallback | Live hospital POIs, reverse geocoding, vector tiles |
| **Sarvam AI Voice & STT** | `sk_n4tzuy3c_JIUK6l5ExNHHGoiiAGwvroYh` | `sk_hr3tv6ew_UBzXjEc9RqZLGuMpzyctBUQC` | `saaras:v3` (STT), `bulbul:v3` (TTS), `sarvam-105b` (LLM) |
| **LiveKit WebRTC Cloud** | URL: `wss://luca-vsv9whhr.livekit.cloud`<br>API Key: `API5veVBN62icXT`<br>API Secret: `0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA` | N/A | Sub-250ms voice streaming WebRTC room |
| **Agora Video & Audio RTC** | App ID: `7c9641fb497543d2b01fe6fe5fe0af15`<br>Cert: `29afb318421747818086445f230f3c61` | N/A | Real-time doctor-patient teleconsultations |
| **Firebase Auth & Cloud** | API Key: `AIzaSyCU7Psyt8Rl5kQScIDAavvleuyNjkhVFxo`<br>App ID: `1:575738669292:web:305a1fce4415b605c3ddc9`<br>Project: `healthexpress-1` | N/A | Google OAuth popup & user sessions |
| **Razorpay Payments** | Key ID: `rzp_live_StBUehIpeULYuL`<br>Secret: `M76UWnmNsVE7hU5QrkriZuor` | N/A | Real payment gateway integration |
| **NVIDIA NIM LLM** | `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` | Model: `openai/gpt-oss-20b` | Clinical AI diagnostic assistant |


---

## 🚀 3. Quick-Start Local Development Guide

### Prerequisites
- **Flutter SDK**: 3.22.0 or higher (`flutter --version`)
- **Node.js**: 18.0 or higher (`node -v`)
- **Git**: Installed and configured
- **Chrome / Modern Web Browser**

---

### Step 1: Run the Main Flutter Web App
```bash
# 1. Navigate to the Flutter app directory
cd healthexpress

# 2. Get dependencies
flutter pub get

# 3. Launch on Chrome (Local Development Server)
flutter run -d chrome
```

---

### Step 2: Run the React Vite Admin Panel
```bash
# 1. Navigate to the Admin Panel directory
cd admin_panel

# 2. Install dependencies
npm install

# 3. Launch local Vite development server
npm run dev
# The admin panel will be live at http://localhost:5173/
```

---

### Step 3: Run Sarvam LiveKit Voice Agent (Optional Local Server)
```bash
cd livekit_voice_agent
npm install
npm start
```

---

## 📦 4. Dual-Deployment Pipeline (How It Works)

The project uses a unified **Dual-Build & Deployment Architecture** where:
1. **Flutter Web App** is compiled and deployed to the root URL `/`
2. **React Vite Admin Panel** is compiled and embedded into `/admin`

### One-Click Deploy Command
To compile both applications and deploy live to GitHub Pages:
```powershell
powershell.exe -ExecutionPolicy Bypass -File deploy.ps1
```

---

## 🔄 5. Token-Only Automated GitHub Migration & Deployment

Developers **only need a GitHub Personal Access Token (PAT)** with `repo` scope to auto-create repositories, push the codebase, build both web apps, and deploy live to GitHub Pages.

### Option A: One-Command Execution (Windows PowerShell)
```powershell
powershell.exe -ExecutionPolicy Bypass -File push_to_new_repo.ps1 -GitHubToken "ghp_YOUR_GITHUB_TOKEN" -RepoName "my-healthexpress"
```

### Option B: Interactive Execution (Prompts for Token & Settings)
```powershell
powershell.exe -ExecutionPolicy Bypass -File push_to_new_repo.ps1
```

### Option C: Linux / macOS Bash Execution
```bash
chmod +x push_to_new_repo.sh
./push_to_new_repo.sh "ghp_YOUR_GITHUB_TOKEN" "my-healthexpress"
```

### What happens automatically when you provide the token:
1. **GitHub API Verification**: Validates the token and retrieves your GitHub account.
2. **Auto Repository Creation**: Checks if the repository exists; if not, automatically creates the public/private repository on GitHub via REST API.
3. **Source Code Push**: Configures authenticated Git remote (`https://x-access-token:TOKEN@github.com/...`) and pushes all source code to `main`.
4. **Full Production Build**:
   - Compiles Flutter Web release bundle (`/healthexpress`).
   - Compiles React Vite Admin Dashboard (`/admin_panel`).
5. **Live GitHub Pages Deployment**: Assembles both apps into a unified distribution with `.nojekyll` and pushes to the `gh-pages` branch.
6. **Live URLs**: Outputs the live URLs for immediate access.

---

## 📂 6. Repository File & Directory Structure

```
healthyxpress_medha/
├── DEVELOPER_ONBOARDING.md      <-- ⭐ Start here for onboarding & architecture
├── deploy.ps1                   <-- Builds Flutter + Admin and deploys to gh-pages
├── push_to_new_repo.ps1         <-- Migrates project to any new GitHub repository
├── apis.txt                     <-- Master reference of all active production keys
│
├── healthexpress/               <-- 📱 Main Flutter Cross-Platform Application
│   ├── lib/
│   │   ├── core/config/app_config.dart   <-- Global API keys and configuration constants
│   │   ├── core/theme/app_colors.dart    <-- Design system tokens & color palette
│   │   ├── data/production_database.dart <-- Offline database & verified hospital dataset
│   │   ├── models/                       <-- Hospital, Doctor, Order, Medicine models
│   │   ├── providers/                    <-- Auth, AI Assistant, Pharmacy, Appointment providers
│   │   ├── screens/user/                 <-- Patient UI, Nearby Hospitals, Voice Call, Pharmacy
│   │   ├── services/                     <-- ApiService, LocationService, DeviceNativeService
│   │   └── widgets/real_mapbox_map.dart  <-- Mapbox GL JS / Leaflet hybrid map widget
│   └── web/
│       └── index.html                    <-- Web Audio, Speech, Mapbox, Agora, Firebase JS SDKs
│
├── admin_panel/                 <-- 💻 React 18 + Vite Operations Dashboard
│   ├── src/
│   │   ├── App.tsx                      <-- Main dashboard routing and layout
│   │   ├── services/api.ts              <-- REST API client for Hostinger MySQL
│   │   └── components/                  <-- Hospital approvals, Pharmacy orders, Live tracker
│   └── package.json
│
├── php_backend/                 <-- 🌐 PHP 8.2 Production REST API
│   ├── api/index.php                    <-- REST API router
│   ├── config/database.php              <-- MySQL PDO database connection
│   └── seed_production_data.php         <-- Database migrations & initial data seeder
│
└── livekit_voice_agent/         <-- 🎙️ Real-time WebRTC Voice AI Sub-250ms Server
    └── server.js
```

---

## 🛠️ 7. Key Architecture Design Patterns

### 1. Dual Map Engine Architecture
- Platform views rendered in Flutter Web are isolated in Flutter's **Shadow DOM**.
- The map system in [`web/index.html`](file:///c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/web/index.html) and [`real_mapbox_map.dart`](file:///c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/lib/widgets/real_mapbox_map.dart) uses direct element registration and recursive shadow DOM traversal.
- It dynamically uses **Mapbox GL JS** with an automatic **Leaflet / CartoDB Voyager** vector tile fallback to guarantee the map never renders blank under any network or WebGL environment.

### 2. Live GPS Location Synchronization
- [`LocationService`](file:///c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/lib/services/location_service.dart) fetches live hardware coordinates via `navigator.geolocation`, falls back to high-accuracy IP Geolocation, and reverse-geocodes the exact neighborhood and city via Mapbox Places API.
- All state providers (`AuthProvider`, `PharmacyProvider`) and hospital radar distance calculations are updated in real time.

### 3. Multilingual Clinical Voice Pipeline
- Combines browser Web Speech VAD (Voice Activity Detection), Sarvam `saaras:v3` STT, `sarvam-105b-conversations` medical LLM, and Sarvam `bulbul:v3` 22kHz HD clinical voice synthesizer (Telugu `kavitha`, Hindi `kavya`, English `priya`).

### 4. Groq Multimodal AI Vision & Diagnostic Scanner
- [`GroqVisionService`](file:///c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/lib/services/groq_vision_service.dart) & [`AiLensScannerScreen`](file:///c:/Users/shese/Desktop/healthyxpress_medha/healthexpress/lib/screens/user/ai_lens_scanner_screen.dart):
  - **Food & Nutrition Scope**: Analyzes meal images, calculates total calories (`kcal`), macros (protein, carbs, fat, fiber, sugar, sodium), Glycemic Index (*Low/Med/High*), Health Score (1-10), and recommends healthier related dishes.
  - **Infection & Disease Scope**: Analyzes skin rashes, wounds, eye/throat symptoms. Determines infection severity (*Mild/Moderate/Urgent*), probable causes, observed symptoms, recommended first-line medications, diagnostic lab tests, and routes users directly to **Book Doctor Appointment** with the relevant specialist (*Dermatologist, General Physician, ENT*).
  - **Medicine & Rx Scope**: Strictly identifies medicine names, chemical molecules, drug classes, clinical indications, dosages, precautions, and 15-min pharmacy fulfillment.
  - **Vision Engine**: Utilizes `qwen/qwen3.6-27b` and `qwen/qwen3.8-27b` multimodal models on Groq Cloud with sanitization of `<think>` reasoning blocks and fallback to `openai/gpt-oss-20b` for interactive follow-up chat.

---

## 📞 8. Support & Maintainer Contact
For questions, infrastructure changes, or credentials provisioning:
- **Platform**: HealthExpress AI
- **Production Server**: Hostinger VPS (`147.93.101.73`)
- **Live Web App**: [https://pavanstarkin-tech.github.io/healthyxpress_medha/](https://pavanstarkin-tech.github.io/healthyxpress_medha/)
- **Live Admin Panel**: [https://pavanstarkin-tech.github.io/healthyxpress_medha/admin/](https://pavanstarkin-tech.github.io/healthyxpress_medha/admin/)

