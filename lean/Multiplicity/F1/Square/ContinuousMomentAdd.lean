/-
F1 square — **the pre-Hilbert layer, brick 99** (`ContinuousMomentAdd.lean`): **the power law in the
exponent** — `compactPow a (s + s') t ≈ compactPow a s t · compactPow a s' t`, i.e. `t^{s+s'} = t^s·t^{s'}`
on the totalized compact power (brick 93). The third and last of the exponent-structure laws, after
continuity (brick 96) and monotonicity (brick 98).

At a fixed `t` the compact power is `exp(−s·L_t)` with `L_t = compactBaseLog a t` (brick 96). The
exponent is additive under `exp`: `exp(−(s+s')·L_t) = exp((−s·L_t) + (−s'·L_t)) = exp(−s·L_t)·exp(−s'·L_t)`,
via `−(s+s') = −s + −s'` (`Rneg_Radd`), right-distributivity, and `RexpReal_add`. So the compact power is
a homomorphism from the additive reals (in the exponent) to the multiplicative reals — the defining
functional equation of a power.

HONEST SCOPE. The pointwise power law of the integrand in the exponent (`s, s'` any reals — no sign
hypothesis: it is purely `exp`'s additivity). No transform pair, no inversion, no positivity, and this
is the totalized power, not identified with `t^s` off the clamp (which needs `log(1/t) = −log t`). Step 4
is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.ContinuousMomentExp

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The power law in the exponent**: `compactPow a (s + s') t ≈ compactPow a s t · compactPow a s' t`.
    `exp(−(s+s')·L_t) = exp(−s·L_t)·exp(−s'·L_t)` via `RexpReal_add` — the totalized compact power is a
    homomorphism from `(ℝ, +)` (exponent) to `(ℝ, ·)`. Holds for all `s, s', t`. -/
theorem compactPow_exp_add (a : Q) (han : 0 < a.num) (had : 0 < a.den) (s s' t : Real) :
    Req (compactPow a han had (Radd s s') t)
        (Rmul (compactPow a han had s t) (compactPow a han had s' t)) := by
  have hkey : ∀ σ : Real,
      Req (compactPow a han had σ t) (RexpReal (Rmul (Rneg σ) (compactBaseLog a han had t))) := by
    intro σ; unfold compactPow gPowClamp RrpowPos compactBaseLog; exact Req_refl _
  have harg : Req (Rmul (Rneg (Radd s s')) (compactBaseLog a han had t))
      (Radd (Rmul (Rneg s) (compactBaseLog a han had t))
            (Rmul (Rneg s') (compactBaseLog a han had t))) :=
    Req_trans (Rmul_congr (Rneg_Radd s s') (Req_refl _))
      (Rmul_distrib_right (Rneg s) (Rneg s') (compactBaseLog a han had t))
  refine Req_trans (hkey (Radd s s')) ?_
  refine Req_trans (RexpReal_congr harg) ?_
  exact Req_trans (RexpReal_add _ _) (Rmul_congr (Req_symm (hkey s)) (Req_symm (hkey s')))

end Multiplicity.UOR.Bridge.F1Square.Square
