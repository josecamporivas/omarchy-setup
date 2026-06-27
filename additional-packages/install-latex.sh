#!/usr/bin/env bash

set -euo pipefail

WORKDIR="/tmp/texlive-install"
INSTALLER_URL="https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz"

echo "=== TeX Live Installation ==="

# Ensure required tools exist
for cmd in curl tar perl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $cmd"
        exit 1
    fi
done

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Please run as root (or with sudo)."
    exit 1
fi

# Prepare working directory
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Downloading installer..."
curl -L -o install-tl-unx.tar.gz "$INSTALLER_URL"

echo "Extracting installer..."
zcat < install-tl-unx.tar.gz | tar xf -

INSTALL_DIR=$(find . -maxdepth 1 -type d -name "install-tl-*" | head -n1)

if [[ -z "$INSTALL_DIR" ]]; then
    echo "ERROR: Could not locate extracted installer directory."
    exit 1
fi

cd "$INSTALL_DIR"

echo "Starting unattended installation..."
perl ./install-tl --no-interaction

echo "Detecting installed TeX Live version..."

YEAR=$(find /usr/local/texlive -maxdepth 1 -mindepth 1 -type d \
    | grep -E '/[0-9]{4}$' \
    | sed 's#.*/##' \
    | sort -n \
    | tail -1)

if [[ -z "$YEAR" ]]; then
    echo "WARNING: Could not determine installed TeX Live year."
    exit 0
fi

PLATFORM=$(find "/usr/local/texlive/${YEAR}/bin" -mindepth 1 -maxdepth 1 -type d \
    | head -n1 \
    | xargs basename)

if [[ -z "$PLATFORM" ]]; then
    echo "WARNING: Could not determine TeX Live platform."
    exit 0
fi

TEXLIVE_BIN="/usr/local/texlive/${YEAR}/bin/${PLATFORM}"

echo "Configuring system PATH..."

cat > /etc/profile.d/texlive.sh <<EOF
export PATH="${TEXLIVE_BIN}:\$PATH"
EOF

chmod 644 /etc/profile.d/texlive.sh

echo
echo "========================================="
echo "TeX Live installed successfully."
echo "Binary path:"
echo "  ${TEXLIVE_BIN}"
echo
echo "PATH configuration written to:"
echo "  /etc/profile.d/texlive.sh"
echo
echo "Log out and back in, or run:"
echo "  source /etc/profile.d/texlive.sh"
echo "========================================="