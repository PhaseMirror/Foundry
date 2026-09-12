#!/usr/bin/env bash
# Abort if any `sorry` token appears outside of lean/Core/Axioms.lean
set -euo pipefail
if grep -R --exclude-dir=target --exclude='Axioms.lean' -n "sorry" lean/Core; then
  echo '❌ Unexpected `sorry` tokens detected outside Axioms.lean'
  exit 1
else
  echo '✅ No stray `sorry` tokens.'
fi
