/-
F1 square — **the pre-Hilbert layer, brick 93** (`ContinuousMoment.lean`): **the compact-side
continuous Mellin parameter** — the transform `∫₀¹ φ(t)·t^s dt` for a real exponent `s ≥ 0`,
generalizing the integer moments `mellinMoment φ n = ∫₀¹ φ·tⁿ` (`TestAlgebra.lean`) to a continuum
of exponents on the unit interval.

The construction totalizes `t ↦ t^s` on `[0,1]` (which vanishes at `t = 0`, where the naive
`RrpowPos` needs `t > 0`) by the RECIPROCAL trick, composing two already-certified integrands:

    compactPow a s t  :=  gPowClamp (−s) (clampedInv a t)  =  max(1/max(t,a), 1)^{−s}.

On `[a, 1]` this is exactly `t^s` (there `clampedInv a t = 1/t ≥ 1`, so `max(1/t,1)^{−s} = (1/t)^{−s}
= t^s`); on `[0, a)` the reciprocal floor pins it at the constant `a^s`, so the function is a genuine
total, bounded (`≤ 1`), Lipschitz `Real → Real` — an `L2Test`. Both factors carry their gateway data:
`gPowClamp (−s)` is `4·|s|`-Lipschitz and `≤ 1` for `−s ≤ 0` (`RpowClampLip.lean`,
`ThetaMellinPow.lean`), and `clampedInv a` is `(1/a)²`-Lipschitz (`ClampedInv.lean`); the composite is
`4·σ·(1/a)²`-Lipschitz once a rational magnitude bound `s ≤ σ` is supplied. Pairing against a test
then gives `compactMoment φ a s = innerI φ (compactPowTest …) = ∫₀¹ φ(t)·compactPow a s t dt`.

HONEST SCOPE. This is the continuous exponent on the compact `[0,1]` domain at a fixed rational floor
`a` — the transform is totalized near `0` by the clamp, so it agrees with the true `∫₀¹ φ·t^s` only up
to the sub-`a` tail (an `O(M·a^{s+1})` correction), and the exact identification `compactPow a s ≈ t^s`
on `[a,1]` (needs `log(1/t) = −log t`) and the `a → 0` limit are NOT established here. This is the
compact analog of the theta half-line `thetaMellinPow` (`ThetaMellinPow.lean`), which already carries
the `σ ≤ 1` exponents; together they are the two ends of the Mellin front. No transform pair, no
inversion, no positivity, no crux — the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.TestAlgebra
import Foundations.F1.Analysis.ThetaMellinPow
import Foundations.F1.Analysis.ClampedInv

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `−s ≤ 0` from `s ≥ 0` — the `gPowClamp` sign side-condition (local helper). -/
private theorem sNeg_nonpos {s : Real} (hs : Rnonneg s) : Rle (Rneg s) zero :=
  Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg hs)) (Rle_of_Req Rneg_zero)

-- ===========================================================================
-- The totalized compact power integrand  t ↦ t^s  (via the reciprocal clamp).
-- ===========================================================================

/-- **The totalized compact power** `compactPow a s t = max(1/max(t,a), 1)^{−s}` — the reciprocal-clamp
    realization of `t ↦ t^s` on `[0,1]`. On `[a,1]` it equals `t^s`; on `[0,a)` it is the constant
    `a^s` (the floor keeps `1/·` finite, so the composite is total). -/
def compactPow (a : Q) (han : 0 < a.num) (had : 0 < a.den) (s : Real) (t : Real) : Real :=
  gPowClamp (Rneg s) (clampedInv a han had t)

/-- `compactPow a s t ≥ 0` (it is a `gPowClamp`, an `exp`). -/
theorem compactPow_nonneg (a : Q) (han : 0 < a.num) (had : 0 < a.den) (s t : Real) :
    Rnonneg (compactPow a han had s t) :=
  gPowClamp_nonneg (Rneg s) (clampedInv a han had t)

/-- `|compactPow a s t| ≤ 1` for `s ≥ 0` — the integral-interface bound (`M = 1`). -/
theorem compactPow_abs_le_one (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real}
    (hs : Rnonneg s) (t : Real) :
    Rle (Rabs (compactPow a han had s t)) (ofQ (⟨1, 1⟩ : Q) (by decide)) :=
  gPowClamp_abs_le_one (Rneg s) (sNeg_nonpos hs) (clampedInv a han had t)

/-- `compactPow a s` respects `≈` — the gateway's congruence datum, from the two factors' congruences. -/
theorem compactPow_congr (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real} (hs : Rnonneg s)
    {x y : Real} (hxy : Req x y) :
    Req (compactPow a han had s x) (compactPow a han had s y) :=
  gPowClamp_congr (Rneg s) (sNeg_nonpos hs) (clampedInv_congr a han had hxy)

/-- **The composite Lipschitz constant** `L = 4·σ·(1/a)²` (rational): the product of the power factor's
    `4·σ` (from `s ≤ σ`) and the clamp factor's `(1/a)²`. -/
