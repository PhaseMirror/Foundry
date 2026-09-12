#!/usr/bin/env bash
# run_phase_mirror_loop.sh — operational runner for the Phase Mirror dissonance loop.
#
# Ties the Python engine to the existing governance tooling and is CI/cron ready.
# Default: analyze docs vs Lean, rank tensions, emit ADR plans into docs/adr/.
# Pass --scaffold-proofs to also manifest missing-theorem gaps as Lean stubs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIME_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PRIME_ROOT"

echo "=== Phase Mirror Operational Loop runner ==="
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Root: $PRIME_ROOT"

# 0. Pre-flight: the UAC-ALP honesty boundary must still hold.
if [ -f scripts/honesty_audit.sh ]; then
  echo ""
  echo "-> Pre-flight: honesty audit (sorry boundary)"
  if ! bash scripts/honesty_audit.sh; then
    echo "!! honesty audit reported unmanifested sorrys; loop continues but flags leaks."
  fi
fi

# 1. Run the loop.
echo ""
echo "-> Running phase_mirror_loop.py"
python3 "$SCRIPT_DIR/phase_mirror_loop.py" "$@"

# 2. Surface the master index.
INDEX="docs/adr/ADR-Plan-Phase-Mirror-Dissonance-Loop.md"
if [ -f "$INDEX" ]; then
  echo ""
  echo "-> Master index: $INDEX"
  head -n 40 "$INDEX"
fi

echo ""
echo "=== Phase Mirror loop run complete ==="
