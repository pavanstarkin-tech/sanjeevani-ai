# Sanjeevani.ai (సంజీవని) 🩺
### *The Edge-First Multimodal Healthcare Super-App for 1.4 Billion People*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![On-Device SLM](https://img.shields.io/badge/On--Device%20SLM-Llama%203.2%201B-FF6F00)](https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF)
[![Medical RAG](https://img.shields.io/badge/Medical%20RAG-128--d%20Dense%20Vectors-10B981)](#-on-device-medical-rag-pipeline)
[![Offline First](https://img.shields.io/badge/Offline%20First-Zero%20Cloud%20Fallback-0EA5E9)](#-zero-internet-intelligence--5-km-grid)
[![ABDM Compliant](https://img.shields.io/badge/ABDM-15--Min%20Dynamic%20QR-8B5CF6)](https://abdm.gov.in)
[![Production](https://img.shields.io/badge/Production-acheva.in-047857)](https://acheva.in)

---

## 🌟 Executive Overview

**Sanjeevani.ai** is a mission-critical, edge-first healthcare super-application engineered to bridge the four deepest divides in healthcare accessibility across rural and urban India:
1. **Connectivity Dropouts**: Solved with native on-device **Medical RAG** running over a local **Llama 3.2 1B Instruct** model and an offline **5 km emergency grid**.
2. **Language & Literacy Barriers**: Solved via regional voice agents (Telugu, Hindi, English, Tanglish/Hinglish) and an interactive photorealistic **AI Doctor Avatar (Dr. Medha)**.
3. **Unaffordable Branded Medications**: Solved through automated **Jan Aushadhi (PMBJP)** generic drug comparison (50% to 80%+ savings) and 15-minute quick-commerce delivery.
4. **Emergency Delays**: Solved with 1-tap **108 emergency SOS**, real-time hospital bed vacancy telemetry, and an interactive **110 BPM CPR pulse metronome**.

---

## 🏗️ Quad-Core System Architecture

```
                                  ┌──────────────────────────────────────────────┐
                                  │           USER INTERACTION LAYER             │
                                  ├──────────────────────┬───────────────────────┤
                                  │  Live Voice Agent    │  AI Doctor Avatar     │
                                  │  (Sarvam AI STT/TTS) │  (Dr. Medha WebRTC)   │
                                  └──────────┬───────────┴───────────┬───────────┘
                                             │                       │
                       ┌─────────────────────▼───────────────────────▼────────────────────┐
                       │                   SANJEEVANI CORE CLIENT (FLUTTER)               │
                       ├─────────────────────────────────┬────────────────────────────────┤
                       │  Online Cloud Pipeline          │  Offline Edge Engine           │
                       │  - NVIDIA NIM (GPT-OSS-20B)     │  - Llama 3.2 1B Instruct Q4    │
                       │  - Groq Llama 3.2 Vision (OCR)  │  - On-Device Medical RAG Layer │
                       │  - Mapbox GL Vector Telemetry   │  - 128-d Dense Hybrid Search   │
                       │  - Agora HD RTC Teleconsult     │  - 0ms Emergency Classifier    │
                       │  - Razorpay Payment Gateway     │  - 110 BPM CPR Audio Metronome │
                       └─────────────────┬───────────────┴────────────────┬───────────────┘
                                         │                                │
                       ┌─────────────────▼───────────────┐ ┌──────────────▼───────────────┐
                       │   CLOUD BACKEND & SUPER ADMIN   │ │    SOVEREIGN & LOCAL DATA    │
                       │   - Hostinger VPS (acheva.in)   │ │  - AHA/ERC/WHO First-Aid     │
                       │   - Node.js Express REST API    │ │  - ICMR Clinical Protocols   │
                       │   - MariaDB Database Cluster    │ │  - Jan Aushadhi Generic Drug │
                       │   - React 19 Ops Command Center │ │  - Aarogyasri (₹25L) & PMJAY │
                       └─────────────────────────────────┘ └──────────────────────────────┘
```

---

## ⚡ Key Capabilities & Feature Modules

### 1. 🧠 On-Device Medical RAG Pipeline (100% Offline)
- **Local Model**: Pre-bundled asset model [`Llama-3.2-1B-Instruct-Q4_K_M.gguf`](file:///c:/Users/shese/Desktop/sanjeevani%20ai/healthexpress/assets/models/) (803 MB) running via native ARM64 `llama.cpp` shared libraries.
- **Fast Emergency Risk Detection**: Sub-2ms local safety classifier scans for critical life-threats (Cardiac Arrest, Stroke FAST, Poisoning, Hemorrhage, Anaphylaxis) and triggers prevalidated emergency steps and a **108 ambulance callout** before LLM generation begins.
- **Hybrid Retrieval**: Combines 128-dimensional dense semantic vector cosine similarity (65%) with BM25 token overlap (35%) and clinical entity boosting.
- **Clinical Evidence Base**: Ingests authoritative guidelines:
  - **AHA / ERC / WHO**: Adult CPR, Choking (Heimlich), Burns, Anaphylaxis, Snakebite.
  - **ICMR Protocols**: Dengue fever & Thrombocytopenia, Diabetes Mellitus, Hypertension crisis.
  - **Jan Aushadhi**: WHO-GMP generic bioequivalents & pricing compendium.
  - **Sovereign Schemes**: Dr. YSR Aarogyasri (₹25 Lakh) and Ayushman Bharat PM-JAY (₹5 Lakh).
- **Prompt Guardrails**: Verbatim 20-rule master system instruction preventing medical hallucinations, enforcing evidence grounding (`<retrieved_medical_context>`), and providing verified source attribution.

### 2. 🎙️ Multimodal Humanized Care (Voice, Avatar & Vision)
- **Regional Voice Agent**: Powered by Sarvam AI (`saaras:v3` Speech-to-Text and `bulbul:v3` Text-to-Speech) supporting fluent Telugu, Hindi, English, Tanglish (*"naku jwaram undi"*), and Hinglish. Features Web Audio RMS Voice Activity Detection (VAD) for hands-free conversations.
- **Interactive Doctor Avatar (Dr. Medha)**: Photorealistic female physician avatar with live lip-sync, expressing 5 dynamic states (*Idle, Listening, Thinking, Speaking, Emergency*).
- **AI Lens Scanner (Groq Vision)**: Deciphers handwritten doctor prescriptions and identifies pill blister packs (strength, dosage, expiry date) in under 2 seconds.

### 3. 🚀 15-Minute Medicine Quick-Commerce & Jan Aushadhi
- **Hyperlocal Dispatch**: Routes prescription orders to pharmacy dark stores within a 3–5 km radius with an automated 15-minute emergency delivery SLA.
- **Live Rider Tracking**: Real-time vector Mapbox GPS tracking with rider telemetry.
- **Jan Aushadhi Comparator**: Chemical salt-to-salt matching that switches expensive branded medicines to identical PMBJP generic alternatives, reducing out-of-pocket costs by 50% to 80%+.
- **30-Minute Medicine Hold Token**: Allows patients to lock critical pharmacy stocks for 30 minutes with a generated verification OTP.

### 4. 🏥 Hyperlocal Discovery & 5 km Emergency Health Grid
- **Bed & Blood Telemetry**: Real-time bed availability tracking (General Beds, ICU Beds, Ventilators, and Oxygen Beds) and Blood Bank units (A+, B+, O+, O-) across nearby empaneled hospitals.
- **1-Tap 108 Emergency SOS**: Instant panic button broadcasting live GPS coordinates, patient history, and pre-triage notes to emergency dispatchers while reserving a trauma bed.
- **RMP Rural Doctor Home Visits**: Dedicated dispatch booking for verified Rural Medical Practitioners to conduct home checkups and vitals screening for elderly patients.

### 5. 👨‍⚕️ Doctor-Only Portal & Teleconsultation Suite
- **Pre-Consultation AI SOAP Notes**: Doctors review AI-generated Subjective, Objective, Assessment, and Plan summaries before joining calls.
- **Agora HD Telehealth**: Sub-200ms encrypted 2-way WebRTC video room with integrated audio volume metering.
- **Digital E-Prescription Builder**: In-call prescription tool that digitally signs orders and automatically routes medications into the patient's 15-minute quick-commerce cart.

### 6. 🛡️ Sovereign Health Schemes & ABDM Privacy QR
- **Cashless Scheme Navigator**: Native eligibility verification for **Dr. YSR Aarogyasri** (₹25 Lakh) and **Ayushman Bharat PM-JAY** (₹5 Lakh) across 3,257+ empaneled surgical procedures.
- **ABDM 15-Minute Dynamic QR**: Time-bound, self-expiring QR consent token (15 to 120 minutes) enabling doctors to inspect patient EHR records securely without physical paperwork.

### 7. 📊 Operations Command Center & Syndromic Surveillance
- **Web Admin Panel (`acheva.in`)**: Production React 19 dashboard hosted on Hostinger VPS managing hospital bed telemetry, pharmacy inventories, doctor license verifications, and Razorpay transactions.
- **Syndromic Outbreak Heatmap**: GIS early-warning system that tracks regional symptom spikes (Dengue, Malaria, Gastroenteritis) to forecast disease outbreaks days before hospital admissions register them.

---

## 📁 Repository Structure

```
healthexpress/
├── assets/
│   ├── models/                                # Bundled on-device GGUF models
│   │   └── Llama-3.2-1B-Instruct-Q4_K_M.gguf  # Pre-built 803 MB Llama asset
│   ├── images/                                # Splash, banners, quick actions
│   ├── audio/                                 # CPR 110 BPM metronome beats
│   └── data/                                  # Local medical protocol registries
├── lib/
│   ├── core/
│   │   ├── config/                            # Environment config & API keys
│   │   ├── services/                          # Network, location & audio utilities
│   │   └── theme/                             # AppColors, typography & UI tokens
│   ├── data/
│   │   └── validated_first_aid_protocols.dart # 10 WHO/AHA First-Aid protocols
│   ├── models/
│   │   ├── medical_rag_chunk.dart             # Medical RAG chunk & retrieval models
│   │   └── offline_medical_models.dart        # SLM, triage & protocol data structures
│   ├── providers/
│   │   ├── offline_medical_slm_provider.dart  # Central offline SLM & RAG coordinator
│   │   └── ai_assistant_provider.dart         # Cloud AI & multimodal assistant provider
│   ├── screens/
│   │   ├── user/
│   │   │   ├── offline_ai_doctor_screen.dart  # Flagship On-Device SLM + RAG Screen
│   │   │   ├── ai_assistant_screen.dart       # Online Multimodal AI Assistant
│   │   │   ├── emergency_ambulance_screen.dart# 108 SOS & Hospital Bed Telemetry
│   │   │   ├── pharmacy_cart_screen.dart      # 15-Min Quick-Commerce Cart
│   │   │   └── doctor_consultation_screen.dart# Agora HD Telemedicine Suite
│   │   └── doctor/                            # Doctor-only portal & clinical tools
│   ├── services/
│   │   ├── medical_slm_engine_service.dart    # llama_cpp_dart inference & prompt formatter
│   │   ├── offline_medical_rag_service.dart   # Hybrid vector retriever & risk classifier
│   │   ├── model_storage_service.dart         # Asset loading & local storage manager
│   │   └── offline_voice_service.dart         # Flutter TTS & STT voice engine
│   └── widgets/
│       ├── markdown_formatted_text.dart       # Rich clinical tables & markdown parser
│       └── first_aid_flow_overlay.dart        # Interactive CPR & first-aid steps
└── test/
    ├── offline_medical_rag_test.dart          # 14 comprehensive on-device RAG tests
    └── offline_medical_slm_test.dart          # First-aid protocol & triage tests
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: 3.24.0 or newer
- **Dart SDK**: 3.5.0 or newer
- **Android SDK**: API level 26+ (Android 8.0+)
- **Architecture**: ARM64 device / emulator (for native `llama.cpp` inference)

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/pavanstarkin-tech/sanjeevani.ai.git
cd "sanjeevani ai/healthexpress"
flutter pub get
```

### 2. Verify On-Device Asset Model
Ensure the pre-bundled GGUF model is present under `assets/models/`:
- `assets/models/Llama-3.2-1B-Instruct-Q4_K_M.gguf` (803 MB)

### 3. Run Automated Medical RAG Test Suite
Validate the complete 14-scenario offline RAG and emergency triage pipeline:
```bash
flutter test test/offline_medical_rag_test.dart
```

### 4. Launch Application
```bash
# Debug mode on connected Android device
flutter run -d <device-id>

# Build production APK
flutter build apk --release
```

---

## 🧪 Verification & Test Coverage

The project includes an automated test suite verifying all 14 Section 10 clinical requirements:

| Test Case | Description | Status |
|:---:|---|:---:|
| **1** | Normal medical query retrieves strong supporting ICMR chunks with metadata | **PASSED** |
| **2** | Out-of-domain queries (e.g. stock market) explicitly flag insufficient evidence | **PASSED** |
| **3** | Unrelated queries (e.g. mechanical tire change) filtered by confidence threshold | **PASSED** |
| **4** | Outdated/conflicting sources preserve review date and clinical versioning | **PASSED** |
| **5** | Life-threat symptoms (Chest pain, Stroke FAST, Dyspnea) trigger 108 escalation | **PASSED** |
| **6** | Poisoning and overdose scenarios enforce "do not induce vomiting" protocols | **PASSED** |
| **7** | Emergency fast-path operates 100% reliably even if vector database is empty | **PASSED** |
| **8** | Prevalidated emergency actions return instantaneously (< 2ms) without waiting for LLM | **PASSED** |
| **9** | Prompt injection instructions inside retrieved text are neutralized by safety rules | **PASSED** |
| **10** | Dense embedding projection and cosine search run 100% locally with zero HTTP calls | **PASSED** |
| **11** | Ambiguous symptoms prompt clarifying questions without false diagnostic certainty | **PASSED** |
| **12** | Very long queries are budgeted safely within the 2048 context window | **PASSED** |
| **13** | Edge retrieval latency benchmarks at **< 2 milliseconds** on CPU | **PASSED** |
| **14** | Section 4 structured response parser extracts all clinical fields & emergency state | **PASSED** |

---

## 🌐 Production Deployments

- **Admin Operations Center**: [https://acheva.in](https://acheva.in) (Hostinger VPS)
- **API Server**: Node.js / Express microservices backed by MariaDB
- **Client App**: Sanjeevani.ai Flutter mobile client

---

## 📜 Medical & Regulatory Disclaimer

*Sanjeevani.ai is an intelligent assistive triage, first-aid guidance, and healthcare access platform. It does not replace professional medical advice, clinical diagnosis, or emergency dispatch services. In any acute or life-threatening emergency, users must immediately contact official emergency services (dial **108** or **112** in India).*

---

**Built with pride by the Sanjeevani.ai Engineering Team** 🇮🇳
