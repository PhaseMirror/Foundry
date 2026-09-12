#!/bin/bash

# --- Grounded Paths ---
SITE_ROOT="/home/aiadmin/helix-core-unified"
MANIFEST_FILE="$SITE_ROOT/thoughts/manifests/ledger_manifest.json"
L1_ANCHOR_TOOL="$SITE_ROOT/scripts/l1_anchor_tool.py"

# --- Requirements Check ---
if ! command -v jq &> /dev/null; then
    echo "❌ [ERROR] 'jq' is not installed."
    exit 1
fi

# --- Logic: Update Permission Braid State ---
update_permission_braid_state() {
    local PERM_FILE="$1"
    if [ ! -f "$PERM_FILE" ]; then
        echo "❌ [ERROR] Permission file not found: $PERM_FILE"
        exit 1
    fi

    local TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    # Update the internal file timestamp
    local tmp_perm=$(mktemp)
    jq --arg ts "$TIMESTAMP" '.last_audit_anchor_utc = $ts' "$PERM_FILE" > "$tmp_perm" && mv "$tmp_perm" "$PERM_FILE"

    # Generate Hash
    local SHA256_HASH=$(sha256sum "$PERM_FILE" | awk '{print $1}')

    # Update Manifest
    local tmp_manifest=$(mktemp)
    jq --arg ts "$TIMESTAMP" \
       --arg path "$PERM_FILE" \
       --arg hash "$SHA256_HASH" \
       '.transactions += [{"timestamp_utc": $ts, "type": "PERMISSION_BRAID_STATE", "filepath": $path, "file_hash_sha256": $hash}] | .manifest_timestamp_utc = $ts | .ledger_period_end_utc = $ts' \
       "$MANIFEST_FILE" > "$tmp_manifest" && mv "$tmp_manifest" "$MANIFEST_FILE"

    echo "✅ [SUCCESS] Permission Braid State Indexed: $SHA256_HASH"
    echo "Anchor Command: python3 $L1_ANCHOR_TOOL $SHA256_HASH"
}

# --- Command Router ---
case "$1" in
    "braid-state")
        update_permission_braid_state "$2"
        ;;
    *)
        echo "Usage: $0 braid-state <path_to_vault_permissions.json>"
        exit 1
        ;;
esac
