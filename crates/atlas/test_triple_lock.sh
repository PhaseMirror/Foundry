#!/bin/bash
set -e

# Chaining the Triple-Lock: Guardian -> Examiner -> Publisher

# 1. Compile all components
cargo build --manifest-path "$(dirname "$0")/Cargo.toml" --quiet

BIN_DIR="$(dirname "$0")/../target/debug"
GUARDIAN="$BIN_DIR/moc-guardian"
EXAMINER="$BIN_DIR/moc-examiner"
PUBLISHER="$BIN_DIR/moc-publisher"

ENSEMBLE_ID="MQEM-001"
SEQ=10
DRIFT_MANIFEST="$(dirname "$0")/drift_manifest_full.json"

# Setup baseline for Examiner
cat <<EOF > "$DRIFT_MANIFEST"
{
  "ensemble_id": "$ENSEMBLE_ID",
  "baseline_weights": [0.4, 0.3, 0.2, 0.1],
  "delta_threshold": 0.0001,
  "timestamp": "2026-06-15T12:00:00Z"
}
EOF

echo "--- STEP 1: GUARDIAN Gating ---"
PROPOSAL=$(cat <<EOF
{
  "name": "MQEM Update",
  "sequence": $SEQ,
  "kappa": 0.9,
  "sigma": 0.5,
  "primes": [2, 3, 5, 7, 11],
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE"
}
EOF
)

GUARDIAN_OUT=$(echo "$PROPOSAL" | "$GUARDIAN" --last-seq 5)
echo "$GUARDIAN_OUT"
GUARDIAN_WITNESS=$(echo "$GUARDIAN_OUT" | tail -n 1)

echo -e "\n--- STEP 2: EXAMINER Auditing ---"
STATE=$(cat <<EOF
{
  "weights": [0.4, 0.3, 0.2, 0.1]
}
EOF
)

EXAMINER_OUT=$(echo "$STATE" | "$EXAMINER" --manifest "$DRIFT_MANIFEST")
echo "$EXAMINER_OUT"
EXAMINER_WITNESS=$(echo "$EXAMINER_OUT" | tail -n 1)

echo -e "\n--- STEP 3: PUBLISHER Codifying ---"
BUNDLE=$(cat <<EOF
{
  "ensemble_id": "$ENSEMBLE_ID",
  "sequence": $SEQ,
  "guardian_witness": "$GUARDIAN_WITNESS",
  "examiner_witness": "$EXAMINER_WITNESS",
  "state_commitment": "HASH-$(echo "$STATE" | md5sum | cut -d' ' -f1)"
}
EOF
)

echo "$BUNDLE" | "$PUBLISHER" --ensemble-id "$ENSEMBLE_ID" --sequence $SEQ

# Cleanup
rm "$DRIFT_MANIFEST"
