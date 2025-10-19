Payments server — Deploy & test

This directory contains a small Node/Express payments server used by the SpecConnect app. The server is intended to run on a secure host (Cloud Run is recommended) and requires provider secrets to process real payments.

Prerequisites
- gcloud CLI installed and authenticated
- A Google Cloud project with billing enabled
- Cloud Run API enabled
- Secret Manager (recommended) or ability to provide env vars at deploy time

Secrets required (do NOT commit to git)
- YOCO_SECRET_KEY — your Yoco secret key (server-side)
- YOCO_WEBHOOK_SECRET — webhook signing secret from Yoco (for verifying webhooks)
- SUPABASE_SERVICE_ROLE_KEY — Supabase service-role key for server-side DB writes
- SUPABASE_URL — URL of your Supabase instance

Quick deploy (Cloud Run)
1. Build & submit the container image to Cloud Build:

```bash
# from project root
./scripts/payments-server/deploy_cloud_run.sh --project=MY_GCP_PROJECT --service=specconnect-payments --image=specconnect-payments --region=us-central1 --use-secret-manager
```

2. If you don't use Secret Manager, run without `--use-secret-manager` and you'll be prompted for the values.

Get the service URL:

```bash
gcloud run services describe specconnect-payments --platform managed --region=us-central1 --format=url
```

Configure Yoco webhook
1. Point the webhook in your Yoco dashboard to `https://<service-url>/webhook`.
2. Copy the webhook signing secret into Secret Manager (or set as env var `YOCO_WEBHOOK_SECRET`).

Local testing with ngrok (no real money)
1. Start the server locally:

```bash
cd scripts/payments-server
npm install
node index.js
```

2. Run ngrok to expose your local server (or use `--host` if using a different tunneling tool):

```bash
ngrok http 3000
# copy the https ngrok URL and configure Yoco webhook to point to https://abcd1234.ngrok.io/webhook
```

Simulate a webhook (signed)
1. Edit `.env.example` with your test secrets or set env vars locally.
2. Use `node webhook-simulate.js` to send a signed test payload to the `/webhook` endpoint.

Verify
- After a successful webhook or test charge, inspect the `payments` table in Supabase and verify `doctor.balance` and the appointment `is_paid` flag were updated.

Security notes
GCP helper: create service account & secrets
1. Create a `secrets.env` file (DO NOT commit) with contents like:

```ini
YOCO_SECRET_KEY=sk_live_...
YOCO_WEBHOOK_SECRET=whsec_...
SUPABASE_SERVICE_ROLE_KEY=service_role_...
SUPABASE_URL=https://your-supabase-url
```

2. Run the helper to create a service account key and upload secrets to Secret Manager:

```bash
./gcp_setup.sh --project=MY_GCP_PROJECT --sa-name=specconnect-deploy-sa --secrets-file=secrets.env
```

3. The helper will create a service account key file named `specconnect-deploy-sa-key.json`. Add that JSON as the GitHub secret `GCP_SA_KEY` and set `GCP_PROJECT_ID` to your project id in the repo secrets.

4. Commit and push to `main` to trigger the `payments-server` workflow which will build and deploy to Cloud Run.

- Never embed secret keys in the client or commit them to git. Use Secret Manager, Heroku config vars or similar.
- Prefer client-side tokenization or hosted checkout when available to maintain PCI compliance. Avoid `/charge-direct` in production.
