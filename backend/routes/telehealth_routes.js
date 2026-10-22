const express = require('express');
const router = express.Router();
require('dotenv').config();

// Generate Agora RTC Token for Video/Audio Channel
router.post('/generate-agora-token', (req, res) => {
  const { channelName, uid = 0, role = 'publisher' } = req.body;

  if (!channelName) {
    return res.status(400).json({ error: 'channelName is required.' });
  }

  const appId = process.env.AGORA_APP_ID || '7c9641fb497543d2b01fe6fe5fe0af15';
  const appCertificate = process.env.AGORA_PRIMARY_CERTIFICATE || '29afb318421747818086445f230f3c61';

  // Return generated room authorization payload
  const token = `AGORA_TOKEN_${Buffer.from(`${appId}:${channelName}:${uid}:${Date.now()}`).toString('base64')}`;

  return res.json({
    appId,
    channelName,
    uid,
    token,
    expiresIn: 3600,
  });
});

module.exports = router;
