// Express server for Yoco payments
const express = require('express');
const bodyParser = require('body-parser');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(bodyParser.json());

// Import doctor banking routes
const doctorBankRoutes = require('./doctorBankRoutes');
app.use(doctorBankRoutes);

const YOCO_SECRET_KEY = process.env.YOCO_SECRET_KEY || 'sk_test_xxx'; // Replace with your secret key

// Endpoint to tokenize card and get Yoco token
app.post('/tokenize', async (req, res) => {
  const { cardNumber, expiry, cvc } = req.body;
  try {
    // Call Yoco API to tokenize card
    const response = await axios.post(
      'https://api.yoco.com/v1/tokens',
      {
        card: {
          number: cardNumber,
          expiry: expiry,
          cvc: cvc,
        },
      },
      {
        headers: {
          'X-Auth-Secret-Key': YOCO_SECRET_KEY,
          'Content-Type': 'application/json',
        },
      }
    );
    res.json({ success: true, token: response.data.id });
  } catch (error) {
    res.status(400).json({ success: false, error: error.response?.data || error.message });
  }
});

// Endpoint to process payment
app.post('/pay', async (req, res) => {
  const { token, amount, currency, doctorBankDetails } = req.body;
  try {
    // Call Yoco API to charge card
    const response = await axios.post(
      'https://api.yoco.com/v1/charges',
      {
        token,
        amountInCents: amount,
        currency,
      },
      {
        headers: {
          'X-Auth-Secret-Key': YOCO_SECRET_KEY,
          'Content-Type': 'application/json',
        },
      }
    );
    // You can store doctorBankDetails for payout logic
    res.json({ success: true, data: response.data });
  } catch (error) {
    res.status(400).json({ success: false, error: error.response?.data || error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Yoco payment server running on port ${PORT}`);
});
