/-
F1 square — **congruence-in-`x` of the real-parameter convolution** (`MulConvRCongr.lean`):
`x ≈ x' ⟹ mulConvR f g x ≈ mulConvR f g x'` — the third continuity datum (with the uniform bound
`mulConvR_abs_le` and the Lipschitz estimate `mulConvR_lipschitz`) needed to bundle
`x ↦ mulConvR f g x` as a bounded-Lipschitz test.

`x ≈ x'` makes the two convolution integrands pointwise-equal (`f(x·c)·g·c ≈ f(x'·c)·g·c` through
`f.hfc`), and both integrals share the (`x`-independent) modulus, so `riemannIntegralI_congr` closes it.

HONEST SCOPE. The congruence datum only; a bounded-Lipschitz fact, no positivity, no crux claim. It
completes the data for the `x`-test but the Mellin transform of `⋆` and the convolution theorem
`M[f⋆g]=M[f]·M[g]` (Wall 3) are still unbuilt — that theorem is what identifies `mulConv` values at
prime powers with `weilPrimeGram (vFrom g)`, i.e. step 4 = RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.MulConvR

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **Congruence-in-`x`**: `x ≈ x' ⟹ mulConvR f g x ≈ mulConvR f g x'`. The integrands agree
    pointwise (`f`'s congruence through the scale) and share the `x`-independent modulus. -/
theorem mulConvR_congr (f g : L2Test) (x x' : Real) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hxS : Rle (Rabs x) (ofQ S hSd)) (hx'S : Rle (Rabs x') (ofQ S hSd))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) (hxx' : Req x x') :
    Req (mulConvR f g x S hSd hSn hxS a han had lo w hlo hw hwn)
        (mulConvR f g x' S hSd hSn hx'S a han had lo w hlo hw hwn) :=
  riemannIntegralI_congr
    (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g)
      (recipTest a han had))
    lo w hlo hw hwn
    (fun y => Rmul_congr (Rmul_congr
      (f.hfc _ _ (Rmul_congr hxx' (Req_refl ((recipTest a han had).f y)))) (Req_refl (g.f y)))
      (Req_refl ((recipTest a han had).f y)))

end Multiplicity.UOR.Bridge.F1Square.Analysis
