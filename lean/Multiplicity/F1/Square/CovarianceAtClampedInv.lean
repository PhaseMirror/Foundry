/-
F1 square — **the dilation covariance at the reconstruction scale `c = clampedInv(a,t)`**
(`CovarianceAtClampedInv.lean`): the real-scale covariance `mellinHat_dilate_covariance_real_ge1`
instantiated at the genuine window scale `c = clampedInv(a, affineMap lo w s) = 1/max(t,a) ≥ 1`, with
all of its hypotheses discharged from the tail commute's own data — so the output matches, term for
term, the `mellinHat(dilateTestR (clampedInv …) …)` that `convTwTail_eq_intTail`'s `hU` reads:

    `clampedInv(a,t)ⁿ⁺¹ · mellinHat (dilateTestR (clampedInv a t) f) n  =  mellinHat f n`.

WHY (grounding `v = ĝ`). `covConnect_pure` needs the covariance `cⁿ⁺¹·(mom+tw) = M` at the genuine
`c = clampedInv(a,t)`. This file supplies it: `c ≥ 1` on the window (`window_clampedInv_ge_one`),
`c ≤ 1/a = Qinv a` (`recipTest.hbd`), `Qinv a ≥ 1` (`Qinv_antitone` from `a ≤ 1`), the `c`-window decay
is exactly the `dilateTestR_window_hdec` the tail commute already carries, and `mellinHat f` reads at
the clean-to-window decay `hdec_window_of_hfdec`. The Mellin data therefore matches `hU` verbatim.

HONEST SCOPE. Object-grounding substrate — the covariance at the genuine reconstruction scale, the
`hcov` slot of `covConnect_pure`. It supplies NO `U` (the head/moment tests), builds NO factorization
`M[f⋆g]=M[f]·M[g]`, grounds NO `v = ĝ`, and — emphatically — applies NO step-4 band-coupling positivity
(`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.MellinHatDilateCovarianceRealGe1
import Multiplicity.F1Square.Square.DilateTestRDecay
import Multiplicity.F1Square.Square.DilTailUniformBound
import Multiplicity.F1Square.Analysis.HaarInterval

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- `1 ≤ 1/a` for `0 < a.num` and `a ≤ 1` (`Qinv` is antitone; `Qinv ⟨1,1⟩ = ⟨1,1⟩`). -/
private theorem one_le_Qinv {a : Q} (han : 0 < a.num) (ha1 : Qle a (⟨1, 1⟩ : Q)) :
    Qle (⟨1, 1⟩ : Q) (Qinv a) :=
  Qinv_antitone (by decide) han ha1

/-- **The dilation covariance at `c = clampedInv(a,t)`.** For a window point `t = affineMap lo w s`
    (`s ∈ [0,1]`), the covariance `clampedInv(a,t)ⁿ⁺¹·mellinHat(dilateTestR (clampedInv a t) f) =
    mellinHat f`, with every hypothesis of `mellinHat_dilate_covariance_real_ge1` discharged from the
    tail commute's data. The Mellin term matches `convTwTail_eq_intTail`'s `hU` verbatim. -/
theorem covariance_at_clampedInv (f : L2Test) (n : Nat) {Cf : Q}
    (hCfd : 0 < Cf.den) (hCfn : 0 ≤ Cf.num)
    (hfdec : ∀ (k : Nat), ∀ y, Rle (ofQ (⟨(k : Int) + 1, 1⟩ : Q) Nat.one_pos) (Rabs y) →
      Rle (Rabs (f.f y)) (ofQ (mul Cf (⟨1, (k + 1) ^ (n + 2)⟩ : Q))
        (Qmul_den_pos hCfd (Nat.pos_pow_of_pos _ (Nat.succ_pos k)))))
    (a : Q) (han : 0 < a.num) (had : 0 < a.den) (ha1 : Qle a (⟨1, 1⟩ : Q))
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num)
    (hw1 : Qle (add lo w) (⟨1, 1⟩ : Q))
    (s : Real) (h1 : Rle s one) :
    Req (Rmul (Rpow (clampedInv a han had (affineMap lo w hlo hw s)) (n + 1))
          (mellinHat (dilateTestR (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
              (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
              ((recipTest a han had).hbd (affineMap lo w hlo hw s)) f)
            n hCfd hCfn
            (dilateTestR_window_hdec f n hCfd hCfn hfdec
              (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
              (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
              ((recipTest a han had).hbd (affineMap lo w hlo hw s))
              (window_clampedInv_ge_one a han had ha1 lo w hlo hw hwn hw1 s h1))))
        (mellinHat f n hCfd hCfn (hdec_window_of_hfdec f n hCfd hCfn hfdec)) :=
  mellinHat_dilate_covariance_real_ge1 f n (Qinv a) (Qinv_den_pos han)
    (Int.le_of_lt (Qinv_num_pos had)) (one_le_Qinv han ha1)
    (clampedInv a han had (affineMap lo w hlo hw s))
    ((recipTest a han had).hbd (affineMap lo w hlo hw s))
    (window_clampedInv_ge_one a han had ha1 lo w hlo hw hwn hw1 s h1)
    hCfd hCfn
    (dilateTestR_window_hdec f n hCfd hCfn hfdec
      (clampedInv a han had (affineMap lo w hlo hw s)) (Qinv a)
      (Qinv_den_pos han) (Int.le_of_lt (Qinv_num_pos had))
      ((recipTest a han had).hbd (affineMap lo w hlo hw s))
      (window_clampedInv_ge_one a han had ha1 lo w hlo hw hwn hw1 s h1))
    (hdec_window_of_hfdec f n hCfd hCfn hfdec)
    hfdec

end Multiplicity.UOR.Bridge.F1Square.Square
