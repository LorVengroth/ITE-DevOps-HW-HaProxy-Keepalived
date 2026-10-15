#!/usr/bin/env bash
set -euo pipefail

APP_SRC="/vagrant/next-app"
APP_DEST="/home/appuser/next-app"
SERVICE_NAME="next-app.service"

echo "=========================================================="
echo " Starting Next.js Deployment on $(hostname)"
echo "=========================================================="

# 1. Ensure target directory exists and is owned by appuser
echo "[1/6] Preparing application destination..."
sudo mkdir -p "$APP_DEST"
sudo chown -R appuser:appuser "$APP_DEST"

# 2. Sync clean source files into the user workspace
echo "[2/6] Syncing code from $APP_SRC..."
sudo rsync -av --delete \
  --exclude 'node_modules' \
  --exclude '.next' \
  --exclude '.git' \
  "$APP_SRC/" "$APP_DEST/"
sudo chown -R appuser:appuser "$APP_DEST"

# 3. Install dependencies and compile production build
echo "[3/6] Building production bundle as appuser..."
sudo -u appuser bash -c "cd $APP_DEST && npm install --silent && npm run build"

# 4. Install and register the systemd service file
echo "[4/6] Installing systemd service..."
sudo cp /vagrant/systemd/$SERVICE_NAME /etc/systemd/system/$SERVICE_NAME
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME

# 5. Restart the application daemon
echo "[5/6] Restarting $SERVICE_NAME..."
sudo systemctl restart $SERVICE_NAME

# 6. Verify service health and port availability
echo "[6/6] Verifying deployment..."
sleep 2

if systemctl is-active --quiet $SERVICE_NAME; then
    echo "Service Status: Active (Running)"
else
    echo "ERROR: Service failed to start!"
    sudo systemctl status $SERVICE_NAME --no-pager
    exit 1
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || true)
if [ "$HTTP_CODE" = "200" ]; then
    echo "Health Check : PASSED (HTTP 200 OK)"
    echo "Active Port  : 3000"
    echo "Host Node    : $(curl -s http://localhost:3000/ | grep -m 1 -ioE "web-01|web-02" || hostname)"
else
    echo "WARNING: Health check returned HTTP $HTTP_CODE"
    exit 1
fi

echo "=========================================================="
echo " Deployment Complete Successfully on $(hostname)!"
echo "=========================================================="