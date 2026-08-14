/-
F1 square — **the covariance continuity gap is a null family** (`CovCombHbound.lean`): the split-at-depth
scale-continuity bound of `covComb_scale_split`, evaluated at a *fast-enough* rational approximant
`qk` of the real scale `c`, is `≤ C₀/(k+1)` — the `hbound` hypothesis of the real-scale dilation
covariance, now discharged from a single fast-approximation input.

`covComb_hbound_of_fast`: for a rational sequence `qk` with `|c − qk| ≤ 1/(covIdx k + 1)` (the fast
condition — satisfied for FREE by `qk k = c.seq (covIdx k)` via `Rabs_sub_seq_le`),

    `|cⁿ⁺¹·M(dilateTestR c) − qkⁿ⁺¹·M(dilateTestR qk)|  ≤  C₀/(k+1)`,   `C₀ := covC0 φ S C n`.

The mechanism: instantiate `covComb_scale_split` at `c' = qk`, `j = k`; collapse the two `genSum`
"heads" to concrete rationals (`genSum_ofQ`); bound `|c − qk| ≤ 1/(covIdx k + 1)` (`hfast`); and drive
the whole thing under `C₀/(k+1)` with the two rate inequalities `Qmul_recip_le` (the index-schedule
terms) and `Qmul_four_le` (the fixed tail). The index `covIdx k` is chosen exactly large enough — from
the *rational* magnitude of the covComb coefficient — that each approximation term lands below
`1/(k+1)`.

WHY. This is the last piece that makes the real-scale Mellin dilation covariance UNCONDITIONAL: fed
`qk k = c.seq (covIdx k)` (whose fast condition is free), it eliminates `hbound` from
`mellinHat_dilate_covariance_real` in favour of the standard per-approximant decay data alone.

HONEST SCOPE. Object-grounding substrate — the null-family rate bound for the covariance's continuity
gap. It builds NO factorization theorem, NO grounding of `v = ĝ`, and — emphatically — NO step-4
band-coupling positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1Square.Square.CovCombScaleCont
import Multiplicity.F1Square.Analysis.GenSumOfQ
import Multiplicity.F1Square.Analysis.CovRateQ

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- The rational data extracted from the covComb coefficient.
-- ===========================================================================

/-- The `head_k` rational: the value of the covComb `genSum` head at depth `k`. -/
def covHk (φ : L2Test) (C : Q) (n k : Nat) : Q :=
  qGenSum (fun m => mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
    (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) k)

/-- The `head_0` rational from the magnitude bound (`mellinHat_abs_le`). -/
def covH0 (φ : L2Test) (C : Q) (n : Nat) : Q :=
  qGenSum (fun m => mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
    (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0)

/-- The magnitude constant `Bφ = φ.M/(n+1) + head_0 + 2` as a rational. -/
def covBq (φ : L2Test) (C : Q) (n : Nat) : Q :=
  add (mul φ.M (⟨1, n + 1⟩ : Q)) (add (covH0 φ C n) (⟨2, 1⟩ : Q))

/-- The two covComb coefficients of `|c − c'|`: `P·(φ.L + head_k)` and `Bφ·(n+1)Sⁿ`. -/
def covCoeff1 (φ : L2Test) (S C : Q) (n k : Nat) : Q :=
  mul (qpow S (n + 1)) (add φ.L (covHk φ C n k))

def covCoeff2 (φ : L2Test) (S C : Q) (n : Nat) : Q :=
  mul (covBq φ C n) (mul (⟨(n : Int) + 1, 1⟩ : Q) (qpow S n))

/-- **The index schedule** — chosen from the rational magnitude of the two covComb coefficients so
    that each approximation term lands below `1/(k+1)`. -/
def covIdx (φ : L2Test) (S C : Q) (n k : Nat) : Nat :=
  ((covCoeff1 φ S C n k).num.toNat + (covCoeff2 φ S C n).num.toNat + 1) * (k + 1)

/-- **The uniform null-family constant** `C₀ = 2 + 4·⌈Sⁿ⁺¹⌉`. -/
def covC0 (S : Q) (n : Nat) : Nat := 2 + 4 * (qpow S (n + 1)).num.toNat

-- ===========================================================================
-- Nonnegativity of the pieces.
-- ===========================================================================

/-- `qGenSum` of termwise-nonneg summands is nonneg. -/
private theorem qGenSum_num_nonneg (g : Nat → Q) (hg : ∀ i, 0 ≤ (g i).num) :
    ∀ N, 0 ≤ (qGenSum g N).num
  | 0 => by show (0 : Int) ≤ 0; exact Int.le_refl 0
  | (N + 1) => Qadd_num_nonneg_loc (qGenSum_num_nonneg g hg N) (hg N)

private theorem hkTerm_den (φ : L2Test) (n : Nat) : ∀ (m : Nat),
    0 < (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M).den :=
  fun m => Qmul_den_pos (Qmul_den_pos φ.hLd (by show 0 < 1; decide)) (powWinTest m n).hMd

private theorem h0Term_den (φ : L2Test) (n : Nat) : ∀ (m : Nat),
    0 < (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M)).den :=
  fun m => Qmul_den_pos (by show 0 < 1; decide) (Qmul_den_pos φ.hMd (powWinTest m n).hMd)

