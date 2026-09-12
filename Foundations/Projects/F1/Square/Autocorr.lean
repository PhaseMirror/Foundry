/-
F1 square — **the autocorrelation `g ⋆ g^τ`** (`Autocorr.lean`): the cone object the Weil prime side
lives on, constructed from the multiplicative convolution.

The doc's step 2/4 pin the target: "Weil positivity is not a pointwise feature of the admissible
class, it lives on the cone `g ⋆ g^τ`." That cone is now a built object:

    `autocorr g x = (g ⋆ g^τ)(x) = ∫ g(x/t)·g(1/t) dt/t`     (`g^τ(t) = g(1/t) = reflectTest a g`),

i.e. `mulConv g (reflectTest a g) x` — the convolution of `g` with its multiplicative reflection.
`autocorr_nonneg`: for a non-negative `g` the autocorrelation is non-negative (the *integrand* is a
product of non-negatives on the window). This is the non-negativity of the DENSITY, at the level of
the constructed integral.

HONEST SCOPE — the load-bearing bright line. This constructs the autocorrelation cone and the
sign of its Haar-integral integrand. It is emphatically NOT the positivity of the **Weil functional**
on the cone — that uniform statement (over the band-indexed cone family, against the live prime side)
is exactly step 4 = RH, and nothing here asserts it. It is also NOT the Mellin convolution theorem
that would identify these values with `weilPrimeGram (vFrom g)`. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MulConv
import Foundations.F1.Analysis.ReflectTest

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The autocorrelation `(g ⋆ g^τ)(x) = ∫ g(x/t)·g(1/t) dt/t`** — the convolution of `g` with its
    multiplicative reflection `g^τ = reflectTest a g`; the cone the Weil prime side inhabits, built on
    the window `[lo, lo+w] ⊆ [a, ∞)`. -/
def autocorr (g : L2Test) (x : Q) (hxn : 0 < x.num) (hxd : 0 < x.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : Real :=
  mulConv g (reflectTest a han had g) x hxn hxd a han had lo w hlo hw hwn

/-- **The autocorrelation of a non-negative test is non-negative** — the integrand
    `g(x/t)·g(1/t)·(1/max(t,a))` is a product of non-negatives. This is the non-negativity of the
    autocorrelation DENSITY; the positivity of the Weil functional on the cone is step 4 = RH and is
    NOT proved here. -/
theorem autocorr_nonneg (g : L2Test) (x : Q) (hxn : 0 < x.num) (hxd : 0 < x.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hg : ∀ y, Rnonneg (g.f y)) :
    Rnonneg (autocorr g x hxn hxd a han had lo w hlo hw hwn) :=
  mulConv_nonneg g (reflectTest a han had g) x hxn hxd a han had lo w hlo hw hwn
    hg (fun y => hg (clampedInv a han had y))

end Multiplicity.UOR.Bridge.F1Square.Square
