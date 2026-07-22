/-
F1 square — stage F: **the certified lower bracket `γ₄ ≥ −1/20`** via DISCRETE Euler–Maclaurin
(NO constructive integration), the LOWER companion of `GammaFourBracket.lean`.

One-degree-up mirror of `GammaThreeLower.lean` (`γ₃ ≥ −1/20`).  Same accelerated sequence
`hSeq4 j = g₄(j) − ½·(ln(j+1))⁴/(j+1)` (`→ γ₄`), whose per-step increment is the trapezoidal residual
`sStep4 = O((ln p)⁴/p³)`; here we bound it BELOW (`sStep4 ≥ −46/(p(p+1))`) instead of above, telescope
to `γ₄ ≥ hSeq4(N) − 46/(N+1)`, and certify at a feasible `N` with the rational quartic/quintic-log
evaluators in the LOWER direction (`lnQuartSumLo` for the sum, `logBound` for the subtracted corrections).

The five parts of `decompForm4 = b⁴C2 + b³R3 + b²R2 + b·R1 + R0` (`d = a−b`, `b = ln p`):
  b⁴·C2 ≥ 0             (`b⁴ ≥ 0`, `C2 ≥ 0` via `C2_nonneg`, the SAME `C2` as degree 3)
  b³·R3 ≥ −27/(p(p+1))  (`R3 = 2d(u1−d) = −2d(d−u1)`, `b³ ≤ 27p`, `d ≤ 1/p`, `d−u1 ≤ 1/(2p(p+1))`)
  b²·R2 ≥ −16/(p(p+1))  (`R2 = d²(3u1−2d) ≥ d²(−2d) = −2d³`, `b² ≤ 4p`, `d³ ≤ 1/p³`)
  b·R1  ≥ −2/(p(p+1))   (`R1 = d³(2u1−d) ≥ d³(−d) = −d⁴`, `b ≤ p`, `d⁴ ≤ 1/p⁴`)
  R0    ≥ −1/(p(p+1))   (`R0 = ½d⁴u1 − (1/5)d⁵ ≥ −(1/5)d⁵`, `d⁵ ≤ 1/p⁵`)

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.GammaFourBracket
import Core.F1.Analysis.GammaThreeLower

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- (A) `lnQuartSumLo` — a rational LOWER bound for `lnQuartSum N = Σ_{k=1}^N (ln k)⁴/k`.
-- Mirror of `lnCubeSumLo`, with `logLowBound` to the FOURTH.
-- ===========================================================================

/-- The accumulated rational lower bound for `Σ_{k=1}^N (ln k)⁴/k`, at fixed denominator `D`: each new
    term `(log(n+1))⁴/(n+1) ≥ (logLowBound n)⁴·(1/(n+1))`, then round DOWN. -/
def lnQuartSumLo (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (n + 1) =>
      qRoundDown (add (lnQuartSumLo T D n)
        (mul (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n))
          (logLowBound T D n)) ⟨1, n + 1⟩)) D

theorem lnQuartSumLo_den_pos (T D : Nat) (hD : 0 < D) : ∀ N, 0 < (lnQuartSumLo T D N).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`ofQ(lnQuartSumLo T D N) ≤ lnQuartSum N`** — the partial sum `Σ (log k)⁴/k` bounded BELOW
    term-by-term via `logN_ge_logLowBound` (to the 4th monotonically, all nonneg), accumulated at
    denominator `D` (round down), artanh depth `T ≤ 21`. -/
