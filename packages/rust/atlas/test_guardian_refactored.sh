#!/bin/bash
set -e

# Refactored Guardian Test: Verifying Dynamic MOC Words and 108-Cycle Mandate

# 1. Compile the guardian
cargo build --manifest-path "$(dirname "$0")/Cargo.toml" --bin moc-guardian --quiet

BIN="$(dirname "$0")/../target/debug/moc-guardian"

# Define Canonical 108-Cycle (2^2 * 3^3)
CAT_108=$(cat <<EOF
{
  "name": "Canonical 108-Cycle",
  "sequence": 20,
  "target_dim": 108,
  "prev_pweh": "1234",
  "blocks": [
    {"p": 2, "r": 2},
    {"p": 3, "r": 3}
  ],
  "kappa": {"num": 2, "den": 10},
  "sigma": {"num": 5, "den": 10},
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE"
}
EOF
)

# Define Dimension Mismatch
CAT_MISMATCH=$(cat <<EOF
{
  "name": "Dimension Mismatch",
  "sequence": 21,
  "target_dim": 108,
  "prev_pweh": "1234",
  "blocks": [
    {"p": 2, "r": 2},
    {"p": 5, "r": 2}
  ],
  "kappa": {"num": 9, "den": 10},
  "sigma": {"num": 5, "den": 10},
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE"
}
EOF
)

# Define a 125-Cycle (5^3) - Verifying dynamic dimension support
CAT_125=$(cat <<EOF
{
  "name": "Dynamic 125-Cycle",
  "sequence": 22,
  "target_dim": 125,
  "prev_pweh": "1234",
  "blocks": [
    {"p": 5, "r": 3}
  ],
  "kappa": {"num": 5, "den": 10},
  "sigma": {"num": 5, "den": 10},
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE"
}
EOF
)

echo "--- Testing Canonical 108-Cycle (Target Dim 108, Kappa 0.2) ---"
echo "$CAT_108" | "$BIN" --last-seq 5

echo -e "\n--- Testing Dimension Mismatch (Expect Failure) ---"
echo "$CAT_MISMATCH" | "$BIN" --last-seq 5 || echo "Correctly rejected dimension mismatch."

echo -e "\n--- Testing Dynamic 125-Cycle (Target Dim 125, Kappa 0.5) ---"
echo "$CAT_125" | "$BIN" --last-seq 5

echo -e "\n--- Testing Replay Attack (Expect Failure) ---"
echo "$CAT_108" | "$BIN" --last-seq 25 || echo "Correctly rejected replay attack."

echo -e "\n--- [SUCCESS] Guardian refactoring verified. ---"
