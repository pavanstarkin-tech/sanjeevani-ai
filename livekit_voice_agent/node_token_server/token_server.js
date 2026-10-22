require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { AccessToken } = require('livekit-server-sdk');

const app = express();
app.use(cors());
app.use(express.json());

const LIVEKIT_URL = process.env.LIVEKIT_URL || 'wss://luca-vsv9whhr.livekit.cloud';
const LIVEKIT_API_KEY = process.env.LIVEKIT_API_KEY || 'API5veVBN62icXT';
const LIVEKIT_API_SECRET = process.env.LIVEKIT_API_SECRET || '0rj6XKM9tbWRfvja4Yo7DVpDk06mPef6XNLQbbdVCgTA';

app.get('/token', async (req, res) => {
  try {
    const roomName = req.query.room || `healthexpress-room-${Date.now()}`;
    const participantName = req.query.identity || `patient-${Math.floor(Math.random() * 10000)}`;

    const token = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
      identity: participantName,
      ttl: '1h',
    });

    token.addGrant({
      roomJoin: true,
      room: roomName,
      canPublish: true,
      canSubscribe: true,
    });

    const jwt = await token.toJwt();
    res.json({
      success: true,
      token: jwt,
      room: roomName,
      url: LIVEKIT_URL,
    });
  } catch (error) {
    console.error('Error generating LiveKit token:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'HealthExpress LiveKit Voice Token Service' });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`🚀 HealthExpress LiveKit Token Server running on port ${PORT}`);
  console.log(`📡 LiveKit Cloud URL: ${LIVEKIT_URL}`);
});
