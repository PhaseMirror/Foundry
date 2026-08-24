/-
F1 square — **the Mellin transform has a bounded magnitude, uniformly in the dilation scale**
(`MellinHatBound.lean`): a finite, scale-INDEPENDENT bound on `|mellinHat (dilateTestR c φ) n|`.

    `|mellinHat (dilateTestR c φ) n|  ≤  φ.M/(n+1)  +  (Σ_{m<N₀} φ.M·(powWinTest m n).M)  +  2`,

where `N₀ = digammaMidx (C·2ⁿ) 0` is the zeroth schedule depth. The bound depends only on `φ.M`, `C`,
and `n` — NOT on the real scale `c` (because `dilateTestR c φ` has `.M = φ.M`, scale-independent).

WHY (rung 6, the magnitude bound the covariance capstone's F-continuity multiplies against). The
capstone shows `F(c) = cⁿ⁺¹·mellinHat(dilateTestR c φ)` is continuous by the product estimate
`|F(c) − F(c')| ≤ |cⁿ⁺¹ − c'ⁿ⁺¹|·|M_c| + |c'ⁿ⁺¹|·|M_c − M_c'|`; the first term needs a finite bound on
`|M_c| = |mellinHat(dilateTestR c φ)|`, which this supplies. The proof is deliberately CRUDE — no decay,
no telescoping: the compact moment is `mellinMoment_abs_le` (`φ.M/(n+1)`, scale-independent), and the
tail `twTail` is `Rlim` of partial sums, so `|twTail| ≤ |0th partial sum| + 2` by the uniform
Bishop-limit rate (`Rabs_dist_Rlim` at `j = 0`), and the 0th partial sum (a FINITE `N₀`-term sum) is
bounded term-by-term by the window bound `|twTerm m| ≤ φ.M·(powWinTest m n).M` (`twTerm_crude_bound`, via
`riemannIntegralI_abs_le_window`). The per-window constant growing with `m` is harmless — only finitely
many terms are summed, the infinite tail is absorbed by the `2/(j+1)` limit rate.

HONEST SCOPE. A finite magnitude bound on the Mellin transform only. It builds NO covariance, NO
F-continuity, NO factorization, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling
positivity) is RH; the crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.MellinHat
import Multiplicity.F1.Square.TailPartialScaleLip
import Multiplicity.F1.Analysis.MellinDecay
import Multiplicity.F1.Analysis.IntegralCertIrrel
import Multiplicity.F1.Square.MomentDecay
import Multiplicity.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- |a| ≤ |a−b| + |b|. -/
private theorem Rabs_le_dist_add (a b : Real) :
    Rle (Rabs a) (Radd (Rabs (Rsub a b)) (Rabs b)) := by
  have hid : Req a (Radd (Rsub a b) b) :=
    Req_symm (Req_trans (Radd_assoc a (Rneg b) b)
      (Req_trans (Radd_congr (Req_refl a)
        (Req_trans (Radd_comm (Rneg b) b) (Radd_neg b))) (Radd_zero a)))
  exact Rle_trans (Rle_of_Req (Rabs_congr hid)) (Rabs_Radd (Rsub a b) b)

/-- Crude per-window bound: |twTerm (dilateTestR c φ) n m| ≤ φ.M·(powWinTest m n).M. -/
theorem twTerm_crude_bound (φ : L2Test) (n m : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd)) :
    Rle (Rabs (twTerm (dilateTestR c S hSd hSn hcS φ) n m))
      (ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
        (Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd))) := by
  refine riemannIntegralI_abs_le_window
    (l2L_den (dilateTestR c S hSd hSn hcS φ) (powWinTest m n))
    (l2L_num (dilateTestR c S hSd hSn hcS φ) (powWinTest m n))
    (l2lip (dilateTestR c S hSd hSn hcS φ) (powWinTest m n))
    (l2fc (dilateTestR c S hSd hSn hcS φ) (powWinTest m n))
    (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M)
    Nat.one_pos (by decide) (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)
    (fun x _ _ => ?_)
  refine Rle_trans (Rle_of_Req (Rabs_Rmul _ _)) ?_
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rabs _)
    ((dilateTestR c S hSd hSn hcS φ).hbd _)) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ φ.hMd φ.hMn)
    ((powWinTest m n).hbd _)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ φ.hMd (powWinTest m n).hMd)


/-- Local finite-sum triangle for genSum (the TailPartialScaleLip one is private). -/
private theorem genSum_Rabs_le' (T : Nat → Real) :
    ∀ N, Rle (Rabs (genSum T N)) (genSum (fun m => Rabs (T m)) N)
  | 0 => Rle_of_Req Rabs_zero
  | (N + 1) =>
      Rle_trans (Rabs_Radd (genSum T N) (T N))
        (Radd_le_add (genSum_Rabs_le' T N) (Rle_of_Req (Req_refl _)))

/-- Crude magnitude bound on the twisted tail: |twTail| ≤ genSum(crude)(N_0) + 2. -/
theorem twTail_crude_bound (φ : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR c S hSd hSn hcS φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Rle (Rabs (twTail (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec))
      (Radd (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
              (Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)))
              (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
            (ofQ (⟨2, 1⟩ : Q) (by decide))) := by
  have wReg : RReg (fun i => genSum (fun m => twTerm (dilateTestR c S hSd hSn hcS φ) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) i)) :=
    genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos) (Int.mul_nonneg hCn (Int.ofNat_nonneg _))
      (twTerm_bound (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec)
  refine Rle_trans (Rabs_le_dist_add _
    (genSum (fun m => twTerm (dilateTestR c S hSd hSn hcS φ) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))) ?_
  refine Rle_trans (Radd_le_add
    (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) (Rabs_dist_Rlim wReg 0))
    (Rle_trans (genSum_Rabs_le' _ _)
      (genSum_le (fun m => twTerm_crude_bound φ n m S hSd hSn c hcS) _))) ?_
  exact Rle_of_Req (Radd_comm _ _)

/-- The Mellin transform is bounded (magnitude), uniformly in the scale. -/
theorem mellinHat_abs_le (φ : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR c S hSd hSn hcS φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m))))) :
    Rle (Rabs (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec))
      (Radd (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n)))
        (Radd (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
                (Qmul_den_pos (by decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)))
                (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
              (ofQ (⟨2, 1⟩ : Q) (by decide)))) := by
  show Rle (Rabs (Radd (mellinMoment (dilateTestR c S hSd hSn hcS φ) n)
      (twTail (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec))) _
  refine Rle_trans (Rabs_Radd _ _) ?_
  exact Radd_le_add (mellinMoment_abs_le (dilateTestR c S hSd hSn hcS φ) n)
    (twTail_crude_bound φ n S hSd hSn c hcS hCd hCn hdec)

end Multiplicity.UOR.Bridge.F1Square.Square
