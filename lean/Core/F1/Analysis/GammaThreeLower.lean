/-
F1 square — stage F: **the certified lower bracket `γ₃ ≥ −1/20`** via DISCRETE Euler–Maclaurin
(NO constructive integration), completing the two-sided bracket on the third Stieltjes constant.

The companion of `GammaThreeBracket.lean` (`γ₃ ≤ 1/8`).  Same accelerated sequence
`hSeq3 j = g₃(j) − ½·(ln(j+1))³/(j+1)` (`→ γ₃`), whose per-step increment is the trapezoidal residual
`sStep3 = O((ln p)³/p³)`; here we bound it BELOW (`sStep3 ≥ −6/(p(p+1))`) instead of above, telescope
to `γ₃ ≥ hSeq3(N) − 6/(N+1)`, and certify at `N = 199` with the rational cubed/quartic-log evaluators
in the LOWER direction (`lnCubeSumLo` for the sum, `logBound` for the subtracted corrections).

The four parts of `decompForm3 = b³C2 + b²R2 + b·R1 + R0` (`d = a−b`, `b = ln p`):
  b³·C2 ≥ 0            (`b³ ≥ 0`, `C2 ≥ 0`)
  b²·R2 ≥ −3/(p(p+1))  (`b² ≤ 4p`, `d ≤ 1/p`, `d−u1 ≤ 1/(2p(p+1))`, the `(3/2)` coefficient)
  b·R1  ≥ −2/(p(p+1))  (`(3/2)u1 − d ≥ −d`, `b ≤ p`, `d³ ≤ 1/p³`)
  R0    ≥ −1/(p(p+1))  (`½d³u1 ≥ 0`, `d⁴ ≤ 1/p⁴`, drop the `−¼d⁴`)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.GammaThreeBracket
import Core.F1.Analysis.GammaTwoUpper

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- (A) `lnCubeSumLo` — a rational LOWER bound for `lnCubeSum N = Σ_{k=1}^N (ln k)³/k`.
-- Mirror of `lnSqSumLo` (the squared case), with `logLowBound` CUBED.
-- ===========================================================================

/-- The accumulated rational lower bound for `Σ_{k=1}^N (ln k)³/k`, at fixed denominator `D`: each new
    term `(log(n+1))³/(n+1) ≥ (logLowBound n)³·(1/(n+1))`, then round DOWN. -/
def lnCubeSumLo (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (n + 1) =>
      qRoundDown (add (lnCubeSumLo T D n)
        (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n)) ⟨1, n + 1⟩)) D

theorem lnCubeSumLo_den_pos (T D : Nat) (hD : 0 < D) : ∀ N, 0 < (lnCubeSumLo T D N).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`ofQ(lnCubeSumLo T D N) ≤ lnCubeSum N`** — the partial sum `Σ (log k)³/k` bounded BELOW
    term-by-term via `logN_ge_logLowBound` (cubed monotonically, all nonneg), accumulated at
    denominator `D` (round down), artanh depth `T ≤ 21`. -/
