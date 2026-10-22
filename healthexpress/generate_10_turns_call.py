import os
import json
import base64
import urllib.request
import wave
import shutil

API_KEYS = [
    'sk_5ijbsyhu_co3XmcxZMgr0Rf0HAjfWvV4x',
    'sk_d3mrjqmd_WCMwFkKIf6GQKxpaUIu9Ucwu'
]

TURNS = [
    {
        "turn": 1,
        "speaker_role": "AI Doctor (Dr. Shanni)",
        "voice": "priya",
        "lang": "en-IN",
        "text": "Hello! I am Dr. Shanni, your AI Clinical Specialist. How can I assist you with your health today?"
    },
    {
        "turn": 2,
        "speaker_role": "Patient (Ramesh)",
        "voice": "amit",
        "lang": "en-IN",
        "text": "Hello Doctor. Since yesterday, I have a high fever, severe headache, and bad body chills."
    },
    {
        "turn": 3,
        "speaker_role": "AI Doctor (Dr. Shanni)",
        "voice": "priya",
        "lang": "en-IN",
        "text": "I understand. Have you checked your body temperature, and do you also have a cough, cold, or throat pain?"
    },
    {
        "turn": 4,
        "speaker_role": "Patient (Ramesh)",
        "voice": "amit",
        "lang": "en-IN",
        "text": "Yes, my temperature was 101.5 degrees Fahrenheit this morning, and I feel very weak and shivering."
    },
    {
        "turn": 5,
        "speaker_role": "AI Doctor (Dr. Shanni)",
        "voice": "priya",
        "lang": "en-IN",
        "text": "Thank you for sharing that. Have you taken any medications like Paracetamol yet, and do you have any allergies?"
    },
    {
        "turn": 6,
        "speaker_role": "Patient (Ramesh)",
        "voice": "amit",
        "lang": "en-IN",
        "text": "I took one Dolo 650 last night. It reduced the headache slightly, but the fever came back. I have no known allergies."
    },
    {
        "turn": 7,
        "speaker_role": "AI Doctor (Dr. Shanni)",
        "voice": "priya",
        "lang": "en-IN",
        "text": "I see. Given acute fever with body ache, it could be a viral fever. Drink plenty of fluids, take oral electrolytes, and get complete bed rest."
    },
    {
        "turn": 8,
        "speaker_role": "Patient (Ramesh)",
        "voice": "amit",
        "lang": "en-IN",
        "text": "Doctor, should I get a blood test done, like a CBC or dengue test, or should I see a physician in person?"
    },
    {
        "turn": 9,
        "speaker_role": "AI Doctor (Dr. Shanni)",
        "voice": "priya",
        "lang": "en-IN",
        "text": "If the fever stays above 101 degrees for more than 48 hours, a CBC and Dengue NS1 test is recommended. If you experience severe dizziness or vomiting, visit an emergency clinic immediately."
    },
    {
        "turn": 10,
        "speaker_role": "Patient (Ramesh)",
        "voice": "amit",
        "lang": "en-IN",
        "text": "Thank you so much, Dr. Shanni. I will stay hydrated, take rest, and visit the hospital if symptoms persist."
    }
]

TEMP_DIR = os.path.join(os.path.dirname(__file__), 'scratch', 'temp_turns')
os.makedirs(TEMP_DIR, exist_ok=True)

def fetch_tts(text, speaker, lang):
    payload = {
        'inputs': [text],
        'target_language_code': lang,
        'speaker': speaker,
        'pitch': 0,
        'pace': 1.03 if speaker == 'amit' else 1.0,
        'loudness': 1.5,
        'speech_sample_rate': 22050,
        'enable_preprocessing': True,
        'model': 'bulbul:v3'
    }
    
    for key in API_KEYS:
        try:
            req = urllib.request.Request(
                'https://api.sarvam.ai/text-to-speech',
                data=json.dumps(payload).encode('utf-8'),
                headers={
                    'api-subscription-key': key,
                    'Content-Type': 'application/json'
                }
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                if data.get('audios') and len(data['audios']) > 0:
                    return base64.b64decode(data['audios'][0])
        except Exception as e:
            print(f"Warning: Key failed or error: {e}")
    return None

def main():
    turn_files = []
    print("=== Generating 10 Turn Voice Agent & Patient Dialogue via Sarvam AI Studio Voice ===")
    
    for item in TURNS:
        t_num = item["turn"]
        role = item["speaker_role"]
        speaker = item["voice"]
        text = item["text"]
        out_path = os.path.join(TEMP_DIR, f"turn_{t_num:02d}_{speaker}.wav")
        
        print(f"Synthesizing Turn {t_num} [{role}]: '{text[:40]}...'")
        audio_bytes = fetch_tts(text, speaker, item["lang"])
        if not audio_bytes:
            raise RuntimeError(f"Failed to fetch TTS for Turn {t_num}")
        
        with open(out_path, 'wb') as f:
            f.write(audio_bytes)
        turn_files.append((out_path, role))
        print(f" -> Turn {t_num} saved ({len(audio_bytes)} bytes)")
    
    # Concatenate all 10 turns with 0.7s conversational silence pause
    final_output_path = os.path.join(os.path.dirname(__file__), 'assets', 'audio', 'dr_shanni_patient_10_turns_call.wav')
    os.makedirs(os.path.dirname(final_output_path), exist_ok=True)
    
    print("\n=== Concatenating all 10 turns into a single seamless audio clip ===")
    
    with wave.open(turn_files[0][0], 'rb') as first_wav:
        params = first_wav.getparams()
        sample_rate = params.framerate
        n_channels = params.nchannels
        sampwidth = params.sampwidth
    
    pause_duration_sec = 0.7
    silence_frames = b'\x00' * int(sample_rate * sampwidth * n_channels * pause_duration_sec)
    
    with wave.open(final_output_path, 'wb') as out_wav:
        out_wav.setparams(params)
        
        for idx, (wav_file, role) in enumerate(turn_files):
            with wave.open(wav_file, 'rb') as in_wav:
                data = in_wav.readframes(in_wav.getnframes())
                out_wav.writeframes(data)
            
            # Add pause between turns (except after the final turn)
            if idx < len(turn_files) - 1:
                out_wav.writeframes(silence_frames)
    
    total_size = os.path.getsize(final_output_path)
    
    # Calculate duration
    with wave.open(final_output_path, 'rb') as final_wav:
        duration_sec = final_wav.getnframes() / float(final_wav.getframerate())
    
    print(f"\nSUCCESS! Combined audio clip created at:\n{final_output_path}")
    print(f"Total Duration: {duration_sec:.1f} seconds ({duration_sec/60:.1f} minutes)")
    print(f"File Size: {total_size / (1024 * 1024):.2f} MB")
    
    # Also copy to brain artifacts directory for direct user download / embedding
    artifact_dir = r"C:\Users\shese\.gemini\antigravity-ide\brain\84052a48-5d16-4643-b0b5-aa93210da14e"
    if os.path.exists(artifact_dir):
        dest_artifact = os.path.join(artifact_dir, 'dr_shanni_patient_10_turns_call.wav')
        shutil.copyfile(final_output_path, dest_artifact)
        print(f"Copied to artifact directory:\n{dest_artifact}")

if __name__ == '__main__':
    main()
