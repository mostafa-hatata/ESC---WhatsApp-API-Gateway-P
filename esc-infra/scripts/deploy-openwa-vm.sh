#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="egyptian-shooting-club"
ZONE="us-central1-a"
VM_NAME="esc-openwa-vm"
REPO_URL="https://github.com/mostafa-hatata/ESC---WhatsApp-API-Gateway-P.git"

gcloud config set project "$PROJECT_ID"

gcloud compute ssh "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --command="
set -e

sudo docker rm -f esc-openwa openwa-api || true

sudo apt-get update
sudo apt-get install -y git docker-compose-plugin

cd /opt
sudo rm -rf ESC---WhatsApp-API-Gateway-P
sudo git clone ${REPO_URL}
sudo chown -R \$USER:\$USER /opt/ESC---WhatsApp-API-Gateway-P

cd /opt/ESC---WhatsApp-API-Gateway-P

cat > .env <<ENV
BIND_HOST=0.0.0.0
NODE_ENV=production
DATABASE_TYPE=sqlite
DATABASE_SYNCHRONIZE=true
AUTO_START_SESSIONS=true
PUPPETEER_HEADLESS=true
PUPPETEER_ARGS=--no-sandbox,--disable-setuid-sandbox,--disable-dev-shm-usage,--disable-gpu
CSP_UPGRADE_INSECURE_REQUESTS=false
ENV

cat > docker-compose.override.yml <<OVERRIDE
services:
  openwa:
    ports:
      - '0.0.0.0:8080:2785'
OVERRIDE

sudo docker compose -f docker-compose.dev.yml -f docker-compose.override.yml up -d --build
sleep 20

sudo docker ps --filter name=openwa
curl -s -o /tmp/openwa.html -w 'openwa_http_code=%{http_code}\n' --max-time 20 http://localhost:8080/ || true
"

VM_IP="$(gcloud compute instances describe "$VM_NAME" \
  --zone="$ZONE" \
  --project="$PROJECT_ID" \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)')"

echo "OpenWA VM URL:"
echo "http://${VM_IP}:8080"
