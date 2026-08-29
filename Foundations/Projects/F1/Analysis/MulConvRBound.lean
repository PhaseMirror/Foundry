/-
F1 square — **the real-parameter convolution is uniformly bounded in `x`** (`MulConvRBound.lean`): the
first half of "`x ↦ mulConvR f g x` is a test the Mellin integral can consume".

`mulConvR f g x = haarIntegral (productTest (reflectTest a (dilateTestR x S f)) g)` unfolds to a
certified interval integral whose integrand `f(x/t)·g(t)·(1/max(t,a))` is bounded on the window by
`M_f·M_g·(1/a)` — a rational INDEPENDENT of `x` (the reflection/dilation preserve the bound `M_f`,
`g` is bounded by `M_g`, the clamped density by `1/a`). So the window bound `riemannIntegralI_abs_le_window`
gives

    `|mulConvR f g x|  ≤  w · (M_f·M_g·(1/a))`     for every real `x`.

This is the uniform boundedness `hbd` needed to bundle `x ↦ mulConvR f g x` as an `L2Test` (the
integrand of the Mellin transform of `⋆`).

HONEST SCOPE. The uniform bound only. The Lipschitz-in-`x` half (continuity under the integral sign,
via the pointwise `f.L·M_g/a`-bound on the difference), the resulting `x`-test, the Mellin transform,
and the convolution theorem `M[f⋆g]=M[f]·M[g]` (Wall 3) are all still unbuilt — and the last is what
would identify `mulConv` values at prime powers with `weilPrimeGram (vFrom g)`, i.e. step 4 = RH. The
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Analysis.MulConvR
import Foundations.F1.Analysis.MellinDecay

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The real-parameter convolution is uniformly bounded in `x`**: `|mulConvR f g x| ≤ w·(M_f·M_g·(1/a))`
    for every real `x` — the window bound applied to the integrand `f(x/t)·g(t)·(1/max(t,a))`, whose
    pointwise bound `M_f·M_g·(1/a)` is independent of `x`. -/
theorem mulConvR_abs_le (f g : L2Test) (x : Real) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (hxS : Rle (Rabs x) (ofQ S hSd)) (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) :
    Rle (Rabs (mulConvR f g x S hSd hSn hxS a han had lo w hlo hw hwn))
        (ofQ (mul w (mul (mul f.M g.M) (Qinv a)))
          (Qmul_den_pos hw (Qmul_den_pos (Qmul_den_pos f.hMd g.hMd) (Qinv_den_pos han)))) :=
  riemannIntegralI_abs_le_window
    (l2L_den (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2L_num (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2lip (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    (l2fc (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g)
      (recipTest a han had))
    lo w (mul (mul f.M g.M) (Qinv a)) hlo hw hwn
    (Qmul_den_pos (Qmul_den_pos f.hMd g.hMd) (Qinv_den_pos han))
    (fun t _ _ => Rle_trans
      (Rle_of_Req (Rabs_Rmul
        ((productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g).f
          (affineMap lo w hlo hw t))
        ((recipTest a han had).f (affineMap lo w hlo hw t))))
      (Rle_trans
        (Rmul_le_Rmul_both (Rnonneg_Rabs _)
          (Rnonneg_ofQ (recipTest a han had).hMd (recipTest a han had).hMn)
          ((productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g).hbd
            (affineMap lo w hlo hw t))
          ((recipTest a han had).hbd (affineMap lo w hlo hw t)))
        (Rle_of_Req (Rmul_ofQ_ofQ
          (productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g).hMd
          (recipTest a han had).hMd))))

end Multiplicity.UOR.Bridge.F1Square.Analysis
