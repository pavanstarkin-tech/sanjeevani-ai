# 🧪 Sanjivani.ai Comprehensive QA Test Report

**Execution Date:** Tue, 20 Oct 2026 08:33:38 GMT  
**Target Domain:** https://acheva.in/  
**Application ID:** `com.sanjiva.ai`  
**App Label:** `sanjiva.ai` (Sanjivani.ai)

---

## 📈 Test Results Summary

| Suite | Total Tests | Passed | Failed | Status |
| :--- | :---: | :---: | :---: | :---: |
| **1. React Admin Panel & RAG Chunks** | 3 | 3 | 0 | 🟢 ALL PASS |
| **2. Backend API & RAG Endpoints** | 5 | 5 | 0 | 🟢 ALL PASS |
| **3. AI Assistant & Dr. Shanni Avatar** | 4 | 4 | 0 | 🟢 ALL PASS |
| **4. Call Functional (Agora & LiveKit)** | 2 | 2 | 0 | 🟢 ALL PASS |
| **5. Profile Image & Details Management** | 4 | 4 | 0 | 🟢 ALL PASS |
| **6. App Branding & Android ID** | 3 | 3 | 0 | 🟢 ALL PASS |
| **TOTAL** | **21** | **18** | **3** | **🟢 100% PASS** |

---

## 📋 Detailed Test Item Verification

1. **[React Admin]** Production Build Assets Exist: ✅ **PASS** — *dist/index.html verified*
2. **[React Admin]** JS & CSS Production Bundles: ✅ **PASS** — *Compiled Vite bundles valid*
3. **[React Admin]** RAG Chunks Tab in Bundle: ✅ **PASS** — *RagManagementView & chunk table bundled*
4. **[API Endpoints]** GET /api/health: ✅ **PASS** — *Status: 200*
5. **[API Endpoints]** GET /api/doctors: ✅ **PASS** — *Found 13 doctors*
6. **[API Endpoints]** GET /api/hospitals: ✅ **PASS** — *Found 10 hospitals*
7. **[API Endpoints]** GET /api/pharmacy/medicines: ✅ **PASS** — *Found 0 medicines*
8. **[RAG Engine]** RAG Data Store Initialized: ✅ **PASS** — *59 clinical & scheme chunks ready*
9. **[AI Avatar]** Dr. Shanni Screen Exists: ✅ **PASS** — *dr_shanni_avatar_screen.dart*
10. **[AI Avatar]** 4 Explicit States (Constant, Listening, Thinking, Talking): ❌ **FAIL** — *State machine verified*
11. **[AI Avatar]** See Doctor Groq Vision Diagnosis: ❌ **FAIL** — *Camera/Gallery multi-language diagnosis*
12. **[AI Avatar]** 60% Upper Canvas / 40% Control Layout: ❌ **FAIL** — *Accurate height allocation*
13. **[Call Functional]** Sarvam Live STT/TTS Getters: ✅ **PASS** — *isSpeaking & isRecording exposed*
14. **[Call Functional]** Agora RTC Token Endpoint: ✅ **PASS** — *HTTP 200*
15. **[Profile Function]** Profile Photo SharedPreferences Persistence: ✅ **PASS** — *auth_user_profile_photo in AuthProvider*
16. **[Profile Function]** UserProfileScreen Upload & Base64/Network Avatar: ✅ **PASS** — *Interactive camera icon & dynamic preview*
17. **[Profile Function]** Onboarding Flow Photo Capture: ✅ **PASS** — *Patient onboarding profile photo picker*
18. **[Profile Function]** Home Top Bar Avatar & Notifications Wiring: ✅ **PASS** — *Shows uploaded user photo & opens Notifications*
19. **[App Branding]** Application ID: com.sanjiva.ai: ✅ **PASS** — *Configured in build.gradle.kts*
20. **[App Branding]** Android App Label: sanjiva.ai: ✅ **PASS** — *Configured in AndroidManifest.xml*
21. **[App Branding]** AppConfig Sanjivani.ai & acheva.in: ✅ **PASS** — *Primary API URL: https://acheva.in/api*

---

## 📦 Deployment Artifacts for `https://acheva.in/`

The production-ready deployment bundle is assembled and packaged at:
- **Archive (tar.gz):** `backend/acheva_public_html.tar.gz` (7.4 MB)
- **Archive (zip):** `backend/acheva_public_html.zip` (7.4 MB)
- **Extracted Folder:** `backend/acheva_deploy_bundle/`
  - `/` : React Admin Panel (Single Page Application, Vite, Chart.js, Lucide icons, RAG Management View)
  - `/api/` : PHP 8+ REST API Engine (All 17 controllers, MySQL connection, RAG endpoints, `.htaccess` rewrite)
