#!/bin/bash

set -e

echo "Downloading k3s install script..."
curl -fsSL https://get.k3s.io -o /tmp/k3s-install.sh
chmod +x /tmp/k3s-install.sh

if ! command -v k3s &> /dev/null; then
    echo "Installing k3s..."
    /tmp/k3s-install.sh --disable traefik
else
    echo "k3s is already installed."
fi

echo "Ensuring k3s service is running..."
sudo systemctl enable --now k3s

echo "Checking k3s status..."
sudo systemctl status k3s --no-pager