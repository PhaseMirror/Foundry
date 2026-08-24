/-
F1 square — **the Mellin pairing of the convolution** (`MellinConv.lean`): `∫ (f ⋆ g)(x)·ψ(x) dx`
over the `x`-window, the pairing of the (now test-valued) convolution against a weight `ψ` — the object
the Mellin transform `M[f⋆g](s) = ∫ (f⋆g)(x)·x^{s-1} dx` and the convolution theorem are about (the
transform is the special case `ψ = x^{s-1}`).

Because `x ↦ (f ⋆ g)(x)` is now a genuine `L2Test` (`mulConvRTest`), its pairing against any weight test
`ψ` is just the interval `L²` pairing `innerIonI`:

    `mellinConv f g ψ = ∫_{xlo}^{xlo+xw} (f ⋆ g)(x)·ψ(x) dx`.

`mellinConv_nonneg`: for non-negative `f, g, ψ` the pairing is `≥ 0` — the positivity structure the
autocorrelation (`g ⋆ g^τ`) carries into its transform.

HONEST SCOPE. The Mellin pairing OBJECT and its density-level positivity. It is NOT the evaluation of
the transform against a specific power weight `x^{s-1}` (needs a power-weight test, unbuilt), and NOT
the convolution theorem `M[f⋆g]=M[f]·M[g]` (Wall 3, the deep two-variable/Fubini step). That theorem is
what identifies `mulConv` values at prime powers with `weilPrimeGram (vFrom g)`, i.e. step 4 = RH. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MulConvRTest
import Multiplicity.F1.Analysis.MulConvR

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The Mellin pairing of the convolution** `mellinConv f g ψ = ∫_{xlo}^{xlo+xw} (f⋆g)(x)·ψ(x) dx` —
    the interval `L²` pairing of the test-valued convolution `mulConvRTest` against a weight `ψ`. The
    Mellin transform `M[f⋆g](s)` is the special case `ψ = x^{s-1}`. -/
def mellinConv (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num) :
    Real :=
  innerIonI (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) ψ xlo xw hxlo hxw hxwn

/-- **The Mellin pairing of a non-negative convolution against a non-negative weight is non-negative**
    — the integrand `(f⋆g)(x)·ψ(x)` is a product of non-negatives (`mulConvR_nonneg` for the
    convolution factor). This is the sign the autocorrelation's transform inhabits. -/
theorem mellinConv_nonneg (f g ψ : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den)
    (hwn : 0 ≤ w.num) (xlo xw : Q) (hxlo : 0 < xlo.den) (hxw : 0 < xw.den) (hxwn : 0 ≤ xw.num)
    (hf : ∀ y, Rnonneg (f.f y)) (hg : ∀ y, Rnonneg (g.f y)) (hψ : ∀ y, Rnonneg (ψ.f y)) :
    Rnonneg (mellinConv f g ψ S hSd hSn a han had lo w hlo hw hwn xlo xw hxlo hxw hxwn) :=
  riemannIntegralI_nonneg
    (l2L_den (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) ψ)
    (l2L_num (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) ψ)
    (l2lip (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) ψ)
    (l2fc (mulConvRTest f g S hSd hSn a han had lo w hlo hw hwn) ψ)
    (fun x => Rnonneg_Rmul
      (mulConvR_nonneg f g (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) S hSd hSn
        (clampS_absle S hSd hSn x) a han had lo w hlo hw hwn hf hg) (hψ x))
    xlo xw hxlo hxw hxwn

end Multiplicity.UOR.Bridge.F1Square.Square