theorem lnQuartSum_ge (T D : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    ∀ N, Rle (ofQ (lnQuartSumLo T D N) (lnQuartSumLo_den_pos T D hD N)) (lnQuartSum N) := by
  intro N
  induction N with
  | zero =>
    have h0 : Req (ofQ (lnQuartSumLo T D 0) (lnQuartSumLo_den_pos T D hD 0)) zero :=
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
    have hLLcbnn : Rnonneg (Rmul (Rmul (ofQ (logLowBound T D n) hLLd) (ofQ (logLowBound T D n) hLLd))
        (ofQ (logLowBound T D n) hLLd)) := Rnonneg_Rmul hLLsqnn hLLnn
    have hlogcbnn : Rnonneg (Rmul (Rmul (logN (n + 1) (Nat.succ_pos n)) (logN (n + 1) (Nat.succ_pos n)))
        (logN (n + 1) (Nat.succ_pos n))) := Rnonneg_Rmul hlogsqnn hlognn
    -- (LL)⁴ ≤ (log(n+1))⁴
    have hq4 : Rle (Rmul (Rmul (Rmul (ofQ (logLowBound T D n) hLLd) (ofQ (logLowBound T D n) hLLd))
            (ofQ (logLowBound T D n) hLLd)) (ofQ (logLowBound T D n) hLLd))
        (Rmul (Rmul (Rmul (logN (n + 1) (Nat.succ_pos n)) (logN (n + 1) (Nat.succ_pos n)))
            (logN (n + 1) (Nat.succ_pos n))) (logN (n + 1) (Nat.succ_pos n))) :=
      Rle_trans (Rmul_le_Rmul_right hLLnn hcb) (Rmul_le_Rmul_left hlogcbnn hlow)
    have hmuld : 0 < (mul (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n))
        (logLowBound T D n)) (⟨1, n + 1⟩ : Q)).den :=
      Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hLLd hLLd) hLLd) hLLd) (Nat.succ_pos n)
    have hq4d : 0 < (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n))
        (logLowBound T D n)).den :=
      Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hLLd hLLd) hLLd) hLLd
    -- per-term: ofQ(LL⁴·(1/(n+1))) ≤ (log⁴)·(1/(n+1)) = lnQuartOver (n+1)
    have hterm : Rle (ofQ (mul (mul (mul (mul (logLowBound T D n) (logLowBound T D n))
            (logLowBound T D n)) (logLowBound T D n)) ⟨1, n + 1⟩) hmuld)
        (lnQuartOver (n + 1) (Nat.succ_pos n)) := by
      refine Rle_trans (Rle_of_Req ?_)
        (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos n) (by show (0 : Int) ≤ 1; decide)) hq4)
      refine Req_trans (Req_symm (Rmul_ofQ_ofQ hq4d (Nat.succ_pos n))) ?_
      refine Rmul_congr ?_ (Req_refl _)
      exact Req_symm (Req_trans (Rmul_congr (Req_trans (Rmul_congr (Rmul_ofQ_ofQ hLLd hLLd)
          (Req_refl _)) (Rmul_ofQ_ofQ (Qmul_den_pos hLLd hLLd) hLLd)) (Req_refl _))
        (Rmul_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos hLLd hLLd) hLLd) hLLd))
    -- accumulate
    refine Rle_trans (Rle_ofQ_ofQ (lnQuartSumLo_den_pos T D hD (n + 1))
      (add_den_pos (lnQuartSumLo_den_pos T D hD n) hmuld)
      (qRoundDown_le (add (lnQuartSumLo T D n)
        (mul (mul (mul (mul (logLowBound T D n) (logLowBound T D n)) (logLowBound T D n))
          (logLowBound T D n)) ⟨1, n + 1⟩))
        (add_den_pos (lnQuartSumLo_den_pos T D hD n) hmuld) D)) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (lnQuartSumLo_den_pos T D hD n) hmuld)) ?_
    exact Radd_le_add ih hterm

-- ===========================================================================
-- (B) Quintic-/quartic-log UPPER bounds (`logBound`) — for the subtracted terms of `hSeq4`.
-- ===========================================================================

/-- **Quintic-log upper bound** `(ln(M+1))⁵ ≤ logBound⁵` — `logQuintic = logQuartic·logN`, each factor
    `≤ logBound`. -/
theorem logQuintic_le (T D M : Nat) (hD : 0 < D) :
    Rle (logQuintic (M + 1) (Nat.succ_pos M))
        (ofQ (mul (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
              (logBound T D M)) (logBound T D M))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logBound_den_pos T D hD M)
            (logBound_den_pos T D hD M)) (logBound_den_pos T D hD M)) (logBound_den_pos T D hD M))
            (logBound_den_pos T D hD M))) := by
  have LBd := logBound_den_pos T D hD M
  have hLBq4nn : Rnonneg (ofQ (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
      (logBound T D M)) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd)) :=
    Rnonneg_congr (Rmul_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd)
      (Rnonneg_Rmul (Rnonneg_congr (Rmul_ofQ_ofQ (Qmul_den_pos LBd LBd) LBd)
        (Rnonneg_Rmul (Rnonneg_congr (Rmul_ofQ_ofQ LBd LBd)
          (Rnonneg_Rmul (logBound_ofQ_nonneg T D M hD) (logBound_ofQ_nonneg T D M hD)))
          (logBound_ofQ_nonneg T D M hD))) (logBound_ofQ_nonneg T D M hD))
  unfold logQuintic
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_logN _ _) (logQuartic_le T D M hD)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hLBq4nn (logN_le_logBound T D hD M)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd) LBd)

/-- **Half-quartic-over-`N` upper bound** `½·(ln(M+1))⁴/(M+1) ≤ ½·logBound⁴/(M+1)` — the trapezoidal
    anchor `½f(M+1)`, `f(x) = ln⁴x/x`, bounded above. -/
theorem halfQuartOver_le (T D M : Nat) (hD : 0 < D) :
    Rle (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (M + 1) (Nat.succ_pos M)))
        (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (mul (mul (logBound T D M) (logBound T D M))
              (logBound T D M)) (logBound T D M)) (⟨1, M + 1⟩ : Q)))
          (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos
            (Qmul_den_pos (logBound_den_pos T D hD M) (logBound_den_pos T D hD M))
            (logBound_den_pos T D hD M)) (logBound_den_pos T D hD M)) (Nat.succ_pos M)))) := by
  have LBd := logBound_den_pos T D hD M
  have hovnn : Rnonneg (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)) :=
    Rnonneg_ofQ (Nat.succ_pos M) (by show (0 : Int) ≤ 1; decide)
  have hLBq4nn : Rnonneg (ofQ (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
      (logBound T D M)) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd)) :=
    Rnonneg_congr (Rmul_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd)
      (Rnonneg_Rmul (Rnonneg_congr (Rmul_ofQ_ofQ (Qmul_den_pos LBd LBd) LBd)
        (Rnonneg_Rmul (Rnonneg_congr (Rmul_ofQ_ofQ LBd LBd)
          (Rnonneg_Rmul (logBound_ofQ_nonneg T D M hD) (logBound_ofQ_nonneg T D M hD)))
          (logBound_ofQ_nonneg T D M hD))) (logBound_ofQ_nonneg T D M hD))
  -- lnQuartOver(M+1) = logQuartic(M+1)·(1/(M+1)) ≤ logBound⁴·(1/(M+1))
  have hinner : Rle (lnQuartOver (M + 1) (Nat.succ_pos M))
      (Rmul (ofQ (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M)) (logBound T D M))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd))
        (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M))) := by
    unfold lnQuartOver
    exact Rmul_le_Rmul_right hovnn (logQuartic_le T D M hD)
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 1; decide)) hinner) ?_
  have hinnerEq : Req (Rmul (ofQ (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
        (logBound T D M)) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd))
        (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)))
      (ofQ (mul (mul (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M)) (logBound T D M))
          (⟨1, M + 1⟩ : Q))
        (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd) (Nat.succ_pos M))) :=
    Rmul_ofQ_ofQ (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd) (Nat.succ_pos M)
  exact Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) hinnerEq)
    (Rmul_ofQ_ofQ (by decide)
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd) (Nat.succ_pos M))))