theorem lnCubeSum_ge (T D : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    ∀ N, Rle (ofQ (lnCubeSumLo T D N) (lnCubeSumLo_den_pos T D hD N)) (lnCubeSum N) := by
  intro N
  induction N with
  | zero =>
    have h0 : Req (ofQ (lnCubeSumLo T D 0) (lnCubeSumLo_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req h0
  | succ n ih =>
    have hLLd := logLowBound_den_pos T D hD n
    have hLLnn : Rnonneg (ofQ (logLowBound T D n) hLLd) :=
      Rnonneg_ofQ hLLd (logLowBound_num_nonneg T D n)
    have hlow := logN_ge_logLowBound T D hD hT n
    have hlognn : Rnonneg (logN (n + 1) (Nat.succ_pos n)) := Rnonneg_logN _ _
    -- (LL)² ≤ (log(n+1))²
    have hsq : Rle (Rmul (ofQ (logLowBound T D n) hLLd) (ofQ (logLowBound T D n) hLLd))
        (Rmul (logN (n + 1) (Nat.succ_pos n)) (logN (n + 1) (Nat.succ_pos n))) :=
      Rle_trans (Rmul_le_Rmul_right hLLnn hlow) (Rmul_le_Rmul_left hlognn hlow)
    have hLLsqnn : Rnonneg (Rmul (ofQ (logLowBound T D n) hLLd) (ofQ (logLowBound T D n) hLLd)) :=
      Rnonneg_Rmul hLLnn hLLnn
    have hlogsqnn : Rnonneg (Rmul (logN (n + 1) (Nat.succ_pos n)) (logN (n + 1) (Nat.succ_pos n))) :=
      Rnonneg_Rmul hlognn hlognn
    -- (LL)³ ≤ (log(n+1))³
    have hcb : Rle (Rmul (Rmul (ofQ (logLowBound T D n) hLLd) (ofQ (logLowBound T D n) hLLd))
          (ofQ (logLowBound T D n) hLLd))
        (Rmul (Rmul (logN (n + 1) (Nat.succ_pos n)) (logN (n + 1) (Nat.succ_pos n)))
          (logN (n + 1) (Nat.succ_pos n))) :=
      Rle_trans (Rmul_le_Rmul_right hLLnn hsq) (Rmul_le_Rmul_left hlogsqnn hlow)
    have hmuld : 0 < (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n))
        (⟨1, n + 1⟩ : Q)).den :=
      Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hLLd hLLd) hLLd) (Nat.succ_pos n)
    have hcbd : 0 < (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n)).den :=
      Qmul_den_pos (Qmul_den_pos hLLd hLLd) hLLd
    -- per-term: ofQ(LL³·(1/(n+1))) ≤ (log³)·(1/(n+1)) = lnCubeOver (n+1)
    have hterm : Rle (ofQ (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n))
          ⟨1, n + 1⟩) hmuld)
        (lnCubeOver (n + 1) (Nat.succ_pos n)) := by
      refine Rle_trans (Rle_of_Req ?_)
        (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos n) (by show (0 : Int) ≤ 1; decide)) hcb)
      refine Req_trans (Req_symm (Rmul_ofQ_ofQ hcbd (Nat.succ_pos n))) ?_
      refine Rmul_congr ?_ (Req_refl _)
      exact Req_symm (Req_trans (Rmul_congr (Rmul_ofQ_ofQ hLLd hLLd) (Req_refl _))
        (Rmul_ofQ_ofQ (Qmul_den_pos hLLd hLLd) hLLd))
    -- accumulate
    refine Rle_trans (Rle_ofQ_ofQ (lnCubeSumLo_den_pos T D hD (n + 1))
      (add_den_pos (lnCubeSumLo_den_pos T D hD n) hmuld)
      (qRoundDown_le (add (lnCubeSumLo T D n)
        (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n)) ⟨1, n + 1⟩))
        (add_den_pos (lnCubeSumLo_den_pos T D hD n) hmuld) D)) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (lnCubeSumLo_den_pos T D hD n) hmuld)) ?_
    exact Radd_le_add ih hterm

-- ===========================================================================
-- (B) Quartic-/cubed-log UPPER bounds (`logBound`).
-- ===========================================================================

/-- **Quartic-log upper bound** `(ln(M+1))⁴ ≤ logBound⁴` — `logQuartic = (ln)³·(ln)`, each factor
    `≤ logBound`. -/
theorem logQuartic_le (T D M : Nat) (hD : 0 < D) :
    Rle (logQuartic (M + 1) (Nat.succ_pos M))
        (ofQ (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M)) (logBound T D M))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logBound_den_pos T D hD M)
            (logBound_den_pos T D hD M)) (logBound_den_pos T D hD M)) (logBound_den_pos T D hD M))) := by
  have LBd := logBound_den_pos T D hD M
  have hLBcbnn : Rnonneg (ofQ (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
      (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd)) :=
    Rnonneg_congr (Rmul_ofQ_ofQ (Qmul_den_pos LBd LBd) LBd)
      (Rnonneg_Rmul (Rnonneg_congr (Rmul_ofQ_ofQ LBd LBd)
        (Rnonneg_Rmul (logBound_ofQ_nonneg T D M hD) (logBound_ofQ_nonneg T D M hD)))
        (logBound_ofQ_nonneg T D M hD))
  unfold logQuartic
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_logN _ _) (logCube_le T D M hD)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hLBcbnn (logN_le_logBound T D hD M)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd)

/-- **Half-cubed-over-`N` upper bound** `½·(ln(M+1))³/(M+1) ≤ ½·logBound³/(M+1)` — the trapezoidal
    anchor `½f(M+1)`, `f(x) = ln³x/x`, bounded above. -/
