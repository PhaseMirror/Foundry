/-
F1 square — **the pre-Hilbert layer, brick 110** (`ContinuousMomentFloorReal.lean`): **the compact
power is floor-independent at EVERY real point above the floor** — `compactPow a s x ≈ compactPow a' s
x` for every real `x ≥ a, a'` (`compactPow_floor_indep_real`), lifting brick 97's rational-point
floor-independence to all reals.

Brick 97 (`compactPow_floor_indep`) proved floor-independence only at rational sample points `q`, which
is what the certified Riemann integral (sampling `i/(N+1)`) needed for the fixed-floor moment. The
`a → 0` limit at GENERAL `s` needs more: the difference of two compact-moment integrands must vanish on
the *whole* overlap interval `[max(a,a'), 1]`, not just at rationals — because the tail bound
(brick 107) quantifies over all reals in the tail. The real-level inertness `clampedInv_eq_of_ge`
(`ClampedInv.lean`: for `x ≥ a` the clamped reciprocal IS `1/x`, any positivity witness) supplies it:
above both floors both compact powers equal `gPowClamp(−s)(1/x)`, so they agree. The positivity witness
for `x` comes free from `x ≥ a > 0` (`Pos_mono` on `Pos (ofQ a)`).

HONEST SCOPE. Floor-independence of the compact-power integrand at every real point `≥` both floors —
the structural fact the general-`s` `a → 0` limit rests on. NOT the limit itself, NOT any identification
of the value with `x^s`. No transform pair, no inversion, no positivity. Step 4 is RH; the crux fields
stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.ContinuousMomentFloor

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **Real-level floor independence**: for two floors `a, a'` both `≤ x` (any REAL `x`), the compact
    power takes the same value at `x` — above both floors each is `gPowClamp(−s)(1/x)`. The positivity
    witness for `x` is extracted from `x ≥ a > 0` via `Pos_mono`. -/
theorem compactPow_floor_indep_real (a a' : Q) (han : 0 < a.num) (had : 0 < a.den)
    (han' : 0 < a'.num) (had' : 0 < a'.den) {s : Real} (hs : Rnonneg s) {x : Real}
    (hx : Rle (ofQ a had) x) (hx' : Rle (ofQ a' had') x) :
    Req (compactPow a han had s x) (compactPow a' han' had' s x) := by
  obtain ⟨kx, hkx⟩ : Pos x := Pos_mono hx ⟨2 * a.den, Qbound_lt_pos han had⟩
  have hns : Rle (Rneg s) zero :=
    Rle_trans (Rle_Rneg (Rle_zero_of_Rnonneg hs)) (Rle_of_Req Rneg_zero)
  unfold compactPow
  exact gPowClamp_congr (Rneg s) hns
    (Req_trans (clampedInv_eq_of_ge hkx hx) (Req_symm (clampedInv_eq_of_ge hkx hx')))

end Multiplicity.UOR.Bridge.F1Square.Square
