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

# --- Input Gate ---
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_file> <owner_id>"
    exit 1
fi

FILE_PATH="$1"
OWNER_ID="$2"

if [ ! -f "$FILE_PATH" ]; then
    echo "❌ [ERROR] File not found: $FILE_PATH"
    exit 1
fi

# --- 1. Forensic Hash generation ---
SHA256_HASH=$(sha256sum "$FILE_PATH" | awk '{print $1}')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# --- 2. Update Ledger Manifest ---
tmp_manifest=$(mktemp)
jq --arg ts "$TIMESTAMP" \
   --arg path "$FILE_PATH" \
   --arg hash "$SHA256_HASH" \
   '.transactions += [{"timestamp_utc": $ts, "type": "VAULT_INGESTION", "filepath": $path, "file_hash_sha256": $hash}] | .manifest_timestamp_utc = $ts | .ledger_period_end_utc = $ts' \
   "$LEDGER_MANIFEST" > "$tmp_manifest" && mv "$tmp_manifest" "$LEDGER_MANIFEST"

# --- 3. Update Permission Braid (Default DENY) ---
# This implements "Custody Before Trust" at the moment of ingestion.
NEW_PERMISSION=$(jq -n \
  --arg hash "$SHA256_HASH" \
  --arg owner "$OWNER_ID" \
  --arg ts "$TIMESTAMP" \
  '{document_hash: $hash, owner_id: $owner, delegate_id: null, access_level: "DENY", valid_until: null, jurisdiction: "Quebec-BHS8", enforcement_mode: "GOVERNANCE", reason: "Default DENY established at ingestion", last_modified_utc: $ts, modified_by_id: "GOOSE-CORE"}')

tmp_perms=$(mktemp)
jq --argjson entry "$NEW_PERMISSION" \
   --arg ts "$TIMESTAMP" \
   '.permissions += [$entry] | .last_audit_anchor_utc = $ts' \
   "$VAULT_PERMISSIONS" > "$tmp_perms" && mv "$tmp_perms" "$VAULT_PERMISSIONS"

# --- 4. Substrate Validation ---
echo "Verifying Braid Integrity..."
python3 "$VALIDATOR" "$VAULT_PERMISSIONS"

if [ $? -eq 0 ]; then
    echo "✅ [SUCCESS] $FILE_PATH ingested and blinded."
    echo "Default State: DENY | Owner: $OWNER_ID"
    echo "Hash: $SHA256_HASH"
else
    echo "❌ [FATAL] Schema validation failed. Ingestion aborted."
    exit 1
fi
