#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Install Spanish DNIe support on Arch Linux for Omarchy
# ============================================================

echo "==> Installing packages..."
# OpenSC is the maintained PKCS#11 provider used by the browser. The AUR
# libpkcs11-dnie package currently links against the removed libassuan.so.0.
sudo pacman -S --needed opensc pcsc-tools ccid p11-kit nss curl unzip

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

OPENSC_MODULE=/usr/lib/opensc-pkcs11.so
NSS_DATABASES=()

initialize_nss_databases() {
  local db

  # Chromium uses the legacy database when it exists, otherwise it uses the
  # newer shared database location.
  for db in "$HOME/.pki/nssdb" "$HOME/.local/share/pki/nssdb"; do
    if [[ -f "$db/cert9.db" && -f "$db/key4.db" ]]; then
      NSS_DATABASES+=("$db")
    fi
  done

  if [[ ${#NSS_DATABASES[@]} -eq 0 ]]; then
    db="$HOME/.local/share/pki/nssdb"
    mkdir -p "$db"
    certutil -N -d "sql:$db" --empty-password
    NSS_DATABASES+=("$db")
  fi
}

add_nss_certificate() {
  local db=$1
  local label=$2
  local trust=$3
  local certificate=$4

  if ! certutil -d "sql:$db" -L -n "$label" >/dev/null 2>&1; then
    certutil -d "sql:$db" -A -n "$label" -t "$trust" -i "$certificate"
  fi
}

initialize_nss_databases

# --------------------------------------------------
# 1. System-wide p11-kit module for OpenSC
# --------------------------------------------------
echo "==> Configuring p11-kit module for OpenSC..."
sudo mkdir -p /etc/pkcs11/modules
if [ ! -f /etc/pkcs11/modules/opensc.module ] && \
   [ ! -f /usr/share/p11-kit/modules/opensc.module ]; then
  echo 'module: /usr/lib/opensc-pkcs11.so
critical: no' | sudo tee /etc/pkcs11/modules/opensc.module > /dev/null
fi

# --------------------------------------------------
# 2. Download and install AC RAIZ DNIE 2 root CA
# --------------------------------------------------
echo "==> Installing AC RAIZ DNIE 2 root certificate..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

if curl -fsSL -o "$TMPDIR/ACRAIZ-DNIE2.zip" \
    "https://www.dnielectronico.es/ZIP/ACRAIZ-DNIE2.zip" && \
    unzip -oq "$TMPDIR/ACRAIZ-DNIE2.zip" -d "$TMPDIR"; then
  :
elif [ -f "/usr/share/libpkcs11-dnie/AC RAIZ DNIE 2.crt" ]; then
  cp "/usr/share/libpkcs11-dnie/AC RAIZ DNIE 2.crt" "$TMPDIR/"
else
  echo "Could not obtain AC RAIZ DNIE 2 certificate."
  exit 1
fi

# Install system-wide. Arch reads anchors from /etc, not /usr/share.
sudo install -Dm644 "$TMPDIR/AC RAIZ DNIE 2.crt" \
  /etc/ca-certificates/trust-source/anchors/AC_RAIZ_DNIE_2.crt
sudo trust extract-compat
echo "  -> System trust store updated"

# Also install in the user NSS databases used by Chromium/Firefox.
for db in "${NSS_DATABASES[@]}"; do
  add_nss_certificate "$db" "AC RAIZ DNIE 2" "C,C,C" \
    "$TMPDIR/AC RAIZ DNIE 2.crt"
done
echo "  -> User NSS database(s) updated"

# --------------------------------------------------
# 3. Register OpenSC PKCS#11 module in NSS database
# --------------------------------------------------
echo "==> Registering OpenSC PKCS#11 module in NSS database..."
for db in "${NSS_DATABASES[@]}"; do
  if ! modutil -dbdir "sql:$db" -list 2>/dev/null | grep -q "OpenSC"; then
    modutil -dbdir "sql:$db" -add "OpenSC" \
      -libfile "$OPENSC_MODULE" -force
  else
    echo "  -> OpenSC module already registered in $db"
  fi
done

# --------------------------------------------------
# 4. Extract and install intermediate CAs from the card
#    (Requires the DNIe to be inserted)
# --------------------------------------------------
echo "==> Attempting to install DNIe intermediate CA from card..."
if opensc-tool --list-readers 2>/dev/null | \
    awk 'NR > 1 && $2 == "Yes" { found = 1 } END { exit !found }'; then
  echo "  -> Card detected, extracting intermediate CA..."

  CARD_CERTIFICATES=$(pkcs15-tool -c 2>/dev/null || true)
  certificate_id() {
    local label=$1
    awk -v label="$label" '
      index($0, "[" label "]") { in_certificate = 1; next }
      in_certificate && /X.509 Certificate \[/ { exit }
      in_certificate && /ID[[:space:]]*:/ { print $NF; exit }
    ' <<< "$CARD_CERTIFICATES"
  }

  INTERMEDIATE_ID=$(certificate_id "CertCAIntermediaDGP")
  if [ -z "$INTERMEDIATE_ID" ]; then
    echo "  -> Intermediate certificate was not found on the card"
    exit 1
  fi
  pkcs15-tool --read-certificate "$INTERMEDIATE_ID" \
    -o "$TMPDIR/dnie_ca.crt"

  if [ -s "$TMPDIR/dnie_ca.crt" ]; then
    # Install system-wide
    sudo install -Dm644 "$TMPDIR/dnie_ca.crt" \
      /etc/ca-certificates/trust-source/anchors/AC_DNIE_004.crt
    sudo trust extract-compat

    # Install in the user NSS databases
    for db in "${NSS_DATABASES[@]}"; do
      add_nss_certificate "$db" "AC DNIE 004" "C,C,C" \
        "$TMPDIR/dnie_ca.crt"
    done

    echo "  -> Intermediate CA installed"

    # Also import the user certificates
    echo "  -> Importing DNIe user certificates..."
    for cert_label in "CertAutenticacion" "CertFirmaDigital"; do
      CERT_ID=$(certificate_id "$cert_label")
      if [ -n "$CERT_ID" ]; then
        pkcs15-tool --read-certificate "$CERT_ID" \
          -o "$TMPDIR/$cert_label.crt"
        NSS_LABEL=$(echo "$cert_label" | sed 's/CertAutenticacion/DNIe Autenticacion/;s/CertFirmaDigital/DNIe Firma/')
        for db in "${NSS_DATABASES[@]}"; do
          add_nss_certificate "$db" "$NSS_LABEL" ",," \
            "$TMPDIR/$cert_label.crt"
        done
      fi
    done
  fi
else
  echo "  -> No card detected (insert DNIe and re-run to import intermediate CA)"
fi

# --------------------------------------------------
# 5. Chromium/Chrome use the module registered in NSS above.
#    The old --load-pkcs11-module flag is not needed.
# --------------------------------------------------
echo "==> Chromium/Chrome NSS configuration complete"

echo ""
echo "============================================"
echo " DNIe setup complete!"
echo ""
echo " Next steps:"
echo "  1. Insert DNIe and restart Chrome/Chromium"
echo "  2. Test at: https://sede.seg-social.gob.es"
echo "============================================"
