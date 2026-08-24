/-
F1 square — **the real-scale moment covariance** (`RiwIMomentCovariance.lean`): the real-upper-limit
window integral of the fixed-band twist weight evaluates as the real-scale scaled moment,

    `riwI (f · powBandGen_{[0,B]}) qk … = cⁿ⁺¹ · mellinMoment (dilateTestR c f) n`,

along a fast positive rational diagonal `qk → c`. This discharges the `hbound` input of
`riwI_eq_of_bound`.

The mechanism mirrors `covComb_hbound_of_fast` (the mellinHat covariance), but with the tail-free
moment Lipschitz `moment_covComb_scale_lip` in place of the split-at-depth scale-continuity. Per
approximant `qk (m k)`:
1. `riwSeq (m k) = (qk (m k))ⁿ⁺¹ · mellinMoment (dilate_{qk (m k)} f) n` — `riwSeq_term_eq_moment`
   (the real-window partial is defeq the fixed-band moment; window `[0, qk (m k)]` under band `B`).
2. bridge to the real-scale form `H(ofQ (qk (m k)))` via `Rpow_ofQ` (scalar) and `mellinMoment_bridge`
   (`dilateTest` → `dilateTestR`).
3. `|riwSeq (m k) − cⁿ⁺¹·M(c)| = |H(ofQ (qk (m k))) − H(c)| ≤ Lip·|c − qk (m k)|`
   (`moment_covComb_scale_lip`), and the two coefficient·rate terms are driven under `2/(k+1)` by the
   rational index schedule `momCovIdx` (`Qmul_recip_le`), exactly as `covIdx` does.

The fast condition `hconv` (`|c − qk (m k)| ≤ 1/(momCovIdx k + 1)`) is a supplied, dischargeable input —
free for the diagonal `qk (m k) = c.seq (momCovIdx …)` via `Rabs_sub_seq_le` at a positive real `c`
(`hqk_pos`), with the window/band data `hqk_B`, `hqk_mS` standard approximation slack. No RH-equivalent
hypothesis is assumed.

HONEST SCOPE. The real-scale moment covariance — the factorization's inner integral evaluated at a real
scale, with `hbound` discharged from the fast-approximation rate. It asserts NO positivity, NO
factorization `M[f⋆g]=M[f]·M[g]`, NO half-line assembly, and — emphatically — NO step-4 band-coupling
positivity (`ArchDominatesPrime`), which is RH. The crux fields stay `none`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Multiplicity.F1.Square.RiwILimit
import Multiplicity.F1.Square.RiwSeqMoment
import Multiplicity.F1.Square.MomentCovLip
import Multiplicity.F1.Square.DilateTestBridge
import Multiplicity.F1.Analysis.CovRateQ
import Multiplicity.F1.Analysis.RealPow

namespace Multiplicity.UOR.Bridge.F1Square.Square

open UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- The fixed-band twist test and the rational coefficient schedule.
-- ===========================================================================

/-- The fixed-band twist weight `f · powBandGen_{[0,B]}ⁿ` whose real-window integral is the moment. -/
def bandTwistTest (f : L2Test) (B : Q) (hBd : 0 < B.den) (hleB : Qle (⟨0, 1⟩ : Q) B) (n : Nat) :
    L2Test :=
  L2Test.mul f (powBandGen (⟨0, 1⟩ : Q) B (by decide) hBd hleB (by decide) n)

/-- The first Lipschitz coefficient of `|c − c'|` from `moment_covComb_scale_lip`:
    `Sⁿ⁺¹ · (1·(f.L·(0+1)·(powTest n).M))`. -/
def momCoeff1 (f : L2Test) (S : Q) (n : Nat) : Q :=
  mul (qpow S (n + 1))
    (mul (⟨1, 1⟩ : Q) (mul (mul f.L (add (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q))) (powTest n).M))

