/-
F1 square — **the multiplicative convolution, constructed** (`MulConv.lean`): the convolution
`(f ⋆ g)(x) = ∫₀^∞ f(x/t) g(t) dt/t` of the multiplicative group, assembled from the transform-bridge
operators built for Wall 1–2.

The construction is a composition of pieces already in hand:

    `f(x/t) = f(x · (1/t)) = (dilateTest x f)(1/t) = (reflectTest a (dilateTest x f))(t)`   (on `t ≥ a`)

so the convolution integrand `t ↦ f(x/t)·g(t)` is `productTest (reflectTest a (dilateTest x f)) g`,
and the convolution against the Haar measure `dt/t` is `haarIntegral` of that:

    `mulConv f g x a [lo, w] = ∫_lo^{lo+w} f(x/t) g(t) dt/t`     (on the window `[lo, lo+w] ⊆ [a, ∞)`).

`mulConv_nonneg`: the convolution of two non-negative tests is non-negative — the shape the
autocorrelation `g ⋆ g^τ` (Weil prime side) lives in.

HONEST SCOPE. This is the multiplicative convolution CONSTRUCTED on a bounded window bounded away from
`0`, from the built group action / inversion / product / Haar integral. It is the object side of
transform-bridge Wall 2. What is NOT here: the **Mellin convolution theorem** `M[f⋆g] = M[f]·M[g]`
(Wall 3), which is what would turn `mulConv` values at prime powers into `weilPrimeGram (vFrom g)`, the
genuine autocorrelation Gram — i.e. step 4 = RH. This file constructs the convolution; it proves no
transform identity about it. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Analysis.HaarInterval
import Multiplicity.F1Square.Analysis.ReflectTest
import Multiplicity.F1Square.Analysis.ProductTest
import Multiplicity.F1Square.Square.MultShift

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The multiplicative convolution on the window** `(f ⋆ g)(x) = ∫_lo^{lo+w} f(x/t) g(t) dt/t` —
    the Haar integral of the product `f(x·(1/t))·g(t)`, with `f(x/t)` realized as
    `reflectTest a (dilateTest x f)` (the dilation-by-`x` of the reflection) and the `dt/t` measure
    supplied by `haarIntegral`. The floor `a > 0` (`a ≤ lo`) keeps every clamped reciprocal inert on
    the window. -/
def mulConv (f g : L2Test) (x : Q) (hxn : 0 < x.num) (hxd : 0 < x.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : Real :=
  haarIntegral (productTest (reflectTest a han had (dilateTest x hxn hxd f)) g)
    a han had lo w hlo hw hwn

/-- **The convolution of non-negative tests is non-negative** — `f, g ≥ 0` pointwise gives an
    integrand `f(x/t)·g(t)·(1/max(t,a)) ≥ 0` (a product of non-negatives), so `mulConv f g x ≥ 0`.
    This is the sign the autocorrelation `g ⋆ g^τ` inhabits. -/
theorem mulConv_nonneg (f g : L2Test) (x : Q) (hxn : 0 < x.num) (hxd : 0 < x.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hf : ∀ y, Rnonneg (f.f y)) (hg : ∀ y, Rnonneg (g.f y)) :
    Rnonneg (mulConv f g x hxn hxd a han had lo w hlo hw hwn) :=
  haarIntegral_nonneg (productTest (reflectTest a han had (dilateTest x hxn hxd f)) g)
    a han had lo w hlo hw hwn (fun t => Rnonneg_Rmul (hf _) (hg t))

end Multiplicity.UOR.Bridge.F1Square.Square