private theorem covHk_den (φ : L2Test) (C : Q) (n k : Nat) : 0 < (covHk φ C n k).den :=
  qGenSum_den _ (hkTerm_den φ n) _

private theorem covH0_den (φ : L2Test) (C : Q) (n : Nat) : 0 < (covH0 φ C n).den :=
  qGenSum_den _ (h0Term_den φ n) _

private theorem covHk_nonneg (φ : L2Test) (C : Q) (n k : Nat) : 0 ≤ (covHk φ C n k).num :=
  qGenSum_num_nonneg _ (fun m => Qmul_num_nonneg
    (Qmul_num_nonneg φ.hLn (by show (0 : Int) ≤ (m : Int) + 2; omega))
    (powWinTest m n).hMn) _

private theorem covH0_nonneg (φ : L2Test) (C : Q) (n : Nat) : 0 ≤ (covH0 φ C n).num :=
  qGenSum_num_nonneg _ (fun m => Qmul_num_nonneg (by show (0 : Int) ≤ 1; decide)
    (Qmul_num_nonneg φ.hMn (powWinTest m n).hMn)) _

private theorem covBq_nonneg (φ : L2Test) (C : Q) (n : Nat) : 0 ≤ (covBq φ C n).num :=
  Qadd_num_nonneg_loc (Qmul_num_nonneg φ.hMn (by show (0 : Int) ≤ 1; decide))
    (Qadd_num_nonneg_loc (covH0_nonneg φ C n) (by show (0 : Int) ≤ 2; decide))

private theorem covCoeff1_nonneg (φ : L2Test) (S C : Q) (n k : Nat) (hSn : 0 ≤ S.num) :
    0 ≤ (covCoeff1 φ S C n k).num :=
  Qmul_num_nonneg (qpow_nonneg hSn (n + 1))
    (Qadd_num_nonneg_loc φ.hLn (covHk_nonneg φ C n k))

private theorem covCoeff2_nonneg (φ : L2Test) (S C : Q) (n : Nat) (hSn : 0 ≤ S.num) :
    0 ≤ (covCoeff2 φ S C n).num :=
  Qmul_num_nonneg (covBq_nonneg φ C n)
    (Qmul_num_nonneg (by show (0 : Int) ≤ (n : Int) + 1; omega) (qpow_nonneg hSn n))

private theorem covCoeff1_den (φ : L2Test) (S C : Q) (n k : Nat) (hSd : 0 < S.den) :
    0 < (covCoeff1 φ S C n k).den :=
  Qmul_den_pos (qpow_den_pos hSd (n + 1)) (add_den_pos φ.hLd (covHk_den φ C n k))

private theorem covCoeff2_den (φ : L2Test) (S C : Q) (n : Nat) (hSd : 0 < S.den) :
    0 < (covCoeff2 φ S C n).den :=
  Qmul_den_pos (add_den_pos (Qmul_den_pos φ.hMd (by show 0 < n + 1; exact Nat.succ_pos n))
      (add_den_pos (covH0_den φ C n) (by show 0 < 1; decide)))
    (Qmul_den_pos (by show 0 < 1; decide) (qpow_den_pos hSd n))

-- ===========================================================================
-- The index bounds (the two Qmul_recip_le hypotheses).
-- ===========================================================================

private theorem covIdx_bound1 (φ : L2Test) (S C : Q) (n k : Nat) :
    (covCoeff1 φ S C n k).num.toNat * (k + 1) < covIdx φ S C n k + 1 := by
  have h : (covCoeff1 φ S C n k).num.toNat * (k + 1)
      ≤ ((covCoeff1 φ S C n k).num.toNat + (covCoeff2 φ S C n).num.toNat + 1) * (k + 1) :=
    Nat.mul_le_mul (by omega) (Nat.le_refl _)
  simp only [covIdx]
  omega

private theorem covIdx_bound2 (φ : L2Test) (S C : Q) (n k : Nat) :
    (covCoeff2 φ S C n).num.toNat * (k + 1) < covIdx φ S C n k + 1 := by
  have h : (covCoeff2 φ S C n).num.toNat * (k + 1)
      ≤ ((covCoeff1 φ S C n k).num.toNat + (covCoeff2 φ S C n).num.toNat + 1) * (k + 1) :=
    Nat.mul_le_mul (by omega) (Nat.le_refl _)
  simp only [covIdx]
  omega

