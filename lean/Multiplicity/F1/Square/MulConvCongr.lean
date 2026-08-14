/-
F1 square — **congruence of the multiplicative convolution in its second argument**
(`MulConvCongr.lean`): if two tests agree on the integration window, their convolutions with a fixed
`f` agree. This is the reusable tool that turns the **self-dual** symmetry `reflectTest a g ≈ g` (on
the window) into the autocorrelation identity `g ⋆ g^τ ≈ g ⋆ g` WITHOUT a change of variables.

    `(∀ y∈[lo,lo+w], g(y) ≈ g'(y))  ⟹  mulConv f g x ≈ mulConv f g' x`.

WHY (the self-dual arm). `mulConv f g x = ∫_lo^{lo+w} f(x/t)·g(t) dt/t`, an integral in which `g` enters
only through the integrand's value on `[lo,lo+w]`. So window-only agreement of the second factor
suffices for the convolutions to agree. For a self-dual test (`reflectTest a g ≈ g` on the window,
`selfDualTest`), this gives `mulConv g (reflectTest a g) ≈ mulConv g g` — the autocorrelation of a
self-dual test IS the plain self-convolution, reached by congruence, not by the nonlinear reciprocal
change-of-variables (which the general, non-self-dual case would require).

The proof is one application of `riemannIntegralI_congr_unit_mod` (the window-only, different-moduli
interval congruence): `mulConv f · x` unfolds definitionally to `riemannIntegralI` of the integrand
`(f(x/t)··(t))·(1/max(t,a))`, in which only the middle factor changes, so the integrands agree on the
window from the second-factor agreement (`Rmul_congr` twice, endpoints reflexive).

HONEST SCOPE. Second-argument window-congruence of `mulConv`. It is NOT the reflected Mellin moment,
NOT the autocorrelation identification `weilPrimeGram (vHat g) = weilPrimePart(g_i ⋆ g_j^τ)`, and
applies NO step-4 positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MulConv
import Multiplicity.F1Square.Square.TwTermPowBand

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The multiplicative convolution is a window-congruence in its second argument**: if `g` and `g'`
    agree on the integration window `[lo, lo+w]`, then `mulConv f g x ≈ mulConv f g' x` — `g` enters
    only through the integrand's window values. One `riemannIntegralI_congr_unit_mod`; the integrands
    `(f(x/t)·g(t))·(1/max(t,a))` and `(f(x/t)·g'(t))·(1/max(t,a))` agree on the window from the
    second-factor agreement. This turns self-duality into the autocorrelation-is-self-convolution
    identity without any change of variables. -/
theorem mulConv_congr_right (f g g' : L2Test) (x : Q) (hxn : 0 < x.num) (hxd : 0 < x.den)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hgg' : ∀ y, Rle zero y → Rle y one →
      Req (g.f (affineMap lo w hlo hw y)) (g'.f (affineMap lo w hlo hw y))) :
    Req (mulConv f g x hxn hxd a han had lo w hlo hw hwn)
        (mulConv f g' x hxn hxd a han had lo w hlo hw hwn) := by
  let A := reflectTest a han had (dilateTest x hxn hxd f)
  refine riemannIntegralI_congr_unit_mod
    (l2L_den (productTest A g) (recipTest a han had)) (l2L_num (productTest A g) (recipTest a han had))
    (l2lip (productTest A g) (recipTest a han had)) (l2fc (productTest A g) (recipTest a han had))
    (l2L_den (productTest A g') (recipTest a han had)) (l2L_num (productTest A g') (recipTest a han had))
    (l2lip (productTest A g') (recipTest a han had)) (l2fc (productTest A g') (recipTest a han had))
    lo w hlo hw hwn ?_
  intro y h0 h1
  exact Rmul_congr (Rmul_congr (Req_refl (A.f (affineMap lo w hlo hw y))) (hgg' y h0 h1))
    (Req_refl ((recipTest a han had).f (affineMap lo w hlo hw y)))

end Multiplicity.UOR.Bridge.F1Square.Square
