#!/usr/bin/env bash
# run_recursive_phase_mirror.sh — operational runner for the ADR-232
# Recursive Phase Mirror Loop.
#
# Default: single-shot analysis of the whole Prime/ tree with time-aware
# triage, emitting ADR-RML plan levers into Governance/adr/proposed/.
# Pass --watch N to run as a continuous sub-phase-mirror-agent daemon.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIME_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PRIME_ROOT"

echo "=== Recursive Phase Mirror Loop (ADR-232) runner ==="
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Root: $PRIME_ROOT"

# Pre-flight honesty boundary (same as the one-shot loop).
if [ -f scripts/honesty_audit.sh ]; then
  echo ""
  echo "-> Pre-flight: honesty audit (sorry boundary)"
  if ! bash scripts/honesty_audit.sh; then
    echo "!! honesty audit reported unmanifested sorrys; loop continues but flags leaks."
  fi
fi

echo ""
echo "-> Running recursive_phase_mirror.py"
python3 "$SCRIPT_DIR/recursive_phase_mirror.py" "$@"

INDEX="Governance/adr/proposed/ADR-Plan-Recursive-Phase-Mirror-Loop.md"
if [ -f "$INDEX" ]; then
  echo ""
  echo "-> Master index: $INDEX"
  head -n 40 "$INDEX"
fi

echo ""
echo "=== Recursive Phase Mirror run complete ==="
