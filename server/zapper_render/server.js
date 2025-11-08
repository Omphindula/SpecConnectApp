/*
  Render-ready Express server for Zapper payments + Firestore

  Features:
  - POST /create_payment  -> create a payment via Zapper API (returns payment link)
  - POST /zapper-webhook  -> receive and validate webhook from Zapper, write to Firestore
  - GET  /check-payment/:reference -> query Firestore for payment by reference

  Configuration via environment variables. See .env.example
*/

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fetch = require('node-fetch');
const crypto = require('crypto');
const helmet = require('helmet');
const admin = require('firebase-admin');
const dotenv = require('dotenv');

dotenv.config();

const PORT = process.env.PORT || 3000;
const ZAPPER_API_BASE = (process.env.ZAPPER_API_BASE || '').replace(/\/$/, '');
const ZAPPER_CREATE_PATH = process.env.ZAPPER_CREATE_PATH || '/v1/payments';
const ZAPPER_VERIFY_PATH = process.env.ZAPPER_VERIFY_PATH || '/v1/payments/{paymentId}';
const ZAPPER_API_KEY = process.env.ZAPPER_API_KEY || '';
const ZAPPER_API_KEY_HEADER = process.env.ZAPPER_API_KEY_HEADER || 'Authorization';

const ZAPPER_WEBHOOK_SECRET = process.env.ZAPPER_WEBHOOK_SECRET || '';
const ZAPPER_WEBHOOK_SIGNATURE_HEADER = (process.env.ZAPPER_WEBHOOK_SIGNATURE_HEADER || 'x-zapper-signature').toLowerCase();

const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '').split(',').map(s => s.trim()).filter(Boolean);

// Initialize Firebase Admin from either JSON env variable or file path
function initFirebaseAdmin() {
  if (admin.apps && admin.apps.length) return admin;

  const svcJson = process.env.FIRESTORE_SERVICE_ACCOUNT || null;
  const svcFile = process.env.FIRESTORE_SERVICE_ACCOUNT_FILE || null;

  try {
    if (svcJson) {
      // FIRESTORE_SERVICE_ACCOUNT is expected to be a JSON string
      const obj = typeof svcJson === 'string' ? JSON.parse(svcJson) : svcJson;
      admin.initializeApp({ credential: admin.credential.cert(obj) });
      console.log('Initialized Firebase Admin from FIRESTORE_SERVICE_ACCOUNT env');
      return admin;
    }

    if (svcFile) {
      // Use require to read local file (Render supports mounting secrets as files)
      const path = require('path');
      const resolved = path.isAbsolute(svcFile) ? svcFile : path.resolve(process.cwd(), svcFile);
      const obj = require(resolved);
      admin.initializeApp({ credential: admin.credential.cert(obj) });
      console.log('Initialized Firebase Admin from FIRESTORE_SERVICE_ACCOUNT_FILE');
      return admin;
    }
  } catch (e) {
    console.error('Failed to initialize firebase admin:', e && e.message ? e.message : e);
    throw e;
  }

  console.warn('No Firebase service account configuration found. Set FIRESTORE_SERVICE_ACCOUNT or FIRESTORE_SERVICE_ACCOUNT_FILE.');
  return admin; // will throw on use
}

initFirebaseAdmin();

const db = admin.firestore();

const app = express();
// capture raw body for webhook verification
app.use(bodyParser.json({ verify: (req, res, buf) => { req.rawBody = buf; } }));
app.use(helmet());

// CORS config
const corsOptions = {
  origin: function(origin, callback) {
    if (!origin) return callback(null, true); // allow server-to-server calls
    if (ALLOWED_ORIGINS.length === 0) return callback(null, true);
    if (ALLOWED_ORIGINS.indexOf(origin) !== -1) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  }
};
app.use(cors(corsOptions));

// Utility: call Zapper create
async function createZapperPayment({ reference, amount, currency = 'ZAR', returnUrl }) {
  if (!ZAPPER_API_BASE) throw new Error('ZAPPER_API_BASE not configured');
  const url = `${ZAPPER_API_BASE}${ZAPPER_CREATE_PATH}`;
  const payload = {
    reference,
    amount: amount || 0,
    currency: currency || 'ZAR',
    callbackUrl: returnUrl || undefined
  };

  const headers = { 'Content-Type': 'application/json' };
  if (ZAPPER_API_KEY) headers[ZAPPER_API_KEY_HEADER] = ZAPPER_API_KEY;

  const resp = await fetch(url, { method: 'POST', headers, body: JSON.stringify(payload) });
  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`Zapper create failed: ${resp.status} ${txt}`);
  }
  const data = await resp.json();
  // Expecting PSP to return checkout url and paymentId
  const paymentLink = data.checkoutUrl || data.paymentUrl || data.url || data.link || data.redirectUrl || null;
  const paymentId = data.id || data.paymentId || data.invoiceId || null;
  return { raw: data, paymentLink, paymentId };
}

// Utility: verify Zapper payment using API
async function verifyZapperPayment(paymentId) {
  if (!ZAPPER_API_BASE) throw new Error('ZAPPER_API_BASE not configured');
  const path = ZAPPER_VERIFY_PATH.replace('{paymentId}', encodeURIComponent(paymentId));
  const url = `${ZAPPER_API_BASE}${path}`;
  const headers = { 'Accept': 'application/json' };
  if (ZAPPER_API_KEY) headers[ZAPPER_API_KEY_HEADER] = ZAPPER_API_KEY;
  const resp = await fetch(url, { method: 'GET', headers });
  if (!resp.ok) {
    const txt = await resp.text();
    throw new Error(`Zapper verify returned ${resp.status}: ${txt}`);
  }
  const data = await resp.json();
  return data;
}

