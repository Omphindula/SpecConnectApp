SpecConnect Zapper backend (Render-ready)
=========================================

This small Express server implements:

- POST /create_payment  — creates a Zapper payment (for client to open checkout)
- POST /zapper-webhook — receive webhook from Zapper and verify signature
- GET  /check-payment/:reference — check payment status by reference (pending|paid|not_found)

It writes payment records to Firestore using Firebase Admin SDK. This is production-ready scaffolding for deployment to Render (or similar hosts).

Important: Do NOT store service account JSON in your repo. Use Render's Environment Secrets and set the `FIRESTORE_SERVICE_ACCOUNT` variable to the JSON content (or use Render's Secret File feature).

Quick start (local):

1. Install dependencies

   npm install

2. Create a .env file based on `.env.example` and fill in your Zapper API and Firebase credentials.

3. Start the server

   node server.js

Endpoints
---------

- POST /create_payment
  Request JSON: { reference: string, amount: number, currency?: 'ZAR', returnUrl?: string }
  Response JSON: { success: true, paymentId, paymentLink }

- POST /zapper-webhook
  Receives raw body from Zapper. Validates signature and writes entry to Firestore collection `payments`.

- GET /check-payment/:reference
  Returns payment status by looking up `payments` collection where `reference` == :reference. If none found, returns 404-like payload.

Render deployment notes
-----------------------

- Add environment variables (in Render dashboard):
  - `FIRESTORE_SERVICE_ACCOUNT` (JSON string) OR `FIRESTORE_SERVICE_ACCOUNT_FILE` (path)
  - `ZAPPER_API_BASE`, `ZAPPER_CREATE_PATH`, `ZAPPER_VERIFY_PATH`, `ZAPPER_API_KEY`, `ZAPPER_WEBHOOK_SECRET`
  - `ALLOWED_ORIGINS` (comma separated) with your Flutter web or other app origins

- Ensure Render service has an HTTPS domain (it will) and point your Zapper webhook configuration to the public URL: `https://<your-render-service>/zapper-webhook`.

Security
--------

- Validate webhook signatures. This implementation supports an HMAC SHA256 approach (using `ZAPPER_WEBHOOK_SECRET`) or vendor header matching. Consult Zapper docs for exact signature method and adapt the `verifyWebhook` function.

Support
-------
If you want I can also add a simple Cloud Function equivalent, or adjust the Zapper request/response shapes to match exact Zapper API fields once you provide API docs or example payloads.
