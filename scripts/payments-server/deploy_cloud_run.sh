#!/usr/bin/env bash
set -euo pipefail

# Deploy the payments-server to Google Cloud Run.
# Usage:
#   ./deploy_cloud_run.sh --project=my-gcp-project --service=specconnect-payments --image=specconnect-payments --region=us-central1 [--use-secret-manager]
# If --use-secret-manager is provided, the script expects the following Secret Manager secret names to exist:
#   yoco-secret, yoco-webhook-secret, supabase-service-role
# The secrets will be attached to the Cloud Run service as versions latest.

print_usage() {
  echo "Usage: $0 --project=GCP_PROJECT --service=SERVICE_NAME --image=IMAGE_NAME --region=REGION [--use-secret-manager]"
  exit 2
}

USE_SM=false
for arg in "$@"; do
  case $arg in
    --use-secret-manager) USE_SM=true; shift;;
    --project=*) PROJECT="${arg#*=}"; shift;;
    --service=*) SERVICE="${arg#*=}"; shift;;
    --image=*) IMAGE="${arg#*=}"; shift;;
    --region=*) REGION="${arg#*=}"; shift;;
    *) echo "Unknown arg: $arg"; print_usage;;
  esac
done

if [ -z "${PROJECT-}" ] || [ -z "${SERVICE-}" ] || [ -z "${IMAGE-}" ] || [ -z "${REGION-}" ]; then
  print_usage
fi

echo "Project: $PROJECT"
echo "Service: $SERVICE"
echo "Image: gcr.io/$PROJECT/$IMAGE"
echo "Region: $REGION"
echo "Use Secret Manager: $USE_SM"

echo "Building and submitting image to Google Cloud Build..."
gcloud config set project "$PROJECT"
gcloud builds submit --tag gcr.io/$PROJECT/$IMAGE ./scripts/payments-server

if [ "$USE_SM" = true ]; then
  echo "Deploying to Cloud Run with Secret Manager secrets..."
  # Map secret names (example names) to environment variable names used by the server
  gcloud run deploy "$SERVICE" \
    --image gcr.io/$PROJECT/$IMAGE \
    --region "$REGION" \
    --platform managed \
    --allow-unauthenticated \
    --set-secrets YOCO_SECRET_KEY=yoco-secret:latest,SUPABASE_SERVICE_ROLE_KEY=supabase-service-role:latest,YOCO_WEBHOOK_SECRET=yoco-webhook-secret:latest
else
  echo "Deploying to Cloud Run. IMPORTANT: you should provide secrets using Secret Manager or interactive input."
  echo "You will be prompted for sensitive values now (they will not be stored in git)."
  read -r -p "YOCO_SECRET_KEY: " -s YOCO_SECRET_KEY
  echo
  read -r -p "YOCO_WEBHOOK_SECRET: " -s YOCO_WEBHOOK_SECRET
  echo
  read -r -p "SUPABASE_SERVICE_ROLE_KEY: " -s SUPABASE_SERVICE_ROLE_KEY
  echo
  read -r -p "SUPABASE_URL: " SUPABASE_URL
  echo

  gcloud run deploy "$SERVICE" \
    --image gcr.io/$PROJECT/$IMAGE \
    --region "$REGION" \
    --platform managed \
    --allow-unauthenticated \
    --set-env-vars "YOCO_SECRET_KEY=$YOCO_SECRET_KEY,SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY,SUPABASE_URL=$SUPABASE_URL,YOCO_WEBHOOK_SECRET=$YOCO_WEBHOOK_SECRET,NODE_ENV=production"
fi

echo "Deployment finished. Run 'gcloud run services describe $SERVICE --platform managed --region $REGION --format=url' to get the HTTPS URL."