/-- The second Lipschitz coefficient of `|c − c'|`: `(f.M/(n+1)) · ((n+1)·Sⁿ)`. -/
def momCoeff2 (f : L2Test) (S : Q) (n : Nat) : Q :=
  mul (mul f.M (⟨1, n + 1⟩ : Q)) (mul (⟨(n : Int) + 1, 1⟩ : Q) (qpow S n))

/-- **The index schedule** — chosen from the rational magnitude of the two moment-Lipschitz
    coefficients so that each coefficient·rate term lands below `1/(k+1)`. -/
def momCovIdx (f : L2Test) (S : Q) (n k : Nat) : Nat :=
  ((momCoeff1 f S n).num.toNat + (momCoeff2 f S n).num.toNat + 1) * (k + 1)

-- ===========================================================================
-- Nonnegativity / positivity of the pieces.
-- ===========================================================================

private theorem momCoeff1_nonneg (f : L2Test) (S : Q) (n : Nat) (hSn : 0 ≤ S.num) :
    0 ≤ (momCoeff1 f S n).num :=
  Qmul_num_nonneg (qpow_nonneg hSn (n + 1))
    (Qmul_num_nonneg (by decide)
      (Qmul_num_nonneg (Qmul_num_nonneg f.hLn (by decide)) (powTest n).hMn))

private theorem momCoeff1_den (f : L2Test) (S : Q) (n : Nat) (hSd : 0 < S.den) :
    0 < (momCoeff1 f S n).den :=
  Qmul_den_pos (qpow_den_pos hSd (n + 1))
    (Qmul_den_pos (by decide)
      (Qmul_den_pos (Qmul_den_pos f.hLd (add_den_pos (by decide) (by decide))) (powTest n).hMd))

private theorem momCoeff2_nonneg (f : L2Test) (S : Q) (n : Nat) (hSn : 0 ≤ S.num) :
    0 ≤ (momCoeff2 f S n).num :=
  Qmul_num_nonneg (Qmul_num_nonneg f.hMn (by show (0 : Int) ≤ 1; decide))
    (Qmul_num_nonneg (by show (0 : Int) ≤ (n : Int) + 1; omega) (qpow_nonneg hSn n))

private theorem momCoeff2_den (f : L2Test) (S : Q) (n : Nat) (hSd : 0 < S.den) :
    0 < (momCoeff2 f S n).den :=
  Qmul_den_pos (Qmul_den_pos f.hMd (Nat.succ_pos n))
    (Qmul_den_pos Nat.one_pos (qpow_den_pos hSd n))

-- ===========================================================================
-- The two index bounds (the Qmul_recip_le hypotheses).
-- ===========================================================================

private theorem momIdx_bound1 (f : L2Test) (S : Q) (n k : Nat) :
    (momCoeff1 f S n).num.toNat * (k + 1) < momCovIdx f S n k + 1 := by
  have h : (momCoeff1 f S n).num.toNat * (k + 1)
      ≤ ((momCoeff1 f S n).num.toNat + (momCoeff2 f S n).num.toNat + 1) * (k + 1) :=
    Nat.mul_le_mul (by omega) (Nat.le_refl _)
  simp only [momCovIdx]
  omega

private theorem momIdx_bound2 (f : L2Test) (S : Q) (n k : Nat) :
    (momCoeff2 f S n).num.toNat * (k + 1) < momCovIdx f S n k + 1 := by
  have h : (momCoeff2 f S n).num.toNat * (k + 1)
      ≤ ((momCoeff1 f S n).num.toNat + (momCoeff2 f S n).num.toNat + 1) * (k + 1) :=
    Nat.mul_le_mul (by omega) (Nat.le_refl _)
  simp only [momCovIdx]
  omega

-- ===========================================================================
-- THE REAL-SCALE MOMENT COVARIANCE.
-- ===========================================================================

/-- **The real-scale moment covariance.** For a fast positive rational diagonal `qk → c` (with
    `|c − qk (m k)| ≤ 1/(momCovIdx k + 1)` — free for `qk (m k) = c.seq (momCovIdx …)` via `Rabs_sub_seq_le`),
    the real-window integral of the fixed-band twist weight is the real-scale scaled moment:

      `riwI (f · powBandGen_{[0,B]}) qk … = cⁿ⁺¹ · mellinMoment (dilateTestR c f) n`.

    This discharges the `hbound` input of `riwI_eq_of_bound`. It asserts NO positivity and NO
    factorization; step-4 band-coupling positivity is RH and the crux fields stay `none`. -/
