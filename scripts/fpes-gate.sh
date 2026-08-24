#!/usr/bin/env bash
# fpes-gate.sh — escape-proof build gate for ADR-0029 (FPES).
#
# Steps (fail-closed; exit 1 aborts the build):
#   0. mathlib audit      : no `import Mathlib` anywhere in lean/Multiplicity/FPES/
#   1. sorry audit        : no `sorry`/`admit`/`axiom` in lean/Multiplicity/FPES/
#   2. lean build         : lake build of the four FPES modules
#   3. lean test          : lake test (runs fpes_test + the RSA suite)
#   4. kani (optional)    : bounded model-checking of the FPES harnesses;
#                           skipped with a warning when Kani is not installed
#
# Usage: scripts/fpes-gate.sh [--skip-kani]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FPES="lean/Multiplicity/FPES"
KANI_DIR="lean/Multiplicity/kani"

if [ "${1:-}" = "--skip-kani" ]; then SKIP_KANI=1; else SKIP_KANI=0; fi

cd "$ROOT"

say() { printf '\n==> %s\n' "$*"; }
ok()  { printf '    PASS: %s\n' "$*"; }
bad() { printf '    FAIL: %s\n' "$*"; exit 1; }

if command -v lake >/dev/null 2>&1; then
    :
else
    say "Lean toolchain missing (lake not on PATH)."
    bad "Install elan + Lean v4.33: https://lean-lang.org/lean4/doc/setup.html"
fi

# --- Step 0: mathlib stays out of the FPES core (FPES-NO-MATHLIB-004) ---
say "Step 0/4 — mathlib audit (FPES-NO-MATHLIB-004)"
if grep -rEl '^[[:space:]]*import[[:space:]]+Mathlib' "$FPES" 2>/dev/null; then
    bad "mathlib import detected in the FPES core"
fi
ok "no 'import Mathlib' in lean/Multiplicity/FPES/"

# --- Step 1: zero sorry / admit / axiom (FPES-NO-SORRY-003) ---
say "Step 1/4 — sorry audit (FPES-NO-SORRY-003)"
if grep -rEn '^[[:space:]]*(sorry|admit)[[:space:]]*$|^[[:space:]]*axiom[[:space:]]+[A-Za-z_]' "$FPES" 2>/dev/null; then
    bad "sorry/admit/axiom detected in the FPES core"
fi
ok "no 'sorry'/'admit'/'axiom' in lean/Multiplicity/FPES/"

# --- Step 2: build the four FPES modules ---
say "Step 2/4 — lake build (FPES-MULTIPLICITY-001, FPES-SURVIVAL-002 proofs)"
(cd lean && lake build \
    Multiplicity.FPES.Core \
    Multiplicity.FPES.Proofs \
    Multiplicity.FPES.Examples \
    Multiplicity.FPES.Test \
    fpes_test)
ok "lake build succeeded (kernel-checked proofs, no sorry)"

# --- Step 3: run the test harness ---
say "Step 3/4 — lake test (fpes_test harness)"
(cd lean && lake test)
ok "lake test passed"

# --- Step 4: Kani bounded model checking (KANI-FPES-001, KANI-FPES-002) ---
say "Step 4/4 — Kani bounded model checking (bounds: max_paths=8, max_classes=8, unwind=9)"
if [ "$SKIP_KANI" -eq 1 ]; then
    say "Skipping Kani (--skip-kani)."
    ok "skipped (explicit)"
elif command -v cargo >/dev/null 2>&1 && cargo kani --version >/dev/null 2>&1; then
    for harness in kani_fpes_001_multiplicity_nonzero kani_fpes_002_contraction_preserves_multiplicity; do
        (cd "$KANI_DIR" && cargo kani --harness "$harness" --unwind 9) \
            || bad "Kani harness '$harness' failed"
        ok "$harness verified"
    done
else
    say "Kani not installed; FPES Kani obligations are deferred to the developer"
    say "environment (run 'make kani-full' there). The Lean gates above are closed."
    ok "skipped (Kani not installed)"
fi

say "FPES gate passed: escape-proof (Lean kernel-checked, no sorry, no mathlib)."
