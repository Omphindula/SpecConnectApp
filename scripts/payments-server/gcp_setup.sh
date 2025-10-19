#!/usr/bin/env bash
set -euo pipefail

# Helper to create a GCP service account and Secret Manager secrets for the payments-server.
# Usage:
#   ./gcp_setup.sh --project=my-project --sa-name=specconnect-deploy-sa --secrets-file=secrets.env
# The secrets.env file should contain the following variables:
#   YOCO_SECRET_KEY
#   YOCO_WEBHOOK_SECRET
#   SUPABASE_SERVICE_ROLE_KEY
#   SUPABASE_URL

print_usage() { echo "Usage: $0 --project=PROJECT --sa-name=SA_NAME --secrets-file=SECRETS_FILE"; exit 2; }

for arg in "$@"; do
  case $arg in
    --project=*) PROJECT="${arg#*=}"; shift;;
    --sa-name=*) SA_NAME="${arg#*=}"; shift;;
    --secrets-file=*) SECRETS_FILE="${arg#*=}"; shift;;
    *) echo "Unknown arg: $arg"; print_usage;;
  esac
done

if [ -z "${PROJECT-}" ] || [ -z "${SA_NAME-}" ] || [ -z "${SECRETS_FILE-}" ]; then
  print_usage
fi

if [ ! -f "$SECRETS_FILE" ]; then echo "Secrets file not found: $SECRETS_FILE"; exit 2; fi

echo "Using project: $PROJECT"
gcloud config set project "$PROJECT"

SA_EMAIL="$SA_NAME@$PROJECT.iam.gserviceaccount.com"
echo "Creating service account: $SA_EMAIL (idempotent)"
gcloud iam service-accounts create "$SA_NAME" --project "$PROJECT" || true

echo "Binding roles to service account"
gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA_EMAIL" --role "roles/run.admin" || true
gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA_EMAIL" --role "roles/storage.admin" || true
gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA_EMAIL" --role "roles/cloudbuild.builds.editor" || true
gcloud projects add-iam-policy-binding "$PROJECT" --member "serviceAccount:$SA_EMAIL" --role "roles/secretmanager.secretAccessor" || true

KEY_FILE="${SA_NAME}-key.json"
echo "Creating service account key: $KEY_FILE"
gcloud iam service-accounts keys create "$KEY_FILE" --iam-account "$SA_EMAIL" --project "$PROJECT"
echo "Created key file: $KEY_FILE"

echo "Uploading secrets to Secret Manager"
while IFS='=' read -r k v; do
  [[ -z "$k" ]] && continue
  # Map common env var keys to the exact Secret Manager names used by the workflow
  case "$k" in
    YOCO_SECRET_KEY) name="yoco-secret" ;;
    YOCO_WEBHOOK_SECRET) name="yoco-webhook-secret" ;;
    SUPABASE_SERVICE_ROLE_KEY) name="supabase-service-role" ;;
    SUPABASE_URL) name="supabase-url" ;;
    *) name=$(echo "$k" | tr '[:upper:]' '[:lower:]' | tr '_' '-') ;;
  esac

  echo "Creating secret: $name"
  # Create the secret if it doesn't exist
  if ! gcloud secrets describe "$name" --project "$PROJECT" >/dev/null 2>&1; then
    gcloud secrets create "$name" --replication-policy="automatic" --project "$PROJECT"
  fi
  # Add the secret value as a new version
  echo -n "$v" | gcloud secrets versions add "$name" --data-file=- --project "$PROJECT"
done < <(grep -v '^#' "$SECRETS_FILE")

echo "All done. Service account key: $KEY_FILE. Add that JSON as GitHub secret GCP_SA_KEY and set GCP_PROJECT_ID to $PROJECT in repo secrets."
