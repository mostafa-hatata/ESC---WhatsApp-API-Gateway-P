#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="egyptian-shooting-club"
REGION="us-central1"
ZONE="us-central1-a"
VM_NAME="esc-openwa-vm"
SERVICE_NAME="esc-whatsapp-gateway"

gcloud config set project "$PROJECT_ID"

VM_IP="$(gcloud compute instances describe "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"

OPENWA_TARGET="http://${VM_IP}:8080"

echo "Deploy Cloud Run proxy to: ${OPENWA_TARGET}"

gcloud run deploy "$SERVICE_NAME" \
  --source esc-infra/cloud-run-proxy \
  --region "$REGION" \
  --allow-unauthenticated \
  --set-env-vars "OPENWA_TARGET=${OPENWA_TARGET}" \
  --project "$PROJECT_ID" \
  --quiet

cd esc-infra/firebase-hosting

firebase deploy \
  --only hosting \
  --project "$PROJECT_ID"

echo "Final URL:"
echo "https://esc-whatsapp-gateway.web.app"
