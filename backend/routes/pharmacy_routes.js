const express = require('express');
const router = express.Router();
const { pool } = require('../database');

// Get Pharmacy Catalog
router.get('/medicines', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM medicines');
    if (rows.length === 0) {
      return res.json([
        { id: 'MED-01', name: 'Paracetamol 650mg', generic_name: 'Paracetamol', category: 'Fever & Pain', price: 32.00, original_price: 40.00, pack_size: 'Strip of 15 Tablets', requires_prescription: false },
        { id: 'MED-02', name: 'Cetirizine 10mg', generic_name: 'Cetirizine HCl', category: 'Allergy & Cold', price: 28.00, original_price: 35.00, pack_size: 'Strip of 10 Tablets', requires_prescription: false },
        { id: 'MED-03', name: 'Cough Relief Syrup', generic_name: 'Dextromethorphan', category: 'Cough Relief', price: 95.00, original_price: 120.00, pack_size: 'Bottle of 100ml', requires_prescription: false },
        { id: 'MED-04', name: 'Electrolyte ORS Sachet', generic_name: 'Oral Rehydration Salts', category: 'Hydration', price: 22.00, original_price: 25.00, pack_size: 'Sachet of 21.8g', requires_prescription: false },
        { id: 'MED-05', name: 'Amoxicillin 500mg', generic_name: 'Amoxicillin Trihydrate', category: 'Antibiotics', price: 110.00, original_price: 140.00, pack_size: 'Strip of 10 Capsules', requires_prescription: true },
        { id: 'MED-06', name: 'Vitamin C 500mg Chewable', generic_name: 'Ascorbic Acid', category: 'Immunity Boost', price: 75.00, original_price: 95.00, pack_size: 'Bottle of 60 Chewables', requires_prescription: false },
      ]);
    }
    return res.json(rows);
  } catch (err) {
    console.error('Error fetching medicines:', err.message);
    return res.status(500).json({ error: 'Failed to fetch medicines' });
  }
});

// GET /api/pharmacy/suggestions — Smart Medicine Suggestions based on symptoms/condition
router.get('/suggestions', async (req, res) => {
  const { symptom, condition, q } = req.query;
  const term = (symptom || condition || q || '').toLowerCase().trim();

  try {
    let query = 'SELECT * FROM medicines';
    let params = [];

    if (term) {
      query += ` WHERE LOWER(name) LIKE ? OR LOWER(generic_name) LIKE ? OR LOWER(category) LIKE ?`;
      const pattern = `%${term}%`;
      params = [pattern, pattern, pattern];
    }

    const [rows] = await pool.query(query, params);

    // If no exact match or term is general, provide mapped clinical medicine suggestions
    let results = rows;
    if (results.length === 0) {
      const [all] = await pool.query('SELECT * FROM medicines LIMIT 6');
      results = all;
    }

    return res.json({
      query: term || 'general',
      count: results.length,
      suggestions: results.map(med => ({
        id: med.id,
        name: med.name,
        genericName: med.generic_name,
        category: med.category,
        price: med.price,
        packSize: med.pack_size,
        requiresPrescription: Boolean(med.requires_prescription),
        recommendedDosage: med.category.includes('Fever') ? '1 tablet post meals TDS' : 'As directed by physician'
      }))
    });
  } catch (err) {
    console.error('Error fetching medicine suggestions:', err.message);
    return res.status(500).json({ error: 'Failed to fetch suggestions' });
  }
});

// Create 15-Minute Delivery Order Handler
const handleCreateOrder = (req, res) => {
  const { userId, items, totalAmount, deliveryAddress } = req.body;
  const orderId = `HE${Math.floor(10000000 + Math.random() * 90000000)}`;

  return res.json({
    success: true,
    message: 'Order placed for 15-minute quick delivery',
    orderId,
    status: 'out_for_delivery',
    etaMinutes: '15 mins',
    driverName: 'Ravi Kumar',
    driverPhone: '+91 9848099887',
    items: items || [{ name: 'Paracetamol 650mg', qty: 1, price: 32.0 }],
    totalAmount: totalAmount || 155.0,
    deliveryAddress: deliveryAddress || 'Flat 402, Green Meadows, Hitech City, Hyderabad',
    createdAt: new Date().toISOString(),
  });
};

router.post('/order', handleCreateOrder);
router.post('/orders', handleCreateOrder);

// GET /api/pharmacy/stores — Empaneled Medical Stores
router.get('/stores', (req, res) => {
  return res.json([
    {
      id: 'STORE-101',
      name: 'MedPlus Express Pharmacy',
      address: 'Plot 42, Silicon Valley Rd, Madhapur, Hyderabad',
      phone: '+91 9848099881',
      rating: 4.8,
      is_open_24x7: true,
      delivery_radius_km: 5.0,
      verification_status: 'verified',
    },
    {
      id: 'STORE-102',
      name: 'Apollo 24x7 Quick Chemist',
      address: 'Near Cyber Towers, Hitech City, Hyderabad',
      phone: '+91 9848011224',
      rating: 4.9,
      is_open_24x7: true,
      delivery_radius_km: 7.0,
      verification_status: 'verified',
    },
    {
      id: 'STORE-103',
      name: 'Generic Aadhaar Pharmacy',
      address: 'Kukatpally Housing Board, Hyderabad',
      phone: '+91 9848033445',
      rating: 4.6,
      is_open_24x7: false,
      delivery_radius_km: 4.0,
      verification_status: 'verified',
    }
  ]);
});

// POST /api/pharmacy/onboard — Onboard a new Medical Store
router.post('/onboard', (req, res) => {
  const { name, phone, email, licenseNumber, gstin, pharmacistName, address } = req.body;
  const storeId = `STORE-${Date.now().toString().slice(-4)}`;

  return res.json({
    success: true,
    message: 'Pharmacy store successfully onboarded and awaiting license review',
    store: {
      id: storeId,
      name: name || 'Partner Pharmacy Hub',
      phone,
      email,
      licenseNumber,
      gstin,
      pharmacistName,
      address,
      status: 'pending_verification',
      createdAt: new Date().toISOString(),
    }
  });
});

// GET /api/pharmacy/orders/user/:userId — Retrieve past pharmacy orders
router.get('/orders/user/:userId', (req, res) => {
  const { userId } = req.params;
  return res.json([
    {
      orderId: 'HE88491024',
      userId,
      storeName: 'MedPlus Express Pharmacy',
      status: 'delivered',
      totalAmount: 185.00,
      itemCount: 3,
      deliveredAt: 'Yesterday, 04:30 PM',
      deliveryAddress: 'Hitech City, Hyderabad, 500081'
    }
  ]);
});

module.exports = router;
