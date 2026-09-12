#!/bin/bash
# Phase 4 End-to-End Governed Loop Simulation
# Exercises: CLI → Sigma Kernel → Archivum ledger (pass + trap paths)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIME_ROOT="$(dirname "$SCRIPT_DIR")"
CLI_DIR="$PRIME_ROOT/crates/commander-cli"
LEDGER="$CLI_DIR/state/archivum/witnesses.jsonl"
PASS_TX="/tmp/sigma_pass_tx.json"
FAIL_TX="/tmp/sigma_fail_tx.json"

echo "=== Phase 4 End-to-End Governed Loop Simulation ==="
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Ensure ledger exists
if [ ! -f "$LEDGER" ]; then
  echo "ERROR: Ledger missing at $LEDGER"
  exit 1
fi

PRE_LINES=$(wc -l < "$LEDGER")
echo "Current ledger lines: $PRE_LINES"

# Clean previous temp files
rm -f "$PASS_TX" "$FAIL_TX"

# ---------------------------------------------------------------- #
# 1. PASS path: valid transition within Lean-verified thresholds
# ---------------------------------------------------------------- #
cat > "$PASS_TX" <<'EOF'
{
  "id": "e2e-simulation-pass-001",
  "r_sc": 47.06998778,
  "l_eff": 0.15
}
EOF

echo ""
echo "→ Running PASS transition..."
cd "$CLI_DIR"
cargo run --offline -- sigma evaluate --input "$PASS_TX" 2>&1 | tail -5

# ---------------------------------------------------------------- #
# 2. TRAP path: L_eff violation (dissonance trap)
# ---------------------------------------------------------------- #
cat > "$FAIL_TX" <<'EOF'
{
  "id": "e2e-simulation-trap-001",
  "r_sc": 47.06998778,
  "l_eff": 1.5
}
EOF

echo ""
echo "→ Running TRAP transition..."
set +e
cargo run --offline -- sigma evaluate --input "$FAIL_TX" 2>&1 | tail -5
FAIL_EXIT=$?
set -e

if [ "$FAIL_EXIT" -ne 0 ]; then
  echo "✓ Expected dissonance trap caught (exit $FAIL_EXIT)"
else
  echo "✗ Unexpected success for violating transition"
  exit 1
fi

# ---------------------------------------------------------------- #
# 3. Verify ledger append-only + PWEH hashes
# ---------------------------------------------------------------- #
echo ""
echo "→ Verifying Archivum ledger..."
POST_LINES=$(wc -l < "$LEDGER")
echo "Post-ledger lines: $POST_LINES"

if [ "$POST_LINES" -le "$PRE_LINES" ]; then
  echo "ERROR: Ledger did not grow!"
  exit 1
fi

# Check for both ratified block and conflict log with PWEH hash
HAS_RATIFIED=$(grep -c '"ratified":true' "$LEDGER" || true)
HAS_CONFLICT=$(grep -c '"breach_type":"LipschitzContraction"' "$LEDGER" || true)
HAS_PWEH=$(grep -c '"pweh_hash"' "$LEDGER" || true)

echo "Ratified blocks: $HAS_RATIFIED"
echo "Conflict logs: $HAS_CONFLICT"
echo "PWEH hashes: $HAS_PWEH"

if [ "$HAS_RATIFIED" -lt 1 ] || [ "$HAS_CONFLICT" -lt 1 ] || [ "$HAS_PWEH" -lt 1 ]; then
  echo "ERROR: Ledger missing expected entries"
  exit 1
fi

echo ""
echo "=== Phase 4 Closure: Governed loop verified ==="
echo "  Pass path:      ✅ ratified block appended"
echo "  Trap path:      ✅ conflict log + PWEH hash appended"
echo "  Ledger growth:  ✅ $PRE_LINES → $POST_LINES lines"
echo "  PWEH hashes:    ✅ $HAS_PWEH entries"