/-- The three small-rational bounds sum to `C₀/(k+1)` (an equality, so `≤`). -/
private theorem covFinalQ (p k1 : Nat) :
    Qle (add (add (⟨1, k1⟩ : Q) (⟨4 * (p : Int), k1⟩ : Q)) (⟨1, k1⟩ : Q))
        (⟨((2 + 4 * p : Nat) : Int), k1⟩ : Q) :=
  Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor)

-- ===========================================================================
-- THE NULL-FAMILY BOUND.
-- ===========================================================================

/-- **The covariance continuity gap is a null family.** For a rational sequence `qk` approximating
    the real scale `c` fast enough (`|c − qk| ≤ 1/(covIdx k + 1)` — free for `qk k = c.seq (covIdx k)`
    via `Rabs_sub_seq_le`), the `covComb_scale_split` gap is `≤ covC0/(k+1)`. This is exactly the
    `hbound` hypothesis of `mellinHat_dilate_covariance_real`, discharged. -/
theorem covComb_hbound_of_fast (φ : L2Test) (n : Nat) (S : Q) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd))
    {C : Q} (hCd : 0 < C.den) (hCn : 0 ≤ C.num)
    (hdec_c : ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR c S hSd hSn hcS φ).f (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q)
            Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (qk : Nat → Q) (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_S : ∀ k, Rle (Rabs (ofQ (qk k) (hqk_den k))) (ofQ S hSd))
    (hdec_qk : ∀ k, ∀ m : Nat, ∀ x, Rle zero x → Rle x one →
      Rle (Rabs ((dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ).f
            (affineMap (⟨(m : Int) + 1, 1⟩ : Q) (⟨1, 1⟩ : Q) Nat.one_pos (by decide) x)))
        (ofQ (mul C (⟨1, (m + 1) ^ (n + 2)⟩ : Q))
          (Qmul_den_pos hCd (Nat.pos_pow_of_pos _ (Nat.succ_pos m)))))
    (hfast : ∀ k, Rle (Rabs (Rsub c (ofQ (qk k) (hqk_den k))))
        (ofQ (⟨1, covIdx φ S C n k + 1⟩ : Q) (Nat.succ_pos _))) :
    ∀ k, Rle (Rabs (Rsub
        (Rmul (Rpow c (n + 1)) (mellinHat (dilateTestR c S hSd hSn hcS φ) n hCd hCn hdec_c))
        (Rmul (Rpow (ofQ (qk k) (hqk_den k)) (n + 1))
          (mellinHat (dilateTestR (ofQ (qk k) (hqk_den k)) S hSd hSn (hqk_S k) φ) n hCd hCn (hdec_qk k)))))
      (ofQ (⟨(covC0 S n : Int), k + 1⟩ : Q) (Nat.succ_pos k)) := by
  intro k
  refine Rle_trans (covComb_scale_split φ n S hSd hSn c (ofQ (qk k) (hqk_den k)) hcS (hqk_S k)
    hCd hCn hdec_c (hdec_qk k) k) ?_
  -- Collapse the two genSum heads to rationals.
  have hHK : Req
      (genSum (fun m => ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
          (hkTerm_den φ n m)) (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) k))
      (ofQ (covHk φ C n k) (covHk_den φ C n k)) :=
    genSum_ofQ (fun m => mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
      (hkTerm_den φ n) (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) k)
  have hH0 : Req
      (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
          (h0Term_den φ n m)) (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
      (ofQ (covH0 φ C n) (covH0_den φ C n)) :=
    genSum_ofQ (fun m => mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
      (h0Term_den φ n) (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0)
  -- Distribute the outer product P·(X + four) and split the sum three ways.
  refine Rle_trans (Rle_of_Req (Radd_congr (Rmul_distrib _ _ _) (Req_refl _))) ?_
  have hPfour : Rle
      (Rmul (ofQ (qpow S (n + 1)) (qpow_den_pos hSd (n + 1)))
        (ofQ (⟨4, k + 1⟩ : Q) (Nat.succ_pos k)))
      (ofQ (⟨4 * ((qpow S (n + 1)).num.toNat : Int), k + 1⟩ : Q) (Nat.succ_pos k)) :=
    Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (qpow_den_pos hSd (n + 1)) (Nat.succ_pos k)))
      (Rle_ofQ_ofQ (Qmul_den_pos (qpow_den_pos hSd (n + 1)) (Nat.succ_pos k)) (Nat.succ_pos k)
        (Qmul_four_le (qpow S (n + 1)) (k + 1) (qpow_nonneg hSn (n + 1)) (qpow_den_pos hSd (n + 1))))
  have hPX : Rle
      (Rmul (ofQ (qpow S (n + 1)) (qpow_den_pos hSd (n + 1)))
        (Rmul (Radd (ofQ φ.L φ.hLd)
            (genSum (fun m => ofQ (mul (mul φ.L (⟨(m : Int) + 2, 1⟩ : Q)) (powWinTest m n).M)
                (hkTerm_den φ n m)) (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) k)))
          (Rabs (Rsub c (ofQ (qk k) (hqk_den k))))))
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
      (Rmul_congr (Radd_congr (Req_refl _) hHK) (Req_refl _)))) ?_
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc _ _ _))) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr
      (Req_trans (Rmul_ofQ_ofQ (qpow_den_pos hSd (n + 1)) (add_den_pos φ.hLd (covHk_den φ C n k)))
        (Req_refl _)) (Req_refl _))) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (covCoeff1_den φ S C n k hSd)
      (covCoeff1_nonneg φ S C n k hSn)) (hfast k)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (covCoeff1_den φ S C n k hSd) (Nat.succ_pos _))) ?_
    exact Rle_ofQ_ofQ (Qmul_den_pos (covCoeff1_den φ S C n k hSd) (Nat.succ_pos _)) (Nat.succ_pos k)
      (Qmul_recip_le (covCoeff1 φ S C n k) (k + 1) (covIdx φ S C n k)
        (covCoeff1_nonneg φ S C n k hSn) (covCoeff1_den φ S C n k hSd) (covIdx_bound1 φ S C n k))
  have hTerm2 : Rle
      (Rmul
        (Radd (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n)))
          (Radd (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
                (h0Term_den φ n m)) (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
            (ofQ (⟨2, 1⟩ : Q) (by decide))))
        (Rmul (ofQ (mul (⟨(n : Int) + 1, 1⟩ : Q) (qpow S n))
              (Qmul_den_pos Nat.one_pos (qpow_den_pos hSd n)))
          (Rabs (Rsub c (ofQ (qk k) (hqk_den k))))))
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    have hBq : Req
        (Radd (ofQ (mul φ.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos φ.hMd (Nat.succ_pos n)))
          (Radd (genSum (fun m => ofQ (mul (⟨1, 1⟩ : Q) (mul φ.M (powWinTest m n).M))
                (h0Term_den φ n m)) (digammaMidx (mul C (⟨((2 ^ n : Nat) : Int), 1⟩ : Q)) 0))
            (ofQ (⟨2, 1⟩ : Q) (by decide))))
        (ofQ (covBq φ C n) (add_den_pos (Qmul_den_pos φ.hMd (Nat.succ_pos n))
          (add_den_pos (covH0_den φ C n) (by decide)))) :=
      Req_trans (Radd_congr (Req_refl _)
        (Req_trans (Radd_congr hH0 (Req_refl _))
          (Radd_ofQ_ofQ (covH0_den φ C n) (by decide))))
        (Radd_ofQ_ofQ (Qmul_den_pos φ.hMd (Nat.succ_pos n))
          (add_den_pos (covH0_den φ C n) (by decide)))
    refine Rle_trans (Rle_of_Req (Rmul_congr hBq (Req_refl _))) ?_
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc _ _ _))) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr
      (Rmul_ofQ_ofQ (add_den_pos (Qmul_den_pos φ.hMd (Nat.succ_pos n))
        (add_den_pos (covH0_den φ C n) (by decide)))
        (Qmul_den_pos Nat.one_pos (qpow_den_pos hSd n))) (Req_refl _))) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (covCoeff2_den φ S C n hSd)
      (covCoeff2_nonneg φ S C n hSn)) (hfast k)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (covCoeff2_den φ S C n hSd) (Nat.succ_pos _))) ?_
    exact Rle_ofQ_ofQ (Qmul_den_pos (covCoeff2_den φ S C n hSd) (Nat.succ_pos _)) (Nat.succ_pos k)
      (Qmul_recip_le (covCoeff2 φ S C n) (k + 1) (covIdx φ S C n k)
        (covCoeff2_nonneg φ S C n hSn) (covCoeff2_den φ S C n hSd) (covIdx_bound2 φ S C n k))
  -- Combine the three bounds and collapse to the final rational.
  refine Rle_trans (Radd_le_add (Radd_le_add hPX hPfour) hTerm2) ?_
  refine Rle_trans (Rle_of_Req (Radd_congr
    (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k)) (Req_refl _))) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ
    (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k))
    (Nat.succ_pos k) (covFinalQ (qpow S (n + 1)).num.toNat (k + 1))

end Multiplicity.UOR.Bridge.F1Square.Square
