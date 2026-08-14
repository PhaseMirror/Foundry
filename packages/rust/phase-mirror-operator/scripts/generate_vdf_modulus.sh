#!/usr/bin/env bash
# Generate a safe 2048-bit RSA modulus for the Pell VDF.
# Run this in a disposable, air-gipped environment.
# Output goes to config/vdf_modulus.hex
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_FILE="$ROOT_DIR/config/vdf_modulus.hex"

mkdir -p "$ROOT_DIR/config"

echo "[VDF-MODULUS] Generating 2048-bit RSA modulus..."
echo "[VDF-MODULUS] This should run in a disposable, air-gapped environment."

if ! command -v openssl >/dev/null 2>&1; then
    echo "[ERROR] openssl not found. Install openssl first."
    exit 1
fi

# Generate private key, extract modulus, then destroy key
PRIV_KEY="/tmp/vdf_modulus_$$.pem"
trap "rm -f '$PRIV_KEY'" EXIT

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM -out "$PRIV_KEY" >/dev/null 2>&1
MODULUS=$(openssl rsa -in "$PRIV_KEY" -modulus -noout 2>/dev/null | sed 's/Modulus=//')

# Zeroize the private key
shred -u "$PRIV_KEY" 2>/dev/null || rm -f "$PRIV_KEY"

# Strip colons and write hex
CLEAN_HEX=$(echo "$MODULUS" | tr -d ':')
echo "$CLEAN_HEX" > "$OUTPUT_FILE"

echo "[SUCCESS] Modulus written to $OUTPUT_FILE"
echo "[WARN] The primes have been destroyed. Save this modulus securely."
echo "[WARN] For production, move this to an HSM or secure enclave."
