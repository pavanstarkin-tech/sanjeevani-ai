FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download VAD and Sarvam model weights
RUN python -m livekit.agents download-files

COPY . .

ENTRYPOINT ["python", "agent.py", "start"]