theorem halfCubeOver_le (T D M : Nat) (hD : 0 < D) :
    Rle (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (M + 1) (Nat.succ_pos M)))
        (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
              (⟨1, M + 1⟩ : Q)))
          (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos
            (Qmul_den_pos (logBound_den_pos T D hD M) (logBound_den_pos T D hD M))
            (logBound_den_pos T D hD M)) (Nat.succ_pos M)))) := by
  have LBd := logBound_den_pos T D hD M
  have hovnn : Rnonneg (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)) :=
    Rnonneg_ofQ (Nat.succ_pos M) (by show (0 : Int) ≤ 1; decide)
  have hLBcbnn : Rnonneg (ofQ (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
      (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd)) :=
    Rnonneg_congr (Rmul_ofQ_ofQ (Qmul_den_pos LBd LBd) LBd)
      (Rnonneg_Rmul (Rnonneg_congr (Rmul_ofQ_ofQ LBd LBd)
        (Rnonneg_Rmul (logBound_ofQ_nonneg T D M hD) (logBound_ofQ_nonneg T D M hD)))
        (logBound_ofQ_nonneg T D M hD))
  -- lnCubeOver(M+1) = logCube(M+1)·(1/(M+1)) ≤ logBound³·(1/(M+1))
  have hinner : Rle (lnCubeOver (M + 1) (Nat.succ_pos M))
      (Rmul (ofQ (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
          (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd)) (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M))) := by
    unfold lnCubeOver
    exact Rmul_le_Rmul_right hovnn (logCube_le T D M hD)
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 1; decide)) hinner) ?_
  have hinnerEq : Req (Rmul (ofQ (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
        (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd)) (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)))
      (ofQ (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M)) (⟨1, M + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) (Nat.succ_pos M))) :=
    Rmul_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) (Nat.succ_pos M)
  exact Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) hinnerEq)
    (Rmul_ofQ_ofQ (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) (Nat.succ_pos M))))

-- ===========================================================================
-- (C) The four per-step LOWER part bounds for `decompForm3 = b³C2 + b²R2 + b·R1 + R0`.
-- ===========================================================================

/-- **`δ⁴ ≤ 1/p⁴`** (`δ³ ≤ 1/p³` times `δ ≤ 1/p`). -/
theorem dquart_self_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp)) := by
  have hd_nn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hcube_nn : Rnonneg (ofQ (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos hp hp) hp)) :=
    Rnonneg_ofQ _ (by show (0 : Int) ≤ 1 * 1 * 1; decide)
  refine Rle_trans (Rmul_le_Rmul_right hd_nn (dcube_self_le p hp)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hcube_nn (deltaLog_upper p hp)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (a := mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
    (b := (⟨1, p⟩ : Q)) (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp)

/-- **`b³·C2 ≥ 0`** — `b³ ≥ 0` and `C2 ≥ 0` (`C2_nonneg`). -/
theorem b3C2_ge (p : Nat) (hp : 1 ≤ p) :
    Rle zero
      (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))) :=
  Rle_zero_of_Rnonneg (Rnonneg_Rmul
    (Rnonneg_Rmul (Rnonneg_Rmul_self (logN p hp)) (Rnonneg_logN p hp))
    (C2_nonneg p hp))

/-- **`b²·R2 ≥ −3/(p(p+1))`** — `b²·(3/2)·d·(u1−d) = −(b²·(3/2)·d·(d−u1))`, and
    `b²·(3/2)·d·(d−u1) ≤ (4p)·(3/2)·(1/p)·(1/(2p(p+1))) = 3/(p(p+1))`. -/
theorem b2R2_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨3, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hδmu1nn : Rnonneg (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) :=
    Rnonneg_Rsub_of_Rle (deltaLog_lower p hp)
  -- the form ≈ −P with P = b²·(3/2)·(d·(d−u1))
  have hswap : Req
      (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))))
      (Rneg (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))))) := by
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
      (Rmul_congr (Req_refl _) (Req_symm (Rneg_Rsub_swap _ _))))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _) (Rmul_neg_right _ _))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_neg_right _ _)) ?_
    exact Rmul_neg_right _ _
  -- P ≤ 3/(p(p+1))
  have hbsqnn : Rnonneg (Rmul (logN p hp) (logN p hp)) := Rnonneg_Rmul_self _
  have hXnn : Rnonneg (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide))
      (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) (Rnonneg_Rmul hδnn hδmu1nn)
  have hu0nn : Rnonneg (ofQ (⟨1, p⟩ : Q) hp) := Rnonneg_ofQ _ (by show (0 : Int) ≤ 1; decide)
  -- d·(d−u1) ≤ (1/p)·(1/(2p(p+1)))
  have h1 : Rle (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
      (ofQ (mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q))
        (Qmul_den_pos hp (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)))) := by
    refine Rle_trans (Rmul_le_Rmul_right hδmu1nn (deltaLog_upper p hp)) ?_
    refine Rle_trans (Rmul_le_Rmul_left hu0nn (dMinusU1_le p hp)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, 2 * p * (p + 1)⟩ : Q)) hp
      (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)))
  -- (3/2)·(d·(d−u1)) ≤ ofQ((3/2)·(1/p)·(1/(2p(p+1))))
  have h2 : Rle (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide))
        (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))))
      (ofQ (mul (⟨3, 2⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q)))
        (Qmul_den_pos (by decide)
          (Qmul_den_pos hp (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p))))) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) h1)
      (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨3, 2⟩ : Q))
        (b := mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q)) (by decide)
        (Qmul_den_pos hp (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)))))
  -- b²·(that) ≤ (4p)·(that) ≤ ofQ(4p·(3/2)·(1/p)·(1/(2p(p+1)))) = ofQ⟨3,p(p+1)⟩
  have hP : Rle (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))))
      (ofQ (⟨3, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_right hXnn (logSq_le_self4 p hp)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos
      (by show (0 : Int) ≤ 4 * (p : Int); omega)) h2) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ
      (a := (⟨4 * (p : Int), 1⟩ : Q))
      (b := mul (⟨3, 2⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q)))
      Nat.one_pos
      (Qmul_den_pos (by decide)
        (Qmul_den_pos hp (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)))))) ?_
    refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) (Qeq_le ?_)
    show Qeq (mul (⟨4 * (p : Int), 1⟩ : Q)
        (mul (⟨3, 2⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q))))
      (⟨3, p * (p + 1)⟩ : Q)
    simp only [Qeq, mul]
    push_cast
    ring_uor
  exact Rle_trans (Rle_Rneg hP) (Rle_of_Req (Req_symm hswap))

