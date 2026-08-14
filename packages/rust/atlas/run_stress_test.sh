#!/bin/bash
set -e

# 1000-Step PIRTM Simulation & zk-STARKs Stress Test
# Generates a long-horizon PWEH ledger and verifies arithmetization scaling.

echo "--- [STRESS-TEST] Initializing 1000-step PIRTM Simulation ---"

# Compile tools
cargo build --manifest-path Substrates/rust/Cargo.toml --bin moc-zk-exporter --quiet

EXPORTER="Substrates/target/debug/moc-zk-exporter"
LEDGER_FILE="stress_ledger.json"

# Python script to generate 1000-step PWEH ledger
python3 -c '
import json
import hashlib
import random

steps = 1000
primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
prev_trace = "0" * 64
ledger = []

print(f"Generating {steps} steps...")

for i in range(1, steps + 1):
    p = random.choice(primes)
    amplitude = round(random.uniform(0.1, 0.2), 6)
    proof_hash = "LEAN_PROOF_HASH_108_CORE"
    
    # S(t) = Hash(S(t-1) || p || amp || M(t))
    payload = f"{prev_trace}{p}{amplitude}{proof_hash}".encode()
    current_trace = hashlib.sha256(payload).hexdigest()
    
    ledger.append({
        "step": i,
        "prime": p,
        "amplitude": amplitude,
        "proof_hash": proof_hash,
        "prev_trace": prev_trace,
        "current_trace": current_trace
    })
    prev_trace = current_trace

with open("stress_ledger.json", "w") as f:
    json.dump(ledger, f, indent=2)

print("Ledger generation complete.")
'

echo "--- [STRESS-TEST] Running zk-STARKs Exporter on 1000 steps ---"
time cat "$LEDGER_FILE" | "$EXPORTER" --ensemble-id "MQEM-STRESS-001" --target-dim 108 > stress_export_output.txt

# Verify the output
TERMINAL_COMMIT=$(grep "Terminal Commitment:" stress_export_output.txt | cut -d' ' -f6)
EXPECTED_COMMIT=$(python3 -c "import json; print(json.load(open(\"$LEDGER_FILE\"))[-1][\"current_trace\"])")

echo -e "\n--- Results ---"
echo "Steps processed: 1000"
echo "Terminal Commitment: $TERMINAL_COMMIT"
echo "Expected Commitment: $EXPECTED_COMMIT"

if [ "$TERMINAL_COMMIT" == "$EXPECTED_COMMIT" ]; then
    echo "[SUCCESS] Stress test PASSED. Path-integrity maintained over 1000 steps."
else
    echo "[FAILURE] Stress test FAILED. Commitment mismatch."
    exit 1
fi

# Cleanup
rm "$LEDGER_FILE" stress_export_output.txt
