/-
F1 square — **the pointwise difference bound of the real-parameter convolution integrand**
(`MulConvRDiff.lean`): `|P_x(y) − P_{x'}(y)| ≤ (f.L·M_g·(1/a)²)·|x − x'|`, uniformly in `y` — the
Lipschitz-in-`x` estimate at the integrand level, from which the continuity of `mulConvR` in `x`
(continuity under the integral sign) follows by the window bound.

The convolution integrand is `P_x(y) = f(x·(1/max(y,a)))·g(y)·(1/max(y,a))`. Its `x`-difference
factors — `c = 1/max(y,a)` pulls out twice, `g(y)` once — leaving `|f(x·c) − f(x'·c)| ≤ f.L·|c|·|x−x'|`
(the slope-`f.L` Lipschitz of `f`), and each `|c| ≤ 1/a`. The product of the three bounds is the
stated coefficient `C = f.L·(1/a)·M_g·(1/a)`, independent of `y`.

HONEST SCOPE. The pointwise integrand estimate only — a bounded-Lipschitz fact, no positivity, no
crux claim. It feeds the Lipschitz-in-`x` continuity of `mulConvR`, which feeds the `x`-test, the
Mellin transform, and finally the convolution theorem `M[f⋆g]=M[f]·M[g]` (Wall 3, still unbuilt); that
last is what would identify `mulConv` values at prime powers with `weilPrimeGram (vFrom g)`, i.e.
step 4 = RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Analysis.MulConvR

namespace Multiplicity.UOR.Bridge.F1Square.Analysis

/-- **The pointwise `x`-difference bound of the convolution integrand** — for every `y`,
    `|P_x(y) − P_{x'}(y)| ≤ ofQ(f.L·(1/a)·M_g·(1/a))·|x − x'|`, where
    `P_x(y) = (productTest (reflectTest a (dilateTestR x S f)) g).f y · (recipTest a).f y`. The
    coefficient is independent of `y` and of `x, x'`. -/