-- ===========================================================================
-- (C) The five per-step LOWER part bounds for `decompForm4 = b⁴C2 + b³R3 + b²R2 + b·R1 + R0`.
-- ===========================================================================

-- `δ⁴ ≤ 1/p⁴` is reused from the degree-3-lower lemma `dquart_self_le` (identical statement).

/-- **`δ⁵ ≤ 1/p⁵`** (`δ⁴ ≤ 1/p⁴` times `δ ≤ 1/p`). -/
theorem dquint_self_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (mul (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp) hp)) := by
  have hd_nn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hquart_nn : Rnonneg (ofQ (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp)) :=
    Rnonneg_ofQ _ (by show (0 : Int) ≤ 1 * 1 * 1 * 1; decide)
  refine Rle_trans (Rmul_le_Rmul_right hd_nn (dquart_self_le p hp)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hquart_nn (deltaLog_upper p hp)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ
    (a := mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
    (b := (⟨1, p⟩ : Q)) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp) hp)

/-- **`b⁴·C2 ≥ 0`** — `b⁴ ≥ 0` and `C2 ≥ 0` (`C2_nonneg`, the SAME `C2` as degree 3). -/
theorem b4C2_ge (p : Nat) (hp : 1 ≤ p) :
    Rle zero
      (Rmul (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) (logN p hp))
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))) :=
  Rle_zero_of_Rnonneg (Rnonneg_Rmul
    (Rnonneg_Rmul (Rnonneg_Rmul (Rnonneg_Rmul_self (logN p hp)) (Rnonneg_logN p hp))
      (Rnonneg_logN p hp))
    (C2_nonneg p hp))

/-- **`b³·R3 ≥ −27/(p(p+1))`** — `b³·2·d·(u1−d) = −(b³·2·d·(d−u1))`, and
    `b³·2·d·(d−u1) ≤ (27p)·2·(1/p)·(1/(2p(p+1))) = 27/(p(p+1))`. -/
theorem b3R3_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨27, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hδmu1nn : Rnonneg (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) :=
    Rnonneg_Rsub_of_Rle (deltaLog_lower p hp)
  -- the form ≈ −P with P = b³·2·(d·(d−u1))
  have hswap : Req
      (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))))
      (Rneg (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))))) := by
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
      (Rmul_congr (Req_refl _) (Req_symm (Rneg_Rsub_swap _ _))))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _) (Rmul_neg_right _ _))) ?_
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_neg_right _ _)) ?_
    exact Rmul_neg_right _ _
  -- P ≤ 27/(p(p+1))
  have hbcbnn : Rnonneg (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp)) :=
    Rnonneg_Rmul (Rnonneg_Rmul_self _) (Rnonneg_logN p hp)
  have hXnn : Rnonneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
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
  -- 2·(d·(d−u1)) ≤ ofQ(2·(1/p)·(1/(2p(p+1))))
  have h2 : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))))
      (ofQ (mul (⟨2, 1⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q)))
        (Qmul_den_pos (by decide)
          (Qmul_den_pos hp (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p))))) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) h1)
      (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨2, 1⟩ : Q))
        (b := mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q)) (by decide)
        (Qmul_den_pos hp (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)))))
  -- b³·(that) ≤ (27p)·(that) ≤ ofQ(27p·2·(1/p)·(1/(2p(p+1)))) = ofQ⟨27,p(p+1)⟩
  have hP : Rle (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))))
      (ofQ (⟨27, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_right hXnn (logCube_le_self27 p hp)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos
      (by show (0 : Int) ≤ 27 * (p : Int); omega)) h2) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ
      (a := (⟨27 * (p : Int), 1⟩ : Q))
      (b := mul (⟨2, 1⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q)))
      Nat.one_pos
      (Qmul_den_pos (by decide)
        (Qmul_den_pos hp (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)))))) ?_
    refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) (Qeq_le ?_)
    show Qeq (mul (⟨27 * (p : Int), 1⟩ : Q)
        (mul (⟨2, 1⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, 2 * p * (p + 1)⟩ : Q))))
      (⟨27, p * (p + 1)⟩ : Q)
    simp only [Qeq, mul]
    push_cast
    ring_uor
  exact Rle_trans (Rle_Rneg hP) (Rle_of_Req (Req_symm hswap))

/-- **`b²·R2 ≥ −16/(p(p+1))`** — `b²·d²·(3u1−2d) ≥ b²·d²·(−2d) = −(2·b²·d³)`, and
    `2·b²·d³ ≤ 2·(4p)·(1/p³) = 8/p² ≤ 16/(p(p+1))`. -/
