const express = require('express');
const router = express.Router();
const Razorpay = require('razorpay');
const crypto = require('crypto');
require('dotenv').config();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_live_StBUehIpeULYuL',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'M76UWnmNsVE7hU5QrkriZuor',
});

// Create Razorpay Order
router.post('/create-order', async (req, res) => {
  const { amount, currency = 'INR', receipt, notes } = req.body;

  try {
    const options = {
      amount: Math.round(parseFloat(amount) * 100), // in paise
      currency,
      receipt: receipt || `rcpt_${Date.now()}`,
      notes: notes || { platform: 'HealthExpress AI' },
    };

    const order = await razorpay.orders.create(options);
    return res.json({
      success: true,
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      keyId: process.env.RAZORPAY_KEY_ID || 'rzp_live_StBUehIpeULYuL',
    });
  } catch (err) {
    console.error('Razorpay order creation error:', err);
    return res.status(500).json({ error: 'Failed to create payment order', details: err.message });
  }
});

// Verify Payment Signature
router.post('/verify', (req, res) => {
  const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

  const keySecret = process.env.RAZORPAY_KEY_SECRET || 'M76UWnmNsVE7hU5QrkriZuor';
  const hmac = crypto.createHmac('sha256', keySecret);
  hmac.update(`${razorpay_order_id}|${razorpay_payment_id}`);
  const generatedSignature = hmac.digest('hex');

  if (generatedSignature === razorpay_signature) {
    return res.json({ success: true, message: 'Payment verified successfully' });
  } else {
    return res.status(400).json({ success: false, message: 'Invalid payment signature' });
  }
});

module.exports = router;
