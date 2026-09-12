/-
F1 square — **the convolution as a bounded-Lipschitz test in `x`** (`MulConvRTest.lean`): the
real-parameter convolution `x ↦ (f ⋆ g)(x)`, totalized by clamping `x` into `[0, S]`, bundled as an
`L2Test`. This is the integrand the Mellin transform of `⋆` ranges over.

`mulConvR f g x` is defined only for `|x| ≤ S`; clamping `x` with `qBandQ 0 S` (inert on `[0, S]`,
`1`-Lipschitz) makes a total function, and the three continuity facts assemble through the clamp:
`hlip = mulConvR_lipschitz ∘ qBandQ_lipschitz`, `hbd = mulConvR_abs_le`, `hfc = mulConvR_congr ∘
qBandQ_congr` (the `mulConvR` value is independent of the `|x| ≤ S` proof).

HONEST SCOPE. The convolution packaged as a test in its output variable — the last of the
`x`-continuity data, now concrete. The Mellin transform `∫ (f⋆g)(x)·x^{σ-1} dx` (needs a power-weight
test) and the convolution theorem `M[f⋆g]=M[f]·M[g]` (Wall 3, the deep two-variable/Fubini step) are
still unbuilt; that theorem identifies `mulConv` values at prime powers with `weilPrimeGram (vFrom g)`,
i.e. step 4 = RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.MulConvRLip
import Foundations.F1.Analysis.MulConvRBound
import Foundations.F1.Analysis.MulConvRCongr
import Foundations.F1.Analysis.BandClamp

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- The `[0, S]`-clamp of `x` has `|clamp x| ≤ S` — the totality witness `mulConvR` demands. -/
theorem clampS_absle (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num) (x : Real) :
    Rle (Rabs (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x)) (ofQ S hSd) := by
  have hab : Qle (⟨0, 1⟩ : Q) S := by
    show (0 : Int) * (S.den : Int) ≤ S.num * 1
    rw [Int.zero_mul, Int.mul_one]; exact hSn
  have hzero_le : Rle zero (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) := by
    intro n
    exact Qle_trans ((qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x).den_pos n)
      (qBandQ_ge (⟨0, 1⟩ : Q) S (by decide) hSd hab x n)
      (Qle_self_add (by show (0 : Int) ≤ 2; decide))
  refine Rle_trans (Rle_of_Req (Rabs_of_nonneg (Rnonneg_of_Rle_zero hzero_le))) ?_
  intro n
  exact Qle_trans hSd (qBandQ_le (⟨0, 1⟩ : Q) S (by decide) hSd x n)
    (Qle_self_add (by show (0 : Int) ≤ 2; decide))

/-- **The convolution as a test in `x`**: `(mulConvRTest f g S a [lo,w]).f x = mulConvR f g (clamp x)`,
    a genuine `L2Test` (Lipschitz modulus `w·f.L·M_g·(1/a)²`, bound `w·M_f·M_g·(1/a)`), the integrand
    the Mellin transform of `⋆` consumes on the `x`-window `[0, S]`. -/
def mulConvRTest (f g : L2Test) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (a : Q) (han : 0 < a.num) (had : 0 < a.den)
    (lo w : Q) (hlo : 0 < lo.den) (hw : 0 < w.den) (hwn : 0 ≤ w.num) : L2Test where
  f := fun x => mulConvR f g (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) S hSd hSn
    (clampS_absle S hSd hSn x) a han had lo w hlo hw hwn
  L := mul w (mul (mul f.L (Qinv a)) (mul g.M (Qinv a)))
  M := mul w (mul (mul f.M g.M) (Qinv a))
  hLd := Qmul_den_pos hw (Qmul_den_pos (Qmul_den_pos f.hLd (Qinv_den_pos han))
    (Qmul_den_pos g.hMd (Qinv_den_pos han)))
  hLn := Int.mul_nonneg hwn (Int.mul_nonneg (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had)))
    (Int.mul_nonneg g.hMn (Int.le_of_lt (Qinv_num_pos had))))
  hMd := Qmul_den_pos hw (Qmul_den_pos (Qmul_den_pos f.hMd g.hMd) (Qinv_den_pos han))
  hMn := Int.mul_nonneg hwn (Int.mul_nonneg (Int.mul_nonneg f.hMn g.hMn)
    (Int.le_of_lt (Qinv_num_pos had)))
  hlip := fun x y => Rle_trans
    (mulConvR_lipschitz f g (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x)
      (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd y) S hSd hSn
      (clampS_absle S hSd hSn x) (clampS_absle S hSd hSn y) a han had lo w hlo hw hwn)
    (Rmul_le_Rmul_left (Rnonneg_ofQ (Qmul_den_pos hw (Qmul_den_pos (Qmul_den_pos f.hLd
        (Qinv_den_pos han)) (Qmul_den_pos g.hMd (Qinv_den_pos han))))
      (Int.mul_nonneg hwn (Int.mul_nonneg (Int.mul_nonneg f.hLn (Int.le_of_lt (Qinv_num_pos had)))
        (Int.mul_nonneg g.hMn (Int.le_of_lt (Qinv_num_pos had))))))
      (qBandQ_lipschitz (⟨0, 1⟩ : Q) S (by decide) hSd x y))
  hfc := fun x y hxy => mulConvR_congr f g (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x)
    (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd y) S hSd hSn
    (clampS_absle S hSd hSn x) (clampS_absle S hSd hSn y) a han had lo w hlo hw hwn
    (qBandQ_congr (⟨0, 1⟩ : Q) S (by decide) hSd hxy)
  hbd := fun x => mulConvR_abs_le f g (qBandQ (⟨0, 1⟩ : Q) S (by decide) hSd x) S hSd hSn
    (clampS_absle S hSd hSn x) a han had lo w hlo hw hwn

end Multiplicity.UOR.Bridge.F1Square.Square
