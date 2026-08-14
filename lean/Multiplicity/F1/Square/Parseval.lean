/-
F1 square — **the pre-Hilbert layer, brick 11** (`Parseval.lean`): **PARSEVAL AT THE FULL
INDICATOR BASIS** — the finite-complete case where Bessel saturates.

Brick 3 proved Bessel: `Σ_{k<K} ⟨f,eₖ⟩² ≤ ⟨f,f⟩_N` for any orthonormal family. This brick proves
that at the FULL indicator basis (`K = N`, the basis the discrete Sonine skeleton lives on) the
inequality is an EQUALITY and the projection is the identity:

- `fourierC_indic` — the Fourier coefficients against the indicators are the coordinates:
  `⟨f, δₖ⟩_N ≈ f(k)` for `k < N` (sifting).
- `proj_indic_eq` — the projection onto the full indicator basis is the identity on the
  truncation: `(P f)(i) ≈ f(i)` for `i < N`.
- **`parseval_indic`** — `Σ_{k<N} ⟨f,δₖ⟩² ≈ ⟨f,f⟩_N`: Bessel is sharp at the complete basis.

WHY (the Sonine route, step 3). The layer's remaining lack is "completeness past finite support
(Parseval and the infinite-dimensional projection, versus Bessel at fixed truncation)". This
brick delivers the FINITE-complete half exactly: at every truncation the indicator basis is
complete and Parseval holds on the nose — so the infinite-dimensional gap is precisely what a
completion (and only a completion) would close, and the Bessel/Parseval boundary is now
kernel-checked rather than informal.

HONEST SCOPE. Parseval for the full finite indicator basis at a fixed truncation; NOT an
infinite-dimensional Parseval, NOT completeness — those need the completion axis, which remains
open and is fenced as such. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.Projection
import Multiplicity.F1Square.Square.SonineProjection

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The Fourier coefficients against the indicators are the coordinates**:
    `⟨f, δₖ⟩_N ≈ f(k)` for `k < N` (commute the factors, then sift). -/
theorem fourierC_indic (f : Nat → Real) {k N : Nat} (hk : k < N) :
    Req (fourierC f indic N k) (f k) :=
  Req_trans (RsumN_congr N (fun i _ => Rmul_comm (f i) (indic k i)))
    (RsumN_indic_mul k f N hk)

/-- **The projection onto the full indicator basis is the identity on the truncation**:
    `(projF indic f N N)(i) ≈ f(i)` for `i < N` — the coefficient sifts against the
    indicator, and the coefficient is the coordinate. -/
theorem proj_indic_eq (f : Nat → Real) {i N : Nat} (hi : i < N) :
    Req (projF indic f N N i) (f i) := by
  refine Req_trans (RsumN_sift i (fun k => fourierC f indic N k) one N hi) ?_
  exact Req_trans (Rmul_one (fourierC f indic N i)) (fourierC_indic f hi)

/-- **PARSEVAL AT THE FULL INDICATOR BASIS**: `Σ_{k<N} ⟨f,δₖ⟩_N² ≈ ⟨f,f⟩_N` — the Bessel
    inequality (brick 3) is an EQUALITY when the orthonormal family is complete for the
    truncation. The finite-complete case of the completeness axis, kernel-checked; the
    infinite-dimensional statement is exactly what a completion would add. -/
theorem parseval_indic (f : Nat → Real) (N : Nat) :
    Req (RsumN (fun k => Rmul (fourierC f indic N k) (fourierC f indic N k)) N)
        (innerN f f N) :=
  RsumN_congr N (fun k hk =>
    Rmul_congr (fourierC_indic f hk) (fourierC_indic f hk))

/-- The Bessel–Parseval boundary, in one statement: the indicator family is orthonormal
    (brick 3's hypothesis holds), Bessel gives `≤`, and completeness of the basis upgrades it
    to `≈` — at every finite truncation. -/
theorem bessel_saturates_at_indic (f : Nat → Real) (N : Nat) :
    Rle (RsumN (fun k => Rmul (fourierC f indic N k) (fourierC f indic N k)) N)
        (innerN f f N)
    ∧ Req (RsumN (fun k => Rmul (fourierC f indic N k) (fourierC f indic N k)) N)
        (innerN f f N) :=
  ⟨bessel (indic_ortho (Nat.le_refl N)) f, parseval_indic f N⟩

end Multiplicity.UOR.Bridge.F1Square.Square