theorem b2R2_ge4 (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨16, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hbsqnn : Rnonneg (Rmul (logN p hp) (logN p hp)) := Rnonneg_Rmul_self _
  have hδ2nn : Rnonneg (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := Rnonneg_Rmul_self _
  -- 3u1 − 2d ≥ −(2d)  (since 3u1 ≥ 0)
  have h3u1nn : Rnonneg (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
      (Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide))
  have hX_ge : Rle (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))) :=
    Rle_trans (Rle_of_Req (Req_symm (Req_trans
        (Radd_comm zero (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
        (Radd_zero (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))))))
      (Rsub_le_sub (Rle_zero_of_Rnonneg h3u1nn) (Rle_refl _))
  -- b²·d²·(3u1−2d) ≥ b²·d²·(−2d) = −(b²·d²·2d)
  have hlow : Rle (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))))
      (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))) :=
    Rmul_le_Rmul_left hbsqnn (Rmul_le_Rmul_left hδ2nn hX_ge)
  -- collapse −(b²·d²·2d) = −(2·(b²·d³))
  have hcollapse : Req (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))))
      (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (Rmul (logN p hp) (logN p hp))
          (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))) := by
    -- d²·(−(2·d)) ≈ −(2·(d²·d)) = −(2·d³)
    have hinner : Req
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
        (Rneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
          (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
      refine Req_trans (Rmul_neg_right _ _) ?_
      refine Rneg_congr ?_
      exact Req_trans (Rmul_left_comm3 _ _ _) (Req_refl _)
    refine Req_trans (Rmul_congr (Req_refl _) hinner) ?_
    refine Req_trans (Rmul_neg_right _ _) ?_
    refine Rneg_congr ?_
    exact Rmul_left_comm3 _ _ _
  -- 2·(b²·d³) ≤ ofQ⟨16,p(p+1)⟩
  have hd3bound_nn : Rnonneg (ofQ (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos hp hp) hp)) :=
    Rnonneg_ofQ _ (by show (0 : Int) ≤ 1 * 1 * 1; decide)
  have hbd3nn : Rnonneg (Rmul (Rmul (logN p hp) (logN p hp))
      (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))) :=
    Rnonneg_Rmul hbsqnn (Rnonneg_Rmul hδ2nn hδnn)
  have hbd3 : Rle (Rmul (Rmul (logN p hp) (logN p hp))
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (ofQ (⟨8, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rmul hδ2nn hδnn) (logSq_le_self4 p hp)) ?_
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ Nat.one_pos
      (by show (0 : Int) ≤ 4 * (p : Int); omega)) (dcube_self_le p hp)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨4 * (p : Int), 1⟩ : Q))
      (b := mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) Nat.one_pos
      (Qmul_den_pos (Qmul_den_pos hp hp) hp))) ?_
    refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
    show Qle (mul (⟨4 * (p : Int), 1⟩ : Q) (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
      (⟨8, p * (p + 1)⟩ : Q)
    simp only [Qle, mul, Int.one_mul, Int.mul_one]
    have key : 4 * p * (p * (p + 1)) ≤ 8 * (1 * (p * p * p)) := by
      have eL : 4 * p * (p * (p + 1)) = 4 * (p * p * p) + 4 * (p * p) := by
        have : ((4 * p * (p * (p + 1)) : Nat) : Int)
            = ((4 * (p * p * p) + 4 * (p * p) : Nat) : Int) := by push_cast; ring_uor
        exact_mod_cast this
      have hle : p * p ≤ p * p * p := Nat.le_mul_of_pos_right (p * p) hp
      omega
    exact_mod_cast key
  have hscale : Rle (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide))
        (Rmul (Rmul (logN p hp) (logN p hp))
          (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (ofQ (⟨16, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hbd3) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨2, 1⟩ : Q)) (b := (⟨8, p * (p + 1)⟩ : Q))
      (by decide) (Nat.mul_pos hp (Nat.succ_pos p)))) ?_
    refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) (Qeq_le ?_)
    show Qeq (mul (⟨2, 1⟩ : Q) (⟨8, p * (p + 1)⟩ : Q)) (⟨16, p * (p + 1)⟩ : Q)
    simp only [Qeq, mul]
    push_cast
    ring_uor
  refine Rle_trans ?_ hlow
  exact Rle_trans (Rle_Rneg hscale) (Rle_of_Req (Req_symm hcollapse))

/-- **`b·R1 ≥ −2/(p(p+1))`** — `b·d³·(2u1−d) ≥ b·d³·(−d) = −(b·d⁴)`, and `b·d⁴ ≤ p·(1/p⁴) =
    1/p³ ≤ 2/(p(p+1))`. -/
