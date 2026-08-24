/-
F1 square — **the covariance combination is scale-continuous** (`CovCombScaleCont.lean`): the object
`F(c) = cⁿ⁺¹ · mellinHat (dilateTestR c φ) n` — whose value the real-scale dilation covariance asserts
is the constant `mellinHat φ n` — varies continuously in the REAL dilation scale `c`, with a
split-at-depth estimate.

For every schedule depth `j`,

    `|F(c) − F(c')|  ≤  Sⁿ⁺¹·((φ.L + head_j)·|c−c'| + 4/(j+1))  +  Bφ·((n+1)·Sⁿ·|c−c'|)`,

where `head_j = Σ_{m<N_j} φ.L·(m+2)·(powWinTest m n).M`, `N_j = digammaMidx(C·2ⁿ) j`, and `Bφ` is the
finite scale-independent Mellin magnitude bound (`mellinHat_abs_le`). As `j → ∞` and `c' → c` the
right-hand side → 0, so `F` is continuous in `c`.

WHY (rung 6, the last continuity step before the real-scale covariance). `F(c) − F(c')` splits by the
mixed-product identity into `cⁿ⁺¹·(M_c − M_c') + (cⁿ⁺¹ − c'ⁿ⁺¹)·M_c'`; the first is bounded by
`|cⁿ⁺¹| ≤ Sⁿ⁺¹` times the Mellin scale-continuity `mellinHat_scale_split`, the second by the
polynomial base-Lipschitz `Rpow_base_lip` times the Mellin magnitude bound `mellinHat_abs_le`. This is
the continuity that, combined with `F` being constant on the rationals (`covariance_at_rational_dilateTestR`)
and the density of the rationals, forces `F(c) = mellinHat φ n` at every real `c` — the real-scale
covariance capstone.

HONEST SCOPE. The split-at-depth scale-continuity of the covariance combination `F` only. It builds NO
real-scale covariance (that is the capstone: `F` continuous + constant on rationals ⟹ `F(c) = mellinHat φ`),
NO factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the
crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinHatBound
import Multiplicity.F1.Square.MellinHatScaleCont
import Multiplicity.F1.Analysis.RpowBaseLip
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

-- local re-derivations of the two RpowBaseLip privates
private theorem Rpow_abs_le_loc {x : Real} {B : Q} (hBd : 0 < B.den) (hBn : 0 ≤ B.num)
    (hxB : Rle (Rabs x) (ofQ B hBd)) :
    ∀ k, Rle (Rabs (Rpow x k)) (ofQ (qpow B k) (qpow_den_pos hBd k))
  | 0 => Rle_of_Req (Rabs_of_nonneg Rnonneg_one)
  | (k + 1) => by
      show Rle (Rabs (Rmul x (Rpow x k))) (ofQ (qpow B (k + 1)) (qpow_den_pos hBd (k + 1)))
      refine Rle_trans (Rle_of_Req (Rabs_Rmul x (Rpow x k))) ?_
      refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs (Rpow x k)) hxB) ?_
      refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ hBd hBn) (Rpow_abs_le_loc hBd hBn hxB k)) ?_
      exact Rle_of_Req (Rmul_ofQ_ofQ hBd (qpow_den_pos hBd k))

private theorem mixed_id_loc (x y Px Py : Real) :
    Req (Rsub (Rmul x Px) (Rmul y Py))
        (Radd (Rmul x (Rsub Px Py)) (Rmul (Rsub x y) Py)) := by
  refine Req_symm ?_
  refine Req_trans (Radd_congr (Rmul_sub_distrib x Px Py) (Rmul_sub_distrib_right x y Py)) ?_
  exact Req_trans (Radd_comm _ _) (Radd_Rsub_Rsub (Rmul x Py) (Rmul y Py) (Rmul x Px))

/-- Continuity of the covariance combination F(c) = cⁿ⁺¹·mellinHat(dilateTestR c φ). -/
theorem covComb_scale_split (φ : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
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
    Rle (Rabs (Rsub
          (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
          (Rmul (Rpow c' (n + 1)) (mellinHat (dilateTestR c' S hSd hSn hc'S φ) n hCd hCn hdec_c'))))
        (Radd
          (Rmul (ofQ (qpow S (n + 1)) (qpow_den_pos hSd (n + 1)))
            (Radd
              (Rmul (Radd (ofQ φ.L φ.hLd)
                      (genSum (fun m => ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
                        (Qmul_den_pos (Qmul_den_pos φ.hLd Nat.one_pos) (powWinTest m n).hMd))
                        (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)))
                (Rabs (Rsub c c')))
              (ofQ (⟨4, j + 1⟩ : Q) (Nat.succ_pos j))))
          (Rmul
            (Radd (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n)))
              (Radd (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
                      (Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)))
                      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
                    (ofQ (⟨2, 1⟩ : Q) (by decide))))
            (Rmul (ofQ (mul (⟨(n : Int) + 1, 1⟩ : Q) (qpow S n))
                    (Qmul_den_pos Nat.one_pos (qpow_den_pos hSd n)))
              (Rabs (Rsub c c'))))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr (mixed_id_loc (Rpow c (n + 1)) (Rpow c' (n + 1))
    (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c)
    (mellinHat (dilateTestR c' S hSd hSn hc'S φ) n hCd hCn hdec_c')))) ?_
  refine Rle_trans (Rabs_Radd _ _) ?_
  refine Radd_le_add ?_ ?_
  · -- |Rpow c^{n+1} · (M_c − M_c')| ≤ ofQ(qpow S (n+1)) · (scale-split bound)
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _) (Rpow_abs_le_loc hSd hSn hcS (n + 1))) ?_
    exact Rmul_le_Rmul_left (Rnonneg_ofQ (qpow_den_pos hSd (n + 1)) (qpow_nonneg hSn (n + 1)))
      (mellinHat_scale_split φ n S hSd hSn c c' hcS hc'S hCd hCn hdec_c hdec_c' j)
  · -- |(Rpow c^{n+1} − Rpow c'^{n+1}) · M_c'| ≤ (mellinHat bound) · (Rpow-lip bound)
    refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_Rabs _)
      (mellinHat_abs_le φ n S hSd hSn c' hc'S hCd hCn hdec_c')) ?_
    refine Rle_trans (Rmul_le_Rmul_right ?_ (Rpow_base_lip hSd hSn hcS hc'S n)) ?_
    · exact Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_Rabs _))
        (mellinHat_abs_le φ n S hSd hSn c' hc'S hCd hCn hdec_c'))
    · exact Rle_of_Req (Rmul_comm _ _)

end Multiplicity.UOR.Bridge.F1Square.Square
