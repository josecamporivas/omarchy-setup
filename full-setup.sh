#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")" || exit 1

echo "Starting full setup..."

echo "*****************"
echo "Installing packages..."
echo "*****************"
./install-packages.sh


echo "*****************"
echo "Stowing configuration..."
echo "*****************"
./stow-config.sh