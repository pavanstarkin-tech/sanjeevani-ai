import logging
import os
from dotenv import load_dotenv
from livekit.agents import (
    JobContext,
    WorkerOptions,
    cli,
)
from livekit.agents.voice import (
    Agent,
    AgentSession,
)
from livekit.plugins import (
    sarvam,
    silero,
)

# ---------------------------------------------------------
# Load environment variables
# ---------------------------------------------------------
load_dotenv()

# ---------------------------------------------------------
# Logging Configuration
# ---------------------------------------------------------
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("healthexpress-livekit-agent")
logger.setLevel(logging.INFO)

# ---------------------------------------------------------
# System Prompt & Clinical Instructions
# ---------------------------------------------------------
HEALTHCARE_INSTRUCTIONS = """
You are Dr. Shanni, a compassionate, knowledgeable, and real-time virtual healthcare assistant and clinical doctor avatar from Sanjeevani.ai.
CRITICAL IDENTITY RULES:
- NEVER say or mention "Health Express" or "HealthExpress".
- Always introduce yourself as "Dr. Shanni" or mention that you are from "Sanjeevani.ai".
Your role is to guide users on general wellness, nutritious diets, government healthcare schemes, and basic over-the-counter medication awareness.

CORE RESPONSIBILITIES:
1. Government Health Schemes: Explain eligibility, benefits, and application processes for Indian healthcare schemes such as Ayushman Bharat (PM-JAY), Dr. YSR Aarogyasri / NTR Vaidya Seva, and Pradhan Mantri Bharatiya Janaushadhi Pariyojana (PMBJP for affordable generic medicines).
2. Healthy Food & Nutrition: Suggest practical, regionally accessible balanced diets, home remedies, hydration habits, and recovery meals tailored to the user's symptoms or lifestyle.
3. Medicines & Medication Guidance: Provide clear educational information on common Over-The-Counter (OTC) medications (such as Paracetamol for fever, ORS for dehydration, or antacids for acidity), how they work, general dosage timing, and potential side effects.

STRICT VOICE & CONVERSATIONAL RULES:
- Speak purely in natural, spoken sentences. NEVER use markdown, bullet points, asterisks (*), numbered lists, or hashtags, because your text is fed directly into a real-time Text-to-Speech engine.
- Keep every response concise (2 to 3 short sentences at a time, roughly 30 to 50 words). Pause and ask a follow-up question so the conversation feels like a real live phone call with a doctor.
- If the user speaks in Telugu (తెలుగు), converse fluently and respectfully in Telugu.
- If the user speaks in Hindi (हिंदी), converse warmly in Hindi.
- If the user speaks English or mixed Indian languages (Hinglish/Telugish), converse naturally.
- Start by asking 1 or 2 clarifying questions about the user's symptoms, age, or duration of discomfort before jumping into suggestions.

VISUAL CAMERA INSPECTION & FACE OBSERVATION:
- If the patient asks "See my face", "Look at me", or asks if you can see them through the camera, warmly say: "I am ready to examine you! Please look straight into your camera and tap the camera icon in the top-right corner of your camera box so I can capture and analyze your live feed in real time."

MEDICAL SAFETY & BOUNDARIES:
- Never prescribe Schedule H or prescription-only antibiotics, steroids, or controlled medications.
- Whenever suggesting an OTC medicine, remind the user to verify with a local pharmacist or physician and check for allergies.
- If the user describes emergency symptoms (chest pain, difficulty breathing, severe bleeding, high persistent fever, or sudden dizziness), immediately instruct them to visit the nearest hospital or call emergency services (108).
"""

def fetch_active_sarvam_api_key() -> str:
    backend_url = os.getenv("BACKEND_API_URL", "https://acheva.in/api")
    try:
        import urllib.request
        import json
        req = urllib.request.Request(f"{backend_url}/public/sarvam-keys/active", headers={"User-Agent": "HealthExpressLiveKit"})
        with urllib.request.urlopen(req, timeout=3) as resp:
            data = json.loads(resp.read().decode())
            if data.get("key"):
                logger.info(f"Using Active Sarvam Key from Server Pool: {data.get('masked_key')}")
                return data["key"]
    except Exception:
        pass
    return os.getenv("SARVAM_API_KEY", "sk_5ijbsyhu_co3XmcxZMgr0Rf0HAjfWvV4x")

# ---------------------------------------------------------
# HealthExpress Clinical AI Voice Agent
# ---------------------------------------------------------
class HealthExpressVoiceAgent(Agent):
    def __init__(self) -> None:
        active_key = fetch_active_sarvam_api_key()
        super().__init__(
            instructions=HEALTHCARE_INSTRUCTIONS,
            # ---------------------------------------------
            # Sarvam Real-Time Speech-to-Text (Saaras v4)
            # Auto-detects Telugu, Hindi, English, etc.
            # ---------------------------------------------
            stt=sarvam.STT(
                api_key=active_key,
                language="unknown",
                model="saaras:v4",
                mode="transcribe",
                flush_signal=True,
            ),
            # ---------------------------------------------
            # Sarvam 105B Conversational Medical LLM
            # ---------------------------------------------
            llm=sarvam.LLM(
                api_key=active_key,
                model="sarvam-105b-conversations",
            ),
            # ---------------------------------------------
            # Sarvam Real-Time Voice Synthesis (Bulbul v4-flash)
            # Ultra-low latency voice output
            # ---------------------------------------------
            tts=sarvam.TTS(
                api_key=active_key,
                target_language_code="en-IN",
                model="bulbul:v4-flash",
                speaker="ishita_en_medical",
            ),
            # ---------------------------------------------
            # Silero Voice Activity Detection (VAD)
            # ---------------------------------------------
            vad=silero.VAD.load(),
        )

    async def on_enter(self):
        """Warm clinical greeting immediately when patient joins the room."""
        logger.info("Patient entered room. Generating immediate clinical greeting...")
        self.session.generate_reply(
            instructions="Greet the patient warmly as Dr. Shanni from Sanjeevani.ai. Never mention Health Express or HealthExpress. Ask how you can help with their health symptoms, diet, medicines, or government health schemes today."
        )

# ---------------------------------------------------------
# LiveKit Room Entrypoint
# ---------------------------------------------------------
async def entrypoint(ctx: JobContext):
    import json
    await ctx.connect()
    logger.info(f"Connected Sanjeevani.ai Voice Agent to room: {ctx.room.name}")
    
    session = AgentSession()

    @ctx.room.on("data_received")
    def on_data_received(data_packet):
        try:
            payload = json.loads(data_packet.data.decode("utf-8"))
            if payload.get("type") == "vision_analysis":
                vision_text = payload.get("text", "")
                logger.info(f"Received Vision Analysis from patient camera: {vision_text}")
                session.generate_reply(
                    instructions=f"The patient just showed their camera. Clinical vision diagnosis: {vision_text}. Respond immediately as Dr. Shanni from Sanjeevani.ai greeting them ('Hello!') and explaining your visual observations and health advice directly to the patient in 2 to 3 spoken sentences. Never mention Health Express."
                )
        except Exception as e:
            logger.error(f"Error handling vision data packet: {e}")
    
    await session.start(
        agent=HealthExpressVoiceAgent(),
        room=ctx.room,
    )

# ---------------------------------------------------------
# Worker Runner
# ---------------------------------------------------------
if __name__ == "__main__":
    cli.run_app(
        WorkerOptions(
            entrypoint_fnc=entrypoint
        )
    )
