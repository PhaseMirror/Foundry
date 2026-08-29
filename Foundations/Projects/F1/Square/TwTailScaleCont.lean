/-
F1 square — **the twisted tail is scale-continuous (split-at-depth bound)** (`TwTailScaleCont.lean`):
the twisted tail `twTail (dilateTestR c φ) n` varies continuously in the REAL dilation scale `c`, with a
split-at-depth estimate that combines the finite-head Lipschitz bound with the uniform Bishop-limit
tail rate.

For every schedule depth `j`,

    `|twTail (dilateTestR c φ) n − twTail (dilateTestR c' φ) n|
          ≤ (Σ_{m<N_j} φ.L·(m+2)·(powWinTest m n).M) · |c − c'|  +  4/(j+1)`,

where `N_j = digammaMidx (C·2ⁿ) j` is the `j`-th partial-sum depth. As `j → ∞` and `c' → c` the
right-hand side → 0, so the tail is continuous in the scale.

WHY (rung 6, the tail-continuity step — no uniform-decay hypothesis needed). `twTail (dilate_c φ) n`
is the `Rlim` of the finite partial sums `genSum (twTerm (dilate_c φ) n) N_j`. The `j`-th partial sum is
within `2/(j+1)` of that `Rlim` by the abstract Bishop-completeness rate (`Rabs_dist_Rlim`) — a bound
that is UNIFORM in the scale `c`, so the tail remainders of the two `twTail`s are each `≤ 2/(j+1)` with
no extra hypothesis. The middle (finite-head) difference is the already-committed
`genSum_twTerm_scale_lipschitz`. A three-term triangle through the two `j`-th partial sums assembles
`2/(j+1) + head + 2/(j+1)`. This is the whole-tail scale-continuity, delivered directly from the
finite-head Lipschitz bound and the uniform limit rate — the per-window constant growing with `m` is
irrelevant, because the tail beyond depth `j` is controlled by the limit rate, not by summing the
per-window bounds.

HONEST SCOPE. The split-at-depth scale-continuity estimate for the twisted tail only. It builds NO
compact+tail assembly (that is `mellinHat`), NO real-scale covariance, NO factorization, NO half-line
assembly, NO positivity, NO determinacy, NO crux. Step 4 (band-coupling positivity) is RH; the crux
fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Foundations.F1.Square.TailPartialScaleLip
import Foundations.F1.Analysis.IntegralCertIrrel
import Foundations.F1.CoreCompat

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

/-- **The two-step triangle** `|a − d| ≤ |a − b| + |b − d|` via `(a−b)+(b−d) ≈ a−d` and `Rabs_Radd`. -/
private theorem Rabs_sub_tri (a b d : Real) :
    Rle (Rabs (Rsub a d)) (Radd (Rabs (Rsub a b)) (Rabs (Rsub b d))) := by
  refine Rle_trans (Rle_of_Req (Rabs_congr ?_)) (Rabs_Radd (Rsub a b) (Rsub b d))
  exact Req_symm (Req_trans (Radd_comm (Rsub a b) (Rsub b d)) (Radd_Rsub_Rsub b d a))

/-- **The twisted tail is scale-continuous (split-at-depth bound).** For real scales `c, c'` each
    bounded by the rational `S`, decay data `hdec_c`/`hdec_c'`, and every schedule depth `j`,

      `|twTail (dilateTestR c φ) n − twTail (dilateTestR c' φ) n|
            ≤ (Σ_{m<N_j} φ.L·(m+2)·(powWinTest m n).M)·|c − c'| + 4/(j+1)`,   `N_j = digammaMidx (C·2ⁿ) j`.

    Three-term triangle through the two `j`-th partial sums `genSum (twTerm (dilate_· φ) n) N_j`: each
    `twTail` is within `2/(j+1)` of its own partial sum by the uniform Bishop-limit rate
    (`Rabs_dist_Rlim`, scale-independent), and the middle finite-head difference is
    `genSum_twTerm_scale_lipschitz`. No uniform-in-scale decay hypothesis is needed — the tail beyond
    depth `j` is controlled by the limit rate, not by summing the growing per-window constants. -/
theorem twTail_scale_split (φ : L2Test) (n : Nat)
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
    Rle (Rabs (Rsub (twTail (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c)
                    (twTail (dilateTestR c' S hSd hSn hc'S φ) n hCd hCn hdec_c')))
        (Radd
          (Rmul (genSum (fun m => ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
                  (Qmul_den_pos (Qmul_den_pos φ.hLd Nat.one_pos) (powWinTest m n).hMd))
                  (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j))
            (Rabs (Rsub c c')))
          (ofQ (⟨4, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  have wc : RReg (fun i => genSum (fun m => twTerm (dilateTestR c S hSd hSn hcS φ) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) i)) :=
    genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos) (Int.mul_nonneg hCn (Int.ofNat_nonneg _))
      (twTerm_bound (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c)
  have wc' : RReg (fun i => genSum (fun m => twTerm (dilateTestR c' S hSd hSn hc'S φ) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) i)) :=
    genSum_RReg _ (Qmul_den_pos hCd Nat.one_pos) (Int.mul_nonneg hCn (Int.ofNat_nonneg _))
      (twTerm_bound (dilateTestR c' S hSd hSn hc'S φ) n hCd hCn hdec_c')
  have dc := Rabs_dist_Rlim wc j
  have dc' := Rabs_dist_Rlim wc' j
  have hhead := genSum_twTerm_scale_lipschitz φ n
    (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j) S hSd hSn c c' hcS hc'S
  refine Rle_trans (Rabs_sub_tri _
    (genSum (fun m => twTerm (dilateTestR c S hSd hSn hcS φ) n m)
      (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) _) ?_
  refine Rle_trans (Radd_le_add (Rle_of_Req (Req_refl _))
    (Rabs_sub_tri _
      (genSum (fun m => twTerm (dilateTestR c' S hSd hSn hc'S φ) n m)
        (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) j)) _)) ?_
  refine Rle_trans (Radd_le_add
    (Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) dc)
    (Radd_le_add hhead dc')) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Req_symm (Radd_assoc _ _ _)) ?_
  refine Req_trans (Radd_congr (Radd_comm _ _) (Req_refl _)) ?_
  refine Req_trans (Radd_assoc _ _ _) ?_
  refine Radd_congr (Req_refl _) ?_
  refine Req_trans (Radd_ofQ_ofQ (Nat.succ_pos j) (Nat.succ_pos j)) ?_
  exact ofQ_congr _ (Nat.succ_pos j) (by simp only [Qeq, add]; push_cast; ring_uor)

end Multiplicity.UOR.Bridge.F1Square.Square
