#!/bin/bash

HABITAT_LOCK_PATH="/home/aiadmin/helix-core-unified/system/core_ops/HABITAT_LOCK.json"
if [ -f "$HABITAT_LOCK_PATH" ]; then
    echo "❌ [FATAL] Habitat is in QUARANTINE mode. All state changes are blocked."
    echo "Reason: $(jq -r .reason "$HABITAT_LOCK_PATH")"
    exit 1
fi


# --- Grounded v1.2.0 Paths ---
SITE_ROOT="/home/aiadmin/helix-core-unified"
LEDGER_MANIFEST="$SITE_ROOT/thoughts/manifests/ledger_manifest.json"
VAULT_PERMISSIONS="$SITE_ROOT/thoughts/vault_permissions.json"
VALIDATOR="$SITE_ROOT/scripts/validate_permission_schema.py"
L1_ANCHOR_TOOL="$SITE_ROOT/scripts/l1_anchor_tool.py"

# --- Input Gate ---
# This Notary is dedicated and has a fixed target.
if [ "$1" != "$VAULT_PERMISSIONS" ]; then
    echo "Usage: $0 $VAULT_PERMISSIONS"
    echo "This notary is dedicated to the Permission Braid only."
    exit 1
fi

TARGET_FILE="$1"

# --- 1. Mandatory Pre-Flight Validation ---
echo "Verifying Permission Braid integrity..."
python3 "$VALIDATOR" "$TARGET_FILE"

if [ $? -ne 0 ]; then
    echo "❌ [FATAL] Schema validation failed. Notarization aborted. Manifest remains untouched."
    exit 1
fi
echo "✅ Integrity verified."

# --- 2. Forensic Hash Generation ---
SHA256_HASH=$(sha256sum "$TARGET_FILE" | awk '{print $1}')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- 3. Update Ledger Manifest ---
echo "Notarizing new Permission Braid state..."
NEW_TRANSACTION=$(jq -n \
  --arg ts "$TIMESTAMP" \
  --arg hash "$SHA256_HASH" \
  '{timestamp_utc: $ts, type: "PERMISSION_BRAID_STATE", details: "Notarized state of the Permission Braid.", permission_file_hash_sha256: $hash}')

tmp_manifest=$(mktemp)
jq --argjson entry "$NEW_TRANSACTION" \
   --arg ts "$TIMESTAMP" \
   '.transactions += [$entry] | .manifest_timestamp_utc = $ts | .ledger_period_end_utc = $ts' \
   "$LEDGER_MANIFEST" > "$tmp_manifest" && mv "$tmp_manifest" "$LEDGER_MANIFEST"

if [ $? -ne 0 ]; then
    echo "❌ [FATAL] Failed to write to the Ledger Manifest. Notarization failed."
    # The original manifest is untouched due to the atomic move.
    exit 1
fi

# --- 4. Final Output for Human-in-Command ---
echo "✅ [SUCCESS] Permission Braid state notarized in the Ledger Manifest."
echo "Hash: $SHA256_HASH"
echo "---"
echo "L1 Anchor Command: python3 $L1_ANCHOR_TOOL $SHA256_HASH"
