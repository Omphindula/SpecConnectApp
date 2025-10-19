#!/usr/bin/env bash
set -euo pipefail
# Helper to run flutter with values from a .env file (bash.exe on Windows)
# Usage: source .env && ./scripts/run_with_env.sh [device]

DEVICE=${1:-chrome}

# Read values exported into the environment (expects SUPABASE_URL, SUPABASE_KEY, OPENAI_PROXY_* etc.)
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
  echo "SUPABASE_URL and SUPABASE_KEY must be set in the environment. You can run: source .env"
  exit 1
fi

DART_DEFINES=(
  "--dart-define=SUPABASE_URL=$SUPABASE_URL"
  "--dart-define=SUPABASE_KEY=$SUPABASE_KEY"
)

if [ ! -z "$OPENAI_PROXY_API_KEY" ]; then
  DART_DEFINES+=("--dart-define=OPENAI_PROXY_API_KEY=$OPENAI_PROXY_API_KEY")
fi
if [ ! -z "$OPENAI_PROXY_ENDPOINT" ]; then
  DART_DEFINES+=("--dart-define=OPENAI_PROXY_ENDPOINT=$OPENAI_PROXY_ENDPOINT")
fi

# Build command
CMD=(flutter run -d "$DEVICE")
for d in "${DART_DEFINES[@]}"; do
  CMD+=("$d")
done

# Print & run
echo "Running: ${CMD[*]}"
"${CMD[@]}"
