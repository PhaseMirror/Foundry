/-
F1 square — **the real-parameter multiplicative convolution** (`MulConvR.lean`): `(f ⋆ g)(x)` at a
REAL output point `x` — the object the Mellin transform `M[f⋆g](σ) = ∫ (f⋆g)(x) x^{σ-1} dx` ranges
over.

Identical in shape to `mulConv` (`Square/MulConv.lean`) but with the dilation-by-`x` taken at a real
scale via `dilateTestR` (with `|x| ≤ S`), so it is a function of a real `x`:

    `mulConvR f g x a [lo, w] = ∫_lo^{lo+w} f(x/t) g(t) dt/t = haarIntegral (productTest (reflectTest a
      (dilateTestR x S f)) g)`.

Because every operator it composes lives in `Analysis` (the real-scale `dilateTestR` replaces the
rational `dilateTest`), the whole real-parameter convolution is an `Analysis`-level object.
`mulConvR_nonneg`: non-negative for non-negative `f, g`.

HONEST SCOPE. The real-parameter convolution — the integrand of the (unbuilt) Mellin transform of
`⋆`. It is NOT that transform, NOT the Mellin convolution theorem (Wall 3), and the immediate NEXT
step it enables — that `x ↦ mulConvR f g x` is itself Lipschitz/bounded in `x` (continuity under the
integral sign), so a test the Mellin integral can consume — is unbuilt. Those, and the theorem
`M[f⋆g]=M[f]·M[g]` they lead to, are what would identify `mulConv` values at prime powers with
`weilPrimeGram (vFrom g)`, i.e. step 4 = RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.HaarInterval
import Foundations.F1.Analysis.ReflectTest
import Foundations.F1.Analysis.ProductTest
import Foundations.F1.Analysis.DilateTestR

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The real-parameter multiplicative convolution** `(f ⋆ g)(x) = ∫_lo^{lo+w} f(x/t) g(t) dt/t` at a
    real output point `x` (with `|x| ≤ S`) — `f(x/t)` realized as `reflectTest a (dilateTestR x S f)`
    (dilation-by-the-real-`x` of the reflection), the `dt/t` measure by `haarIntegral`. This is the
    object the Mellin transform of the convolution integrates over. -/
def mulConvR (f g : L2Test) (x : Real) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hxS : Rle (Rabs x) (ofQ S hSd)) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : Real :=
  haarIntegral (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
    a han had lo w hlo hw hwn

/-- **The real-parameter convolution of non-negative tests is non-negative** — the integrand
    `f(x/t)·g(t)·(1/max(t,a)) ≥ 0` is a product of non-negatives. -/
theorem mulConvR_nonneg (f g : L2Test) (x : Real) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hxS : Rle (Rabs x) (ofQ S hSd)) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hf : ∀ y, Rnonneg (f.f y)) (hg : ∀ y, Rnonneg (g.f y)) :
    Rnonneg (mulConvR f g x S hSd hSn hxS a han had lo w hlo hw hwn) :=
  haarIntegral_nonneg (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
    a han had lo w hlo hw hwn (fun t => Rnonneg_Rmul (hf _) (hg t))

end Multiplicity.UOR.Bridge.F1Square.Analysis