// Verify incoming webhook: HMAC sha256 of raw body
function verifyWebhook(req) {
  if (!ZAPPER_WEBHOOK_SECRET) return { ok: false, reason: 'no-webhook-secret' };
  const header = (req.headers[ZAPPER_WEBHOOK_SIGNATURE_HEADER] || '').toString();
  if (!header) return { ok: false, reason: 'no-signature-header' };
  try {
    const expected = crypto.createHmac('sha256', ZAPPER_WEBHOOK_SECRET).update(req.rawBody || Buffer.from('')).digest('hex');
    // Some providers send hex, some send prefixed values; accept contains
    if (header.toLowerCase() === expected.toLowerCase() || header.toLowerCase().endsWith(expected.toLowerCase()) || header.toLowerCase().includes(expected.toLowerCase())) {
      return { ok: true };
    }
    return { ok: false, reason: 'signature-mismatch', expected, got: header };
  } catch (e) {
    return { ok: false, reason: 'error', error: String(e) };
  }
}

// POST /create_payment
app.post('/create_payment', async (req, res) => {
  try {
    const { reference, amount, currency, returnUrl } = req.body || {};
    if (!reference) return res.status(400).json({ success: false, error: 'reference required' });
    if (!amount && amount !== 0) return res.status(400).json({ success: false, error: 'amount required' });

    const zapper = await createZapperPayment({ reference, amount, currency, returnUrl });
    // Persist a record with status 'created'
    await db.collection('payments').doc(reference).set({
      reference,
      paymentId: zapper.paymentId || null,
      paymentLink: zapper.paymentLink || null,
      amount: amount || 0,
      currency: currency || 'ZAR',
      status: 'created',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      raw: zapper.raw || null
    }, { merge: true });

    return res.json({ success: true, paymentId: zapper.paymentId || null, paymentLink: zapper.paymentLink || null });
  } catch (e) {
    console.error('create_payment error', e && e.message ? e.message : e);
    return res.status(500).json({ success: false, error: String(e) });
  }
});

// Webhook endpoint
app.post('/zapper-webhook', async (req, res) => {
  try {
    const verification = verifyWebhook(req);
    if (!verification.ok) {
      console.warn('Webhook verification failed', verification);
      // respond 400 to indicate invalid signature
      return res.status(400).json({ success: false, error: 'signature_invalid', details: verification });
    }

    const event = req.body || {};
    // Adapt to Zapper payload: try to extract reference, amount, status, paymentId
    const paymentId = event.paymentId || event.id || event.data?.id || event.data?.paymentId || null;
    const reference = event.reference || event.data?.reference || event.data?.metadata?.reference || null;
    const status = (event.status || event.transactionStatus || event.data?.status || '').toString().toLowerCase() || 'unknown';
    const amount = event.amount || event.data?.amount || (event.data && event.data.amount) || null;

    // Persist to Firestore under either reference or paymentId
    const docId = reference || paymentId || (`pay_${Date.now()}`);
    await db.collection('payments').doc(docId).set({
      reference: reference || null,
      paymentId: paymentId || null,
      status: status || 'unknown',
      amount: typeof amount === 'number' ? amount : (amount ? Number(amount) : null),
      raw: event,
      receivedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    // Optionally: when verified paid, also mark appointment doc (if you have appointments collection)
    if (reference) {
      try {
        await db.collection('appointments').doc(String(reference)).set({
          paid: status === 'paid' || status === 'successful' || status === 'completed',
          status: status === 'paid' ? 'paid' : status,
          paymentId: paymentId || null,
          paidAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      } catch (e) {
        console.warn('Failed to update appointment paid status', e && e.message ? e.message : e);
      }
    }

    return res.json({ success: true });
  } catch (e) {
    console.error('zapper-webhook error', e && e.message ? e.message : e);
    return res.status(500).json({ success: false, error: String(e) });
  }
});

// GET /check-payment/:reference
app.get('/check-payment/:reference', async (req, res) => {
  try {
    const { reference } = req.params;
    if (!reference) return res.status(400).json({ success: false, error: 'reference required' });

    // Try direct document id first
    const docRef = db.collection('payments').doc(String(reference));
    const doc = await docRef.get();
    if (doc.exists) {
      const data = doc.data() || {};
      return res.json({ success: true, found: true, status: data.status || 'unknown', paymentId: data.paymentId || null, raw: data.raw || null });
    }

    // Otherwise query by reference field (in case doc id was paymentId)
    const q = await db.collection('payments').where('reference', '==', String(reference)).limit(1).get();
    if (!q.empty) {
      const d = q.docs[0].data() || {};
      return res.json({ success: true, found: true, status: d.status || 'unknown', paymentId: d.paymentId || null, raw: d.raw || null });
    }

    return res.json({ success: true, found: false, status: 'not_found' });
  } catch (e) {
    console.error('check-payment error', e && e.message ? e.message : e);
    return res.status(500).json({ success: false, error: String(e) });
  }
});

// Simple health
app.get('/health', (req, res) => res.json({ ok: true }));

app.listen(PORT, () => {
  console.log(`SpecConnect Zapper backend listening on port ${PORT}`);
});
