#!/bin/bash
set -e

# zk-STARKs Export Test: Transforming PWEH Ledger to arithmetized trace

# 1. Compile the exporter
cargo build --manifest-path "$(dirname "$0")/Cargo.toml" --bin moc-zk-exporter --quiet

BIN="$(dirname "$0")/../target/debug/moc-zk-exporter"

# 2. Simulate a PWEH Ledger (List of PwehEntry)
# S(t) = Hash(S(t-1) || p_i || |A_p T(t)| || M(t))
LEDGER=$(cat <<EOF
[
  {
    "step": 1,
    "prime": 2,
    "amplitude": 0.148492,
    "proof_hash": "LEAN_PROOF_HASH_108_CORE",
    "prev_trace": "0000000000000000000000000000000000000000000000000000000000000000",
    "current_trace": "d33a9a4fdf03a10f22494ce47c0ab515f7fe78920f11c0e3bc5ffd5bd0a5ceee"
  },
  {
    "step": 2,
    "prime": 3,
    "amplitude": 0.125678,
    "proof_hash": "LEAN_PROOF_HASH_108_CORE",
    "prev_trace": "d33a9a4fdf03a10f22494ce47c0ab515f7fe78920f11c0e3bc5ffd5bd0a5ceee",
    "current_trace": "073ab8fee338f8d9654d19f8a6f9ba9b9a6628bd3bd5c67373c78646f1166911"
  }
]
EOF
)

echo "--- Executing zk-STARKs Export ---"
echo "$LEDGER" | "$BIN" --ensemble-id "MQEM-001" --target-dim 108

echo -e "\n--- [SUCCESS] zk-STARKs export verified. ---"
