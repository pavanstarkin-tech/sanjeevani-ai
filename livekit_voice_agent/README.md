# HealthExpress AI - Real-Time Sarvam + LiveKit Voice Agent

Full-Duplex Real-Time Conversational AI Voice Assistant for HealthExpress.

## Architecture
```
Browser / App (Microphone)
       │
       ▼ (WebRTC Audio Stream)
┌──────────────┐
│ LiveKit Cloud│ (wss://luca-vsv9whhr.livekit.cloud)
└──────┬───────┘
       │
       ▼ (Sub-100ms WebRTC Pipeline)
┌──────────────────────────────┐
│ Python LiveKit Voice Agent   │
│  ├── STT: Sarvam Saaras v4   │ (flush_signal=True, min_endpointing_delay=0.07)
│  ├── LLM: Sarvam 105B Conv   │
│  └── TTS: Sarvam Bulbul v3   │ (shubh / multilingual Indian voices)
└──────┬───────────────────────┘
       │
       ▼ (Real-time Audio Response)
LiveKit Cloud ➔ Browser Audio Speaker
```

---

## Quick Start Guide

### Step 1: Install Python Requirements & Run Voice Agent
```bash
cd livekit_voice_agent

# 1. Create and activate virtual environment
python -m venv venv

# Windows:
venv\Scripts\activate

# macOS / Linux:
source venv/bin/activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Start LiveKit Voice Agent
python agent.py dev
```

### Step 2: Start Token Server
In a separate terminal:
```bash
cd livekit_voice_agent
npm install
node token_server.js
```

### Step 3: Test Voice Agent in Console Mode
```bash
python agent.py console
```
You can now speak into your microphone and test real-time Telugu, Hindi, and English voice triage.