theorem riwI_moment_covariance (f : L2Test) (n : Nat) (B S : Q) (hBd : 0 < B.den)
    (hleB : Qle (⟨0, 1⟩ : Q) B) (hSd : 0 < S.den) (hSn : 0 ≤ S.num)
    (c : Real) (hcS : Rle (Rabs c) (ofQ S hSd))
    (qk : Nat → Q) (hqk_pos : ∀ k, 0 < (qk k).num) (hqk_den : ∀ k, 0 < (qk k).den)
    (hqk_fast : ∀ j k, Qle (mul (Qabs (Qsub (qk j) (qk k))) (bandTwistTest f B hBd hleB n).M)
      (add (⟨1, j + 1⟩ : Q) (⟨1, k + 1⟩ : Q)))
    (m : Nat → Nat) (hm : ∀ k, k ≤ m k)
    (hqk_B : ∀ k, Qle (add (qk (m k)) (⟨1, 1⟩ : Q)) B)
    (hqk_mS : ∀ k, Rle (Rabs (ofQ (qk (m k)) (hqk_den (m k)))) (ofQ S hSd))
    (hconv : ∀ k, Rle (Rabs (Rsub c (ofQ (qk (m k)) (hqk_den (m k)))))
      (ofQ (⟨1, momCovIdx f S n k + 1⟩ : Q) (Nat.succ_pos (momCovIdx f S n k)))) :
    Req (riwI (bandTwistTest f B hBd hleB n) qk hqk_pos hqk_den hqk_fast)
        (Rmul (Rpow c (n + 1)) (mellinMoment (dilateTestR c S hSd hSn hcS f) n)) := by
  refine riwI_eq_of_bound _ qk hqk_pos hqk_den hqk_fast _ m hm (C₀ := 2) (fun k => ?_)
  -- STEP 1: the real-window partial IS the fixed-band scaled moment (defeq).
  have hterm : Req (riwSeq (bandTwistTest f B hBd hleB n) qk hqk_pos hqk_den (m k))
      (Rmul (ofQ (qpow (qk (m k)) (n + 1)) (qpow_den_pos (hqk_den (m k)) (n + 1)))
        (mellinMoment (dilateTest (qk (m k)) (hqk_pos (m k)) (hqk_den (m k)) f) n)) :=
    riwSeq_term_eq_moment f n (qk (m k)) B (hqk_pos (m k)) (hqk_den (m k)) hBd (hqk_B k)
  -- STEP 2: bridge the scalar (Rpow_ofQ) and the moment (dilateTest → dilateTestR).
  have hbridge : Req
      (Rmul (ofQ (qpow (qk (m k)) (n + 1)) (qpow_den_pos (hqk_den (m k)) (n + 1)))
        (mellinMoment (dilateTest (qk (m k)) (hqk_pos (m k)) (hqk_den (m k)) f) n))
      (Rmul (Rpow (ofQ (qk (m k)) (hqk_den (m k))) (n + 1))
        (mellinMoment (dilateTestR (ofQ (qk (m k)) (hqk_den (m k))) S hSd hSn (hqk_mS k) f) n)) :=
    Rmul_congr (Req_symm (Rpow_ofQ (hqk_den (m k)) (n + 1)))
      (mellinMoment_bridge f n (qk (m k)) (hqk_pos (m k)) (hqk_den (m k)) S hSd hSn (hqk_mS k))
  have hH : Req (riwSeq (bandTwistTest f B hBd hleB n) qk hqk_pos hqk_den (m k))
      (Rmul (Rpow (ofQ (qk (m k)) (hqk_den (m k))) (n + 1))
        (mellinMoment (dilateTestR (ofQ (qk (m k)) (hqk_den (m k))) S hSd hSn (hqk_mS k) f) n)) :=
    Req_trans hterm hbridge
  -- STEP 3: rewrite the partial, symmetrize, and apply the moment Lipschitz.
  refine Rle_trans (Rle_of_Req (Rabs_congr (Rsub_congr hH (Req_refl _)))) ?_
  refine Rle_trans (Rle_of_Req (Rabs_Rsub_symm _ _)) ?_
  refine Rle_trans (moment_covComb_scale_lip f n S hSd hSn c
    (ofQ (qk (m k)) (hqk_den (m k))) hcS (hqk_mS k)) ?_
  -- Bound each coefficient·rate term by 1/(k+1).
  have hT1 : Rle
      (Rmul (ofQ (qpow S (n + 1)) (qpow_den_pos hSd (n + 1)))
        (Rmul (ofQ (mul (⟨1, 1⟩ : Q)
            (mul (mul f.L (add (⟨0, 1⟩ : Q) (⟨1, 1⟩ : Q))) (powTest n).M))
            (Qmul_den_pos (by decide)
              (Qmul_den_pos (Qmul_den_pos f.hLd (add_den_pos (by decide) (by decide)))
                (powTest n).hMd)))
          (Rabs (Rsub c (ofQ (qk (m k)) (hqk_den (m k)))))))
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc _ _ _))) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr (Rmul_ofQ_ofQ _ _) (Req_refl _))) ?_
    refine Rle_trans (Rmul_le_Rmul_left
      (Rnonneg_ofQ (momCoeff1_den f S n hSd) (momCoeff1_nonneg f S n hSn)) (hconv k)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (momCoeff1_den f S n hSd)
      (Nat.succ_pos (momCovIdx f S n k)))) ?_
    exact Rle_ofQ_ofQ (Qmul_den_pos (momCoeff1_den f S n hSd) (Nat.succ_pos (momCovIdx f S n k)))
      (Nat.succ_pos k)
      (Qmul_recip_le (momCoeff1 f S n) (k + 1) (momCovIdx f S n k)
        (momCoeff1_nonneg f S n hSn) (momCoeff1_den f S n hSd) (momIdx_bound1 f S n k))
  have hT2 : Rle
      (Rmul (ofQ (mul f.M (⟨1, n + 1⟩ : Q)) (Qmul_den_pos f.hMd (Nat.succ_pos n)))
        (Rmul (ofQ (mul (⟨(n : Int) + 1, 1⟩ : Q) (qpow S n))
            (Qmul_den_pos Nat.one_pos (qpow_den_pos hSd n)))
          (Rabs (Rsub c (ofQ (qk (m k)) (hqk_den (m k)))))))
      (ofQ (⟨1, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc _ _ _))) ?_
    refine Rle_trans (Rle_of_Req (Rmul_congr (Rmul_ofQ_ofQ _ _) (Req_refl _))) ?_
    refine Rle_trans (Rmul_le_Rmul_left
      (Rnonneg_ofQ (momCoeff2_den f S n hSd) (momCoeff2_nonneg f S n hSn)) (hconv k)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (momCoeff2_den f S n hSd)
      (Nat.succ_pos (momCovIdx f S n k)))) ?_
    exact Rle_ofQ_ofQ (Qmul_den_pos (momCoeff2_den f S n hSd) (Nat.succ_pos (momCovIdx f S n k)))
      (Nat.succ_pos k)
      (Qmul_recip_le (momCoeff2 f S n) (k + 1) (momCovIdx f S n k)
        (momCoeff2_nonneg f S n hSn) (momCoeff2_den f S n hSd) (momIdx_bound2 f S n k))
  -- Combine the two bounds and collapse to 2/(k+1).
  refine Rle_trans (Radd_le_add hT1 hT2) ?_
  refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (Nat.succ_pos k) (Nat.succ_pos k))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (Nat.succ_pos k) (Nat.succ_pos k)) (Nat.succ_pos k)
    (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))

end Multiplicity.UOR.Bridge.F1Square.Square
