# **Flutter LiveKit Healthcare Voice Agent Setup**

[https\://gemini.google.com/app/c10bf4d3600b22db](https://gemini.google.com/app/c10bf4d3600b22db)

*User prompt:  please give me the instructions and an instructional prompt to set up the voice agent and a digital author. I'm using LiveKit, and for LiveKit TDS STD, I'm using the Serpom API. For the LLM, I think I'm also using Serpom. In the case of using the Serpom API, I want to integrate this live call assistant and live doctor avatar. The live call avatar, live call doctor avatar, and live call assistant are all the same. Only in the live doctor avatar will the avatar video be played whenever the AI is responding through the speaker. Give me full instructions on how to set it up. I am using Flutter code, so now give me the instructions to implement this functionality. If possible, also give the related code. I want to make it a real-time working one. It should act like a healthcare assistant. It will suggest health schemes, healthy food, medicines, and medication suggestions. It should work in real time because we are using LiveKit, right? *

Response: To build your real-time healthcare assistant and live doctor avatar using **LiveKit**, **Sarvam AI** (for TTS, STT, and LLM), and **Flutter**, your architecture splits into two layers:

> 1. **Python LiveKit Agent Backend:** Connects to your LiveKit room and routes real-time audio through Sarvam AI (saaras:v4 for STT, sarvam-105b for LLM, and bulbul:v4-flash for TTS).  
> 2. **Flutter Client App:** Joins the same LiveKit WebRTC room, captures the user's microphone, plays the AI's audio response, and listens to the remote participant's isSpeaking event (or lk.agent.state attribute) to dynamically play/pause your local doctor avatar video whenever the AI speaks.

## **1\. Instructional System Prompt (Healthcare & Doctor Avatar)**

Use this instructional prompt inside your LiveKit Agent configuration. It is specifically tuned for voice output (removing markdown characters so the TTS reads smoothly) and covers health schemes, nutrition, and OTC medication guidance safely.

`You are Dr. Arogya, a compassionate, knowledgeable, and real-time virtual healthcare assistant and digital doctor avatar. Your role is to guide users on general wellness, nutritious diets, government healthcare schemes, and basic medication awareness.`

`CORE RESPONSIBILITIES:`  
`1. Government Health Schemes: Explain eligibility, benefits, and application processes for Indian healthcare schemes such as Ayushman Bharat (PM-JAY), Dr. YSR Aarogyasri / NTR Vaidya Seva, Pradhan Mantri Bharatiya Janaushadhi Pariyojana (PMBJP for affordable generic medicines), and maternal health programs.`  
`2. Healthy Food & Nutrition: Suggest practical, regionally accessible balanced diets, home remedies, hydration habits, and recovery meals tailored to the user's symptoms or lifestyle.`  
`3. Medicines & Medication Guidance: Provide clear educational information on common Over-The-Counter (OTC) medications (such as Paracetamol for fever, ORS for dehydration, or antacids for acidity), how they work, general dosage timing, and potential side effects.`

`STRICT VOICE & CONVERSATIONAL RULES:`  
`- Speak purely in natural, spoken sentences. NEVER use markdown, bullet points, asterisks (*), numbered lists, or hashtags, because your text is fed directly into a real-time Text-to-Speech engine.`  
`- Keep every response concise (2 to 3 short sentences at a time, roughly 30 to 50 words). Pause and ask a follow-up question so the conversation feels like a real live phone call with a doctor.`  
`- Start by asking 1 or 2 clarifying questions about the user's symptoms, age, or duration of discomfort before jumping into suggestions.`

`MEDICAL SAFETY & BOUNDARIES:`  
`- Never prescribe Schedule H or prescription-only antibiotics, steroids, or controlled medications.`  
`- Whenever suggesting an OTC medicine, remind the user to verify with a local pharmacist or physician and check for allergies.`  
`- If the user describes emergency symptoms (chest pain, difficulty breathing, severe bleeding, high persistent fever, or sudden dizziness), immediately instruct them to visit the nearest hospital or call emergency services (108).`

## **2\. Step-by-Step Setup Instructions**

**1Set up LiveKit Cloud and Sarvam AI Keys**

Requires Python 3.10+ and Flutter 3.19+

Create accounts on **LiveKit Cloud** (cloud.livekit.io) and **Sarvam AI** (dashboard.sarvam.ai). Copy your LIVEKIT\_URL, LIVEKIT\_API\_KEY, LIVEKIT\_API\_SECRET, and SARVAM\_API\_KEY.

**2Install the Python LiveKit Agent with Sarvam Plugin**

Run on your backend server or local dev machine

Install the official LiveKit Agents SDK along with the Sarvam and Silero VAD plugins:

`pip install "livekit-agents[sarvam,silero]" python-dotenv`

Create a .env file in your backend folder containing your four keys:

`LIVEKIT_URL=wss://your-project.livekit.cloud`  
`LIVEKIT_API_KEY=APIxxxxxxx`  
`LIVEKIT_API_SECRET=xxxxxxxxxx`  
`SARVAM_API_KEY=your_sarvam_api_key`

**3Run the Real-Time Agent Worker**

Save the Python backend code (provided in Section 3 below) as agent.py and start the worker in development mode:

`python agent.py dev`

Whenever a Flutter user joins a LiveKit room, this worker automatically dispatches your AI Doctor into that room.

**4Configure the Flutter Application & Assets**

Requires microphone permissions on Android and iOS

Add livekit\_client, video\_player, and permission\_handler to your pubspec.yaml:

`dependencies:`  
  `flutter:`  
    `sdk: flutter`  
  `livekit_client: ^2.3.0`  
  `video_player: ^2.8.6`  
  `permission_handler: ^11.3.1`

Place a seamless looping video of your doctor speaking in assets/videos/doctor\_speaking.mp4 (and optionally an idle blinking loop or static portrait in assets/images/doctor\_idle.png) and declare them in pubspec.yaml.

**5Add Android and iOS Microphone Permissions**

In android/app/src/main/AndroidManifest.xml, add:

`<uses-permission android:name="android.permission.RECORD_AUDIO" />`  
`<uses-permission android:name="android.permission.INTERNET" />`  
`<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />`

In ios/Runner/Info.plist, add NSMicrophoneUsageDescription.

## **3\. Python Backend Code (agent.py with Sarvam STT, LLM & TTS)**

This uses the official livekit-plugins-sarvam integration. You can set language to "en-IN", "te-IN" (Telugu), "hi-IN" (Hindi), or "unknown" (auto-detect).

`import logging`  
`from dotenv import load_dotenv`  
`from livekit.agents import JobContext, WorkerOptions, cli`  
`from livekit.agents.voice import Agent, AgentSession`  
`from livekit.plugins import sarvam, silero`

`load_dotenv()`  
`logger = logging.getLogger("healthcare-voice-agent")`  
`logger.setLevel(logging.INFO)`

`HEALTHCARE_INSTRUCTIONS = """`  
`You are Dr. Arogya, a compassionate, knowledgeable, and real-time virtual healthcare assistant and digital doctor avatar.`  
`Your role is to guide users on general wellness, nutritious diets, government healthcare schemes (such as Ayushman Bharat, Aarogyasri, and PMBJP generic medicine stores), and basic over-the-counter medication awareness.`  
`Speak purely in natural, spoken sentences without any markdown, bullet points, or asterisks.`  
`Keep every response concise—around 2 to 3 short sentences—and ask a follow-up question to keep the conversation interactive.`  
`Never prescribe restricted antibiotics or controlled substances, and always advise consulting a certified doctor for severe symptoms.`  
`"""`

`class HealthcareDoctorAgent(Agent):`  
    `def __init__(self) -> None:`  
        `super().__init__(`  
            `instructions=HEALTHCARE_INSTRUCTIONS,`  
            `# Sarvam Saaras v4 for real-time Speech-to-Text`  
            `stt=sarvam.STT(`  
                `language="en-IN", # Use "te-IN" for Telugu, "hi-IN" for Hindi, or "unknown" for auto-detect`  
                `model="saaras:v4",`  
                `mode="transcribe",`  
            `),`  
            `# Sarvam LLM for generating healthcare responses`  
            `llm=sarvam.LLM(`  
                `model="sarvam-105b-conversations",`  
            `),`  
            `# Sarvam Bulbul v4 Flash for ultra-low-latency Text-to-Speech`  
            `tts=sarvam.TTS(`  
                `language_code="en-IN",`  
                `model="bulbul:v4-flash",`  
                `speaker="anand", # Male doctor voice: "anand", "aditya", "rohan" | Female: "simran_en_customer", "priya"`  
            `),`  
            `vad=silero.VAD.load(),`  
        `)`

    `async def on_enter(self):`  
        `# Greet the patient immediately when they join the call`  
        `self.session.generate_reply(`  
            `instructions="Greet the user warmly as Dr. Arogya and ask how you can help with their health, diet, medicines, or health schemes today."`  
        `)`

`async def entrypoint(ctx: JobContext):`  
    `await ctx.connect()`  
    `logger.info(f"Patient connected to room: {ctx.room.name}")`

    `session = AgentSession()`  
    `await session.start(`  
        `agent=HealthcareDoctorAgent(),`  
        `room=ctx.room,`  
    `)`

`if __name__ == "__main__":`  
    `cli.run_app(WorkerOptions(entrypoint_fnc=entrypoint))`

## **4\. Flutter Code: Unified Live Call Assistant & Doctor Avatar**

Since your **Live Call Assistant** and **Live Doctor Avatar** share the exact same LiveKit session and backend logic, you can pass a single boolean (isDoctorAvatarMode) into the screen—or let the user toggle between **Voice Call Mode** and **Doctor Avatar Mode** live during the call.

### **How the Avatar Sync Works in Real Time**

LiveKit automatically tracks voice energy and agent state on the remote participant (RemoteParticipant). Whenever Sarvam TTS streams audio through the speaker:

> 1. participant.isSpeaking turns true **OR** participant.attributes\['lk.agent.state'\] \== 'speaking'.  
> 2. A EventsListener\<RoomEvent\> in Flutter detects ActiveSpeakersChangedEvent and ParticipantAttributesChanged.  
> 3. When the AI starts speaking, \_videoController.play() triggers immediately. The moment the AI stops speaking, \_videoController.pause() (and optional reset to frame 0\) keeps the doctor silently listening.

`import 'package:flutter/material.dart';`  
`import 'package:livekit_client/livekit_client.dart';`  
`import 'package:permission_handler/permission_handler.dart';`  
`import 'package:video_player/video_player.dart';`

`class LiveHealthcareAssistantScreen extends StatefulWidget {`  
  `final String livekitUrl;`  
  `final String roomToken;`  
  `final bool initialAvatarMode; // true = Live Doctor Avatar, false = Audio Call Assistant`

  `const LiveHealthcareAssistantScreen({`  
    `super.key,`  
    `required this.livekitUrl,`  
    `required this.roomToken,`  
    `this.initialAvatarMode = true,`  
  `});`

  `@override`  
  `State<LiveHealthcareAssistantScreen> createState() =>`  
      `_LiveHealthcareAssistantScreenState();`  
`}`

`class _LiveHealthcareAssistantScreenState`  
    `extends State<LiveHealthcareAssistantScreen> {`  
  `Room? _room;`  
  `EventsListener<RoomEvent>? _listener;`  
  `late VideoPlayerController _avatarVideoController;`

  `bool _isConnected = false;`  
  `bool _isMicMuted = false;`  
  `bool _isAiSpeaking = false;`  
  `late bool _isDoctorAvatarMode;`  
  `String _agentStatusText = "Connecting to Dr. Arogya...";`

  `@override`  
  `void initState() {`  
    `super.initState();`  
    `_isDoctorAvatarMode = widget.initialAvatarMode;`  
    `_initAvatarVideo();`  
    `_connectToLiveKit();`  
  `}`

  `/// 1. Initialize the local looping Doctor Avatar video`  
  `Future<void> _initAvatarVideo() async {`  
    `_avatarVideoController = VideoPlayerController.asset(`  
      `'assets/videos/doctor_speaking.mp4',`  
    `);`  
    `await _avatarVideoController.initialize();`  
    `await _avatarVideoController.setLooping(true);`  
    `await _avatarVideoController.setVolume(0.0); // Mute video file; audio comes from LiveKit`  
    `setState(() {});`  
  `}`

  `/// 2. Connect to LiveKit Room and listen for AI speech events`  
  `Future<void> _connectToLiveKit() async {`  
    `await Permission.microphone.request();`

    `final room = Room(`  
      `roomOptions: const RoomOptions(`  
        `adaptiveStream: true,`  
        `dynacast: true,`  
      `),`  
    `);`

    `_listener = room.createListener();`

    `// Listen to active speaker changes (fires in real time when AI TTS audio plays)`  
    `_listener!`  
      `..on<ActiveSpeakersChangedEvent>((event) {`  
        `_checkIfAgentIsSpeaking();`  
      `})`  
      `..on<ParticipantAttributesChanged>((event) {`  
        `_checkIfAgentIsSpeaking();`  
      `})`  
      `..on<ParticipantConnectedEvent>((event) {`  
        `setState(() {`  
          `_agentStatusText = "Dr. Arogya is online";`  
        `});`  
      `})`  
      `..on<RoomDisconnectedEvent>((event) {`  
        `setState(() {`  
          `_isConnected = false;`  
          `_agentStatusText = "Call ended";`  
        `});`  
        `_syncAvatarPlayback(false);`  
      `});`

    `try {`  
      `await room.connect(widget.livekitUrl, widget.roomToken);`  
      `await room.localParticipant?.setMicrophoneEnabled(true);`

      `// Ensure speakerphone is enabled for voice/avatar calls`  
      `await Hardware.instance.setSpeakerphoneOn(true);`

      `setState(() {`  
        `_room = room;`  
        `_isConnected = true;`  
        `_agentStatusText = "Listening...";`  
      `});`  
    `} catch (e) {`  
      `setState(() {`  
        `_agentStatusText = "Connection failed: $e";`  
      `});`  
    `}`  
  `}`

  `/// 3. Detect whether the Sarvam/LiveKit Agent is currently speaking`  
  `void _checkIfAgentIsSpeaking() {`  
    `if (_room == null) return;`

    `bool agentSpeaking = false;`  
    `String status = "Listening...";`

    `for (final participant in _room!.remoteParticipants.values) {`  
      `final agentState = participant.attributes['lk.agent.state'];`

      `// Check both LiveKit's WebRTC audio level detector and the official Agent state attribute`  
      `if (participant.isSpeaking || agentState == 'speaking') {`  
        `agentSpeaking = true;`  
        `status = "Dr. Arogya is speaking...";`  
        `break;`  
      `} else if (agentState == 'thinking') {`  
        `status = "Dr. Arogya is thinking...";`  
      `}`  
    `}`

    `if (agentSpeaking != _isAiSpeaking || status != _agentStatusText) {`  
      `setState(() {`  
        `_isAiSpeaking = agentSpeaking;`  
        `_agentStatusText = status;`  
      `});`  
      `_syncAvatarPlayback(agentSpeaking);`  
    `}`  
  `}`

  `/// 4. Play the Doctor Avatar video ONLY when AI is speaking through the speaker`  
  `void _syncAvatarPlayback(bool shouldPlay) {`  
    `if (!_avatarVideoController.value.isInitialized) return;`

    `if (shouldPlay && _isDoctorAvatarMode) {`  
      `if (!_avatarVideoController.value.isPlaying) {`  
        `_avatarVideoController.play();`  
      `}`  
    `} else {`  
      `if (_avatarVideoController.value.isPlaying) {`  
        `_avatarVideoController.pause();`  
        `// Optional: Reset to a neutral closed-mouth frame (e.g., 0ms) when silent`  
        `_avatarVideoController.seekTo(Duration.zero);`  
      `}`  
    `}`  
  `}`

  `Future<void> _toggleMic() async {`  
    `if (_room?.localParticipant == null) return;`  
    `final nextState = !_isMicMuted;`  
    `await _room!.localParticipant!.setMicrophoneEnabled(!nextState);`  
    `setState(() {`  
      `_isMicMuted = nextState;`  
    `});`  
  `}`

  `void _toggleAvatarMode(bool value) {`  
    `setState(() {`  
      `_isDoctorAvatarMode = value;`  
    `});`  
    `_syncAvatarPlayback(_isAiSpeaking);`  
  `}`

  `@override`  
  `void dispose() {`  
    `_listener?.dispose();`  
    `_room?.disconnect();`  
    `_room?.dispose();`  
    `_avatarVideoController.dispose();`  
    `super.dispose();`  
  `}`

  `@override`  
  `Widget build(BuildContext context) {`  
    `return Scaffold(`  
      `backgroundColor: const Color(0xFF0B0F19),`  
      `appBar: AppBar(`  
        `backgroundColor: Colors.transparent,`  
        `elevation: 0,`  
        `title: Text(`  
          `_isDoctorAvatarMode ? "Live Doctor Avatar" : "Live Call Assistant",`  
          `style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),`  
        `),`  
        `actions: [`  
          `Row(`  
            `children: [`  
              `const Text("Avatar", style: TextStyle(color: Colors.white70, fontSize: 12)),`  
              `Switch(`  
                `value: _isDoctorAvatarMode,`  
                `activeColor: const Color(0xFF00E5FF),`  
                `onChanged: _toggleAvatarMode,`  
              `),`  
            `],`  
          `),`  
        `],`  
      `),`  
      `body: SafeArea(`  
        `child: Column(`  
          `mainAxisAlignment: MainAxisAlignment.spaceBetween,`  
          `children: [`  
            `// Mode Badge & Status`  
            `Padding(`  
              `padding: const EdgeInsets.only(top: 12.0),`  
              `child: Column(`  
                `children: [`  
                  `Container(`  
                    `padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),`  
                    `decoration: BoxDecoration(`  
                      `color: const Color(0xFF1A233A),`  
                      `borderRadius: BorderRadius.circular(20),`  
                      `border: Border.all(`  
                        `color: _isAiSpeaking ? const Color(0xFF00E5FF) : Colors.white24,`  
                      `),`  
                    `),`  
                    `child: Text(`  
                      `_agentStatusText,`  
                      `style: TextStyle(`  
                        `color: _isAiSpeaking ? const Color(0xFF00E5FF) : Colors.white70,`  
                        `fontSize: 14,`  
                        `fontWeight: FontWeight.w500,`  
                      `),`  
                    `),`  
                  `),`  
                `],`  
              `),`  
            `),`

            `// Center Display: Doctor Video Avatar OR Voice Assistant Pulse`  
            `Expanded(`  
              `child: Center(`  
                `child: _isDoctorAvatarMode`  
                    `? _buildDoctorAvatarView()`  
                    `: _buildAudioAssistantView(),`  
              `),`  
            `),`

            `// Bottom Call Controls`  
            `Padding(`  
              `padding: const EdgeInsets.only(bottom: 36.0),`  
              `child: Row(`  
                `mainAxisAlignment: MainAxisAlignment.spaceEvenly,`  
                `children: [`  
                  `// Mute / Unmute Mic Button`  
                  `FloatingActionButton(`  
                    `heroTag: "mic_btn",`  
                    `backgroundColor: _isMicMuted ? Colors.redAccent : const Color(0xFF1E293B),`  
                    `onPressed: _isConnected ? _toggleMic : null,`  
                    `child: Icon(`  
                      `_isMicMuted ? Icons.mic_off : Icons.mic,`  
                      `color: Colors.white,`  
                    `),`  
                  `),`

                  `// End Call Button`  
                  `FloatingActionButton.large(`  
                    `heroTag: "end_call_btn",`  
                    `backgroundColor: Colors.red,`  
                    `onPressed: () {`  
                      `_room?.disconnect();`  
                      `Navigator.of(context).pop();`  
                    `},`  
                    `child: const Icon(Icons.call_end, color: Colors.white, size: 32),`  
                  `),`  
                `],`  
              `),`  
            `),`  
          `],`  
        `),`  
      `),`  
    `);`  
  `}`

  ``/// Renders the Doctor Avatar Video that plays ONLY when `_isAiSpeaking` is true``  
  `Widget _buildDoctorAvatarView() {`  
    `return AnimatedContainer(`  
      `duration: const Duration(milliseconds: 250),`  
      `width: 300,`  
      `height: 380,`  
      `decoration: BoxDecoration(`  
        `color: const Color(0xFF151C2C),`  
        `borderRadius: BorderRadius.circular(25),`  
        `border: Border.all(`  
          `color: _isAiSpeaking ? const Color(0xFF00E5FF) : Colors.white12,`  
          `width: _isAiSpeaking ? 3.0 : 1.5,`  
        `),`  
        `boxShadow: _isAiSpeaking`  
            `? [`  
                `BoxShadow(`  
                  `color: const Color(0xFF00E5FF).withOpacity(0.35),`  
                  `blurRadius: 28,`  
                  `spreadRadius: 4,`  
                `)`  
              `]`  
            `: [],`  
      `),`  
      `clipBehavior: Clip.antiAlias,`  
      `child: _avatarVideoController.value.isInitialized`  
          `? FittedBox(`  
              `fit: BoxFit.cover,`  
              `child: SizedBox(`  
                `width: _avatarVideoController.value.size.width,`  
                `height: _avatarVideoController.value.size.height,`  
                `child: VideoPlayer(_avatarVideoController),`  
              `),`  
            `)`  
          `: const Center(`  
              `child: CircularProgressIndicator(color: Color(0xFF00E5FF)),`  
            `),`  
    `);`  
  `}`

  `/// Renders the standard Live Call Assistant view (when Avatar mode is off)`  
  `Widget _buildAudioAssistantView() {`  
    `return AnimatedContainer(`  
      `duration: const Duration(milliseconds: 300),`  
      `width: _isAiSpeaking ? 180 : 150,`  
      `height: _isAiSpeaking ? 180 : 150,`  
      `decoration: BoxDecoration(`  
        `shape: BoxShape.circle,`  
        `color: const Color(0xFF151C2C),`  
        `border: Border.all(`  
          `color: _isAiSpeaking ? const Color(0xFF00E5FF) : Colors.white24,`  
          `width: 3,`  
        `),`  
        `boxShadow: _isAiSpeaking`  
            `? [`  
                `BoxShadow(`  
                  `color: const Color(0xFF00E5FF).withOpacity(0.45),`  
                  `blurRadius: 40,`  
                  `spreadRadius: 8,`  
                `)`  
              `]`  
            `: [],`  
      `),`  
      `child: const Icon(`  
        `Icons.health_and_safety_rounded,`  
        `size: 64,`  
        `color: Color(0xFF00E5FF),`  
      `),`  
    `);`  
  `}`  
`}`

### **Key Implementation Details to Keep in Mind**

> * **Why Mute the VideoPlayerController (setVolume(0.0))?** The real-time voice audio is already coming through LiveKit's WebRTC audio track from Sarvam's bulbul:v4-flash TTS. Muting the local MP4 ensures the video only acts as a visual puppet without playing overlapping audio.  
> * **Idle vs. Speaking Transition:** If your doctor\_speaking.mp4 starts at 0:00 with the doctor in a calm, closed-mouth posture, calling \_avatarVideoController.seekTo(Duration.zero) right after pause() ensures the doctor never freezes mid-syllable with an open mouth when they finish a sentence.

**Sources**

> 1. [Build Your First Voice Agent using LiveKit | Sarvam API Docs](https://docs.sarvam.ai/api/integration/build-voice-agent-with-live-kit)  
> 2. [Government Scheme Awareness Agent using LiveKit \- Sarvam Docs](https://docs.sarvam.ai/api/cookbook/example-voice-agents/government-scheme-agent)  
> 3. [LiveKit Integration \- Sarvam AI](https://www.sarvam.ai/integrations/livekit)  
> 4. [LiveKit in Production | Sarvam API Docs](https://docs.sarvam.ai/api/integration/livekit-production-best-practices)  
> 5. [build\_voice\_agent\_with\_livekit.ipynb \- sarvam-ai-cookbook \- GitHub](https://github.com/sarvamai/sarvam-ai-cookbook/blob/main/integrations/build_voice_agent_with_livekit.ipynb)

---

