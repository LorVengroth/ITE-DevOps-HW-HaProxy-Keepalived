#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/4] Installing System Prerequisites ==="
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg git build-essential

echo "=== [2/4] Installing Node.js 20 LTS & npm ==="
if ! command -v node >/dev/null 2>&1; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt-get update -y
    sudo apt-get install -y nodejs
fi

echo "=== [3/4] Creating Dedicated Non-Root User (appuser) ==="
if ! id "appuser" &>/dev/null; then
    sudo useradd -m -s /bin/bash appuser
fi

echo "=== [4/4] Setting Up Application Directory ==="
sudo mkdir -p /home/appuser/next-app
sudo chown -R appuser:appuser /home/appuser/next-app
sudo chmod 755 /home/appuser


echo "Verification:"
echo "NODE VERSION : " node -v
echo "NPM VERSION : " npm -v
echo "appuser id  : " id appuser