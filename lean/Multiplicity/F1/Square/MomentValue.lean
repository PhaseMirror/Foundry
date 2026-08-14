/-
F1 square — **the pre-Hilbert layer, brick 23** (`MomentValue.lean`): **THE MOMENT MAP TAKES
CERTIFIED NONZERO VALUES** — the transform-side data is not degenerate.

Two exact evaluations of the integer-moment skeleton (brick 10), the first nonzero values of
the layer's transform-side data:

- `mellinMoment oneTest 0 ≈ 1` — the pairing of the constant test with itself is the constant
  integral (`riemannIntegral_const_gen` through the global congruence `1·1 ≈ 1`).
- **`mellinMoment clampTest 0 ≈ 1/2`** — the clamped identity's zeroth moment: on `[0,1]` the
  clamp is inert (`clamp01_inert`, the band identity at real arguments), so the integrand
  agrees with `x` exactly where the integral samples, and the NEW unit-local congruence
  (`riemannIntegral_congr_unit`, antisymmetry of `riemannIntegral_le_unit`) hands the value to
  `riemannIntegral_id_gen` (`∫₀¹ x = 1/2`) at the shared modulus `L = 1`.

With brick 22's `mellinMoment_zeroL2 ≈ 0`, the moment functionals now provably SEPARATE tests:
the skeleton carries genuine, distinguishing spectral data, not the zero map.

HONEST SCOPE. Values of the compact `[0,1]` moment pairing. `clampTest` has no half-line
decay (the clamp is `1` beyond `1`), so these are NOT transform values — `mellinHat` does not
exist for it on the decay class; the first nonzero value of the full transform (a nonzero
`[0,1]`-supported test with evaluated moments) is the banked next construction. No continuous
parameter, no coupling. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.TestAlgebra
import Multiplicity.F1Square.Analysis.IntegralLocal
import Multiplicity.F1Square.Analysis.IntegralEval

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The clamp is inert on `[0,1]`**: `clamp01 x ≈ x` for `0 ≤ x ≤ 1` — the band identity at
    real arguments (`qBandQ_eq_of_band`), the domain-local closed form of `clampTest`. -/
theorem clamp01_inert {x : Real} (h0 : Rle zero x) (h1 : Rle x one) :
    Req (clamp01 x) x :=
  qBandQ_eq_of_band h0 h1

/-- **`mellinMoment oneTest 0 ≈ 1`** — the constant test's zeroth moment: the integrand is
    globally `1·1 ≈ 1`, and the constant integral is the constant. -/
theorem mellinMoment_one_zero : Req (mellinMoment oneTest 0) one := by
  have hlipg : ∀ x y : Real, Rle (Rabs (Rsub one one))
      (Rmul (ofQ (l2L oneTest (powTest 0)) (l2L_den oneTest (powTest 0)))
        (Rabs (Rsub x y))) := by
    intro x y
    have hz : Req (Rabs (Rsub one one)) zero :=
      Req_trans (Rabs_congr (Radd_neg one)) Rabs_zero
    refine Rle_trans (Rle_of_Req hz) ?_
    exact Rle_zero_of_Rnonneg (Rnonneg_Rmul
      (Rnonneg_ofQ (l2L_den oneTest (powTest 0)) (l2L_num oneTest (powTest 0)))
      (Rnonneg_Rabs _))
  have hfcg : ∀ x y : Real, Req x y → Req one one := fun _ _ _ => Req_refl one
  have hfg : ∀ x, Req (Rmul (oneTest.f x) ((powTest 0).f x)) one := fun _ => Rmul_one one
  refine Req_trans (riemannIntegral_congr (g := fun _ => one)
    (l2L_den oneTest (powTest 0)) (l2L_num oneTest (powTest 0))
    (l2lip oneTest (powTest 0)) (l2fc oneTest (powTest 0)) hlipg hfcg hfg) ?_
  exact riemannIntegral_const_gen one (l2L_den oneTest (powTest 0))
    (l2L_num oneTest (powTest 0)) hlipg hfcg

/-- **THE FIRST NONZERO NON-TRIVIAL MOMENT VALUE**: `mellinMoment clampTest 0 ≈ 1/2` — the
    clamped identity's zeroth moment is `∫₀¹ x dx`: the clamp is inert on the sampling domain
    (`clamp01_inert`), the unit-local congruence moves the integral to the identity integrand
    at the shared modulus `L = 1`, and `riemannIntegral_id_gen` evaluates it. -/
theorem mellinMoment_clamp_zero : Req (mellinMoment clampTest 0) half := by
  refine Req_trans (mellinMoment_zero clampTest) ?_
  refine Req_trans (riemannIntegral_congr_unit (g := fun x => x)
    clampTest.hLd clampTest.hLn clampTest.hlip clampTest.hfc lip_id congr_id
    (fun x h0 h1 => clamp01_inert h0 h1)) ?_
  exact riemannIntegral_id_gen clampTest.hLd clampTest.hLn lip_id congr_id

end Multiplicity.UOR.Bridge.F1Square.Square
