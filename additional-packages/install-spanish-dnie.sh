#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Install Spanish DNIe support on Arch Linux for Omarchy
# ============================================================

echo "==> Installing packages..."
sudo pacman -S --needed opensc pcsc-tools ccid
yay -S --needed libpkcs11-dnie

# AutoFirma depends on java-runtime=17.
# Remove jre17-openjdk if present (conflicts with jdk17-openjdk)
if pacman -Q jre17-openjdk &>/dev/null; then
  sudo pacman -Rdd --noconfirm jre17-openjdk
fi
# Pre-install jdk17-openjdk via pacman so yay doesn't prompt for provider
if ! pacman -Q jdk17-openjdk &>/dev/null; then
  sudo pacman -S --noconfirm jdk17-openjdk
fi
# autofirma (source) no compila con JDK 17 (usa javax.swing.JApplet eliminado).
# Usamos autofirma-bin que es pre-compilado a partir del .deb oficial.
yay -S --noconfirm --needed autofirma-bin

echo "==> Enabling pcscd service..."
sudo systemctl enable --now pcscd.service

# --------------------------------------------------
# 1. System-wide p11-kit module for OpenSC
# --------------------------------------------------
echo "==> Configuring p11-kit module for OpenSC..."
sudo mkdir -p /etc/pkcs11/modules
if [ ! -f /etc/pkcs11/modules/opensc.module ]; then
  echo 'module: /usr/lib/opensc-pkcs11.so
critical: no' | sudo tee /etc/pkcs11/modules/opensc.module > /dev/null
fi

# --------------------------------------------------
# 2. Download and install AC RAIZ DNIE 2 root CA
# --------------------------------------------------
echo "==> Installing AC RAIZ DNIE 2 root certificate..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

curl -sL -o "$TMPDIR/ACRAIZ-DNIE2.zip" \
  "https://www.dnielectronico.es/ZIP/ACRAIZ-DNIE2.zip"
unzip -o "$TMPDIR/ACRAIZ-DNIE2.zip" -d "$TMPDIR"

# Install system-wide
sudo cp "$TMPDIR/AC RAIZ DNIE 2.crt" /usr/share/ca-certificates/trust-source/anchors/
sudo trust extract-compat
echo "  -> System trust store updated"

# Also install in user NSS db (Firefox/Chromium)
if [ -d ~/.pki/nssdb ]; then
  certutil -d ~/.pki/nssdb -A -n "AC RAIZ DNIE 2" -t "C,C,C" \
    -i "$TMPDIR/AC RAIZ DNIE 2.crt" 2>/dev/null && \
    echo "  -> Added to user NSS database" || \
    echo "  -> Already in NSS database"
fi

# --------------------------------------------------
# 3. Register OpenSC PKCS#11 module in NSS database
# --------------------------------------------------
echo "==> Registering OpenSC PKCS#11 module in NSS database..."
if ! modutil -dbdir ~/.pki/nssdb/ -list 2>/dev/null | grep -q "OpenSC"; then
  modutil -dbdir ~/.pki/nssdb/ -add "OpenSC" \
    -libfile /usr/lib/opensc-pkcs11.so -force
else
  echo "  -> OpenSC module already registered"
fi

# --------------------------------------------------
# 4. Extract and install intermediate CAs from the card
#    (Requires the DNIe to be inserted)
# --------------------------------------------------
echo "==> Attempting to install DNIe intermediate CA from card..."
if pkcs15-tool --list-readers 2>/dev/null | grep -q "Card.*Yes"; then
  echo "  -> Card detected, extracting intermediate CA..."

  # Read the intermediate CA from the card
  INTERMEDIATE_ID="5330323033304245443032344434363230323630343237313633363039"
  pkcs15-tool --read-certificate "$INTERMEDIATE_ID" \
    -o "$TMPDIR/dnie_ca.crt" 2>/dev/null

  if [ -s "$TMPDIR/dnie_ca.crt" ]; then
    # Install system-wide
    sudo cp "$TMPDIR/dnie_ca.crt" \
      /usr/share/ca-certificates/trust-source/anchors/AC_DNIE_004.crt
    sudo trust extract-compat

    # Install in NSS db
    certutil -d ~/.pki/nssdb -A -n "AC DNIE 004" -t "C,C,C" \
      -i "$TMPDIR/dnie_ca.crt" 2>/dev/null || true

    echo "  -> Intermediate CA installed"

    # Also import the user certificates
    echo "  -> Importing DNIe user certificates..."
    for cert_label in "CertAutenticacion" "CertFirmaDigital"; do
      CERT_ID=$(pkcs15-tool -D 2>/dev/null | grep -B1 "$cert_label" | \
        grep "ID" | awk '{print $NF}')
      if [ -n "$CERT_ID" ]; then
        pkcs15-tool --read-certificate "$CERT_ID" \
          -o "$TMPDIR/$cert_label.crt" 2>/dev/null
        NSS_LABEL=$(echo "$cert_label" | sed 's/CertAutenticacion/DNIe Autenticacion/;s/CertFirmaDigital/DNIe Firma/')
        certutil -d ~/.pki/nssdb -A -n "$NSS_LABEL" -t ",," \
          -i "$TMPDIR/$cert_label.crt" 2>/dev/null || true
      fi
    done
  fi
else
  echo "  -> No card detected (insert DNIe and re-run to import intermediate CA)"
fi

# --------------------------------------------------
# 5. Add PKCS#11 module flag for Chromium/Chrome
# --------------------------------------------------
echo "==> Configuring browser flags..."
for flags_file in ~/.config/chromium-flags.conf ~/.config/chrome-flags.conf \
                  ~/.config/google-chrome-flags.conf; do
  if [ -f "$flags_file" ]; then
    if ! grep -q "load-pkcs11-module" "$flags_file" 2>/dev/null; then
      echo "--load-pkcs11-module=/usr/lib/opensc-pkcs11.so" >> "$flags_file"
      echo "  -> Updated $flags_file"
    else
      echo "  -> Already configured in $flags_file"
    fi
  fi
done

echo ""
echo "============================================"
echo " DNIe setup complete!"
echo ""
echo " Next steps:"
echo "  1. Insert DNIe and restart Chrome/Chromium"
echo "  2. Test at: https://sede.seg-social.gob.es"
echo "============================================"

