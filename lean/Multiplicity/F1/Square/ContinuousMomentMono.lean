/-
F1 square — **the pre-Hilbert layer, brick 98** (`ContinuousMomentMono.lean`): **the compact power is
antitone in the exponent** — `s ≤ s' ⟹ compactPow a s' t ≤ compactPow a s t`. The monotone companion
to brick 96's continuity: together they characterize how the continuous Mellin integrand
(brick 93) depends on `s` — continuously and monotonically.

At a fixed point `t` the compact power is `compactPow a s t = exp(−s·L_t)` with `L_t = compactBaseLog
a t ≥ 0` (the log of the clamped reciprocal base, `≥ 1`, brick 96). A larger exponent `s' ≥ s` gives a
more negative product `−s'·L_t ≤ −s·L_t` (since `L_t ≥ 0`), and `exp` is monotone
(`RexpReal_le_of_le`), so `exp(−s'·L_t) ≤ exp(−s·L_t)`. Hence `t^{s'} ≤ t^s` — the familiar fact that a
base in `(0,1]` decreases under a larger exponent, here on the totalized power, for ALL `t` (no sign
hypothesis on `s` needed: `L_t ≥ 0` is unconditional).

HONEST SCOPE. Pointwise antitonicity of the integrand in the exponent. The moment-level version
`compactMoment φ a s' ≤ compactMoment φ a s` would need a GLOBALLY non-negative test `φ` (the integral
monotonicity `riemannIntegral_le` compares products pointwise on all of `ℝ`) and is not asserted here.
No transform pair, no inversion, no positivity. Step 4 is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentExp

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The compact power is antitone in the exponent**: `s ≤ s' ⟹ compactPow a s' t ≤ compactPow a s t`.
    The base `max(1/max(t,a),1) ≥ 1`, so its log `L_t ≥ 0`; a larger exponent scales `−s·L_t` down, and
    `exp` is monotone. Holds for all `t` and all `s ≤ s'` (no sign hypothesis). -/
theorem compactPow_antitone_exp (a : Q) (han : 0 < a.num) (had : 0 < a.den) {s s' : Real}
    (hss' : Rle s s') (t : Real) :
    Rle (compactPow a han had s' t) (compactPow a han had s t) := by
  have hkey : ∀ σ : Real,
      Req (compactPow a han had σ t) (RexpReal (Rmul (Rneg σ) (compactBaseLog a han had t))) := by
    intro σ; unfold compactPow gPowClamp RrpowPos compactBaseLog; exact Req_refl _
  have hexp : Rle (Rmul (Rneg s') (compactBaseLog a han had t))
      (Rmul (Rneg s) (compactBaseLog a han had t)) :=
    Rmul_le_Rmul_right (compactBaseLog_nonneg a han had t) (Rle_Rneg hss')
  exact Rle_trans (Rle_of_Req (hkey s'))
    (Rle_trans (RexpReal_le_of_le hexp) (Rle_of_Req (Req_symm (hkey s))))

end Multiplicity.UOR.Bridge.F1Square.Square
