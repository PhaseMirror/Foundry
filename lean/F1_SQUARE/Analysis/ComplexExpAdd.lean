/-
F1 square — the **complex exponential law** `e^{z+w} = e^z · e^w` (`Cexp_add`), the keystone that lifts
the real exponential/trigonometric addition formulas into ℂ. It is the prerequisite for the η-series
variation bound `Σ |n⁻ˢ − (n+1)⁻ˢ| < ∞` (the integration-free route to `ζ` on the critical strip):
`|n⁻ˢ − (n+1)⁻ˢ| = n^{−σ}·|Cexp(w) − 1|` with `w = −s·(log(n+1) − log n)`, and `|Cexp(w) − 1|` is
controlled through the complex modulus once the exponential is multiplicative.

`Cexp z = e^{re z}·(cos(im z) + i·sin(im z))`, so `Cexp_add` is the componentwise combination of three
real laws — `RexpReal_add` (`e^{x+y}=e^x e^y`), `Rcos_add` (`cos(a+b)=cos a cos b − sin a sin b`) and
`Rsin_add` (`sin(a+b)=sin a cos b + cos a sin b`) — followed by a pure real-ring rearrangement
(`Rmul4_rearrange`, `Rmul_sub_distrib`/`Rmul_distrib`). No new convergence obligation.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.ComplexExp
import F1Square.Analysis.CosSinAddFormula
import F1Square.Analysis.ExpRealAdd
import F1Square.Analysis.ExpLog

namespace UOR.Bridge.F1Square.Analysis

/-- **The complex exponential respects `≈`**: `z ≈ w ⟹ e^z ≈ e^w` (componentwise, from `RexpReal_congr`,
    `Rcos_congr`, `Rsin_congr`). -/
theorem Cexp_congr {z w : Complex} (h : Ceq z w) : Ceq (Cexp z) (Cexp w) :=
  ⟨Rmul_congr (RexpReal_congr h.1) (Rcos_congr h.2),
    Rmul_congr (RexpReal_congr h.1) (Rsin_congr h.2)⟩

/-- **The complex exponential law** `e^{z+w} ≈ e^z · e^w`. Componentwise: the real part is
    `e^{re z+re w}·cos(im z+im w)` reorganized via `RexpReal_add`+`Rcos_add` into
    `(e^{re z}cos(im z))(e^{re w}cos(im w)) − (e^{re z}sin(im z))(e^{re w}sin(im w))` (the `Cmul` real part);
    the imaginary part likewise via `Rsin_add`. Each step is `Rmul_congr` of the three real addition laws
    then a `Rmul4_rearrange`/`Rmul_sub_distrib`/`Rmul_distrib` ring move. -/
theorem Cexp_add (z w : Complex) : Ceq (Cexp (Cadd z w)) (Cmul (Cexp z) (Cexp w)) := by
  refine ⟨?_, ?_⟩
  · -- real part: e^{·}·cos(·) ≈ (e cos)(e cos) − (e sin)(e sin)
    show Req (Rmul (RexpReal (Radd z.re w.re)) (Rcos (Radd z.im w.im)))
      (Rsub (Rmul (Rmul (RexpReal z.re) (Rcos z.im)) (Rmul (RexpReal w.re) (Rcos w.im)))
            (Rmul (Rmul (RexpReal z.re) (Rsin z.im)) (Rmul (RexpReal w.re) (Rsin w.im))))
    refine Req_trans (Rmul_congr (RexpReal_add z.re w.re) (Rcos_add z.im w.im)) ?_
    refine Req_trans (Rmul_sub_distrib (Rmul (RexpReal z.re) (RexpReal w.re))
        (Rmul (Rcos z.im) (Rcos w.im)) (Rmul (Rsin z.im) (Rsin w.im))) ?_
    exact Rsub_congr
      (Rmul4_rearrange (RexpReal z.re) (RexpReal w.re) (Rcos z.im) (Rcos w.im))
      (Rmul4_rearrange (RexpReal z.re) (RexpReal w.re) (Rsin z.im) (Rsin w.im))
  · -- imaginary part: e^{·}·sin(·) ≈ (e cos)(e sin) + (e sin)(e cos)
    show Req (Rmul (RexpReal (Radd z.re w.re)) (Rsin (Radd z.im w.im)))
      (Radd (Rmul (Rmul (RexpReal z.re) (Rcos z.im)) (Rmul (RexpReal w.re) (Rsin w.im)))
            (Rmul (Rmul (RexpReal z.re) (Rsin z.im)) (Rmul (RexpReal w.re) (Rcos w.im))))
    refine Req_trans (Rmul_congr (RexpReal_add z.re w.re) (Rsin_add z.im w.im)) ?_
    refine Req_trans (Rmul_distrib (Rmul (RexpReal z.re) (RexpReal w.re))
        (Rmul (Rcos z.im) (Rsin w.im)) (Rmul (Rsin z.im) (Rcos w.im))) ?_
    exact Radd_congr
      (Rmul4_rearrange (RexpReal z.re) (RexpReal w.re) (Rcos z.im) (Rsin w.im))
      (Rmul4_rearrange (RexpReal z.re) (RexpReal w.re) (Rsin z.im) (Rcos w.im))

end UOR.Bridge.F1Square.Analysis
