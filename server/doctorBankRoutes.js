// Endpoint to store and fetch doctor banking details
const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const path = require('path');

const router = express.Router();
const DATA_FILE = path.join(__dirname, 'doctor_bank_details.json');

// Save doctor banking details
router.post('/doctor/bank-details', (req, res) => {
  const { doctorId, bankName, accountHolder, accountNumber, branchCode } = req.body;
  if (!doctorId) return res.status(400).json({ error: 'doctorId required' });
  let data = {};
  if (fs.existsSync(DATA_FILE)) {
    data = JSON.parse(fs.readFileSync(DATA_FILE));
  }
  data[doctorId] = { bankName, accountHolder, accountNumber, branchCode };
  fs.writeFileSync(DATA_FILE, JSON.stringify(data));
  res.json({ success: true });
});

// Fetch doctor banking details
router.get('/doctor/bank-details/:doctorId', (req, res) => {
  const doctorId = req.params.doctorId;
  if (!doctorId) return res.status(400).json({ error: 'doctorId required' });
  let data = {};
  if (fs.existsSync(DATA_FILE)) {
    data = JSON.parse(fs.readFileSync(DATA_FILE));
  }
  const details = data[doctorId];
  if (!details) return res.status(404).json({ error: 'No details found' });
  res.json(details);
});

module.exports = router;
