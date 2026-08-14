/-
F1 square — **the Mellin transform is scale-continuous (split-at-depth bound)** (`MellinHatScaleCont.lean`):
the integer-point Mellin transform `mellinHat (dilateTestR c φ) n = ∫₀^∞ φ(c·x)·xⁿ dx` varies continuously
in the REAL dilation scale `c`, assembling the compact moment's Lipschitz bound with the twisted tail's
split-at-depth bound.

For every schedule depth `j`,

    `|mellinHat (dilateTestR c φ) n − mellinHat (dilateTestR c' φ) n|
          ≤ (φ.L + Σ_{m<N_j} φ.L·(m+2)·(powWinTest m n).M) · |c − c'|  +  4/(j+1)`,

where `N_j = digammaMidx (C·2ⁿ) j`. As `j → ∞` and `c' → c` the right-hand side → 0.

WHY (rung 6, the full Mellin scale-continuity). `mellinHat = mellinMoment + twTail`. The compact moment
is `φ.L`-Lipschitz in the scale (`mellinMoment_scale_lipschitz`); the tail obeys the split-at-depth
bound (`twTail_scale_split`, whose tail-beyond-depth remainder is the uniform Bishop-limit rate, needing
no uniform-decay hypothesis). Splitting `mellinHat(c) − mellinHat(c')` into the moment difference plus
the tail difference (`Rsub_Radd_Radd`, triangle `Rabs_Radd`) and factoring the common `|c−c'|`
(`Rmul_distrib_right`) gives the combined estimate. This is the scale-continuity engine the real-scale
dilation covariance capstone consumes: the rational-scale covariance
(`mellinHat_dilate_covariance_uncond`, read in `dilateTestR` form by `mellinHat_bridge`) passed to the
limit `q_k → c`.

HONEST SCOPE. The split-at-depth scale-continuity estimate for the Mellin transform only. It builds NO
real-scale covariance (that is the capstone: approximate `c` by rationals, apply the rational covariance,
pass to the limit through this continuity), NO factorization, NO half-line assembly, NO positivity, NO
determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.TwTailScaleCont
import Multiplicity.F1Square.Square.MellinMomentScaleLip

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The Mellin transform is scale-continuous (split-at-depth bound).** For real scales `c, c'` each
    bounded by the rational `S`, decay data `hdec_c`/`hdec_c'`, and every schedule depth `j`,

      `|mellinHat (dilateTestR c φ) n − mellinHat (dilateTestR c' φ) n|
            ≤ (φ.L + Σ_{m<N_j} φ.L·(m+2)·(powWinTest m n).M)·|c − c'| + 4/(j+1)`,   `N_j = digammaMidx (C·2ⁿ) j`.

    `mellinHat = mellinMoment + twTail`: the moment difference is `φ.L`-Lipschitz
    (`mellinMoment_scale_lipschitz`), the tail difference obeys `twTail_scale_split`; `Rsub_Radd_Radd` +
    `Rabs_Radd` split the sum and `Rmul_distrib_right` factors the common `|c−c'|`. As `j → ∞`, `c' → c`
    the bound → 0. The scale-continuity engine the real-scale covariance capstone passes to the limit. -/
theorem mellinHat_scale_split (φ : L2Test) (n : Nat)
    (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c c' : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) (hc'S : Rle (Rabs c') (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_c : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR c S hSd hSn hcS φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hdec_c' : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR c' S hSd hSn hc'S φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (j : Nat) :
    Rle (Rabs (Rsub (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c)
                    (mellinHat (dilateTestR c' S hSd hSn hc'S φ) n hCd hCn hdec_c')))
        (Radd
          (Rmul (Radd (ofQ φ.L φ.hLd)
                  (genSum (fun m => ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
                    (Qmul_den_pos (Qmul_den_pos φ.hLd Nat.one_pos) (powWinTest m n).hMd))
                    (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)))
            (Rabs (Rsub c c')))
          (ofQ (⟨4, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_Radd_Radd _ _ _ _))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Rle_trans (Radd_le_add
    (mellinMoment_scale_lipschitz φ n S hSd hSn c c' hcS hc'S)
    (twTail_scale_split φ n S hSd hSn c c' hcS hc'S hCd hCn hdec_c hdec_c' j)) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
  exact Radd_congr (Req_symm (Rmul_distrib_right (ofQ φ.L φ.hLd) _ _)) (Req_refl _)

end Multiplicity.UOR.Bridge.F1Square.Square
