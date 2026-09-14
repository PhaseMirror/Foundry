#!/usr/bin/env bash
# ADR: Sorry Check Script
# Delegates to Python for precise sorry tactic detection.
# Scans ADR/ directory for `sorry` tactic usage and fails if any
# are found outside the allowed quarantine file (ADR/Core/Axioms.lean).
#
# Enforces ADR-0010 (Axiom-Clean Kernel Boundary): zero untracked
# proof debt in the ADR/ directory.
#
# Usage: ./scripts/check_adr_sorry.sh
# CI:    python3 scripts/check_adr_sorry.py

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== ADR Sorry Check ==="
python3 "$SCRIPT_DIR/check_adr_sorry.py"