theorem bR1_ge4 (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨2, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rmul (logN p hp)
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hbnn : Rnonneg (logN p hp) := Rnonneg_logN p hp
  have hδ3nn : Rnonneg (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) :=
    Rnonneg_Rmul (Rnonneg_Rmul_self _) hδnn
  -- 2u1 − d ≥ −d  (2u1 ≥ 0)
  have hAnn : Rnonneg (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
      (Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide))
  have hX_ge : Rle (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
      (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) :=
    Rle_trans (Rle_of_Req (Req_symm (Req_trans
        (Radd_comm zero (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
        (Radd_zero (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))))
      (Rsub_le_sub (Rle_zero_of_Rnonneg hAnn) (Rle_refl _))
  -- b·d³·(2u1−d) ≥ b·d³·(−d) = −(b·d⁴)
  have hlow : Rle (Rmul (logN p hp)
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rmul (logN p hp)
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) :=
    Rmul_le_Rmul_left hbnn (Rmul_le_Rmul_left hδ3nn hX_ge)
  -- −(b·d⁴) form
  have hcollapse : Req (Rmul (logN p hp)
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rneg (Rmul (logN p hp)
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) :=
    Req_trans (Rmul_congr (Req_refl _) (Rmul_neg_right _ _)) (Rmul_neg_right _ _)
  -- b·d⁴ ≤ ofQ⟨2,p(p+1)⟩
  have hd4bound_nn : Rnonneg (ofQ (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp)) :=
    Rnonneg_ofQ _ (by show (0 : Int) ≤ 1 * 1 * 1 * 1; decide)
  have hbd4 : Rle (Rmul (logN p hp)
        (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (ofQ (⟨2, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_left hbnn (dquart_self_le p hp)) ?_
    refine Rle_trans (Rmul_le_Rmul_right hd4bound_nn (logN_le_self p hp)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨(p : Int), 1⟩ : Q))
      (b := mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) Nat.one_pos
      (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp))) ?_
    refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
    show Qle (mul (⟨(p : Int), 1⟩ : Q)
        (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
      (⟨2, p * (p + 1)⟩ : Q)
    simp only [Qle, mul, Int.one_mul, Int.mul_one]
    have key : p * (p * (p + 1)) ≤ 2 * (1 * (p * p * p * p)) := by
      have eL : p * (p * (p + 1)) = p * p * p + p * p := by
        have : ((p * (p * (p + 1)) : Nat) : Int) = ((p * p * p + p * p : Nat) : Int) := by
          push_cast; ring_uor
        exact_mod_cast this
      have h1 : p * p ≤ p * p * p := Nat.le_mul_of_pos_right (p * p) hp
      have h2 : p * p * p ≤ p * p * p * p := Nat.le_mul_of_pos_right (p * p * p) hp
      omega
    exact_mod_cast key
  refine Rle_trans ?_ hlow
  exact Rle_trans (Rle_Rneg hbd4) (Rle_of_Req (Req_symm hcollapse))

/-- **`R0 = ½d⁴u1 − (1/5)d⁵ ≥ −1/(p(p+1))`** (`½d⁴u1 ≥ 0`, `d⁵ ≤ 1/p⁵`, drop the `−(1/5)d⁵`). -/
theorem R0_ge4 (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))))
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
        (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hu1nn : Rnonneg (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) :=
    Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)
  -- A = ½d⁴u1 ≥ 0
  have hA_nn : Rnonneg (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
      (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
      (Rnonneg_Rmul (Rnonneg_Rmul (Rnonneg_Rmul (Rnonneg_Rmul_self _) hδnn) hδnn) hu1nn)
  -- R0 ≥ −B  (B = (1/5)d⁵)
  have hR0 : Rle (Rneg (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
        (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
          (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
    refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ hA_nn)
    refine Req_symm (Req_trans (Radd_congr (Req_refl _) (Rneg_neg _)) ?_)
    refine Req_trans (Radd_assoc _ (Rneg _) _) ?_
    exact Req_trans (Radd_congr (Req_refl _)
      (Req_trans (Radd_comm (Rneg _) _) (Radd_neg _))) (Radd_zero _)
  -- B = (1/5)d⁵ ≤ 1/(p(p+1))
  have hquint : Rle (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (dquint_self_le p hp)) ?_
    refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨1, 5⟩ : Q))
      (b := mul (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
      (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) hp) hp))) ?_
    refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
    show Qle (mul (⟨1, 5⟩ : Q)
        (mul (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
      (⟨1, p * (p + 1)⟩ : Q)
    simp only [Qle, mul, Int.one_mul, Int.mul_one]
    have key : p * (p + 1) ≤ 5 * (p * p * p * p * p) := by
      have eL : p * (p + 1) = p * p + p := by
        have : ((p * (p + 1) : Nat) : Int) = ((p * p + p : Nat) : Int) := by push_cast; ring_uor
        exact_mod_cast this
      have hp1 : p ≤ p * p := Nat.le_mul_of_pos_right p hp
      have h2 : p * p ≤ p * p * p := Nat.le_mul_of_pos_right (p * p) hp
      have h3 : p * p * p ≤ p * p * p * p := Nat.le_mul_of_pos_right (p * p * p) hp
      have h4 : p * p * p * p ≤ p * p * p * p * p := Nat.le_mul_of_pos_right (p * p * p * p) hp
      omega
    exact_mod_cast key
  exact Rle_trans (Rle_Rneg hquint) hR0

-- ===========================================================================
-- (D) The per-step lower bound `sStep4 ≥ −46/(p(p+1))` and its telescoping.
-- ===========================================================================

/-- **The five-part per-step lower bound**: `sStep4 (j+1) ≥ 0 + (−27/D) + (−16/D) + (−2/D) + (−1/D)`,
    `D = (j+1)(j+2)` — combining `b4C2 ≥ 0`, `b3R3 ≥ −27/D`, `b2R2 ≥ −16/D`, `bR1 ≥ −2/D`,
    `R0 ≥ −1/D` against `sStep4_decomp`. -/
theorem sStep4_lower_clean (j : Nat) :
    Rle (Radd (Radd (Radd (Radd zero
            (Rneg (ofQ (⟨27, (j + 1) * ((j + 1) + 1)⟩ : Q)
              (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
          (Rneg (ofQ (⟨16, (j + 1) * ((j + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
          (Rneg (ofQ (⟨2, (j + 1) * ((j + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
          (Rneg (ofQ (⟨1, (j + 1) * ((j + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))))))
        (sStep4 (j + 1) (Nat.succ_pos j)) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (sStep4_decomp (j + 1) (Nat.succ_pos j))))
  exact Radd_le_add (Radd_le_add (Radd_le_add (Radd_le_add (b4C2_ge (j + 1) (Nat.succ_pos j))
    (b3R3_ge (j + 1) (Nat.succ_pos j))) (b2R2_ge4 (j + 1) (Nat.succ_pos j)))
    (bR1_ge4 (j + 1) (Nat.succ_pos j))) (R0_ge4 (j + 1) (Nat.succ_pos j))

/-- **`sStep4 (j+1) ≥ −46/((j+1)(j+2))`** — the consolidated single-term per-step lower bound (the five
    parts `0 + 27 + 16 + 2 + 1` collapse over the common denominator `D = (j+1)(j+2)`). -/
theorem sStep4_lower_tele (j : Nat) :
    Rle (Rneg (ofQ (⟨46, (j + 1) * ((j + 1) + 1)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))))
        (sStep4 (j + 1) (Nat.succ_pos j)) := by
  have hD : 0 < (j + 1) * ((j + 1) + 1) := Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1))
  have hcollapse : Req
      (Radd (Radd (Radd (Radd zero (Rneg (ofQ (⟨27, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
          (Rneg (ofQ (⟨16, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
          (Rneg (ofQ (⟨2, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
          (Rneg (ofQ (⟨1, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
      (Rneg (ofQ (⟨46, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) := by
    have hA : Req (Radd zero (Rneg (ofQ (⟨27, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
        (Rneg (ofQ (⟨27, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) :=
      Req_trans (Radd_comm zero _) (Radd_zero _)
    have hB : Req (Radd (Rneg (ofQ (⟨27, (j + 1) * ((j + 1) + 1)⟩ : Q) hD))
          (Rneg (ofQ (⟨16, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
        (Rneg (ofQ (⟨43, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) :=
      Req_trans (Req_symm (Rneg_Radd _ _))
        (Rneg_congr (Radd_ofQ_same 27 16 ((j + 1) * ((j + 1) + 1)) hD))
    have hC : Req (Radd (Rneg (ofQ (⟨43, (j + 1) * ((j + 1) + 1)⟩ : Q) hD))
          (Rneg (ofQ (⟨2, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
        (Rneg (ofQ (⟨45, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) :=
      Req_trans (Req_symm (Rneg_Radd _ _))
        (Rneg_congr (Radd_ofQ_same 43 2 ((j + 1) * ((j + 1) + 1)) hD))
    have hE : Req (Radd (Rneg (ofQ (⟨45, (j + 1) * ((j + 1) + 1)⟩ : Q) hD))
          (Rneg (ofQ (⟨1, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)))
        (Rneg (ofQ (⟨46, (j + 1) * ((j + 1) + 1)⟩ : Q) hD)) :=
      Req_trans (Req_symm (Rneg_Radd _ _))
        (Rneg_congr (Radd_ofQ_same 45 1 ((j + 1) * ((j + 1) + 1)) hD))
    exact Req_trans (Radd_congr (Radd_congr (Radd_congr hA (Req_refl _)) (Req_refl _)) (Req_refl _))
      (Req_trans (Radd_congr (Radd_congr hB (Req_refl _)) (Req_refl _))
        (Req_trans (Radd_congr hC (Req_refl _)) hE))
  exact Rle_trans (Rle_of_Req (Req_symm hcollapse)) (sStep4_lower_clean j)

/-- **Telescoping tail (lower)**: `hSeq4(N+k) ≥ hSeq4(N) − (46/(N+1) − 46/(N+k+1))` (`N ≥ 1`). -/
theorem hSeq4_tele_lo (N : Nat) (hN : 1 ≤ N) : ∀ k,
    Rle (Rsub (hSeq4 N) (Rsub (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨46, N + k + 1⟩ : Q) (Nat.succ_pos (N + k)))))
        (hSeq4 (N + k)) := by
  intro k
  induction k with
  | zero =>
    exact Rle_of_Req (Req_trans (Rsub_congr (Req_refl _)
      (Radd_neg (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N)))) (Radd_zero (hSeq4 N)))
  | succ k ih =>
    have hstep : Rle (Rneg (ofQ (⟨46, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1)))))
        (Rsub (hSeq4 (N + k + 1)) (hSeq4 (N + k))) :=
      Rle_trans (sStep4_lower_tele (N + k)) (Rle_of_Req (Req_symm (hSeq4_step_eq (N + k))))
    have hABc : Req (Radd (Rsub (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨46, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))
          (ofQ (⟨46, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1)))))
        (Rsub (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))
          (ofQ (⟨46, N + (k + 1) + 1⟩ : Q) (Nat.succ_pos (N + (k + 1))))) := by
      apply Req_of_seq_Qeq; intro n
      show Qeq (add (add (⟨46, N + 1⟩ : Q) (neg (⟨46, N + k + 1⟩ : Q)))
          (⟨46, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q))
        (add (⟨46, N + 1⟩ : Q) (neg (⟨46, N + (k + 1) + 1⟩ : Q)))
      simp only [Qeq, add, neg, mul]
      push_cast
      ring_uor
    have hcombine : Req
        (Radd (Rsub (hSeq4 N) (Rsub (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))
              (ofQ (⟨46, N + k + 1⟩ : Q) (Nat.succ_pos (N + k)))))
          (Rneg (ofQ (⟨46, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1))))))
        (Rsub (hSeq4 N) (Rsub (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))
          (ofQ (⟨46, N + (k + 1) + 1⟩ : Q) (Nat.succ_pos (N + (k + 1)))))) := by
      refine Req_trans (Radd_assoc (hSeq4 N) _ _) ?_
      refine Radd_congr (Req_refl (hSeq4 N)) ?_
      exact Req_trans (Req_symm (Rneg_Radd _ _)) (Rneg_congr hABc)
    refine Rle_trans (Rle_of_Req (Req_symm hcombine)) ?_
    refine Rle_trans (Radd_le_add ih hstep) ?_
    exact Rle_of_Req (Req_symm (sub_add_cancel_real (hSeq4 (N + k + 1)) (hSeq4 (N + k))))

/-- **`hSeq4(N+k) ≥ hSeq4(N) − 46/(N+1)`** (uniform in `k`, `N ≥ 1`) — drop the nonneg `+46/(N+k+1)`. -/
theorem hSeq4_lower_const (N : Nat) (hN : 1 ≤ N) (k : Nat) :
    Rle (Rsub (hSeq4 N) (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))) (hSeq4 (N + k)) := by
  have hBkle : Rle (Rsub (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))
        (ofQ (⟨46, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))
      (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N)) :=
    Rsub_le_self _ (Rnonneg_ofQ (Nat.succ_pos (N + k)) (by show (0 : Int) ≤ 46; decide))
  exact Rle_trans (Rsub_le_sub (Rle_of_Req (Req_refl (hSeq4 N))) hBkle) (hSeq4_tele_lo N hN k)

/-- **`hSeq4 N ≤ g4Seq N`** — `g4Seq N = hSeq4 N + ½·(ln(N+1))⁴/(N+1)` and the correction is `≥ 0`. -/
theorem hSeq4_le_g4Seq (N : Nat) : Rle (hSeq4 N) (g4Seq N) := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (Rsub_sub_self (g4Seq N)
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnQuartOver (N + 1) (Nat.succ_pos N))))) ?_)
  exact Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
    (lnQuartOver_nonneg (N + 1) (Nat.succ_pos N))

/-- **`γ₄ ≥ hSeq4 N − 46/(N+1)`** for `N ∈ [1, 2^22]` — each reindexed `g4SeqDyadic k = g4Seq(2^{2k+22})`
    (`≥ 2^22 ≥ N`) is `≥ hSeq4(2^{2k+22}) ≥ hSeq4 N − 46/(N+1)`, so the limit is too. -/
theorem Rgamma4_ge_hSeq4 {N : Nat} (hN : 1 ≤ N) (hN22 : N ≤ 2 ^ 22) :
    Rle (Rsub (hSeq4 N) (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))) Rgamma4 := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have hN2k : N ≤ 2 ^ (2 * k + 22) := by
    have h22 : (2 : Nat) ^ 22 ≤ 2 ^ (2 * k + 22) := Nat.pow_le_pow_right (by omega) (by omega)
    omega
  have htend : Rle (Rsub (g4SeqDyadic k) Rgamma4) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    RTendsTo_to_Rle (Rlim_tendsTo g4SeqDyadic g4SeqDyadic_RReg) k
  have hanchor : Rle (Rsub (hSeq4 N) (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))) (g4SeqDyadic k) := by
    obtain ⟨d, hd⟩ := Nat.le.dest hN2k
    have h1 : Rle (Rsub (hSeq4 N) (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))) (hSeq4 (N + d)) :=
      hSeq4_lower_const N hN d
    rw [hd] at h1
    exact Rle_trans h1 (hSeq4_le_g4Seq (2 ^ (2 * k + 22)))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split
    (Rsub (hSeq4 N) (ofQ (⟨46, N + 1⟩ : Q) (Nat.succ_pos N))) (g4SeqDyadic k) Rgamma4))) ?_
  refine Rle_trans (Radd_le_add
    (Rsub_le_of_le_add (Rle_trans hanchor (Rle_of_Req
      (Req_symm (Req_trans (Radd_comm zero (g4SeqDyadic k)) (Radd_zero (g4SeqDyadic k)))))))
    htend) ?_
  exact Rle_of_Req (Req_trans (Radd_comm zero _) (Radd_zero _))

-- ===========================================================================
-- (E) The numeric bracket: `γ₄ ≥ −1/20`.
-- ===========================================================================

/-- The **rational lower bound on `hSeq4 N`** (depth `T`, denominator `D`) as a single `Q`.
    `lnQuartSumLo` (sum, lower) minus the two corrections upper-bounded by `logBound⁵`/`logBound⁴`. -/
def gBound4lo (T D N : Nat) : Q :=
  add (add (lnQuartSumLo T D (N + 1))
      (neg (mul (⟨1, 5⟩ : Q) (mul (mul (mul (mul (logBound T D N) (logBound T D N))
        (logBound T D N)) (logBound T D N)) (logBound T D N)))))
    (neg (mul (⟨1, 2⟩ : Q) (mul (mul (mul (mul (logBound T D N) (logBound T D N))
      (logBound T D N)) (logBound T D N)) (⟨1, N + 1⟩ : Q))))

theorem gBound4lo_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound4lo T D N).den :=
  add_den_pos (add_den_pos (lnQuartSumLo_den_pos T D hD (N + 1))
      (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos
        (logBound_den_pos T D hD N) (logBound_den_pos T D hD N)) (logBound_den_pos T D hD N))
        (logBound_den_pos T D hD N)) (logBound_den_pos T D hD N))))
    (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos
      (logBound_den_pos T D hD N) (logBound_den_pos T D hD N)) (logBound_den_pos T D hD N))
      (logBound_den_pos T D hD N)) (Nat.succ_pos N)))

set_option maxRecDepth 40000 in
/-- **`ofQ(gBound4lo T D N) ≤ hSeq4 N`** (`T ≤ 21`) — the rational lower bound (`lnQuartSum_ge`,
    `logQuintic_le`, `halfQuartOver_le`), collapsing the all-`ofQ` Rsub-tower to the single `gBound4lo`. -/
theorem hSeq4_ge_gBound4lo (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (gBound4lo T D N) (gBound4lo_den_pos T D N hD)) (hSeq4 N) := by
  have LBd := logBound_den_pos T D hD N
  have hquint : Rle (Rmul (ofQ (⟨1, 5⟩ : Q) (by decide)) (logQuintic (N + 1) (Nat.succ_pos N)))
      (ofQ (mul (⟨1, 5⟩ : Q) (mul (mul (mul (mul (logBound T D N) (logBound T D N))
          (logBound T D N)) (logBound T D N)) (logBound T D N)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd)
          LBd) LBd) LBd))) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (logQuintic_le T D N hD))
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide)
        (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd) LBd) LBd) LBd)))
  have hlow : Rle (Rsub (Rsub (ofQ (lnQuartSumLo T D (N + 1)) (lnQuartSumLo_den_pos T D hD (N + 1)))
        (ofQ (mul (⟨1, 5⟩ : Q) (mul (mul (mul (mul (logBound T D N) (logBound T D N))
            (logBound T D N)) (logBound T D N)) (logBound T D N)))
          (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd)
            LBd) LBd) LBd))))
      (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (mul (mul (logBound T D N) (logBound T D N)) (logBound T D N))
          (logBound T D N)) (⟨1, N + 1⟩ : Q)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LBd LBd)
          LBd) LBd) (Nat.succ_pos N))))) (hSeq4 N) := by
    unfold hSeq4 g4Seq
    exact Rsub_le_sub (Rsub_le_sub (lnQuartSum_ge T D hD hT (N + 1)) hquint) (halfQuartOver_le T D N hD)
  exact Rle_trans (Rle_of_Req (Req_symm (Req_of_seq_Qeq (fun _ => Qeq_refl _)))) hlow

set_option maxRecDepth 40000 in
/-- The numeric heart: `−1/5 ≤ gBound4lo 6 10⁸ 245 − 46/246` — one big-integer kernel `decide`.
    (`C = 46 = 27+16+2+1` from the polynomial-log caps; the LOOSE `−1/5` target — sufficient for
    `Pos λ₅`, where `γ₄` enters only via `−(5/24)γ₄` — keeps `N = 245` inside the kernel stack.) -/
theorem gamma4_lo_decide :
    Qle (⟨-1, 5⟩ : Q) (Qsub (gBound4lo 6 100000000 245) (⟨46, 245 + 1⟩ : Q)) := by decide

/-- **`γ₄ ≥ −1/5` (`= −0.2`)** — the certified LOWER bracket on the fourth Stieltjes constant.
    `γ₄ ≥ hSeq4(245) − 46/246` (`Rgamma4_ge_hSeq4`), `hSeq4(245) ≥ ofQ(gBound4lo 6 10⁸ 245)`
    (`hSeq4_ge_gBound4lo`), `gBound4lo 6 10⁸ 245 − 46/246 ≥ −1/5` (`gamma4_lo_decide`).  This loose
    bracket is the sole remaining numeric gate for `Pos Rlambda5` (`n = 5`). -/
theorem Rgamma4_ge_neg02 : Rle (ofQ (⟨-1, 5⟩ : Q) (by decide)) Rgamma4 := by
  have hD : 0 < 100000000 := by decide
  refine Rle_trans ?_ (Rgamma4_ge_hSeq4 (show 1 ≤ 245 by decide) (show 245 ≤ 2 ^ 22 by decide))
  refine Rle_trans ?_
    (Rsub_le_sub (hSeq4_ge_gBound4lo 6 100000000 245 hD (by decide)) (Rle_of_Req (Req_refl _)))
  exact Rle_trans
    (Rle_ofQ_ofQ (by decide)
      (add_den_pos (gBound4lo_den_pos 6 100000000 245 hD) (Nat.succ_pos 245)) gamma4_lo_decide)
    (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ (gBound4lo_den_pos 6 100000000 245 hD) (Nat.succ_pos 245))))

end UOR.Bridge.F1Square.Analysis
