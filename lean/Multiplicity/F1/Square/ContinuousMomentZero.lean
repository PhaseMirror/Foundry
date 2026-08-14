/-
F1 square — **the pre-Hilbert layer, brick 95** (`ContinuousMomentZero.lean`): **the continuous
Mellin transform specializes to the integer skeleton at `s = 0`** — `compactMoment φ a 0 ≈
mellinMoment φ 0 = ∫₀¹ φ`, the consistency check that the continuous parameter (brick 93) agrees with
the integer moment map (`TestAlgebra.lean`) where they overlap.

At exponent `s = 0` the compact power is the constant `1` everywhere (`compactPow_zero`): `t^0 = exp(0·
log t) = exp 0 = 1`, uniformly in the floor `a` (the base `clampedInv a t` and the clamp are irrelevant
once the exponent kills the log). So the compact power test and the constant-`1` test `oneTest = powTest
0` agree on `[0,1]`, and the certified `L²` pairing — which only integrates over `[0,1]` — cannot tell
them apart (`innerI_right_congr_on_unit`). Hence `compactMoment φ a 0 ≈ mellinMoment φ 0`, the zeroth
integer moment `∫₀¹ φ`.

This is the first EVALUATION of the continuous transform (bricks 93–94 built and pinned its algebra;
this reads off a value), and the anchor that the continuous exponent is a genuine extension of the
integer moments, not an unrelated object.

HONEST SCOPE. The single specialization `s = 0`; the general integer specialization `compactMoment φ a
n ≈ mellinMoment φ n` (`n ≥ 1`) needs the `t^s ≈ tⁿ` identification on `[a,1]` (which needs `log(1/t) =
−log t`) and is NOT established here. No transform pair, no inversion, no positivity. Step 4 is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMoment
import Multiplicity.F1Square.Square.PairingUnitCongr

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The compact power at exponent `0` is the constant `1`** — `t^0 = exp(0·log t) = exp 0 = 1`,
    every `t`, every floor. The exponent kills the log before the base/clamp matter. -/
theorem compactPow_zero (a : Q) (han : 0 < a.num) (had : 0 < a.den) (t : Real) :
    Req (compactPow a han had zero t) one := by
  unfold compactPow gPowClamp RrpowPos
  refine Req_trans (RexpReal_congr ?_) RexpReal_zero
  exact Req_trans (Rmul_congr Rneg_zero (Req_refl _))
    (Req_trans (Rmul_comm zero _) (Rmul_zero _))

/-- **The continuous transform specializes to the integer skeleton at `s = 0`**:
    `compactMoment φ a 0 ≈ mellinMoment φ 0 = ∫₀¹ φ`. The compact power test and `oneTest = powTest 0`
    agree on `[0,1]` (`compactPow_zero`), and `innerI` only sees `[0,1]`. -/
theorem compactMoment_zero (φ : L2Test) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (σ : Q) (hσd : 0 < σ.den) (hσn : 0 ≤ σ.num) (hsB0 : Rle zero (ofQ σ hσd)) :
    Req (compactMoment φ a han had Rnonneg_zero σ hσd hσn hsB0) (mellinMoment φ 0) :=
  innerI_right_congr_on_unit φ (compactPowTest a han had Rnonneg_zero σ hσd hσn hsB0) oneTest
    (fun x _ _ => compactPow_zero a han had x)

end Multiplicity.UOR.Bridge.F1Square.Square
