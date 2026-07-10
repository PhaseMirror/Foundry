#!/bin/bash
set -e

# Action 2 Test: NF(Q,p) reduction and PWEH Trace Ledger

# 1. Compile the guardian
cargo build --manifest-path "$(dirname "$0")/Cargo.toml" --bin moc-guardian --quiet

BIN="$(dirname "$0")/../target/debug/moc-guardian"

echo "--- STEP 1: NF(Q,p) Reduction Test ---"
# Proposal with duplicate primes (2^1, 3^2, 2^1, 3^1) -> should merge to (2^2, 3^3) = 108
CAT_NF=$(cat <<EOF
{
  "name": "NF Reduction Test",
  "sequence": 30,
  "target_dim": 108,
  "blocks": [
    {"p": 2, "r": 1},
    {"p": 3, "r": 2},
    {"p": 2, "r": 1},
    {"p": 3, "r": 1}
  ],
  "kappa": 0.2,
  "sigma": 0.5,
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE",
  "prev_pweh": "0000000000000000000000000000000000000000000000000000000000000000"
}
EOF
)

NF_OUT=$(echo "$CAT_NF" | "$BIN" --last-seq 5)
echo "$NF_OUT"
if [[ "$NF_OUT" == *"NF(Q,p) complete: 4 -> 2 blocks"* ]]; then
  echo "[PASS] NF(Q,p) correctly merged redundant blocks."
else
  echo "[FAIL] NF(Q,p) reduction failed."
  exit 1
fi

echo "--- STEP 2: PWEH Trace Dependency Test ---"
PWEH_1=$(echo "$NF_OUT" | grep "PWEH Trace:" | cut -d' ' -f4)

# Identical proposal but different prev_pweh -> should yield different trace
CAT_PWEH_2=$(echo "$CAT_NF" | sed "s/0000000000000000000000000000000000000000000000000000000000000000/1111111111111111111111111111111111111111111111111111111111111111/")
PWEH_2=$(echo "$CAT_PWEH_2" | "$BIN" --last-seq 5 | grep "PWEH Trace:" | cut -d' ' -f4)

echo "Trace 1: $PWEH_1"
echo "Trace 2: $PWEH_2"

if [ "$PWEH_1" != "$PWEH_2" ]; then
  echo "[PASS] PWEH correctly demonstrates path dependency."
else
  echo "[FAIL] PWEH trace collision detected."
  exit 1
fi

echo -e "\n--- STEP 3: 10 Random PIRTM Steps Simulation ---"
PREV_PWEH="0000000000000000000000000000000000000000000000000000000000000000"
for i in {1..10}
do
  SEQ=$((40 + i))
  # Random kappa between 0.1 and 1.5
  KAPPA=$(python3 -c "import random; print(round(random.uniform(0.1, 1.5), 2))")
  
  echo -n "Step $i: kappa=$KAPPA ... "
  
  PROP=$(cat <<EOF
{
  "name": "Random Step $i",
  "sequence": $SEQ,
  "target_dim": 108,
  "blocks": [
    {"p": 2, "r": 2},
    {"p": 3, "r": 3}
  ],
  "kappa": $KAPPA,
  "sigma": 0.5,
  "signature": "AUTHORIZED_GUARDIAN_SIG",
  "proof_hash": "LEAN_PROOF_HASH_108_CORE",
  "prev_pweh": "$PREV_PWEH"
}
EOF
)

  OUT=$(echo "$PROP" | "$BIN" --last-seq $((SEQ - 1)) 2>&1) || true
  
  if [[ "$OUT" == *"PASS: Contraction verified"* ]]; then
    echo "PASS"
    PREV_PWEH=$(echo "$OUT" | grep "PWEH Trace:" | cut -d' ' -f4)
  elif [[ "$OUT" == *"REJECT: Contraction bound violated"* ]]; then
    echo "REJECT (Lawful Halt)"
  else
    echo "ERROR"
    echo "$OUT"
    exit 1
  fi
done

echo -e "\n--- [SUCCESS] Action 2 Verified. ---"