theorem mulConvR_integrand_diff (f g : L2Test) (x x' : Real) (S : Q) (hSd : 0 < S.den)
    (hSn : 0 ≤ S.num) (hxS : Rle (Rabs x) (ofQ S hSd)) (hx'S : Rle (Rabs x') (ofQ S hSd))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (y : Real) :
    Rle (Rabs (Rsub
          (Rmul ((productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g).f y)
                ((recipTest a han had).f y))
          (Rmul ((productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g).f y)
                ((recipTest a han had).f y))))
        (Rmul (ofQ (mul (mul f.L (Qinv a)) (mul g.M (Qinv a)))
              (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
                (Qmul_den_pos g.hMd (Qinv_den_pos han))))
          (Rabs (Rsub x x'))) := by
  -- `c = (recipTest a).f y` and its bound `|c| ≤ 1/a`.
  have hc : Rle (Rabs ((recipTest a han had).f y)) (ofQ (Qinv a) (Qinv_den_pos han)) :=
    (recipTest a han had).hbd y
  -- The `f`-argument difference: `|f(x·c) − f(x'·c)| ≤ ofQ(f.L·(1/a))·|x − x'|`.
  have harg : Rle (Rabs (Rsub (f.f (Rmul x ((recipTest a han had).f y)))
        (f.f (Rmul x' ((recipTest a han had).f y)))))
      (Rmul (ofQ (mul f.L (Qinv a)) (Qmul_den_pos f.hLd (Qinv_den_pos han)))
        (Rabs (Rsub x x'))) := by
    have hinner : Rle (Rabs (Rsub (Rmul x ((recipTest a han had).f y))
          (Rmul x' ((recipTest a han had).f y))))
        (Rmul (ofQ (Qinv a) (Qinv_den_pos han)) (Rabs (Rsub x x'))) := by
      refine Rle_trans (Rle_of_Req (Req_trans
        (Rabs_congr (Req_symm (Rmul_sub_distrib_right x x' ((recipTest a han had).f y))))
        (Rabs_Rmul (Rsub x x') ((recipTest a han had).f y)))) ?_
      exact Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs (Rsub x x')) hc)
        (Rle_of_Req (Rmul_comm (Rabs (Rsub x x')) (ofQ (Qinv a) (Qinv_den_pos han))))
    refine Rle_trans (f.hlip (Rmul x ((recipTest a han had).f y))
      (Rmul x' ((recipTest a han had).f y))) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ f.hLd f.hLn) hinner) (Rle_of_Req ?_)
    exact Req_trans (Req_symm (Rmul_assoc (ofQ f.L f.hLd) (ofQ (Qinv a) (Qinv_den_pos han))
      (Rabs (Rsub x x')))) (Rmul_congr (Rmul_ofQ_ofQ f.hLd (Qinv_den_pos han)) (Req_refl _))
  -- Factor the integrand difference: `P_x − P_{x'} = ((f(x·c) − f(x'·c))·g(y))·c`, then bound each.
  refine Rle_trans (Rle_of_Req (Req_trans (Rabs_congr
      (Req_symm (Rmul_sub_distrib_right
        ((productTest (reflectTest a han had (dilateTestR x S hSd hSn hxS f)) g).f y)
        ((productTest (reflectTest a han had (dilateTestR x' S hSd hSn hx'S f)) g).f y)
        ((recipTest a han had).f y))))
      (Rabs_Rmul _ ((recipTest a han had).f y)))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr
      (Req_trans (Rabs_congr (Req_symm (Rmul_sub_distrib_right
        (f.f (Rmul x ((recipTest a han had).f y)))
        (f.f (Rmul x' ((recipTest a han had).f y))) (g.f y))))
        (Rabs_Rmul _ (g.f y))) (Req_refl _))) ?_
  -- Now bound: `(|f(x·c)−f(x'·c)|·|g|)·|c| ≤ ((ofQ(f.L/a)·|x−x'|)·ofQ M_g)·ofQ(1/a)`.
  refine Rle_trans (Rmul_le_Rmul_both
      (Rnonneg_Rmul (Rnonneg_Rabs _) (Rnonneg_Rabs _))
      (Rnonneg_ofQ (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had)))
      (Rmul_le_Rmul_both (Rnonneg_Rabs _) (Rnonneg_ofQ g.hMd g.hMn) harg (g.hbd y)) hc)
    (Rle_of_Req ?_)
  -- `((ofQ P·R)·ofQ M_g)·ofQ(1/a) ≈ ofQ(P·(M_g·(1/a)))·R`   (collect the constants, keep `R = |x−x'|`).
  refine Req_trans (Rmul_assoc (Rmul (ofQ (mul f.L (Qinv a))
    (Qmul_den_pos f.hLd (Qinv_den_pos han))) (Rabs (Rsub x x'))) (ofQ g.M g.hMd)
    (ofQ (Qinv a) (Qinv_den_pos han))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_ofQ_ofQ g.hMd (Qinv_den_pos han))) ?_
  refine Req_trans (Rmul_assoc (ofQ (mul f.L (Qinv a)) (Qmul_den_pos f.hLd (Qinv_den_pos han)))
    (Rabs (Rsub x x')) (ofQ (mul g.M (Qinv a)) (Qmul_den_pos g.hMd (Qinv_den_pos han)))) ?_
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_comm (Rabs (Rsub x x'))
    (ofQ (mul g.M (Qinv a)) (Qmul_den_pos g.hMd (Qinv_den_pos han))))) ?_
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (mul f.L (Qinv a))
    (Qmul_den_pos f.hLd (Qinv_den_pos han)))
    (ofQ (mul g.M (Qinv a)) (Qmul_den_pos g.hMd (Qinv_den_pos han))) (Rabs (Rsub x x')))) ?_
  exact Rmul_congr (Rmul_ofQ_ofQ (Qmul_den_pos f.hLd (Qinv_den_pos han))
    (Qmul_den_pos g.hMd (Qinv_den_pos han))) (Req_refl _)

end Multiplicity.UOR.Bridge.F1Square.Analysis
