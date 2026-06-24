#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")" || exit 1

echo "Starting full setup..."

echo "*****************"
echo "UNINSTALLING PACKAGES AND WEBAPPS..."
echo "*****************"
./uninstall-packages.sh

echo "*****************"
echo "INSTALLING PACKAGES..."
echo "*****************"
./install-packages.sh


echo "*****************"
echo "STOWING CONFIGURATION..."
echo "*****************"
./stow-config.sh