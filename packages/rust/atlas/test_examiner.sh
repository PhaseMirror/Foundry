#!/bin/bash
set -e

# Compile the examiner
cargo build --manifest-path "$(dirname "$0")/Cargo.toml" --bin moc-examiner --quiet

BIN="$(dirname "$0")/../target/debug/moc-examiner"
MANIFEST="$(dirname "$0")/drift_manifest.json"

# Create a sample Drift Manifest (MD-005)
cat <<EOF > "$MANIFEST"
{
  "ensemble_id": "MQEM-001",
  "baseline_weights": [400000, 300000, 200000, 100000],
  "delta_threshold": 100,
  "timestamp": "2026-06-15T12:00:00Z"
}
EOF

# Define valid state (No drift)
STATE_VALID=$(cat <<EOF
{
  "weights": [400000, 300000, 200000, 100000]
}
EOF
)

# Define valid state (Small drift within threshold)
STATE_SMALL_DRIFT=$(cat <<EOF
{
  "weights": [400010, 299990, 200000, 100000]
}
EOF
)

# Define invalid state (Large drift)
STATE_LARGE_DRIFT=$(cat <<EOF
{
  "weights": [500000, 200000, 200000, 100000]
}
EOF
)

# Define invalid state (Convexity violation)
STATE_NON_CONVEX=$(cat <<EOF
{
  "weights": [500000, 500000, 500000, 500000]
}
EOF
)

echo "--- Testing Valid State (No Drift) ---"
echo "$STATE_VALID" | "$BIN" --manifest "$MANIFEST"

echo -e "\n--- Testing Small Drift (Within Threshold) ---"
echo "$STATE_SMALL_DRIFT" | "$BIN" --manifest "$MANIFEST"

echo -e "\n--- Testing Large Drift (Expect Failure) ---"
echo "$STATE_LARGE_DRIFT" | "$BIN" --manifest "$MANIFEST" || echo "Correctly rejected large drift."

echo -e "\n--- Testing Convexity Violation (Expect Failure) ---"
echo "$STATE_NON_CONVEX" | "$BIN" --manifest "$MANIFEST" || echo "Correctly rejected convexity violation."

# Cleanup
rm "$MANIFEST"
