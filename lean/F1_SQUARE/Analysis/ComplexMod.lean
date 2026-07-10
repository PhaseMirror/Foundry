/-
F1 square — **the `Cexp` modulus identity** `|Cexp z|² = exp(2·Re z)`, i.e. `(exp(Re z))²`.
This is the analytic payoff of the Pythagorean identity `cos² + sin² = 1` (`Rcos_sq_add_sin_sq`):
the imaginary rotation `cos(Im z) + i·sin(Im z)` has unit modulus, so the modulus of `Cexp z`
is governed entirely by its real part. It is the gateway to the `nˢ` modulus `|n⁻ˢ| = n⁻ᴿᵉˢ`
that drives convergence of the complex `ζ` for `Re s > 1`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.ComplexExp
import F1Square.Analysis.CosSinBound

namespace UOR.Bridge.F1Square.Analysis

/-- The **squared modulus** `|z|² = (Re z)² + (Im z)²` of a complex number. -/
def CnormSq (z : Complex) : Real := Radd (Rmul z.re z.re) (Rmul z.im z.im)

/-- **The `Cexp` modulus identity**: `|Cexp z|² = (exp(Re z))²`. Since `Cexp z = exp(Re z)·(cos(Im z) +
    i·sin(Im z))`, its squared modulus is `exp(Re z)²·(cos² + sin²) = exp(Re z)²` by `cos²+sin²=1`. -/
theorem Cexp_normSq (z : Complex) :
    Req (CnormSq (Cexp z)) (Rmul (RexpReal z.re) (RexpReal z.re)) := by
  show Req (Radd (Rmul (Rmul (RexpReal z.re) (Rcos z.im)) (Rmul (RexpReal z.re) (Rcos z.im)))
      (Rmul (Rmul (RexpReal z.re) (Rsin z.im)) (Rmul (RexpReal z.re) (Rsin z.im))))
    (Rmul (RexpReal z.re) (RexpReal z.re))
  refine Req_trans (Radd_congr (Rmul4_rearrange (RexpReal z.re) (Rcos z.im) (RexpReal z.re) (Rcos z.im))
      (Rmul4_rearrange (RexpReal z.re) (Rsin z.im) (RexpReal z.re) (Rsin z.im))) ?_
  refine Req_trans (Req_symm (Rmul_distrib (Rmul (RexpReal z.re) (RexpReal z.re))
      (Rmul (Rcos z.im) (Rcos z.im)) (Rmul (Rsin z.im) (Rsin z.im)))) ?_
  exact Req_trans (Rmul_congr (Req_refl _) (Rcos_sq_add_sin_sq z.im)) (Rmul_one _)

end UOR.Bridge.F1Square.Analysis
