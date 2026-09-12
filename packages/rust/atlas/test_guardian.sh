#!/bin/bash
set -e

# Compile the guardian
cargo build --manifest-path "$(dirname "$0")/Cargo.toml" --bin moc-guardian --quiet

# Define binary path
BIN="$(dirname "$0")/../target/debug/moc-guardian"

# Define valid proposal
CAT_VALID=$(cat <<EOF
{
  "name": "Valid Proposal",
  "sequence": 10,
  "target_dim": 108,
  "prev_pweh": "1234",
  "blocks": [{"p":2,"r":2},{"p":3,"r":3}],
  "kappa": {"num": 9, "den": 10},
  "sigma": {"num": 5, "den": 10},
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE"
}
EOF
)

# Define invalid proposal (Invalid Signature)
CAT_BAD_SIG=$(cat <<EOF
{
  "name": "Bad Signature",
  "sequence": 11,
  "target_dim": 108,
  "prev_pweh": "1234",
  "blocks": [{"p":2,"r":2},{"p":3,"r":3}],
  "kappa": {"num": 9, "den": 10},
  "sigma": {"num": 5, "den": 10},
  "signature": "FORGED_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE"
}
EOF
)

# Define invalid proposal (Contraction Violation)
CAT_BAD_CONTRACT=$(cat <<EOF
{
  "name": "Contraction Violation",
  "sequence": 12,
  "target_dim": 108,
  "prev_pweh": "1234",
  "blocks": [{"p":2,"r":2},{"p":3,"r":3}],
  "kappa": {"num": 25, "den": 10},
  "sigma": {"num": 5, "den": 10},
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE"
}
EOF
)

# Define invalid proposal (Proof Hash Mismatch)
CAT_BAD_HASH=$(cat <<EOF
{
  "name": "Hash Mismatch",
  "sequence": 13,
  "target_dim": 108,
  "prev_pweh": "1234",
  "blocks": [{"p":2,"r":2},{"p":3,"r":3}],
  "kappa": {"num": 9, "den": 10},
  "sigma": {"num": 5, "den": 10},
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "WRONG_HASH"
}
EOF
)

echo "--- Testing Valid Proposal ---"
echo "$CAT_VALID" | "$BIN" --last-seq 5
echo -e "\n--- Testing Bad Signature (Expect Failure) ---"
echo "$CAT_BAD_SIG" | "$BIN" --last-seq 5 || echo "Correctly rejected bad signature."

echo -e "\n--- Testing Contraction Violation (Expect Failure) ---"
echo "$CAT_BAD_CONTRACT" | "$BIN" --last-seq 5 || echo "Correctly rejected contraction violation."

echo -e "\n--- Testing Proof Hash Mismatch (Expect Failure) ---"
echo "$CAT_BAD_HASH" | "$BIN" --last-seq 5 || echo "Correctly rejected proof hash mismatch."

echo -e "\n--- Testing Replay Attack (Expect Failure) ---"
echo "$CAT_VALID" | "$BIN" --last-seq 15 || echo "Correctly rejected replay attack."
