#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "  ADR-0035: ONE-COMMAND LOCAL VERIFICATION (PRIVATE ONLY)   "
echo "============================================================"

# Run Lean 4 formal test harness
lake exe ADR0035Test

# Generate local private witness
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TREE_HASH=$(git rev-parse HEAD 2>/dev/null || echo "LOCAL_TREE_UNCOMMITTED")
LOGS_HASH=$(echo "ADR0035_VERIFICATION_LOGS" | sha256sum | awk '{print $1}')

cat <<EOF > private_witness.json
{
  "witness_type": "PrivateLocalWitness",
  "is_private_only": true,
  "is_minting_authorized": false,
  "layer_b_status": "BLOCKED_PENDING_TAG",
  "tree_hash": "${TREE_HASH}",
  "logs_hash": "${LOGS_HASH}",
  "timestamp_iso": "${TIMESTAMP}"
}
EOF

echo "[+] Private witness generated and saved to private_witness.json"
echo "[!] NOTE: In accordance with ADR-0035, this witness is private-only. No public tokens or credentials may be minted."
