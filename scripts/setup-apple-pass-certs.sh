#!/usr/bin/env bash
# ==============================================================================
# Encore - Apple Wallet PassKit Certificate Extraction & Setup Script
# ==============================================================================
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$DIR/.." && pwd)"
WEB_ENV="$ROOT_DIR/web/.env.local"

echo "========================================================"
echo "🎟️  ENCORE - APPLE WALLET PASSKIT CERTIFICATE SETUP"
echo "========================================================"
echo ""

P12_FILE=""

# Check arguments or look in common directories
if [ -n "$1" ] && [ -f "$1" ]; then
    P12_FILE="$1"
elif [ -f "$ROOT_DIR/pass.p12" ]; then
    P12_FILE="$ROOT_DIR/pass.p12"
elif [ -f "$DIR/pass.p12" ]; then
    P12_FILE="$DIR/pass.p12"
elif [ -f "$HOME/Downloads/pass.p12" ]; then
    P12_FILE="$HOME/Downloads/pass.p12"
elif [ -f "$HOME/Desktop/pass.p12" ]; then
    P12_FILE="$HOME/Desktop/pass.p12"
fi

if [ -z "$P12_FILE" ]; then
    echo "Nenašiel sa súbor pass.p12 automaticky."
    read -rp "Zadaj cestu k vyexportovanému pass.p12 (napr. ~/Downloads/pass.p12): " USER_INPUT_PATH
    # Expand tilde if present
    USER_INPUT_PATH="${USER_INPUT_PATH/#\~/$HOME}"
    if [ -f "$USER_INPUT_PATH" ]; then
        P12_FILE="$USER_INPUT_PATH"
    else
        echo "❌ Chyba: Súbor '$USER_INPUT_PATH' neexistuje."
        exit 1
    fi
fi

echo "✅ Našiel sa súbor: $P12_FILE"
read -s -rp "Zadaj heslo pre pass.p12 (ak si žiadne nezadal v Kľúčenke, stlač Enter): " P12_PASS
echo ""

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

CERT_PEM="$TMP_DIR/pass_cert.pem"
KEY_PEM="$TMP_DIR/pass_key.pem"

echo "⏳ Extrahujem certifikát a privátny kľúč pomocou OpenSSL..."

# Extract certificate (try legacy provider if OpenSSL 3 requires it for Keychain p12)
if openssl pkcs12 -in "$P12_FILE" -clcerts -nokeys -out "$CERT_PEM" -passin pass:"$P12_PASS" 2>/dev/null; then
    :
elif openssl pkcs12 -in "$P12_FILE" -clcerts -nokeys -out "$CERT_PEM" -passin pass:"$P12_PASS" -legacy 2>/dev/null; then
    :
else
    echo "❌ Chyba pri extrakcii certifikátu. Skontroluj heslo k .p12 súboru."
    exit 1
fi

# Extract private key
if openssl pkcs12 -in "$P12_FILE" -nocerts -nodes -out "$KEY_PEM" -passin pass:"$P12_PASS" 2>/dev/null; then
    :
elif openssl pkcs12 -in "$P12_FILE" -nocerts -nodes -out "$KEY_PEM" -passin pass:"$P12_PASS" -legacy 2>/dev/null; then
    :
else
    echo "❌ Chyba pri extrakcii privátneho kľúča."
    exit 1
fi

# Check Apple WWDR G4 intermediate cert
WWDR_PEM="$DIR/AppleWWDRCAG4.pem"
if [ ! -f "$WWDR_PEM" ]; then
    echo "⏳ Sťahujem oficiálny Apple WWDR G4 certifikát..."
    curl -sS -o "$TMP_DIR/AppleWWDRCAG4.cer" https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer
    openssl x509 -inform DER -in "$TMP_DIR/AppleWWDRCAG4.cer" -out "$WWDR_PEM"
fi

# Convert to single-line base64
B64_CERT="$(base64 -i "$CERT_PEM" | tr -d '\n\r')"
B64_KEY="$(base64 -i "$KEY_PEM" | tr -d '\n\r')"
B64_WWDR="$(base64 -i "$WWDR_PEM" | tr -d '\n\r')"

echo ""
echo "🎉 Certifikáty úspešne vygenerované a enkódované do Base64!"
echo ""

# Update local web/.env.local
if [ -f "$WEB_ENV" ]; then
    # Remove old entries if present
    grep -v '^APPLE_PASS_' "$WEB_ENV" | grep -v '^APPLE_TEAM_IDENTIFIER' | grep -v '^APPLE_WWDR_CERT_BASE64' > "$WEB_ENV.tmp" || true
    mv "$WEB_ENV.tmp" "$WEB_ENV"
    
    cat <<EOF >> "$WEB_ENV"

# Apple Wallet PassKit Configuration
APPLE_PASS_TYPE_IDENTIFIER=pass.com.jakub.encore
APPLE_TEAM_IDENTIFIER=2MD5BS4DLM
APPLE_PASS_CERT_BASE64=$B64_CERT
APPLE_PASS_KEY_BASE64=$B64_KEY
APPLE_WWDR_CERT_BASE64=$B64_WWDR
EOF
    echo "✅ web/.env.local bol automaticky aktualizovaný pre lokálne testovanie."
fi

echo ""
echo "=========================================================================="
echo "📋 PREKOPÍRUJ TIETO PREMENNÉ DO VERCEL DASHBOARD (Project Settings > Environment Variables):"
echo "=========================================================================="
echo ""
echo "APPLE_PASS_TYPE_IDENTIFIER=pass.com.jakub.encore"
echo "APPLE_TEAM_IDENTIFIER=2MD5BS4DLM"
echo "APPLE_WWDR_CERT_BASE64=$B64_WWDR"
echo "APPLE_PASS_CERT_BASE64=$B64_CERT"
echo "APPLE_PASS_KEY_BASE64=$B64_KEY"
echo ""
echo "=========================================================================="
echo "Všetko je pripravené! Po nahraní na Vercel začne Apple Wallet generovať plnohodnotné .pkpass karty."
echo "=========================================================================="