def compactPowL (a σ : Q) : Q := mul (mul (⟨4, 1⟩ : Q) σ) (mul (Qinv a) (Qinv a))

theorem compactPowL_den (a σ : Q) (hσd : 0 < σ.den) (han : 0 < a.num) : 0 < (compactPowL a σ).den :=
  Qmul_den_pos (Qmul_den_pos (by decide) hσd) (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han))

theorem compactPowL_num (a σ : Q) (hσn : 0 ≤ σ.num) (had : 0 < a.den) : 0 ≤ (compactPowL a σ).num :=
  Qmul_num_nonneg (Qmul_num_nonneg (by decide) hσn)
    (Qmul_num_nonneg (Int.le_of_lt (Qinv_num_pos had)) (Int.le_of_lt (Qinv_num_pos had)))

set_option maxHeartbeats 1600000 in
/-- **`compactPow a s` is globally `4·σ·(1/a)²`-Lipschitz** for `s ≥ 0` with `s ≤ σ` (`σ` rational):
    compose `gPowClamp (−s)`'s `4·|−s|`-Lipschitz bound with `clampedInv a`'s `(1/a)²`-Lipschitz bound,
    then over-bound `4·|−s| ≤ 4·σ`. This is the `∀x,y, |f x − f y| ≤ ofQ L·|x−y|` shape `L2Test` wants. -/
theorem compactPow_lipschitz (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real} (hs : Rnonneg s)
    (σ : Q) (hσd : 0 < σ.den) (hsB : Rle s (ofQ σ hσd)) (x y : Real) :
    Rle (Rabs (Rsub (compactPow a han had s x) (compactPow a han had s y)))
      (Rmul (ofQ (compactPowL a σ) (compactPowL_den a σ hσd han)) (Rabs (Rsub x y))) := by
  unfold compactPow
  -- magnitude bound `|−s| ≤ σ` from `s ≤ σ` and `s ≥ 0`
  have heB : Rle (Rabs (Rneg s)) (ofQ σ hσd) :=
    Rle_trans (Rle_of_Req (Rabs_Rneg s)) (Rle_trans (Rle_of_Req (Rabs_of_nonneg hs)) hsB)
  have hK4e_nn : Rnonneg (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rabs (Rneg s))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_Rabs _)
  have hCInv_nn : Rnonneg (Rmul (ofQ (mul (Qinv a) (Qinv a))
        (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han))) (Rabs (Rsub x y))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han))
      (Qmul_num_nonneg (Int.le_of_lt (Qinv_num_pos had)) (Int.le_of_lt (Qinv_num_pos had))))
      (Rnonneg_Rabs _)
  -- A: gPowClamp Lipschitz;  C: multiply the clamp Lipschitz on the left by 4|−s|
  refine Rle_trans (gPowClamp_lipschitz (Rneg s) (sNeg_nonpos hs) _ _) ?_
  refine Rle_trans (Rmul_le_Rmul_left hK4e_nn (clampedInv_lipschitz a han had x y)) ?_
  -- E: over-bound 4|−s| ≤ 4σ on the left factor
  refine Rle_trans (Rmul_le_Rmul_right hCInv_nn
    (Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) heB)
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) hσd)))) ?_
  -- F: reassociate and fuse the two rational factors into `compactPowL a σ`
  refine Rle_of_Req (Req_trans (Req_symm (Rmul_assoc _ _ _)) ?_)
  exact Rmul_congr (Rmul_ofQ_ofQ (Qmul_den_pos (by decide) hσd)
    (Qmul_den_pos (Qinv_den_pos han) (Qinv_den_pos han))) (Req_refl _)

-- ===========================================================================
-- The continuous compact Mellin moment.
-- ===========================================================================

/-- **The compact power test** `t ↦ t^s` as an `L2Test` (floor `a`, exponent `s ≥ 0` bounded by the
    rational `σ`). Lipschitz constant `4·σ·(1/a)²`, bound `1`. -/
def compactPowTest (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real} (hs : Rnonneg s)
    (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) : L2Test where
  f := compactPow a han had s
  L := compactPowL a σ
  M := ⟨1, 1⟩
  hLd := compactPowL_den a σ hσd han
  hLn := compactPowL_num a σ hσn had
  hMd := by decide
  hMn := by decide
  hlip := compactPow_lipschitz a han had hs σ hσd hsB
  hfc := fun _ _ hxy => compactPow_congr a han had hs hxy
  hbd := compactPow_abs_le_one a han had hs

/-- **The continuous compact Mellin moment** `compactMoment φ a s = ∫₀¹ φ(t)·t^s dt` — the transform
    of `φ` at the continuous exponent `s ≥ 0` (totalized near `0` at floor `a`), a certified
    constructive real. The continuous-parameter generalization of `mellinMoment φ n`. -/
def compactMoment (φ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s : Real} (hs : Rnonneg s)
    (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB : Rle s (ofQ σ hσd)) : Real :=
  innerI φ (compactPowTest a han had hs σ hσd hσn hsB)

end Multiplicity.UOR.Bridge.F1Square.Square
