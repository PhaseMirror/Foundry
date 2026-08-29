#!/usr/bin/env bash
# ADR-0027 verification ladder.
#
# Tier 1 (mathematical): the Lean certificate core — built with zero `sorry`,
# with the axiom footprint limited to the documented domain axioms.
# Tier 2 (operational): the Rust certificate-runtime — 24 unit tests plus
# bounded model checking (Kani) of the FFI validation surface, the n=2
# arithmetic identities, and the end-to-end runtime soundness property.
#
# Notes on the machine environment:
#   - requires `lake` (Lean 4.33) and a working `cargo kani` (Kani 0.67)
#   - harnesses are verified one-per-invocation: running every harness in a
#     single `cargo kani --tests` batch trips a CBMC `memcpy` missing-crate
#     artifact in the current dev toolchain, whereas isolated runs are clean.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEAN_DIR="$ROOT/lean"
RUST_DIR="$ROOT/rust"

cd "$ROOT"

# ---------------------------------------------------------------------------
# Tier 1 — Lean certificate core
# ---------------------------------------------------------------------------
echo "== Tier 1: Lean kernel proof =="
(cd "$LEAN_DIR" && lake build)

echo "-- asserting no 'sorry' anywhere in the Lean sources --"
if grep -RInE 'sorry|sorryAx' --include='*.lean' "$LEAN_DIR"; then
    echo "ERROR: 'sorry' found in Lean sources" >&2
    exit 1
fi
echo "no 'sorry' found"

echo "-- asserting the axiom footprint of the exported theorems --"
AX_PROBE="$(mktemp)"
trap 'rm -f "$AX_PROBE" "$AX_PROBE.out"' EXIT
cat > "$AX_PROBE" <<'EOF'
import CertificateCore
#print axioms CertificateCore.FFI.certificateCheck_pure_sound
#print axioms CertificateCore.SpectralContraction.spectral_contraction_bound
EOF

(cd "$LEAN_DIR" && lake env lean "$AX_PROBE") > "$AX_PROBE.out" 2>&1

# Axioms introduced deliberately by this project (see ADR-0027 §2.3). The
# kernel's own axioms (propext, Choice, Quot.sound) are always allowed.
ALLOWED='
propext
Classical.choice
Quot.sound
CertificateCore.FFI.le_add_self_nonneg
CertificateCore.GraphLaplacian.laplacian_mean_zero
CertificateCore.GraphLaplacian.spectral_gap
CertificateCore.GraphLaplacian.spectral_radius
CertificateCore.Mat.mulVec_sub
CertificateCore.SpectralContraction.laplacian_contraction_bound
CertificateCore.Vec.meanZero_eq_of_mean_zero
CertificateCore.Vec.meanZero_smul
CertificateCore.Vec.meanZero_vsub
'

unknown=0
while read -r ax; do
    [ -z "$ax" ] && continue
    if ! grep -qxF "$ax" <<< "$ALLOWED"; then
        echo "ERROR: undocumented axiom in footprint: $ax" >&2
        unknown=1
    fi
done < <(grep -oE '\[[^]]*\]' "$AX_PROBE.out" | grep -oE '[A-Za-z][A-Za-z0-9.]+' || true)

if [ "$unknown" -ne 0 ]; then
    echo "full axiom print:" >&2
    cat "$AX_PROBE.out" >&2
    exit 1
fi
echo "axiom footprint is clean"

# ---------------------------------------------------------------------------
# Tier 2 — Rust certificate-runtime
# ---------------------------------------------------------------------------
echo "== Tier 2: Rust unit tests =="
(cd "$RUST_DIR" && cargo test --workspace)

echo "== Tier 2: Kani bounded model checking =="
HARNESSES=(
    verify_ffi_rejects_zero_dimension
    verify_ffi_rejects_nonpositive_spectrum
    verify_ffi_rejects_out_of_range_alpha
    verify_ffi_returns_legal_codes
    verify_ffi_valid_input_never_errors
    verify_construction_accepts_admissible_alpha
    verify_graph_from_weights_sound
    verify_heat_step_matches_formula
    verify_laplacian_structural_invariants
    verify_mean_zero_algebra
    verify_contraction_bound
    verify_certified_step_never_commits_uncertified
)
(cd "$RUST_DIR/certificate-runtime")
for h in "${HARNESSES[@]}"; do
    echo "-- kani: $h --"
    (cd "$RUST_DIR/certificate-runtime" && cargo kani --tests --harness "$h")
done

echo "verification OK"