/-- **`b·R1 ≥ −2/(p(p+1))`** — `b·d²·((3/2)u1 − d) ≥ b·d²·(−d) = −b·d³`, and `b·d³ ≤ p·(1/p³) =
    1/p² ≤ 2/(p(p+1))`. -/
theorem bR1_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨2, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rmul (logN p hp)
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hbnn : Rnonneg (logN p hp) := Rnonneg_logN p hp
  have hδ2nn : Rnonneg (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := Rnonneg_Rmul_self _
  -- (3/2)u1 − d ≥ −d
  have hAnn : Rnonneg (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
      (Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide))
  -- Rneg d ≈ Rsub zero d ≤ Rsub ((3/2)u1) d  (since 0 ≤ (3/2)u1)
  have hX_ge : Rle (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
      (Rsub (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) :=
    Rle_trans (Rle_of_Req (Req_symm (Req_trans
        (Radd_comm zero (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
        (Radd_zero (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))))
      (Rsub_le_sub (Rle_zero_of_Rnonneg hAnn) (Rle_refl _))
  -- b·d²·((3/2)u1−d) ≥ b·d²·(−d) = −(b·d³)
  have hlow : Rle (Rmul (logN p hp) (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rmul (logN p hp)
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) :=
    Rmul_le_Rmul_left hbnn (Rmul_le_Rmul_left hδ2nn hX_ge)
  -- −(b·d³) form
  have hcollapse : Req (Rmul (logN p hp) (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rneg (Rmul (logN p hp) (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) :=
    Req_trans (Rmul_congr (Req_refl _) (Rmul_neg_right _ _)) (Rmul_neg_right _ _)
  -- b·d³ ≤ ofQ⟨2,p(p+1)⟩
  have hd3bound_nn : Rnonneg (ofQ (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos hp hp) hp)) :=
    Rnonneg_ofQ _ (by show (0 : Int) ≤ 1 * 1 * 1; decide)
  have hbd3 : Rle (Rmul (logN p hp) (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (ofQ (⟨2, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_left hbnn (dcube_self_le p hp)) ?_
    refine Rle_trans (Rmul_le_Rmul_right hd3bound_nn (logN_le_self p hp)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨(p : Int), 1⟩ : Q))
      (b := mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) Nat.one_pos
      (Qmul_den_pos (Qmul_den_pos hp hp) hp))) ?_
    refine Rle_trans (Rle_ofQ_ofQ
      (a := mul (⟨(p : Int), 1⟩ : Q) (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
      (b := (⟨1, p * p⟩ : Q))
      (Qmul_den_pos Nat.one_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp))
      (Nat.mul_pos hp hp) (Qeq_le ?_)) ?_
    · show Qeq (mul (⟨(p : Int), 1⟩ : Q) (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
        (⟨1, p * p⟩ : Q)
      simp only [Qeq, mul]
      push_cast
      ring_uor
    · refine Rle_ofQ_ofQ (Nat.mul_pos hp hp) (Nat.mul_pos hp (Nat.succ_pos p)) ?_
      show Qle (⟨1, p * p⟩ : Q) (⟨2, p * (p + 1)⟩ : Q)
      simp only [Qle, Int.one_mul]
      have key : p * (p + 1) ≤ 2 * (p * p) := by
        have hpsq : p ≤ p * p := Nat.le_mul_of_pos_left p hp
        have e4 : p * (p + 1) = p * p + p := by
          have : ((p * (p + 1) : Nat) : Int) = ((p * p + p : Nat) : Int) := by push_cast; ring_uor
          exact_mod_cast this
        omega
      exact_mod_cast key
  refine Rle_trans ?_ hlow
  exact Rle_trans (Rle_Rneg hbd3) (Rle_of_Req (Req_symm hcollapse))

/-- **`R0 = ½d³u1 − ¼d⁴ ≥ −1/(p(p+1))`** (`½d³u1 ≥ 0`, `d⁴ ≤ 1/p⁴`, drop the `−¼d⁴`). -/
theorem R0_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
        (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hu1nn : Rnonneg (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) :=
    Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)
  -- A = ½d³u1 ≥ 0
  have hA_nn : Rnonneg (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
      (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
      (Rnonneg_Rmul (Rnonneg_Rmul (Rnonneg_Rmul_self _) hδnn) hu1nn)
  -- R0 ≥ −B  (B = ¼d⁴)
  have hR0 : Rle (Rneg (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
        (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
    refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ hA_nn)
    refine Req_symm (Req_trans (Radd_congr (Req_refl _) (Rneg_neg _)) ?_)
    refine Req_trans (Radd_assoc _ (Rneg _) _) ?_
    exact Req_trans (Radd_congr (Req_refl _)
      (Req_trans (Radd_comm (Rneg _) _) (Radd_neg _))) (Radd_zero _)
  -- B = ¼d⁴ ≤ 1/(p(p+1))
  have hquart : Rle (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (dquart_self_le p hp)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨1, 4⟩ : Q))
      (b := mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (by decide)
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp))) ?_
    refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
    show Qle (mul (⟨1, 4⟩ : Q) (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
      (⟨1, p * (p + 1)⟩ : Q)
    simp only [Qle, mul, Int.one_mul, Int.mul_one]
    have key : p * (p + 1) ≤ 4 * (p * p * p * p) := by
      have hpp_pos : 0 < p * p := Nat.mul_pos hp hp
      have e4 : p * (p + 1) = p * p + p := by
        have : ((p * (p + 1) : Nat) : Int) = ((p * p + p : Nat) : Int) := by push_cast; ring_uor
        exact_mod_cast this
      have hpsq : p ≤ p * p := Nat.le_mul_of_pos_left p hp
      have hstep1 : p * (p + 1) ≤ 2 * (p * p) := by omega
      have h4 : 4 * (p * p * p * p) = (2 * (p * p)) * (2 * (p * p)) := by
        have : ((4 * (p * p * p * p) : Nat) : Int)
            = (((2 * (p * p)) * (2 * (p * p)) : Nat) : Int) := by push_cast; ring_uor
        exact_mod_cast this
      have hstep2 : 2 * (p * p) ≤ (2 * (p * p)) * (2 * (p * p)) :=
        Nat.le_mul_of_pos_left _ (by omega)
      omega
    exact_mod_cast key
  exact Rle_trans (Rle_Rneg hquart) hR0

-- ===========================================================================
-- (D) The per-step lower bound `sStep3 ≥ −6/(p(p+1))` and its telescoping.
-- ===========================================================================

/-- **The four-part per-step lower bound**: `sStep3 (j+1) ≥ 0 + (−3/D) + (−2/D) + (−1/D)`,
    `D = (j+1)(j+2)` — combining `b³C2 ≥ 0`, `b²R2 ≥ −3/D`, `bR1 ≥ −2/D`, `R0 ≥ −1/D` against
    `sStep3_decomp`. -/
theorem sStep3_lower_clean (j : Nat) :
    Rle (Radd (Radd (Radd zero
            (Rneg (ofQ (⟨3, (j + 1) * ((j + 1) + 1)⟩ : Q)
              (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
          (Rneg (ofQ (⟨2, (j + 1) * ((j + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
          (Rneg (ofQ (⟨1, (j + 1) * ((j + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
        (sStep3 (j + 1) (Nat.succ_pos j)) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (sStep3_decomp (j + 1) (Nat.succ_pos j))))
  exact Radd_le_add (Radd_le_add (Radd_le_add (b3C2_ge (j + 1) (Nat.succ_pos j))
    (b2R2_ge (j + 1) (Nat.succ_pos j))) (bR1_ge (j + 1) (Nat.succ_pos j)))
    (R0_ge (j + 1) (Nat.succ_pos j))

/-- **`sStep3 (j+1) ≥ −6/((j+1)(j+2))`** — the consolidated single-term per-step lower bound (the four
    parts `0 + 3 + 2 + 1` collapse over the common denominator `D = (j+1)(j+2)`). -/
theorem sStep3_lower_tele (j : Nat) :
    Rle (Rneg (ofQ (⟨6, (j + 1) * ((j + 1) + 1)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))))
        (sStep3 (j + 1) (Nat.succ_pos j)) := by
  have hD : 0 < (j + 1) * ((j + 1) + 1) := Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))
  -- collapse: LB ≈ −6/D
  have hcollapse : Req
      (Radd (Radd (Radd zero (Rneg (ofQ (⟨3, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
          (Rneg (ofQ (⟨2, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
          (Rneg (ofQ (⟨1, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
      (Rneg (ofQ (⟨6, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) := by
    -- (zero + N3) ≈ N3, then N3+N2 ≈ −5/D, then +N1 ≈ −6/D
    have hA : Req (Radd zero (Rneg (ofQ (⟨3, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
        (Rneg (ofQ (⟨3, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) :=
      Req_trans (Radd_comm zero _) (Radd_zero _)
    have hB : Req (Radd (Rneg (ofQ (⟨3, (j + 1) * ((j + 1) + 1)⟩ : Q) hD))
          (Rneg (ofQ (⟨2, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
        (Rneg (ofQ (⟨5, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) :=
      Req_trans (Req_symm (Rneg_Radd _ _))
        (Rneg_congr (Radd_ofQ_same 3 2 ((j + 1) * ((j + 1) + 1)) hD))
    have hC : Req (Radd (Rneg (ofQ (⟨5, (j + 1) * ((j + 1) + 1)⟩ : Q) hD))
          (Rneg (ofQ (⟨1, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
        (Rneg (ofQ (⟨6, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) :=
      Req_trans (Req_symm (Rneg_Radd _ _))
        (Rneg_congr (Radd_ofQ_same 5 1 ((j + 1) * ((j + 1) + 1)) hD))
    exact Req_trans (Radd_congr (Radd_congr hA (Req_refl _)) (Req_refl _))
      (Req_trans (Radd_congr hB (Req_refl _)) hC)
  exact Rle_trans (Rle_of_Req (Req_symm hcollapse)) (sStep3_lower_clean j)

/-- **Telescoping tail (lower)**: `hSeq3(N+k) ≥ hSeq3(N) − (6/(N+1) − 6/(N+k+1))` (`N ≥ 1`). -/
theorem hSeq3_tele_lo (N : Nat) (hN : 1 ≤ N) : ∀ k,
    Rle (Rsub (hSeq3 N) (Rsub (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨6, N + k + 1⟩ : Q) (Nat.succ_pos (N + k)))))
        (hSeq3 (N + k)) := by
  intro k
  induction k with
  | zero =>
    exact Rle_of_Req (Req_trans (Rsub_congr (Req_refl _)
      (Radd_neg (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N)))) (Radd_zero (hSeq3 N)))
  | succ k ih =>
    -- per-step: hSeq3(P+1) − hSeq3(P) ≥ −6/((P+1)(P+2)),  P = N+k
    have hstep : Rle (Rneg (ofQ (⟨6, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1)))))
        (Rsub (hSeq3 (N + k + 1)) (hSeq3 (N + k))) :=
      Rle_trans (sStep3_lower_tele (N + k)) (Rle_of_Req (Req_symm (hSeq3_step_eq (N + k))))
    have hABc : Req (Radd (Rsub (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨6, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))
          (ofQ (⟨6, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1)))))
        (Rsub (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))
          (ofQ (⟨6, N + (k + 1) + 1⟩ : Q) (Nat.succ_pos (N + (k + 1))))) := by
      apply Req_of_seq_Qeq; intro n
      show Qeq (add (add (⟨6, N + 1⟩ : Q) (neg (⟨6, N + k + 1⟩ : Q)))
          (⟨6, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q))
        (add (⟨6, N + 1⟩ : Q) (neg (⟨6, N + (k + 1) + 1⟩ : Q)))
      simp only [Qeq, add, neg, mul]
      push_cast
      ring_uor
    have hcombine : Req
        (Radd (Rsub (hSeq3 N) (Rsub (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))
              (ofQ (⟨6, N + k + 1⟩ : Q) (Nat.succ_pos (N + k)))))
          (Rneg (ofQ (⟨6, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1))))))
        (Rsub (hSeq3 N) (Rsub (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))
          (ofQ (⟨6, N + (k + 1) + 1⟩ : Q) (Nat.succ_pos (N + (k + 1)))))) := by
      refine Req_trans (Radd_assoc (hSeq3 N) _ _) ?_
      refine Radd_congr (Req_refl (hSeq3 N)) ?_
      exact Req_trans (Req_symm (Rneg_Radd _ _)) (Rneg_congr hABc)
    refine Rle_trans (Rle_of_Req (Req_symm hcombine)) ?_
    refine Rle_trans (Radd_le_add ih hstep) ?_
    exact Rle_of_Req (Req_symm (sub_add_cancel_real (hSeq3 (N + k + 1)) (hSeq3 (N + k))))

/-- **`hSeq3(N+k) ≥ hSeq3(N) − 6/(N+1)`** (uniform in `k`, `N ≥ 1`) — drop the nonneg `+6/(N+k+1)`. -/
theorem hSeq3_lower_const (N : Nat) (hN : 1 ≤ N) (k : Nat) :
    Rle (Rsub (hSeq3 N) (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))) (hSeq3 (N + k)) := by
  have hBkle : Rle (Rsub (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))
        (ofQ (⟨6, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))
      (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N)) :=
    Rsub_le_self _ (Rnonneg_ofQ (Nat.succ_pos (N + k)) (by show (0 : Int) ≤ 6; decide))
  exact Rle_trans (Rsub_le_sub (Rle_of_Req (Req_refl (hSeq3 N))) hBkle) (hSeq3_tele_lo N hN k)

/-- **`hSeq3 N ≤ g3Seq N`** — `g3Seq N = hSeq3 N + ½·(ln(N+1))³/(N+1)` and the correction is `≥ 0`. -/
theorem hSeq3_le_g3Seq (N : Nat) : Rle (hSeq3 N) (g3Seq N) := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (Rsub_sub_self (g3Seq N)
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (N + 1) (Nat.succ_pos N))))) ?_)
  exact Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
    (lnCubeOver_nonneg (N + 1) (Nat.succ_pos N))

/-- **`γ₃ ≥ hSeq3 N − 6/(N+1)`** for `N ∈ [1, 2^14]` — each reindexed `g3SeqDyadic k = g3Seq(2^{2k+14})`
    (`≥ 2^14 ≥ N`) is `≥ hSeq3(2^{2k+14}) ≥ hSeq3 N − 6/(N+1)`, so the limit is too. -/
theorem Rgamma3_ge_hSeq3 {N : Nat} (hN : 1 ≤ N) (hN14 : N ≤ 2 ^ 14) :
    Rle (Rsub (hSeq3 N) (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))) Rgamma3 := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have hN2k : N ≤ 2 ^ (2 * k + 14) := by
    have h14 : (2 : Nat) ^ 14 ≤ 2 ^ (2 * k + 14) := Nat.pow_le_pow_right (by omega) (by omega)
    omega
  have htend : Rle (Rsub (g3SeqDyadic k) Rgamma3) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    RTendsTo_to_Rle (Rlim_tendsTo g3SeqDyadic g3SeqDyadic_RReg) k
  have hanchor : Rle (Rsub (hSeq3 N) (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))) (g3SeqDyadic k) := by
    obtain ⟨d, hd⟩ := Nat.le.dest hN2k
    have h1 : Rle (Rsub (hSeq3 N) (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))) (hSeq3 (N + d)) :=
      hSeq3_lower_const N hN d
    rw [hd] at h1
    exact Rle_trans h1 (hSeq3_le_g3Seq (2 ^ (2 * k + 14)))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split
    (Rsub (hSeq3 N) (ofQ (⟨6, N + 1⟩ : Q) (Nat.succ_pos N))) (g3SeqDyadic k) Rgamma3))) ?_
  refine Rle_trans (Radd_le_add
    (Rsub_le_of_le_add (Rle_trans hanchor (Rle_of_Req
      (Req_symm (Req_trans (Radd_comm zero (g3SeqDyadic k)) (Radd_zero (g3SeqDyadic k)))))))
    htend) ?_
  exact Rle_of_Req (Req_trans (Radd_comm zero _) (Radd_zero _))

-- ===========================================================================
-- (E) The numeric bracket: `γ₃ ≥ −1/20`.
-- ===========================================================================

/-- The **rational lower bound on `hSeq3 N`** (depth `T`, denominator `D`) as a single `Q` (`def`, so
    the deep evaluator term stays opaque downstream — the `gBound` pattern).  `lnCubeSumLo` (sum,
    lower) minus the two corrections upper-bounded by `logBound⁴`/`logBound³`. -/
def gBound3lo (T D N : Nat) : Q :=
  add (add (lnCubeSumLo T D (N + 1))
      (neg (mul (⟨1, 4⟩ : Q) (mul (mul (mul (logBound T D N) (logBound T D N))
        (logBound T D N)) (logBound T D N)))))
    (neg (mul (⟨1, 2⟩ : Q) (mul (mul (mul (logBound T D N) (logBound T D N))
      (logBound T D N)) (⟨1, N + 1⟩ : Q))))

theorem gBound3lo_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound3lo T D N).den :=
  add_den_pos (add_den_pos (lnCubeSumLo_den_pos T D hD (N + 1))
      (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logBound_den_pos T D hD N)
        (logBound_den_pos T D hD N)) (logBound_den_pos T D hD N)) (logBound_den_pos T D hD N))))
    (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logBound_den_pos T D hD N)
      (logBound_den_pos T D hD N)) (logBound_den_pos T D hD N)) (Nat.succ_pos N)))

set_option maxRecDepth 40000 in
/-- **`ofQ(gBound3lo T D N) ≤ hSeq3 N`** (`T ≤ 21`) — the rational lower bound (`lnCubeSum_ge`,
    `logQuartic_le`, `halfCubeOver_le`), collapsing the all-`ofQ` Rsub-tower to the single `gBound3lo`. -/
theorem hSeq3_ge_gBound3lo (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (gBound3lo T D N) (gBound3lo_den_pos T D N hD)) (hSeq3 N) := by
  have LBd := logBound_den_pos T D hD N
  have hquart : Rle (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (logQuartic (N + 1) (Nat.succ_pos N)))
      (ofQ (mul (⟨1, 4⟩ : Q) (mul (mul (mul (logBound T D N) (logBound T D N))
          (logBound T D N)) (logBound T D N)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd))) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (logQuartic_le T D N hD))
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd)))
  have hlow : Rle (Rsub (Rsub (ofQ (lnCubeSumLo T D (N + 1)) (lnCubeSumLo_den_pos T D hD (N + 1)))
        (ofQ (mul (⟨1, 4⟩ : Q) (mul (mul (mul (logBound T D N) (logBound T D N))
            (logBound T D N)) (logBound T D N)))
          (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd))))
      (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (mul (logBound T D N) (logBound T D N)) (logBound T D N))
          (⟨1, N + 1⟩ : Q)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd)
          (Nat.succ_pos N))))) (hSeq3 N) := by
    unfold hSeq3 g3Seq
    exact Rsub_le_sub (Rsub_le_sub (lnCubeSum_ge T D hD hT (N + 1)) hquart) (halfCubeOver_le T D N hD)
  exact Rle_trans (Rle_of_Req (Req_symm (Req_of_seq_Qeq (fun _ => Qeq_refl _)))) hlow

set_option maxRecDepth 40000 in
/-- The numeric heart: `−1/20 ≤ gBound3lo 3 10⁸ 199 − 6/200` — one big-integer kernel `decide`. -/
theorem gamma3_lo_decide :
    Qle (⟨-1, 20⟩ : Q) (Qsub (gBound3lo 3 100000000 199) (⟨6, 199 + 1⟩ : Q)) := by decide

/-- **`γ₃ ≥ −1/20` (`= −0.05`)** — the certified LOWER bracket on the third Stieltjes constant,
    completing the two-sided bracket `−1/20 ≤ γ₃ ≤ 1/8`.  `γ₃ ≥ hSeq3(199) − 6/200`
    (`Rgamma3_ge_hSeq3`), `hSeq3(199) ≥ ofQ(gBound3lo 3 10⁸ 199)` (`hSeq3_ge_gBound3lo`),
    `gBound3lo 3 10⁸ 199 − 6/200 ≥ −1/20` (`gamma3_lo_decide`). -/
theorem Rgamma3_ge_neg005 : Rle (ofQ (⟨-1, 20⟩ : Q) (by decide)) Rgamma3 := by
  have hD : 0 < 100000000 := by decide
  refine Rle_trans ?_ (Rgamma3_ge_hSeq3 (show 1 ≤ 199 by decide) (show 199 ≤ 2 ^ 14 by decide))
  refine Rle_trans ?_
    (Rsub_le_sub (hSeq3_ge_gBound3lo 3 100000000 199 hD (by decide)) (Rle_of_Req (Req_refl _)))
  exact Rle_trans
    (Rle_ofQ_ofQ (by decide)
      (add_den_pos (gBound3lo_den_pos 3 100000000 199 hD) (Nat.succ_pos 199)) gamma3_lo_decide)
    (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ (gBound3lo_den_pos 3 100000000 199 hD) (Nat.succ_pos 199))))

end UOR.Bridge.F1Square.Analysis
