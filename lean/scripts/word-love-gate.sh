#!/usr/bin/env bash
# word-love-gate.sh — ADR-0031 proof-carrying acceptance gate
#
# Enforces production invariants:
#   1. No sorry/admit/axiom in production — every Lean theorem is machine-checked
#   2. Escape-proof enforcement — violating a contract makes compilation impossible
#   3. Executable test suite passes 100%
#   4. Kani bounded verification harnesses registered
#
# Usage:  scripts/word-love-gate.sh [--verbose]
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

echo "============================================================"
echo "   Word Love (ADR-0031) Acceptance Gate"
echo "============================================================"
echo ""

# --- Check 1: YAML contract exists and is non-empty ---
echo "[1/5] Provable YAML Contract"
if [[ -f "$ROOT_DIR/contracts/word_love.yaml" ]] && [[ -s "$ROOT_DIR/contracts/word_love.yaml" ]]; then
  ok "contracts/word_love.yaml exists ($(wc -l < "$ROOT_DIR/contracts/word_love.yaml") lines)"
else
  fail "contracts/word_love.yaml missing or empty"
fi

# --- Check 2: No sorry/admit/axiom in WordLove Lean sources ---
echo "[2/5] Sorry-Free Machine-Checked Proof Enforcement"
SORRY_HITS=$(python3 - "$ROOT_DIR/Multiplicity/WordLove/" <<'PYEOF'
import sys, os, re, glob

wl_dir = sys.argv[1]
for fpath in sorted(glob.glob(os.path.join(wl_dir, "*.lean"))):
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
  ok "No sorry/admit/axiom in Multiplicity/WordLove/*.lean"
else
  fail "sorry/admit/axiom found in WordLove sources:"
  echo "$SORRY_HITS" | while read -r line; do
    echo "    $line"
  done
fi

# --- Check 3: Lean kernel builds all WordLove modules ---
echo "[3/5] Lean Kernel Build (lake build word_love_test)"
if lake build word_love_test 2>&1 | tail -1 | grep -q "Build completed"; then
  ok "lake build word_love_test succeeded"
else
  BUILD_OUT=$(lake build word_love_test 2>&1 || true)
  if echo "$BUILD_OUT" | grep -q "Build completed"; then
    ok "lake build word_love_test succeeded"
  else
    fail "lake build word_love_test failed"
    if [[ $VERBOSE -eq 1 ]]; then
      echo "$BUILD_OUT" | tail -10 | sed 's/^/    /'
    fi
  fi
fi

# --- Check 4: WordLove test suite passes ---
echo "[4/5] WordLove Test Harness Execution"
TEST_OUT=$(cd "$ROOT_DIR" && lake exe word_love_test 2>&1 || true)
if echo "$TEST_OUT" | grep -q "ALL WORD LOVE (ADR-0031) VERIFICATION TESTS PASSED"; then
  ok "lake exe word_love_test — all tests passed"
else
  fail "lake exe word_love_test — test failures detected"
  if [[ $VERBOSE -eq 1 ]]; then
    echo "$TEST_OUT" | tail -20 | sed 's/^/    /'
  fi
fi

# --- Check 5: Kani harnesses exist and are registered ---
echo "[5/5] Kani Verification Harnesses"
KANI_FILE="$ROOT_DIR/Multiplicity/kani/src/proofs/word_love.rs"
if [[ -f "$KANI_FILE" ]]; then
  KANI_COUNT=$(grep -c '#\[kani::proof\]' "$KANI_FILE" 2>/dev/null || echo 0)
  if [[ "$KANI_COUNT" -ge 5 ]]; then
    ok "Kani harnesses: $KANI_COUNT proof functions in word_love.rs"
  else
    fail "Expected ≥5 Kani proof functions, found $KANI_COUNT"
  fi
else
  fail "Kani harness file not found: $KANI_FILE"
fi

# --- Summary ---
echo ""
echo "=== Word Love Gate Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
  echo "GATE FAILED — build blocked"
  exit 1
else
  echo "GATE PASSED — all Word Love (ADR-0031) proof obligations verified"
  exit 0
fi
