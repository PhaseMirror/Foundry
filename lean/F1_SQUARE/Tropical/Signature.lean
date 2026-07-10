/-
F1 square — tropical Hodge-index signatures (Thrust B), as kernel-checked `decide` theorems.

Companion §2.3 (the parallel-pencil finding and the fan-vs-fiber correction) and §2.1 (the
Babaee–Huh caution that the Hodge signature is NOT automatic). Pure Lean 4, no Mathlib, no `sorry`.

Scope/honesty: general negative-(semi)definiteness over variables needs a ring normalizer (absent
here), so we establish the *distinguishing* facts concretely — degeneracy, kernel vectors, and
explicit positive directions — which is exactly what the §2.3 correction and the Babaee–Huh caution
assert. The nondegenerate fiber form `(1,2)` itself is proved in `Template.lean`.
-/

namespace UOR.Bridge.F1Square.Tropical.Signature

/-- 2×2 determinant. -/
def det2 (a b c d : Int) : Int := a * d - b * c

/-- 3×3 determinant (cofactor expansion along the first row). -/
def det3 (a b c d e f g h i : Int) : Int :=
  a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)

/-! ## §2.3 — the parallel pencil

In the tropical (log) coordinate the scaling Frobenius `Fr_n : x ↦ x + log n` is an affine shift,
so the graph `Γ_n` and the diagonal `Δ` share recession direction `(1,1)`. The stable-intersection
multiplicity is `|det((1,1),(1,1))| = 0`, so `Δ · Γ_n = 0`: a parallel pencil, with the arithmetic
content relocated to the shift length `log p`. -/

theorem parallel_pencil : det2 1 1 1 1 = 0 := by decide

/-- `Δ · Γ_n = 0` (the stable-intersection multiplicity vanishes). -/
theorem delta_gamma_zero : (det2 1 1 1 1).natAbs = 0 := by decide

/-! ## §2.3 correction — the `(1, ρ−1)` shape is the fiber form, not the toric-boundary fan form

The fan-derived recession form `[[−2,1,0],[1,−1,1],[0,1,−2]]` (smooth toric-surface fan rule) is
DEGENERATE, hence is NOT the nondegenerate fiber/correspondence form (which carries the genuine
Hodge signature `(1,2)`, proved in `Template.lean`). We exhibit its degeneracy concretely. -/

/-- The fan recession form's quadratic value at `(x,y,z)`. -/
def fanForm (x y z : Int) : Int :=
  -2 * (x * x) - (y * y) - 2 * (z * z) + 2 * (x * y) + 2 * (y * z)

/-- The fan form is DEGENERATE: `det = 0`. So it is a different intersection-theoretic object than
    the nondegenerate fiber form — the §2.3 correction. -/
theorem fan_degenerate : det3 (-2) 1 0 1 (-1) 1 0 1 (-2) = 0 := by decide

/-- An explicit null (kernel) vector `(1,2,1)` of the fan form — witnessing the degeneracy. -/
theorem fan_kernel : fanForm 1 2 1 = 0 := by decide

/-- No positive direction on the standard basis (consistent with the `(0,2)` + kernel shape). -/
theorem fan_basis_nonpos :
    fanForm 1 0 0 ≤ 0 ∧ fanForm 0 1 0 ≤ 0 ∧ fanForm 0 0 1 ≤ 0 := by decide

/-! ## §2.1 — the Babaee–Huh caution: the Hodge signature is NOT automatic

Babaee–Huh (arXiv 1502.00299) exhibit a tropical surface whose intersection form does not have the
Hodge-index signature. We mechanize the phenomenon: a form with TWO independent positive directions
(so signature `(2,1)`, not `(1, ρ−1)`) — a concrete stand-in showing the desired sign pattern can
fail, so any concrete `𝕊` must verify the signature, never assume it. -/

/-- A stand-in indefinite form `diag(1,1,−1)` with two positive directions. -/
def bhForm (x y z : Int) : Int := x * x + y * y - z * z

/-- Two orthogonal positive directions `(1,0,0)`, `(0,1,0)` ⇒ ≥ 2 positive eigenvalues ⇒ signature
    is NOT `(1, ρ−1)`. The Hodge signature is not automatic. -/
theorem bh_two_positive_dirs : 0 < bhForm 1 0 0 ∧ 0 < bhForm 0 1 0 := by decide

end UOR.Bridge.F1Square.Tropical.Signature
