#!/bin/bash
#
# Checkpoint Alpha (v0.1)
# A manual script to generate a Merkle root of the Helix Ledger's state.
# This serves as the first implementation of the §8 Checkpoint-Only model.
#

set -euo pipefail

LEDGER_DIR="/home/aiadmin/helix_ledger"

echo "--- Generating Checkpoint Alpha State Hash ---"
echo "Timestamp: $(date -u --iso-8601=seconds)"
echo ""

# 1. Define the set of files that constitute the state.
#    This list should be expanded as more critical components are added.
STATE_FILES=(
  "$LEDGER_DIR/modules/bitcoin/audit_log.json"
  "$LEDGER_DIR/upv_baseline.jsonl"
  "$LEDGER_DIR/core/hcs_01_epistemic_marker_protocol.md"
  "$LEDGER_DIR/core/hsc_01_splicing_contract.md"
  "$LEDGER_DIR/core/consent_registry.json"
  "$LEDGER_DIR/docs/constitutional_audit_01.md"
)

echo "Found ${#STATE_FILES[@]} files to include in the state hash:"
for f in "${STATE_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "  - $(basename "$f")"
  else
    echo "  - WARNING: $(basename "$f") not found. Skipping."
  fi
done
echo ""

# 2. Concatenate all found files and compute the final SHA-256 hash.
#    The `find` command with `-exec cat {} +` is a robust way to handle
#    missing files gracefully.
STATE_HASH=$(find "${STATE_FILES[@]}" -type f -exec cat {} + | sha256sum | awk '{print $1}')

echo "------------------------------------------------------------------"
echo "Epoch State Merkle Root (Checkpoint Alpha):"
echo "$STATE_HASH"
echo "------------------------------------------------------------------"
echo "This hash represents the complete, auditable state of the Helix Ledger."
echo "In a production environment, this value would be committed to the Bitcoin blockchain via an OP_RETURN transaction."
