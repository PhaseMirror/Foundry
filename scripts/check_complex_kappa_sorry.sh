#!/usr/bin/env bash
set -euo pipefail

# Zero-sorry enforcement script for ComplexKappa Lean modules.
# Fails the build if any `sorry` or `admit` is found in src/ComplexKappa/.
# Also checks for `native_decide` used as a proof bypass.

echo "=== ComplexKappa Zero-Sorry Check ==="

SORRY_COUNT=$(grep -rn "sorry\|admit" src/ComplexKappa/ 2>/dev/null | wc -l || echo "0")
NATIVE_DECIDE_COUNT=$(grep -rn "native_decide" src/ComplexKappa/ 2>/dev/null | wc -l || echo "0")

echo "Found ${SORRY_COUNT} sorry/admit occurrences"
echo "Found ${NATIVE_DECIDE_COUNT} native_decide occurrences"

if [ "${SORRY_COUNT}" -gt 0 ]; then
  echo "::error::Zero-sorry violation: found sorry or admit in ComplexKappa modules"
  grep -rn "sorry\|admit" src/ComplexKappa/
  exit 1
fi

if [ "${NATIVE_DECIDE_COUNT}" -gt 0 ]; then
  echo "::warning::Found native_decide — verify these are not bypassing unproven propositions"
fi

echo "✓ Zero-sorry check passed"
exit 0
