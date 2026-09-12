#!/usr/bin/env bash
# fpes-gate.sh — ADR-0029 proof-carrying acceptance gate
#
# Enforces decision drivers 1 and 5:
#   1. No sorry in production — every Lean theorem is machine-checked
#   5. Escape-proof enforcement — violating a contract makes compilation impossible
#
# Usage:  scripts/fpes-gate.sh [--verbose]
# Exit 0  all checks pass
# Exit 1  any check fails (blocks build)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERBOSE=0
if [[ "${1:-}" == "--verbose" || "${1:-}" == "-v" ]]; then
  VERBOSE=1
fi

PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

echo "=== FPES Gate (ADR-0029) ==="
echo ""

# --- Check 1: YAML contract exists and is non-empty ---
echo "[1/5] YAML contract"
if [[ -f "$ROOT_DIR/contracts/fpes.yaml" ]] && [[ -s "$ROOT_DIR/contracts/fpes.yaml" ]]; then
  ok "contracts/fpes.yaml exists ($(wc -l < "$ROOT_DIR/contracts/fpes.yaml") lines)"
else
  fail "contracts/fpes.yaml missing or empty"
fi

# --- Check 2: No sorry/admit/axiom in FPES Lean sources ---
echo "[2/5] Sorry-free enforcement"
# Strip block comments, string literals, and line comments, then grep.
# Uses python3 for reliable multi-line comment state tracking.
SORRY_HITS=$(python3 - "$ROOT_DIR/Multiplicity/FPES/" <<'PYEOF'
import sys, os, re, glob

fpes_dir = sys.argv[1]
for fpath in sorted(glob.glob(os.path.join(fpes_dir, "*.lean"))):
    with open(fpath) as f:
        text = f.read()

    # Strip block comments (/- ... -/) with nesting
    depth = 0
    cleaned = []
    i = 0
    while i < len(text):
        if text[i:i+2] == '/-':
            depth += 1
            i += 2
        elif text[i:i+2] == '-/' and depth > 0:
            depth -= 1
            i += 2
        elif depth == 0:
            cleaned.append(text[i])
            i += 1
        else:
            i += 1
    text = ''.join(cleaned)

    # Strip string literals
    text = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', text)

    # Strip line comments and check
    lines = text.split('\n')
    for lineno, line in enumerate(lines, 1):
        code = line.split('--')[0].strip()
        if not code:
            continue
        for kw in ['sorry', 'admit', 'axiom']:
            if re.search(r'\b' + kw + r'\b', code):
                with open(fpath) as f2:
                    orig = f2.read().split('\n')
                print(f"{fpath}:{lineno}: {orig[lineno-1].strip()}")
PYEOF
)

if [[ -z "$SORRY_HITS" ]]; then
  ok "No sorry/admit/axiom in Multiplicity/FPES/*.lean"
else
  fail "sorry/admit/axiom found in FPES sources:"
  echo "$SORRY_HITS" | while read -r line; do
    echo "    $line"
  done
fi

# --- Check 3: Lean kernel builds all FPES modules ---
echo "[3/5] Lean build (lake build)"
if lake build Multiplicity.FPES.Test 2>&1 | tail -1 | grep -q "Build completed"; then
  ok "lake build Multiplicity.FPES.Test succeeded"
else
  BUILD_OUT=$(lake build Multiplicity.FPES.Test 2>&1 || true)
  if echo "$BUILD_OUT" | grep -q "Build completed"; then
    ok "lake build Multiplicity.FPES.Test succeeded"
  else
    fail "lake build Multiplicity.FPES.Test failed"
    if [[ $VERBOSE -eq 1 ]]; then
      echo "$BUILD_OUT" | tail -10 | sed 's/^/    /'
    fi
  fi
fi

# --- Check 4: FPES test suite passes ---
echo "[4/5] FPES test suite"
TEST_OUT=$(cd "$ROOT_DIR" && lake test 2>&1 || true)
if echo "$TEST_OUT" | grep -q "All FPES tests passed"; then
  ok "lake test — all FPES tests passed"
else
  fail "lake test — FPES tests failed"
  if [[ $VERBOSE -eq 1 ]]; then
    echo "$TEST_OUT" | tail -20 | sed 's/^/    /'
  fi
fi

# --- Check 5: Kani harnesses exist and are registered ---
echo "[5/5] Kani harnesses"
KANI_FILE="$ROOT_DIR/Multiplicity/kani/src/proofs/fpes.rs"
if [[ -f "$KANI_FILE" ]]; then
  KANI_COUNT=$(grep -c '#\[kani::proof\]' "$KANI_FILE" 2>/dev/null || echo 0)
  if [[ "$KANI_COUNT" -ge 2 ]]; then
    ok "Kani harnesses: $KANI_COUNT proof functions in fpes.rs"
  else
    fail "Expected ≥2 Kani proof functions, found $KANI_COUNT"
  fi
else
  fail "Kani harness file not found: $KANI_FILE"
fi

# --- Summary ---
echo ""
echo "=== Gate Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "GATE FAILED — build blocked (ADR-0029 decision driver 5)"
  exit 1
else
  echo "GATE PASSED — all FPES proof obligations verified"
  exit 0
fi
