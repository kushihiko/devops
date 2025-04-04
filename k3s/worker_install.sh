#!/bin/bash

set -e

echo "Downloading k3s install script..."
curl -fsSL https://get.k3s.io -o /tmp/k3s-install.sh
chmod +x /tmp/k3s-install.sh

K3S_TOKEN=$1
MASTER_IP=$2

if [ -z "$K3S_TOKEN" ]; then
    echo "Error: K3S_TOKEN is not set."
    exit 1
fi

if [ -z "$MASTER_IP" ]; then
    echo "Error: MASTER_IP is not set."
    exit 1
fi

echo "Joining k3s worker node..."
curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$K3S_TOKEN sh -

echo "Ensuring k3s service is running..."
sudo systemctl enable --now k3s-agent

echo "Checking k3s worker status..."
sudo systemctl status k3s-agent --no-pager