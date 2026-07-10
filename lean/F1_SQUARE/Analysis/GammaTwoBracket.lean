/-
F1 square — v0.20.0 stage F: **the certified bracket `γ₂ ≥ −0.02`** via DISCRETE Euler–Maclaurin
(NO constructive integration), tying off `Pos λ₃`.

`γ₂ = g2Seq(N) + tail`, and the trapezoidal anchor `½f(N)` (`f(x)=ln²x/x`) captures the leading tail
`½ln²N/N`, leaving the summable trapezoidal residual `s_p = O(ln²p/p³)`. So
`γ₂ ≥ g2Seq(N) − ½ln²N/N − ε`, certifiable at `N = 200` with the rational squared/cubed-log evaluators.

THIS FILE — part (A): the squared-log lower-bound evaluator `lnSqSumLo` (a rational lower bound for
`Σ_{k≤N}(ln k)²/k`, the `GammaOne.lnSumBound` analogue, lower side, via `logLowBound` squared and
round-down) and the cubed/squared-log upper bounds (`logCube`/`logN²` via `logBound`). Parts (B)/(C)
(the `½ln²N/N` bound and the trapezoidal residual) and the final assembly follow.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.GammaTwo
import F1Square.Analysis.RMulNF

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- (A) `lnSqSumLo` — a rational LOWER bound for `lnSqSum N = Σ_{k=1}^N (ln k)²/k`.
-- ===========================================================================

/-- The accumulated rational lower bound for `Σ_{k=1}^N (ln k)²/k`, at fixed denominator `D`: each new
    term `(log(n+1))²/(n+1) ≥ (logLowBound n)²·(1/(n+1))`, then round DOWN. -/
def lnSqSumLo (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (n + 1) =>
      qRoundDown (add (lnSqSumLo T D n)
        (mul (mul (logLowBound T D n) (logLowBound T D n)) ⟨1, n + 1⟩)) D

theorem lnSqSumLo_den_pos (T D : Nat) (hD : 0 < D) : ∀ N, 0 < (lnSqSumLo T D N).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`ofQ(lnSqSumLo T D N) ≤ lnSqSum N`** — the partial sum `Σ (log k)²/k` bounded BELOW term-by-term
    via `logN_ge_logLowBound` (squared monotonically, both sides nonneg), accumulated at denominator
    `D` (round down), artanh depth `T ≤ 21`. -/
theorem lnSqSumLo_le (T D : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    ∀ N, Rle (ofQ (lnSqSumLo T D N) (lnSqSumLo_den_pos T D hD N)) (lnSqSum N) := by
  intro N
  induction N with
  | zero =>
    have h0 : Req (ofQ (lnSqSumLo T D 0) (lnSqSumLo_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req h0
  | succ n ih =>
    have hLLd := logLowBound_den_pos T D hD n
    have hLLnn : Rnonneg (ofQ (logLowBound T D n) hLLd) :=
      Rnonneg_ofQ hLLd (logLowBound_num_nonneg T D n)
    have hlow := logN_ge_logLowBound T D hD hT n
    have hlognn : Rnonneg (logN (n + 1) (Nat.succ_pos n)) := Rnonneg_logN _ _
    -- per-term lower bound `(LL)²·(1/(n+1)) ≤ (log(n+1))²·(1/(n+1)) = lnSqOver (n+1)`
    have hsq : Rle (Rmul (ofQ (logLowBound T D n) hLLd) (ofQ (logLowBound T D n) hLLd))
        (Rmul (logN (n + 1) (Nat.succ_pos n)) (logN (n + 1) (Nat.succ_pos n))) :=
      Rle_trans (Rmul_le_Rmul_right hLLnn hlow) (Rmul_le_Rmul_left hlognn hlow)
    have hmuld : 0 < (mul (mul (logLowBound T D n) (logLowBound T D n)) (⟨1, n + 1⟩ : Q)).den :=
      Qmul_den_pos (Qmul_den_pos hLLd hLLd) (Nat.succ_pos n)
    have hsqd : 0 < (mul (logLowBound T D n) (logLowBound T D n)).den := Qmul_den_pos hLLd hLLd
    have hterm : Rle (ofQ (mul (mul (logLowBound T D n) (logLowBound T D n)) ⟨1, n + 1⟩) hmuld)
        (lnSqOver (n + 1) (Nat.succ_pos n)) := by
      -- ofQ(LL²·(1/(n+1))) ≈ (ofQ LL·ofQ LL)·ofQ(1/(n+1)) ≤ (log²)·(1/(n+1)) = lnSqOver
      refine Rle_trans (Rle_of_Req ?_)
        (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos n) (by show (0 : Int) ≤ 1; decide)) hsq)
      refine Req_trans (Req_symm (Rmul_ofQ_ofQ hsqd (Nat.succ_pos n))) ?_
      exact Rmul_congr (Req_symm (Rmul_ofQ_ofQ hLLd hLLd)) (Req_refl _)
    -- accumulate: ofQ(round-down(prev + term)) ≤ prev + term ≤ lnSqSum n + lnSqOver(n+1)
    refine Rle_trans (Rle_ofQ_ofQ (lnSqSumLo_den_pos T D hD (n + 1))
      (add_den_pos (lnSqSumLo_den_pos T D hD n) hmuld)
      (qRoundDown_le (add (lnSqSumLo T D n)
        (mul (mul (logLowBound T D n) (logLowBound T D n)) ⟨1, n + 1⟩))
        (add_den_pos (lnSqSumLo_den_pos T D hD n) hmuld) D)) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (lnSqSumLo_den_pos T D hD n) hmuld)) ?_
    exact Radd_le_add ih hterm

-- ===========================================================================
-- (B) Cubed/squared-log UPPER bounds (`logBound`).
-- ===========================================================================

/-- `Rnonneg (ofQ (logBound T D M))` — the upper log bound is `≥ log(M+1) ≥ 0`. -/
theorem logBound_ofQ_nonneg (T D M : Nat) (hD : 0 < D) :
    Rnonneg (ofQ (logBound T D M) (logBound_den_pos T D hD M)) :=
  Rnonneg_of_Rle_zero (Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_logN (M + 1) (Nat.succ_pos M)))
    (logN_le_logBound T D hD M))

/-- `log(M+1)² ≤ logBound²` (squared monotonicity, both sides nonneg). -/
theorem logNsq_le (T D M : Nat) (hD : 0 < D) :
    Rle (Rmul (logN (M + 1) (Nat.succ_pos M)) (logN (M + 1) (Nat.succ_pos M)))
        (Rmul (ofQ (logBound T D M) (logBound_den_pos T D hD M))
              (ofQ (logBound T D M) (logBound_den_pos T D hD M))) :=
  Rle_trans (Rmul_le_Rmul_right (Rnonneg_logN _ _) (logN_le_logBound T D hD M))
    (Rmul_le_Rmul_left (logBound_ofQ_nonneg T D M hD) (logN_le_logBound T D hD M))

/-- **Cubed-log upper bound** `(ln(M+1))³ ≤ logBound³` (`logCube`). -/
theorem logCube_le (T D M : Nat) (hD : 0 < D) :
    Rle (logCube (M + 1) (Nat.succ_pos M))
        (ofQ (mul (mul (logBound T D M) (logBound T D M)) (logBound T D M))
          (Qmul_den_pos (Qmul_den_pos (logBound_den_pos T D hD M) (logBound_den_pos T D hD M))
            (logBound_den_pos T D hD M))) := by
  have LBd := logBound_den_pos T D hD M
  have hLBsqnn : Rnonneg (Rmul (ofQ (logBound T D M) LBd) (ofQ (logBound T D M) LBd)) :=
    Rnonneg_Rmul (logBound_ofQ_nonneg T D M hD) (logBound_ofQ_nonneg T D M hD)
  refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_logN _ _) (logNsq_le T D M hD)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hLBsqnn (logN_le_logBound T D hD M)) ?_
  exact Rle_of_Req (Req_trans (Rmul_congr (Rmul_ofQ_ofQ LBd LBd) (Req_refl _))
    (Rmul_ofQ_ofQ (Qmul_den_pos LBd LBd) LBd))

/-- **Half-squared-over-`N` upper bound** `½·(ln(M+1))²/(M+1) ≤ ½·logBound²/(M+1)` — the trapezoidal
    anchor `½f(M+1)`, `f(x) = ln²x/x`, bounded above. -/
theorem halfSqOver_le (T D M : Nat) (hD : 0 < D) :
    Rle (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
          (Rmul (Rmul (logN (M + 1) (Nat.succ_pos M)) (logN (M + 1) (Nat.succ_pos M)))
            (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M))))
        (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (logBound T D M) (logBound T D M)) ⟨1, M + 1⟩))
          (Qmul_den_pos (by decide) (Qmul_den_pos
            (Qmul_den_pos (logBound_den_pos T D hD M) (logBound_den_pos T D hD M)) (Nat.succ_pos M)))) := by
  have LBd := logBound_den_pos T D hD M
  have hovnn : Rnonneg (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)) :=
    Rnonneg_ofQ (Nat.succ_pos M) (by show (0 : Int) ≤ 1; decide)
  have hinner : Rle (Rmul (Rmul (logN (M + 1) (Nat.succ_pos M)) (logN (M + 1) (Nat.succ_pos M)))
        (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)))
      (Rmul (Rmul (ofQ (logBound T D M) LBd) (ofQ (logBound T D M) LBd))
        (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M))) :=
    Rmul_le_Rmul_right hovnn (logNsq_le T D M hD)
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by show (0 : Int) ≤ 1; decide)) hinner) ?_
  -- ½·((LB·LB)·(1/(M+1)))  ≈  ofQ(½·((logBound·logBound)·(1/(M+1))))
  have hinnerEq : Req (Rmul (Rmul (ofQ (logBound T D M) LBd) (ofQ (logBound T D M) LBd))
        (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)))
      (ofQ (mul (mul (logBound T D M) (logBound T D M)) ⟨1, M + 1⟩)
        (Qmul_den_pos (Qmul_den_pos LBd LBd) (Nat.succ_pos M))) :=
    Req_trans (Rmul_congr (Rmul_ofQ_ofQ LBd LBd) (Req_refl _))
      (Rmul_ofQ_ofQ (Qmul_den_pos LBd LBd) (Nat.succ_pos M))
  exact Rle_of_Req (Req_trans (Rmul_congr (Req_refl _) hinnerEq)
    (Rmul_ofQ_ofQ (by decide) (Qmul_den_pos (Qmul_den_pos LBd LBd) (Nat.succ_pos M))))

-- ===========================================================================
-- (C1) The residual framework: `hSeq j = g₂(j) − ½·(ln(j+1))²/(j+1)` (the trapezoidal-corrected
-- sequence, `→ γ₂`), whose per-step increment is the trapezoidal residual `sStep`.
-- ===========================================================================

/-- `x = ½x + ½x`. -/
theorem half_add_self (x : Real) :
    Req x (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) x)) := by
  have hone : Req (Radd (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2⟩ : Q) (by decide))) one := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  refine Req_trans ?_ (Rmul_distrib_right (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2⟩ : Q) (by decide)) x)
  exact Req_symm (Req_trans (Rmul_congr hone (Req_refl x)) (Req_trans (Rmul_comm one x) (Rmul_one x)))

/-- `((u+u) − C) − (u − v) ≈ (u+v) − C` (the residual regrouping; the `u`/`−u` cancel). -/
theorem resid_regroup (u v C : Real) :
    Req (Rsub (Rsub (Radd u u) C) (Rsub u v)) (Rsub (Radd u v) C) := by
  show Req (Radd (Radd (Radd u u) (Rneg C)) (Rneg (Radd u (Rneg v)))) (Radd (Radd u v) (Rneg C))
  have hrn : Req (Rneg (Radd u (Rneg v))) (Radd (Rneg u) v) :=
    Req_trans (Rneg_Radd u (Rneg v)) (Radd_congr (Req_refl _) (Rneg_neg v))
  refine Req_trans (Radd_congr (Req_refl _) hrn) ?_
  refine Req_trans (Radd_assoc (Radd u u) (Rneg C) (Radd (Rneg u) v)) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_comm (Rneg C) (Radd (Rneg u) v))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_assoc (Rneg u) v (Rneg C))) ?_
  refine Req_trans (Req_symm (Radd_assoc (Radd u u) (Rneg u) (Radd v (Rneg C)))) ?_
  refine Req_trans (Radd_congr ?_ (Req_refl _)) (Req_symm (Radd_assoc u v (Rneg C)))
  exact Req_trans (Radd_assoc u u (Rneg u))
    (Req_trans (Radd_congr (Req_refl u) (Radd_neg u)) (Radd_zero u))

/-- The **trapezoidal-corrected sequence** `h(j) = g₂(j) − ½·(ln(j+1))²/(j+1)` — same limit `γ₂` as
    `g₂`, but its increment is the summable trapezoidal residual. -/
def hSeq (j : Nat) : Real :=
  Rsub (g2Seq j) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (j + 1) (Nat.succ_pos j)))

/-- The **per-step trapezoidal residual** `s_p = ½[(ln(p+1))²/(p+1) + (ln p)²/p] − ⅓[(ln(p+1))³ −
    (ln p)³]` (`p ≥ 1`) — `O(ln²p/p³)`, the increment of `hSeq`. -/
def sStep (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (p + 1) (Nat.succ_pos p)))
             (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver p hp)))
       (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
         (Rsub (logCube (p + 1) (Nat.succ_pos p)) (logCube p hp)))

/-- **`h(j+1) − h(j) ≈ s_{j+1}`** — the increment of the corrected sequence is the trapezoidal
    residual (`e_{j+1} − ½(f(j+2)−f(j+1))`, regrouped via `half_add_self`/`resid_regroup`). -/
theorem hSeq_step_eq (j : Nat) :
    Req (Rsub (hSeq (j + 1)) (hSeq j)) (sStep (j + 1) (Nat.succ_pos j)) := by
  unfold hSeq sStep
  refine Req_trans (Rsub_sub_sub (g2Seq (j + 1))
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (j + 2) (Nat.succ_pos (j + 1))))
    (g2Seq j) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (j + 1) (Nat.succ_pos j)))) ?_
  refine Req_trans (Rsub_congr (g2Seq_step_eq j) (Req_refl _)) ?_
  -- e_{j+1} = (ln(j+2))²/(j+2) − ⅓Δ;  rewrite the leading `(ln(j+2))²/(j+2)` as ½·+½·
  refine Req_trans (Rsub_congr
    (Rsub_congr (half_add_self (lnSqOver (j + 2) (Nat.succ_pos (j + 1)))) (Req_refl _))
    (Req_refl _)) ?_
  exact resid_regroup (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (j + 2) (Nat.succ_pos (j + 1))))
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (j + 1) (Nat.succ_pos j)))
    (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
      (Rsub (logCube (j + 2) (Nat.succ_pos (j + 1))) (logCube (j + 1) (Nat.succ_pos j))))

-- ===========================================================================
-- (C2) The `s_p` decomposition.  Stage 1: replace the cube difference `a³−b³` by `δ·(a²+ab+b²)`
-- (`cube_diff_identity`), exposing the trapezoidal structure.  Stage 2 (`a = b+δ` collection) follows.
-- ===========================================================================

/-- **Stage 1 of the `s_p` decomposition**: `s_p = ½a²/(p+1) + ½b²/p − ⅓·δ·(a²+ab+b²)`, with
    `a = ln(p+1)`, `b = ln p`, `δ = a − b`. (`a³−b³ = δ(a²+ab+b²)` via `cube_diff_identity`.) -/
theorem sStep_stage1 (p : Nat) (hp : 1 ≤ p) :
    Req (sStep p hp)
        (Rsub (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
                  (Rmul (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
                    (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
                (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
                  (Rmul (Rmul (logN p hp) (logN p hp)) (ofQ (⟨1, p⟩ : Q) hp))))
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
            (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Radd (Radd (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
                      (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
                (Rmul (logN p hp) (logN p hp)))))) := by
  -- `s_p` is `½·lnSqOver(p+1) + ½·lnSqOver(p) − ⅓·(logCube(p+1) − logCube(p))`; rewrite the cube diff.
  unfold sStep lnSqOver logCube
  refine Rsub_congr (Req_refl _) (Rmul_congr (Req_refl _) ?_)
  -- a³ − b³  ≈  δ·(a²+ab+b²)
  exact Req_symm (cube_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))

-- Scalar-merge helpers (coefficients kept as `ofQ` FACTORS so `RMulNF` collapses `½·2=1`, `⅓·3=1`).

/-- `x + x ≈ 2·x`. -/
theorem two_mul_eq (x : Real) : Req (Radd x x) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x) := by
  have htwo : Req (Radd one one) (ofQ (⟨2, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  exact Req_trans (Radd_congr hx1 hx1)
    (Req_trans (Req_symm (Rmul_distrib_right one one x)) (Rmul_congr htwo (Req_refl x)))

/-- `(b+d)² ≈ b² + 2·(b·d) + d²` (cross term with coefficient `2` as a factor). -/
theorem sq_binom2 (b d : Real) :
    Req (Rmul (Radd b d) (Radd b d))
        (Radd (Radd (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d))) (Rmul d d)) := by
  refine Req_trans (Rmul_distrib_right b d (Radd b d)) ?_
  refine Req_trans (Radd_congr (Rmul_distrib b b d) (Rmul_distrib d b d)) ?_
  -- (b² + b·d) + (d·b + d²);  d·b ≈ b·d
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Rmul_comm d b) (Req_refl _))) ?_
  -- (b² + b·d) + (b·d + d²)  ≈  (b² + 2·(b·d)) + d²
  refine Req_trans (Radd_assoc (Rmul b b) (Rmul b d) (Radd (Rmul b d) (Rmul d d))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Req_symm (Radd_assoc (Rmul b d) (Rmul b d) (Rmul d d)))) ?_
  refine Req_trans (Req_symm (Radd_assoc (Rmul b b) (Radd (Rmul b d) (Rmul b d)) (Rmul d d))) ?_
  exact Radd_congr (Radd_congr (Req_refl _) (two_mul_eq (Rmul b d))) (Req_refl _)

/-- `x + x + x ≈ 3·x`. -/
theorem three_mul_eq (x : Real) :
    Req (Radd (Radd x x) x) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x) := by
  have h3 : Req (Radd (Radd one one) one) (ofQ (⟨3, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr (Radd_congr hx1 hx1) hx1) ?_
  refine Req_trans (Radd_congr (Req_symm (Rmul_distrib_right one one x)) (Req_refl _)) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right (Radd one one) one x)) (Rmul_congr h3 (Req_refl x))

/-- `2·x + x ≈ 3·x`. -/
theorem two_plus_one (x : Real) :
    Req (Radd (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x) x) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x) := by
  have h3 : Req (Radd (ofQ (⟨2, 1⟩ : Q) (by decide)) one) (ofQ (⟨3, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr (Req_refl _) hx1) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨2, 1⟩ : Q) (by decide)) one x))
    (Rmul_congr h3 (Req_refl x))

/-- **Inner-sum merge** `(b+d)² + (b+d)·b + b² ≈ 3·b² + 3·(b·d) + d²`.  Atoms `B=b²`, `T=2·(b·d)`,
    `Dd=d²`, `U=b·d`: flatten the LHS to `RsumL [B,T,Dd,B,U,B]`, permute to `[B,B,B,T,U,Dd]`
    (choice-free, explicit), and unmerge the RHS coefficients (`3B = B+B+B`, `3·(b·d) = T+U`). -/
theorem inner_merge (b d : Real) :
    Req (Radd (Radd (Rmul (Radd b d) (Radd b d)) (Rmul (Radd b d) b)) (Rmul b b))
        (Radd (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
                    (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b d))) (Rmul d d)) := by
  have hbb : Req (Rmul (Radd b d) b) (Radd (Rmul b b) (Rmul b d)) :=
    Req_trans (Rmul_distrib_right b d b) (Radd_congr (Req_refl _) (Rmul_comm d b))
  -- LHS ≈ ((B+T+Dd)+(B+U))+B
  refine Req_trans (Radd_congr (Radd_congr (sq_binom2 b d) hbb) (Req_refl (Rmul b b))) ?_
  -- flatten LHS to RsumL [B,T,Dd,B,U,B]
  refine Req_trans (Radd_congr (Radd_congr
      (Radd_eq_RsumL3 (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)) (Rmul d d))
      (Radd_eq_RsumL (Rmul b b) (Rmul b d))) (RsumL_singleton (Rmul b b))) ?_
  refine Req_trans (Radd_congr (Req_symm (RsumL_append
      [Rmul b b, Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d), Rmul d d] [Rmul b b, Rmul b d]))
      (Req_refl _)) ?_
  refine Req_trans (Req_symm (RsumL_append
      [Rmul b b, Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d), Rmul d d, Rmul b b, Rmul b d]
      [Rmul b b])) ?_
  -- permute [B,T,Dd,B,U,B] ~ [B,B,B,T,U,Dd]  (B=b², T=2bd, Dd=d², U=bd); explicit, choice-free
  have s1 := List.Perm.cons (Rmul b b) (List.Perm.cons (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d))
    (List.Perm.swap (Rmul b b) (Rmul d d) [Rmul b d, Rmul b b]))
  have s2 := List.Perm.cons (Rmul b b) (List.Perm.swap (Rmul b b)
    (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)) [Rmul d d, Rmul b d, Rmul b b])
  have q1 := List.Perm.cons (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d))
    (List.Perm.cons (Rmul d d) (List.Perm.swap (Rmul b b) (Rmul b d) []))
  have q2 := List.Perm.cons (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d))
    (List.Perm.swap (Rmul b b) (Rmul d d) [Rmul b d])
  have q3 := List.Perm.swap (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d))
    [Rmul d d, Rmul b d]
  have s3 := List.Perm.cons (Rmul b b) (List.Perm.cons (Rmul b b) ((q1.trans q2).trans q3))
  have s4 := List.Perm.cons (Rmul b b) (List.Perm.cons (Rmul b b) (List.Perm.cons (Rmul b b)
    (List.Perm.cons (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d))
      (List.Perm.swap (Rmul b d) (Rmul d d) []))))
  refine Req_trans (RsumL_perm ((s1.trans s2).trans (s3.trans s4))) ?_
  -- RsumL [B,B,B,T,U,Dd] ≈ RHS  (unmerge 3B, 3bd)
  refine Req_trans (RsumL_append [Rmul b b, Rmul b b, Rmul b b]
      [Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d), Rmul b d, Rmul d d]) ?_
  refine Req_trans (Radd_congr (Req_symm (Radd_eq_RsumL3 (Rmul b b) (Rmul b b) (Rmul b b)))
      (Req_symm (Radd_eq_RsumL3 (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)) (Rmul b d)
        (Rmul d d)))) ?_
  -- ((B+B+B) ≈ 3B) and ((2bd + bd + d²) → need (T+U)+d²; regroup then two_plus_one)
  refine Req_trans (Radd_congr (three_mul_eq (Rmul b b)) (Req_refl _)) ?_
  -- now: Radd (3B) ((T + bd) + d²)  ;  (T+bd) ≈ 3bd, then attach d²
  refine Req_trans (Radd_congr (Req_refl _)
      (Radd_congr (two_plus_one (Rmul b d)) (Req_refl (Rmul d d)))) ?_
  -- Radd (3B) (Radd (3bd) d²) ≈ Radd (Radd (3B) (3bd)) d²
  exact Req_symm (Radd_assoc (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
    (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b d)) (Rmul d d))

/-- `½·(2·x) ≈ x` — the `RMulNF` coefficient collapse `½·2 = 1` (via `Rmul_ofQ_ofQ` then `decide`). -/
theorem half_two_cancel (x : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) x)) x := by
  have hc : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨2, 1⟩ : Q) (by decide))) one :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide))
    (ofQ (⟨2, 1⟩ : Q) (by decide)) x)) ?_
  exact Req_trans (Rmul_congr hc (Req_refl x)) (Rone_mul x)

/-- `⅓·(3·x) ≈ x` — the `RMulNF` coefficient collapse `⅓·3 = 1`. -/
theorem third_three_cancel (x : Real) :
    Req (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x)) x := by
  have hc : Req (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨3, 1⟩ : Q) (by decide))) one :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 3⟩ : Q) (by decide))
    (ofQ (⟨3, 1⟩ : Q) (by decide)) x)) ?_
  exact Req_trans (Rmul_congr hc (Req_refl x)) (Rone_mul x)

/-- `x·(3·c) ≈ 3·(x·c)` — pull the scalar `3` to the front (for the `⅓·3` collapse in the cube term). -/
theorem mul3_pull (x c : Real) :
    Req (Rmul x (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) c))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul x c)) := by
  refine Req_trans (Req_symm (Rmul_assoc x (ofQ (⟨3, 1⟩ : Q) (by decide)) c)) ?_
  exact Req_trans (Rmul_congr (Rmul_comm x (ofQ (⟨3, 1⟩ : Q) (by decide))) (Req_refl c))
    (Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) x c)

-- ===========================================================================
-- (C2 stage 2 — the decomposition target).  `decompForm a b u0 u1` is the trapezoidal residual in
-- its **bound-ready** shape `b²·C2 + b·R1 + R0`, with `d = a − b`, `C2 = ½(u0+u1) − d` (the
-- trapezoidal error of `1/x`, independent of `b`), `R1 = d·u1 − d²`, `R0 = ½d²u1 − ⅓d³`.
-- ===========================================================================

/-- The **bound-ready decomposition** `b²·(½(u0+u1) − d) + b·(d·u1 − d²) + (½d²u1 − ⅓d³)` of the
    trapezoidal residual `s_p` (`d = a − b`).  The leading factor `C2 = ½(u0+u1) − d` is the
    trapezoidal error of `1/x` (the clean `≤ 1/(2p(p+1)(2p+1))` summand). -/
def decompForm (a b u0 u1 : Real) : Real :=
  Radd (Radd
      (Rmul (Rmul b b)
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)))
      (Rmul b (Rsub (Rmul (Rsub a b) u1) (Rmul (Rsub a b) (Rsub a b)))))
    (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rsub a b) (Rsub a b)) u1))
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))))

/-- **`decompForm` expands to the 7 canonical monomials** (`RprodL` form, coefficient `ofQ` first),
    by distributing only (`d = a − b` is treated as an atom). -/
theorem decompForm_eq_RsumL (a b u0 u1 : Real) :
    Req (decompForm a b u0 u1)
      (RsumL [ RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1],
               Rneg (RprodL [b, b, Rsub a b]),
               RprodL [b, Rsub a b, u1],
               Rneg (RprodL [b, Rsub a b, Rsub a b]),
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1],
               Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b]) ]) := by
  -- P = b²·C2  →  ½b²u0 + ½b²u1 − b²d
  have hP : Req (Rmul (Rmul b b)
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)))
      (Radd (Radd (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])
                  (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1]))
            (Rneg (RprodL [b, b, Rsub a b]))) := by
    refine Req_trans (Rmul_sub_distrib (Rmul b b)
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)) ?_
    refine Rsub_congr ?_ (Rmul_eq_RprodL3 b b (Rsub a b))
    refine Req_trans (Rmul_congr (Req_refl (Rmul b b))
      (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide)) u0 u1)) ?_
    refine Req_trans (Rmul_distrib (Rmul b b)
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u0) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u1)) ?_
    refine Radd_congr ?_ ?_
    · exact Req_trans (Rmul_pair_eq_RprodL4 b b (ofQ (⟨1, 2⟩ : Q) (by decide)) u0)
        (RprodL_perm ((List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [u0])).trans
          (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, u0])))
    · exact Req_trans (Rmul_pair_eq_RprodL4 b b (ofQ (⟨1, 2⟩ : Q) (by decide)) u1)
        (RprodL_perm ((List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [u1])).trans
          (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, u1])))
  -- Q = b·R1  →  b·d·u1 − b·d²
  have hQ : Req (Rmul b (Rsub (Rmul (Rsub a b) u1) (Rmul (Rsub a b) (Rsub a b))))
      (Radd (RprodL [b, Rsub a b, u1]) (Rneg (RprodL [b, Rsub a b, Rsub a b]))) := by
    refine Req_trans (Rmul_sub_distrib b (Rmul (Rsub a b) u1) (Rmul (Rsub a b) (Rsub a b))) ?_
    exact Rsub_congr (Rmul_congr (Req_refl b) (Rmul_eq_RprodL (Rsub a b) u1))
      (Rmul_congr (Req_refl b) (Rmul_eq_RprodL (Rsub a b) (Rsub a b)))
  -- R0  →  ½d²u1 − ⅓d³
  have hR : Req
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rsub a b) (Rsub a b)) u1))
            (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))))
      (Radd (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1])
            (Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b]))) :=
    Rsub_congr (Rmul_congr (Req_refl _) (Rmul_eq_RprodL3 (Rsub a b) (Rsub a b) u1))
      (Rmul_congr (Req_refl _) (Rmul_eq_RprodL3 (Rsub a b) (Rsub a b) (Rsub a b)))
  -- assemble: decompForm = Radd (Radd P Q) R0
  refine Req_trans (Radd_congr (Radd_congr hP hQ) hR) ?_
  refine Req_trans (Radd_congr (Radd_congr
      (Radd_eq_RsumL3 (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])
        (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1]) (Rneg (RprodL [b, b, Rsub a b])))
      (Radd_eq_RsumL (RprodL [b, Rsub a b, u1]) (Rneg (RprodL [b, Rsub a b, Rsub a b]))))
      (Radd_eq_RsumL (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1])
        (Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])))) ?_
  refine Req_trans (Radd_congr (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1], Rneg (RprodL [b, b, Rsub a b])]
      [RprodL [b, Rsub a b, u1], Rneg (RprodL [b, Rsub a b, Rsub a b])])) (Req_refl _)) ?_
  exact Req_symm (RsumL_append
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1], Rneg (RprodL [b, b, Rsub a b]),
     RprodL [b, Rsub a b, u1], Rneg (RprodL [b, Rsub a b, Rsub a b])]
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1],
     Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])])

/-- The **stage-1 residual form** (exactly `sStep_stage1`'s RHS, parameterized): `½a²u1 + ½b²u0 −
    ⅓·(a−b)·(a²+ab+b²)`. -/
def lhsForm (a b u0 u1 : Real) : Real :=
  Rsub (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul a a) u1))
             (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul b b) u0)))
       (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
         (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))))

/-- `a ≈ b + (a − b)` — the additive cancellation that substitutes `a = b + d`. -/
theorem sub_add_cancel_real (a b : Real) : Req a (Radd b (Rsub a b)) := by
  refine Req_symm ?_
  show Req (Radd b (Radd a (Rneg b))) a
  refine Req_trans (Radd_congr (Req_refl b) (Radd_comm a (Rneg b))) ?_
  refine Req_trans (Req_symm (Radd_assoc b (Rneg b) a)) ?_
  refine Req_trans (Radd_congr (Radd_neg b) (Req_refl a)) ?_
  exact Req_trans (Radd_comm zero a) (Radd_zero a)

/-- **PART A** of `lhsForm`: `½·a²·u1 → ½b²u1 + b·d·u1 + ½d²u1` (`a = b+d`, `sq_binom2`, `½·2=1`). -/
theorem partA_eq (a b u1 : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul a a) u1))
      (Radd (Radd (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1]) (RprodL [b, Rsub a b, u1]))
            (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1])) := by
  have ha := sub_add_cancel_real a b
  have haa : Req (Rmul (Rmul a a) u1)
      (Rmul (Radd (Radd (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))
        (Rmul (Rsub a b) (Rsub a b))) u1) :=
    Rmul_congr (Req_trans (Rmul_congr ha ha) (sq_binom2 b (Rsub a b))) (Req_refl u1)
  refine Req_trans (Rmul_congr (Req_refl _) haa) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Rmul_distrib_right (Radd (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))
      (Rmul (Rsub a b) (Rsub a b)) u1)) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Radd_congr (Rmul_distrib_right (Rmul b b)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))) u1) (Req_refl _))) ?_
  refine Req_trans (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Radd (Rmul (Rmul b b) u1)
      (Rmul (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))) u1))
    (Rmul (Rmul (Rsub a b) (Rsub a b)) u1)) ?_
  refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Rmul (Rmul b b) u1)
    (Rmul (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))) u1)) (Req_refl _)) ?_
  refine Radd_congr (Radd_congr ?_ ?_) ?_
  · exact Rmul_congr (Req_refl _) (Rmul_eq_RprodL3 b b u1)
  · refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_assoc (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b)) u1)) ?_
    refine Req_trans (half_two_cancel (Rmul (Rmul b (Rsub a b)) u1)) ?_
    exact Rmul_eq_RprodL3 b (Rsub a b) u1
  · exact Rmul_congr (Req_refl _) (Rmul_eq_RprodL3 (Rsub a b) (Rsub a b) u1)

/-- **PART C distribution**: expose `⅓·(a−b)·(a²+ab+b²)` as `T1 + T2 + T3` (`inner_merge`, distribute). -/
theorem partC_distrib (a b : Real) :
    Req
      (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))))
      (Radd (Radd
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
            (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))))
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
            (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rsub a b) (Rmul (Rsub a b) (Rsub a b))))) := by
  have ha := sub_add_cancel_real a b
  have hinner : Req (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))
      (Radd (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
                  (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))
            (Rmul (Rsub a b) (Rsub a b))) :=
    Req_trans (Radd_congr (Radd_congr (Rmul_congr ha ha) (Rmul_congr ha (Req_refl b)))
      (Req_refl (Rmul b b))) (inner_merge b (Rsub a b))
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl (Rsub a b)) hinner)) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Rmul_distrib (Rsub a b)
      (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
            (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))
      (Rmul (Rsub a b) (Rsub a b)))) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Radd_congr (Rmul_distrib (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b)))) (Req_refl _))) ?_
  refine Req_trans (Rmul_distrib (ofQ (⟨1, 3⟩ : Q) (by decide))
    (Radd (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b)))
          (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b)))))
    (Rmul (Rsub a b) (Rmul (Rsub a b) (Rsub a b)))) ?_
  exact Radd_congr (Rmul_distrib (ofQ (⟨1, 3⟩ : Q) (by decide))
    (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b)))
    (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))) (Req_refl _)

/-- `T1 = ⅓·(d·(3·b²)) ≈ b²d` (`⅓·3=1`, normalize). -/
theorem partC1 (a b : Real) :
    Req (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))))
        (RprodL [b, b, Rsub a b]) := by
  refine Req_trans (Rmul_congr (Req_refl _) (mul3_pull (Rsub a b) (Rmul b b))) ?_
  refine Req_trans (third_three_cancel (Rmul (Rsub a b) (Rmul b b))) ?_
  exact Req_trans (Rmul_congr (Req_refl (Rsub a b)) (Rmul_eq_RprodL b b))
    (RprodL_perm ((List.Perm.swap b (Rsub a b) [b]).trans
      (List.Perm.cons b (List.Perm.swap b (Rsub a b) []))))

/-- `T2 = ⅓·(d·(3·(b·d))) ≈ b·d²` (`⅓·3=1`, normalize). -/
theorem partC2 (a b : Real) :
    Req (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rsub a b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b)))))
        (RprodL [b, Rsub a b, Rsub a b]) := by
  refine Req_trans (Rmul_congr (Req_refl _) (mul3_pull (Rsub a b) (Rmul b (Rsub a b)))) ?_
  refine Req_trans (third_three_cancel (Rmul (Rsub a b) (Rmul b (Rsub a b)))) ?_
  exact Req_trans (Rmul_congr (Req_refl (Rsub a b)) (Rmul_eq_RprodL b (Rsub a b)))
    (RprodL_perm (List.Perm.swap b (Rsub a b) [Rsub a b]))

/-- `T3 = ⅓·(d·d²) ≈ ⅓d³` (normalize only). -/
theorem partC3 (a b : Real) :
    Req (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rmul (Rsub a b) (Rsub a b))))
        (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b]) :=
  Rmul_congr (Req_refl _)
    (Rmul_congr (Req_refl (Rsub a b)) (Rmul_eq_RprodL (Rsub a b) (Rsub a b)))

/-- **PART C** of `lhsForm`: `⅓·(a−b)·(a²+ab+b²) → b²d + b·d² + ⅓d³` (`inner_merge`, `⅓·3=1`). -/
theorem partC_eq (a b : Real) :
    Req
      (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))))
      (Radd (Radd (RprodL [b, b, Rsub a b]) (RprodL [b, Rsub a b, Rsub a b]))
            (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])) :=
  Req_trans (partC_distrib a b)
    (Radd_congr (Radd_congr (partC1 a b) (partC2 a b)) (partC3 a b))

/-- **`lhsForm` expands to the same 7 canonical monomials** (`d = a − b` an atom): substitute
    `a = b + d` (`sq_binom2`/`inner_merge` collapse the cross terms, `½·2`/`⅓·3` cancel). -/
theorem lhsForm_eq_RsumL (a b u0 u1 : Real) :
    Req (lhsForm a b u0 u1)
      (RsumL [ RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1],
               RprodL [b, Rsub a b, u1],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0],
               Rneg (RprodL [b, b, Rsub a b]),
               Rneg (RprodL [b, Rsub a b, Rsub a b]),
               Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b]) ]) := by
  have hPARTA := partA_eq a b u1
  have hPARTB : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul b b) u0))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0]) :=
    Rmul_congr (Req_refl _) (Rmul_eq_RprodL3 b b u0)
  have hPARTC := partC_eq a b
  -- the negated cube
  have hnegC : Req
      (Rneg (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Rmul (Rsub a b) (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)))))
      (Radd (Radd (Rneg (RprodL [b, b, Rsub a b])) (Rneg (RprodL [b, Rsub a b, Rsub a b])))
            (Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b]))) :=
    Req_trans (Rneg_congr hPARTC)
      (Req_trans (Rneg_Radd (Radd (RprodL [b, b, Rsub a b]) (RprodL [b, Rsub a b, Rsub a b]))
        (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b]))
        (Radd_congr (Rneg_Radd (RprodL [b, b, Rsub a b]) (RprodL [b, Rsub a b, Rsub a b]))
          (Req_refl _)))
  -- assemble: lhsForm = Radd (Radd PARTA PARTB) (Rneg PARTC)
  refine Req_trans (Radd_congr (Radd_congr hPARTA hPARTB) hnegC) ?_
  refine Req_trans (Radd_congr (Radd_congr
      (Radd_eq_RsumL3 (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1]) (RprodL [b, Rsub a b, u1])
        (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1]))
      (RsumL_singleton (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])))
      (Radd_eq_RsumL3 (Rneg (RprodL [b, b, Rsub a b])) (Rneg (RprodL [b, Rsub a b, Rsub a b]))
        (Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])))) ?_
  refine Req_trans (Radd_congr (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1], RprodL [b, Rsub a b, u1],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1]]
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0]])) (Req_refl _)) ?_
  exact Req_symm (RsumL_append
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1], RprodL [b, Rsub a b, u1],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0]]
    [Rneg (RprodL [b, b, Rsub a b]), Rneg (RprodL [b, Rsub a b, Rsub a b]),
     Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])])

/-- **The keystone free identity**: `lhsForm ≈ decompForm` — the trapezoidal residual equals its
    bound-ready decomposition `b²·C2 + b·R1 + R0`.  A polynomial identity in the 4 atoms `a,b,u0,u1`
    (`d = a−b`), proved by reducing both sides to the same 7 canonical monomials and matching by an
    explicit, choice-free permutation. -/
theorem decomp_generic (a b u0 u1 : Real) :
    Req (lhsForm a b u0 u1) (decompForm a b u0 u1) := by
  -- canonical monomials c1..c7 (LHS order) → decompForm order [c4,c1,c5,c2,c6,c3,c7]
  -- via an explicit, choice-free 7-element permutation (six adjacent transpositions).
  have t1 := List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1])
    (List.Perm.cons (RprodL [b, Rsub a b, u1])
      (List.Perm.swap (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])
        (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1])
        [Rneg (RprodL [b, b, Rsub a b]), Rneg (RprodL [b, Rsub a b, Rsub a b]),
         Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])]))
  have t2 := List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1])
    (List.Perm.swap (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0]) (RprodL [b, Rsub a b, u1])
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1],
       Rneg (RprodL [b, b, Rsub a b]), Rneg (RprodL [b, Rsub a b, Rsub a b]),
       Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])])
  have t3 := List.Perm.swap (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])
    (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1])
    [RprodL [b, Rsub a b, u1], RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1],
     Rneg (RprodL [b, b, Rsub a b]), Rneg (RprodL [b, Rsub a b, Rsub a b]),
     Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])]
  have t4 := List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])
    (List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1])
      (List.Perm.cons (RprodL [b, Rsub a b, u1])
        (List.Perm.swap (Rneg (RprodL [b, b, Rsub a b]))
          (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1])
          [Rneg (RprodL [b, Rsub a b, Rsub a b]),
           Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])])))
  have t5 := List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])
    (List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1])
      (List.Perm.swap (Rneg (RprodL [b, b, Rsub a b])) (RprodL [b, Rsub a b, u1])
        [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1],
         Rneg (RprodL [b, Rsub a b, Rsub a b]),
         Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])]))
  have t6 := List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u0])
    (List.Perm.cons (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, u1])
      (List.Perm.cons (Rneg (RprodL [b, b, Rsub a b]))
        (List.Perm.cons (RprodL [b, Rsub a b, u1])
          (List.Perm.swap (Rneg (RprodL [b, Rsub a b, Rsub a b]))
            (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, u1])
            [Rneg (RprodL [ofQ (⟨1, 3⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b])]))))
  exact Req_trans (lhsForm_eq_RsumL a b u0 u1)
    (Req_trans (RsumL_perm ((t1.trans (t2.trans (t3.trans (t4.trans (t5.trans t6)))))))
      (Req_symm (decompForm_eq_RsumL a b u0 u1)))

/-- **`sStep p ≈ decompForm`** at the log/reciprocal atoms — instantiating the keystone at
    `a = ln(p+1)`, `b = ln p`, `u0 = 1/p`, `u1 = 1/(p+1)`. -/
theorem sStep_decomp (p : Nat) (hp : 1 ≤ p) :
    Req (sStep p hp)
      (decompForm (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
        (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) :=
  Req_trans (sStep_stage1 p hp)
    (decomp_generic (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
      (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))

-- ===========================================================================
-- (C3a) **`C2 ≥ 0` (trapezoid ≥ integral)** — the key structural coincidence: the trapezoidal
-- midpoint `M = ½(1/p+1/(p+1))` IS the `T=0` artanh upper bound `dPlusQ 0 p` (exactly, as rationals:
-- `2·(1/(2p+1) + 1/((2p+1)·4p(p+1))) = (2p+1)/(2p(p+1)) = M`).  So `δ = d ≤ dPlusQ 0 p ≈ M`, hence
-- `C2 = M − d ≥ 0` — with NO series comparison or polynomial inequality.
-- ===========================================================================

/-- **`dPlusQ 0 p = ½(1/p + 1/(p+1))`** (as rationals) — the trapezoidal midpoint equals the `T=0`
    artanh upper bound. -/
theorem dPlusQ_zero_eq_mid (p : Nat) (_hp : 1 ≤ p) :
    Qeq (dPlusQ 0 p) (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))) := by
  show ((dPlusQ 0 p).num) * ((mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))).den : Int)
     = ((mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))).num)
       * ((dPlusQ 0 p).den : Int)
  simp only [dPlusQ, artSum, artTerm, qpow, npow, mul, add]
  push_cast
  ring_uor

/-- **`C2 = ½(1/p+1/(p+1)) − d ≥ 0`** — the trapezoidal-error coefficient is nonnegative
    (`d ≤ dPlusQ 0 p ≈ M`). -/
theorem C2_nonneg (p : Nat) (hp : 1 ≤ p) :
    Rnonneg (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
  have hMd : 0 < (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))).den :=
    Qmul_den_pos (by decide)
      (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p))
  -- d ≤ ofQ(dPlusQ 0 p) ≈ ofQ(M_Q) ≈ M
  have hdM : Rle (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (ofQ (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))) hMd) :=
    Rle_trans (deltaLog_upper_tight p 0 hp)
      (Rle_of_Req (ofQ_congr (dPlusQ_den_pos 0 p hp) hMd (dPlusQ_zero_eq_mid p hp)))
  have hMeq : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
      (ofQ (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))) hMd) :=
    Req_trans (Rmul_congr (Req_refl _)
        (Radd_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)))
      (Rmul_ofQ_ofQ (by decide)
        (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)))
  exact Rnonneg_Rsub_of_Rle (Rle_trans hdM (Rle_of_Req (Req_symm hMeq)))

-- ===========================================================================
-- (C3b) The CLEAN per-step lower bound `s_{j+1} ≥ −1/(2p(p+1)) − 1/(3p³)` (elementary, telescoping
-- tail — no dyadic machinery).  Uses the crude `ln p ≤ p` and the trapezoid handle `d − u1 ≤ M − u1
-- = 1/(2p(p+1))`, which keeps the R1 cancellation while staying summable.
-- ===========================================================================

/-- **`log p ≤ p`** (crude) — `exp(log p) = p ≤ 1 + p ≤ exp p`. -/
theorem logN_le_self (p : Nat) (hp : 1 ≤ p) :
    Rle (logN p hp) (ofQ (⟨(p : Int), 1⟩ : Q) Nat.one_pos) := by
  have hpnn : Rnonneg (ofQ (⟨(p : Int), 1⟩ : Q) Nat.one_pos) :=
    Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ (p : Int); omega)
  refine RexpReal_reflects_le hpnn (Rle_trans (Rle_of_Req (Rexp_logN p hp)) ?_)
  refine Rle_trans ?_ (RexpReal_ge_one_add_nonneg hpnn)
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ Rnonneg_one)
  refine Req_symm (Req_trans (Radd_assoc one (ofQ (⟨(p : Int), 1⟩ : Q) Nat.one_pos)
    (Rneg (ofQ (⟨(p : Int), 1⟩ : Q) Nat.one_pos))) ?_)
  exact Req_trans (Radd_congr (Req_refl one)
    (Radd_neg (ofQ (⟨(p : Int), 1⟩ : Q) Nat.one_pos))) (Radd_zero one)

/-- **`d ≤ M = ½(1/p+1/(p+1))`** (trapezoid ≥ integral, restated as an order fact). -/
theorem deltaLog_le_mid (p : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q)))
          (Qmul_den_pos (by decide)
            (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)))) :=
  Rle_trans (deltaLog_upper_tight p 0 hp)
    (Rle_of_Req (ofQ_congr (dPlusQ_den_pos 0 p hp)
      (Qmul_den_pos (by decide)
        (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)))
      (dPlusQ_zero_eq_mid p hp)))

/-- **`d − u1 ≤ 1/(2p(p+1))`** — the trapezoid handle (`d ≤ M`, `M − u1 = 1/(2p(p+1))`), keeping the
    cancellation that makes `R1 = d·u1 − d²` summable. -/
theorem dMinusU1_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (ofQ (⟨1, 2 * p * (p + 1)⟩ : Q)
          (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p))) := by
  refine Rle_trans (Rsub_le_sub (deltaLog_le_mid p hp) (Rle_of_Req (Req_refl _))) ?_
  refine Rle_of_Req (Req_of_seq_Qeq (fun n => ?_))
  show Qeq (add (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))) (neg (⟨1, p + 1⟩ : Q)))
    (⟨1, 2 * p * (p + 1)⟩ : Q)
  simp only [Qeq, add, mul, neg]
  push_cast
  ring_uor

/-- `−(X − Y) ≈ Y − X`. -/
theorem Rneg_Rsub_swap (X Y : Real) : Req (Rneg (Rsub X Y)) (Rsub Y X) :=
  Req_trans (Rneg_Radd X (Rneg Y))
    (Req_trans (Radd_congr (Req_refl _) (Rneg_neg Y)) (Radd_comm (Rneg X) Y))

/-- **`b·d ≤ 1`** (`b = log p ≤ p`, `d ≤ 1/p`). -/
theorem bd_le_one (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logN p hp) (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) one := by
  have hd_nn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hpnn : Rnonneg (ofQ (⟨(p : Int), 1⟩ : Q) Nat.one_pos) :=
    Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ (p : Int); omega)
  refine Rle_trans (Rmul_le_Rmul_right hd_nn (logN_le_self p hp)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hpnn (deltaLog_upper p hp)) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (a := (⟨(p : Int), 1⟩ : Q)) (b := (⟨1, p⟩ : Q))
    Nat.one_pos hp) ?_)
  exact ofQ_congr (Qmul_den_pos (a := (⟨(p : Int), 1⟩ : Q)) (b := (⟨1, p⟩ : Q)) Nat.one_pos hp)
    Nat.one_pos
    (by show Qeq (mul (⟨(p : Int), 1⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, 1⟩ : Q)
        simp only [Qeq, mul]; push_cast; ring_uor)

theorem bR1_lower (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨1, 2 * p * (p + 1)⟩ : Q)
          (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p))))
        (Rmul (logN p hp)
          (Rsub (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                  (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                  (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
  have key : Rle (Rmul (logN p hp)
        (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))))
      (ofQ (⟨1, 2 * p * (p + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p))) := by
    refine Rle_trans (Rle_of_Req (Req_symm (Rmul_assoc (logN p hp)
      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))))) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_Rsub_of_Rle (deltaLog_lower p hp))
      (bd_le_one p hp)) ?_
    exact Rle_trans (Rle_of_Req (Rone_mul _)) (dMinusU1_le p hp)
  -- d·(d−u1) ≈ −R1, so b·(d·(d−u1)) ≈ −(b·R1)
  have hswap : Req
      (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rsub (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
          (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
      (Rneg (Rsub (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                    (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
              (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) :=
    Req_trans (Rmul_sub_distrib (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
      (Req_symm (Rneg_Rsub_swap _ _))
  have heq := Req_trans (Rmul_congr (Req_refl (logN p hp)) hswap)
    (Rmul_neg_right (logN p hp)
      (Rsub (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
  have hk2 := Rle_trans (Rle_of_Req (Req_symm heq)) key
  exact Rle_trans (Rle_Rneg hk2) (Rle_of_Req (Rneg_neg _))

/-- **`d² ≤ 1/p²`** (`d ≤ 1/p`, squared). -/
theorem dsq_self_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (Qmul_den_pos hp hp)) := by
  have hd_nn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hu_nn : Rnonneg (ofQ (⟨1, p⟩ : Q) hp) :=
    Rnonneg_ofQ (c := (⟨1, p⟩ : Q)) hp (by show (0 : Int) ≤ 1; decide)
  refine Rle_trans (Rmul_le_Rmul_right hd_nn (deltaLog_upper p hp)) ?_
  refine Rle_trans (Rmul_le_Rmul_left hu_nn (deltaLog_upper p hp)) ?_
  exact Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, p⟩ : Q)) hp hp)

/-- **`d³ ≤ 1/p³`** (`(d·d)·d`). -/
theorem dcube_self_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos hp hp) hp)) := by
  have hd_nn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hu_nn : Rnonneg (ofQ (⟨1, p⟩ : Q) hp) :=
    Rnonneg_ofQ (c := (⟨1, p⟩ : Q)) hp (by show (0 : Int) ≤ 1; decide)
  have husq_nn : Rnonneg (ofQ (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (Qmul_den_pos hp hp)) :=
    Rnonneg_congr (Rmul_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, p⟩ : Q)) hp hp)
      (Rnonneg_Rmul hu_nn hu_nn)
  refine Rle_trans (Rmul_le_Rmul_right hd_nn (dsq_self_le p hp)) ?_
  refine Rle_trans (Rmul_le_Rmul_left husq_nn (deltaLog_upper p hp)) ?_
  exact Rle_of_Req (Req_trans
    (Rmul_congr (Rmul_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, p⟩ : Q)) hp hp) (Req_refl _))
    (Rmul_ofQ_ofQ (a := mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (b := (⟨1, p⟩ : Q))
      (Qmul_den_pos hp hp) hp))

/-- **`R0 = ½d²u1 − ⅓d³ ≥ −1/(3p³)`** (`½d²u1 ≥ 0`, `d³ ≤ 1/p³`). -/
theorem R0_lower_clean (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (mul (⟨1, 3⟩ : Q) (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
          (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos hp hp) hp))))
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
                (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
                  (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
            (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                  (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
  -- abbreviations: A = ½d²u1, B = ⅓d³
  have hA_nn : Rnonneg (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
      (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
      (Rnonneg_Rmul (Rnonneg_Rmul_self _) (Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)))
  -- R0 ≥ −B  (i.e. Rle (Rneg B) R0)
  have hR0 : Rle (Rneg (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
              (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
                (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
          (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))) := by
    refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ hA_nn)
    -- A ≈ (A − B) − (−B)
    refine Req_symm (Req_trans (Radd_congr (Req_refl _) (Rneg_neg _)) ?_)
    refine Req_trans (Radd_assoc _ (Rneg _) _) ?_
    exact Req_trans (Radd_congr (Req_refl _)
      (Req_trans (Radd_comm (Rneg _) _) (Radd_neg _))) (Radd_zero _)
  -- −1/(3p³) ≤ −B  (since B ≤ 1/(3p³))
  have hcube : Rle (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
        (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (ofQ (mul (⟨1, 3⟩ : Q) (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos hp hp) hp))) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (dcube_self_le p hp))
      (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨1, 3⟩ : Q))
        (b := mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q))
        (by decide) (Qmul_den_pos (Qmul_den_pos hp hp) hp)))
  exact Rle_trans (Rle_Rneg hcube) hR0

/-- **`s_{j+1} ≥ −1/(2(j+1)(j+2)) − 1/(3(j+1)³)`** — the CLEAN per-step lower bound (telescoping
    tail).  `b²C2 ≥ 0`, `b·R1 ≥ −1/(2p(p+1))` (`bR1_lower`), `R0 ≥ −1/(3p³)` (`R0_lower_clean`),
    `p = j+1`. -/
theorem sStep_lower_clean (j : Nat) :
    Rle (Radd (Radd zero
            (Rneg (ofQ (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q)
              (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos (j + 1))))))
          (Rneg (ofQ (mul (⟨1, 3⟩ : Q) (mul (mul (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) (⟨1, j + 1⟩ : Q)))
            (Qmul_den_pos (by decide)
              (Qmul_den_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)) (Nat.succ_pos j))))))
        (sStep (j + 1) (Nat.succ_pos j)) := by
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (sStep_decomp (j + 1) (Nat.succ_pos j))))
  refine Radd_le_add (Radd_le_add ?_ (bR1_lower (j + 1) (Nat.succ_pos j)))
    (R0_lower_clean (j + 1) (Nat.succ_pos j))
  exact Rle_zero_of_Rnonneg (Rnonneg_Rmul (Rnonneg_Rmul_self (logN (j + 1) (Nat.succ_pos j)))
    (C2_nonneg (j + 1) (Nat.succ_pos j)))

-- ===========================================================================
-- (C4) The telescoping tail.  Consolidate to a single term `s_{j+1} ≥ −1/((j+1)(j+2))` (`j ≥ 1`),
-- then sum: `hSeq(M) ≥ hSeq(N) − 1/(N+1)`.
-- ===========================================================================

/-- **`2(j+1)(j+2) ≤ 3(j+1)³`** (`j ≥ 1`) — the cube domination behind `1/(3(j+1)³) ≤
    1/(2(j+1)(j+2))` (so the two per-step terms collapse to one telescoping `1/((j+1)(j+2))`). -/
theorem cube_dom_nat (j : Nat) (hj : 1 ≤ j) :
    2 * (j + 1) * (j + 2) ≤ 3 * (j + 1) * (j + 1) * (j + 1) := by
  have hid : 3 * (j + 1) * (j + 1) * (j + 1) + (j + 1)
           = 2 * (j + 1) * (j + 2) + (j + 1) * (3 * (j * j) + 4 * j) := by
    have hi : ((3 * (j + 1) * (j + 1) * (j + 1) + (j + 1) : Nat) : Int)
            = ((2 * (j + 1) * (j + 2) + (j + 1) * (3 * (j * j) + 4 * j) : Nat) : Int) := by
      push_cast; ring_uor
    exact_mod_cast hi
  have hge : (j + 1) ≤ (j + 1) * (3 * (j * j) + 4 * j) :=
    Nat.le_mul_of_pos_right (j + 1) (by omega)
  omega

/-- **`B_Q = 1/(3(j+1)³) ≤ A_Q = 1/(2(j+1)(j+2))`** (`j ≥ 1`) — from `cube_dom_nat`. -/
theorem hBA_qle (j : Nat) (hj : 1 ≤ j) :
    Qle (mul (⟨1, 3⟩ : Q) (mul (mul (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) (⟨1, j + 1⟩ : Q)))
      (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q) := by
  have h := cube_dom_nat j hj
  have eR : (3 * ((j + 1) * (j + 1) * (j + 1)) : Nat) = 3 * (j + 1) * (j + 1) * (j + 1) := by
    have hi : ((3 * ((j + 1) * (j + 1) * (j + 1)) : Nat) : Int)
            = ((3 * (j + 1) * (j + 1) * (j + 1) : Nat) : Int) := by push_cast; ring_uor
    exact_mod_cast hi
  unfold Qle
  simp only [mul, Int.one_mul, Int.mul_one]
  rw [eR]
  exact_mod_cast h

/-- **`A_Q + B_Q ≤ 1/((j+1)(j+2))`** (`j ≥ 1`) — `A_Q + B_Q ≤ A_Q + A_Q = 2A_Q = 1/((j+1)(j+2))`. -/
theorem hAB_qle (j : Nat) (hj : 1 ≤ j) :
    Qle (add (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q)
        (mul (⟨1, 3⟩ : Q) (mul (mul (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) (⟨1, j + 1⟩ : Q))))
      (⟨1, (j + 1) * (j + 2)⟩ : Q) := by
  refine Qle_trans (add_den_pos
      (show 0 < 2 * (j + 1) * ((j + 1) + 1) from
        Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos (j + 1)))
      (show 0 < 2 * (j + 1) * ((j + 1) + 1) from
        Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos (j + 1))))
    (Qadd_le_add (Qle_refl (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q)) (hBA_qle j hj)) ?_
  -- add A_Q A_Q = 2A_Q  =  1/((j+1)(j+2))
  refine Qeq_le ?_
  show Qeq (add (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q) (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q))
    (⟨1, (j + 1) * (j + 2)⟩ : Q)
  unfold Qeq add
  push_cast
  ring_uor

/-- **`s_{j+1} ≥ −1/((j+1)(j+2))`** (`j ≥ 1`) — single-term telescoping per-step bound. -/
theorem sStep_lower_tele (j : Nat) (hj : 1 ≤ j) :
    Rle (Rneg (ofQ (⟨1, (j + 1) * (j + 2)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos j) (Nat.succ_pos (j + 1)))))
        (sStep (j + 1) (Nat.succ_pos j)) := by
  refine Rle_trans ?_ (sStep_lower_clean j)
  have hcollapse : Req
      (Radd (Radd zero (Rneg (ofQ (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q)
          (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos (j + 1))))))
        (Rneg (ofQ (mul (⟨1, 3⟩ : Q) (mul (mul (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) (⟨1, j + 1⟩ : Q)))
          (Qmul_den_pos (by decide)
            (Qmul_den_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)) (Nat.succ_pos j))))))
      (Rneg (ofQ (add (⟨1, 2 * (j + 1) * ((j + 1) + 1)⟩ : Q)
        (mul (⟨1, 3⟩ : Q) (mul (mul (⟨1, j + 1⟩ : Q) (⟨1, j + 1⟩ : Q)) (⟨1, j + 1⟩ : Q))))
        (add_den_pos (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos (j + 1)))
          (Qmul_den_pos (by decide)
            (Qmul_den_pos (Qmul_den_pos (Nat.succ_pos j) (Nat.succ_pos j)) (Nat.succ_pos j)))))) := by
    refine Req_trans (Radd_congr (Req_trans (Radd_comm zero _) (Radd_zero _)) (Req_refl _)) ?_
    exact Req_trans (Req_symm (Rneg_Radd _ _)) (Rneg_congr (Radd_ofQ_ofQ _ _))
  refine Rle_trans ?_ (Rle_of_Req (Req_symm hcollapse))
  exact Rle_Rneg (Rle_ofQ_ofQ _ _ (hAB_qle j hj))

/-- **Telescoping tail**: `hSeq(N+k) ≥ hSeq(N) − (1/(N+1) − 1/(N+k+1))` (`N ≥ 1`), by induction on `k`
    (`hSeq_step_eq` + `sStep_lower_tele` + the telescoping identity `1/(N+1)−1/(P+1) + 1/((P+1)(P+2))
    = 1/(N+1)−1/(P+2)`).  Hence `hSeq(M) ≥ hSeq(N) − 1/(N+1)` for all `M ≥ N`. -/
theorem hSeq_tele (N : Nat) (hN : 1 ≤ N) : ∀ k,
    Rle (Rsub (hSeq N) (Rsub (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨1, N + k + 1⟩ : Q) (Nat.succ_pos (N + k)))))
        (hSeq (N + k)) := by
  intro k
  induction k with
  | zero =>
    refine Rle_of_Req (Req_trans (Rsub_congr (Req_refl _)
      (Radd_neg (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)))) (Radd_zero (hSeq N)))
  | succ k ih =>
    have hPk : 1 ≤ N + k := Nat.le_trans hN (Nat.le_add_right N k)
    -- per-step: hSeq(P+1) − hSeq(P) ≥ −1/((P+1)(P+2)),  P = N+k
    have hstep : Rle (Rneg (ofQ (⟨1, (N + k + 1) * (N + k + 2)⟩ : Q)
          (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1)))))
        (Rsub (hSeq (N + k + 1)) (hSeq (N + k))) :=
      Rle_trans (sStep_lower_tele (N + k) hPk) (Rle_of_Req (Req_symm (hSeq_step_eq (N + k))))
    -- telescoping Q-identity: B_k + c = B_{k+1}
    have hABc : Req (Radd (Rsub (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨1, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))
          (ofQ (⟨1, (N + k + 1) * (N + k + 2)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1)))))
        (Rsub (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
          (ofQ (⟨1, N + (k + 1) + 1⟩ : Q) (Nat.succ_pos (N + (k + 1))))) := by
      apply Req_of_seq_Qeq; intro n
      show Qeq (add (add (⟨1, N + 1⟩ : Q) (neg (⟨1, N + k + 1⟩ : Q)))
          (⟨1, (N + k + 1) * (N + k + 2)⟩ : Q))
        (add (⟨1, N + 1⟩ : Q) (neg (⟨1, N + (k + 1) + 1⟩ : Q)))
      simp only [Qeq, add, neg, mul]
      push_cast
      ring_uor
    -- combine: (hSeq N − B_k) + (−c) ≈ hSeq N − B_{k+1}
    have hcombine : Req
        (Radd (Rsub (hSeq N) (Rsub (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
              (ofQ (⟨1, N + k + 1⟩ : Q) (Nat.succ_pos (N + k)))))
          (Rneg (ofQ (⟨1, (N + k + 1) * (N + k + 2)⟩ : Q)
            (Nat.mul_pos (Nat.succ_pos (N + k)) (Nat.succ_pos (N + k + 1))))))
        (Rsub (hSeq N) (Rsub (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
          (ofQ (⟨1, N + (k + 1) + 1⟩ : Q) (Nat.succ_pos (N + (k + 1)))))) := by
      refine Req_trans (Radd_assoc (hSeq N) _ _) ?_
      refine Radd_congr (Req_refl (hSeq N)) ?_
      exact Req_trans (Req_symm (Rneg_Radd _ _)) (Rneg_congr hABc)
    refine Rle_trans (Rle_of_Req (Req_symm hcombine)) ?_
    refine Rle_trans (Radd_le_add ih hstep) ?_
    exact Rle_of_Req (Req_symm (sub_add_cancel_real (hSeq (N + k + 1)) (hSeq (N + k))))

/-- `a − (a − b) ≈ b`. -/
theorem Rsub_sub_self (a b : Real) : Req (Rsub a (Rsub a b)) b := by
  refine Req_trans (Radd_congr (Req_refl a)
    (Req_trans (Rneg_Radd a (Rneg b)) (Radd_congr (Req_refl _) (Rneg_neg b)))) ?_
  refine Req_trans (Req_symm (Radd_assoc a (Rneg a) b)) ?_
  refine Req_trans (Radd_congr (Radd_neg a) (Req_refl b)) ?_
  exact Req_trans (Radd_comm zero b) (Radd_zero b)

/-- **`hSeq(N+k) ≥ hSeq(N) − 1/(N+1)`** (uniform in `k`, `N ≥ 1`) — drop the nonneg `+1/(N+k+1)`. -/
theorem hSeq_lower_const (N : Nat) (hN : 1 ≤ N) (k : Nat) :
    Rle (Rsub (hSeq N) (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))) (hSeq (N + k)) := by
  have hBkle : Rle (Rsub (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))
        (ofQ (⟨1, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))
      (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N)) := by
    refine Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (Rsub_sub_self _ _)) ?_)
    exact Rnonneg_ofQ (Nat.succ_pos (N + k)) (by show (0 : Int) ≤ 1; decide)
  exact Rle_trans (Rsub_le_sub (Rle_of_Req (Req_refl (hSeq N))) hBkle) (hSeq_tele N hN k)

-- ===========================================================================
-- (C5a) The limit: `γ₂ ≥ hSeq(N) − 1/(N+1)`.  Each `g2SeqDyadic k = g2Seq(2^{2k+8}) ≥ hSeq(2^{2k+8})
-- ≥ hSeq(N) − 1/(N+1)`, so the limit `γ₂` is too (one-sided Archimedean via the `RTendsTo` rate).
-- ===========================================================================

/-- **`hSeq N ≤ g2Seq N`** — `g2Seq N = hSeq N + ½(ln(N+1))²/(N+1)` and the correction is `≥ 0`. -/
theorem hSeq_le_g2Seq (N : Nat) : Rle (hSeq N) (g2Seq N) := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (Rsub_sub_self (g2Seq N)
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (N + 1) (Nat.succ_pos N))))) ?_)
  exact Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
    (lnSqOver_nonneg (N + 1) (Nat.succ_pos N))

/-- **`γ₂ ≥ hSeq N − 1/(N+1)`** for `N ∈ [1, 256]` — each reindexed `g2SeqDyadic k = g2Seq(2^{2k+8})`
    (`2^{2k+8} ≥ 256 ≥ N`) is `≥ hSeq(2^{2k+8}) ≥ hSeq N − 1/(N+1)`, so the limit is too. -/
theorem Rgamma2_ge_hSeq {N : Nat} (hN : 1 ≤ N) (hN256 : N ≤ 256) :
    Rle (Rsub (hSeq N) (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))) Rgamma2 := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have hN2k : N ≤ 2 ^ (2 * k + 8) := by
    have h8 : (2 : Nat) ^ 8 ≤ 2 ^ (2 * k + 8) := Nat.pow_le_pow_right (by omega) (by omega)
    have h256 : (256 : Nat) = 2 ^ 8 := by decide
    omega
  have htend : Rle (Rsub (g2SeqDyadic k) Rgamma2) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    RTendsTo_to_Rle (Rlim_tendsTo g2SeqDyadic g2SeqDyadic_RReg) k
  have hanchor : Rle (Rsub (hSeq N) (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))) (g2SeqDyadic k) := by
    obtain ⟨d, hd⟩ := Nat.le.dest hN2k
    have h1 : Rle (Rsub (hSeq N) (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))) (hSeq (N + d)) :=
      hSeq_lower_const N hN d
    rw [hd] at h1
    exact Rle_trans h1 (hSeq_le_g2Seq (2 ^ (2 * k + 8)))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split
    (Rsub (hSeq N) (ofQ (⟨1, N + 1⟩ : Q) (Nat.succ_pos N))) (g2SeqDyadic k) Rgamma2))) ?_
  refine Rle_trans (Radd_le_add
    (Rsub_le_of_le_add (Rle_trans hanchor (Rle_of_Req
      (Req_symm (Req_trans (Radd_comm zero (g2SeqDyadic k)) (Radd_zero (g2SeqDyadic k)))))))
    htend) ?_
  exact Rle_of_Req (Req_trans (Radd_comm zero _) (Radd_zero _))

-- ===========================================================================
-- (C5b) **THE BRACKET: `γ₂ ≥ −0.02`** — `γ₂ ≥ hSeq(199) − 1/200`, with `hSeq(199)` bounded below by
-- the single rational `gBound2 3 10⁸ 199` (wrapped as a `def` so the giant evaluator term stays
-- opaque in the flat final proof — the `γ₁`/`gBound` pattern), the residual `1/200`, and one `decide`.
-- ===========================================================================

/-- `(ofQ a) − (ofQ b) ≈ ofQ(a − b)` — generic, no evaluation (keeps big `a,b` opaque). -/
theorem Rsub_ofQ_ofQ {a b : Q} (ha : 0 < a.den) (hb : 0 < b.den) :
    Req (Rsub (ofQ a ha) (ofQ b hb)) (ofQ (add a (neg b)) (add_den_pos ha hb)) :=
  Req_trans (Radd_congr (Req_refl (ofQ a ha)) (Rneg_ofQ b hb))
    (Radd_ofQ_ofQ (a := a) (b := neg b) ha hb)

/-- The **rational lower bound on `hSeq N`** (depth `T`, denominator `D`) as a single `Q` (`def`, so
    the deep evaluator term stays opaque downstream — the `gBound` pattern). -/
def gBound2 (T D N : Nat) : Q :=
  add (add (lnSqSumLo T D (N + 1))
      (neg (mul (⟨1, 3⟩ : Q) (mul (mul (logBound T D N) (logBound T D N)) (logBound T D N)))))
    (neg (mul (⟨1, 2⟩ : Q) (mul (mul (logBound T D N) (logBound T D N)) (⟨1, N + 1⟩ : Q))))

theorem gBound2_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound2 T D N).den :=
  add_den_pos (add_den_pos (lnSqSumLo_den_pos T D hD (N + 1))
      (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (logBound_den_pos T D hD N)
        (logBound_den_pos T D hD N)) (logBound_den_pos T D hD N))))
    (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (logBound_den_pos T D hD N)
      (logBound_den_pos T D hD N)) (Nat.succ_pos N)))

set_option maxRecDepth 40000 in
/-- **`ofQ(gBound2 T D N) ≤ hSeq N`** (`T ≤ 21`) — the rational lower bound (`lnSqSumLo_le`,
    `logCube_le`, `halfSqOver_le`), collapsing the all-`ofQ` Rsub-tower to the single `gBound2`. -/
theorem hSeq_ge_gBound2 (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (gBound2 T D N) (gBound2_den_pos T D N hD)) (hSeq N) := by
  have Ld := logBound_den_pos T D hD N
  have hcube : Rle (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (logCube (N + 1) (Nat.succ_pos N)))
      (ofQ (mul (⟨1, 3⟩ : Q) (mul (mul (logBound T D N) (logBound T D N)) (logBound T D N)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos Ld Ld) Ld))) :=
    Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (logCube_le T D N hD))
      (Rle_of_Req (Rmul_ofQ_ofQ (by decide) (Qmul_den_pos (Qmul_den_pos Ld Ld) Ld)))
  have hlow : Rle
      (Rsub (Rsub (ofQ (lnSqSumLo T D (N + 1)) (lnSqSumLo_den_pos T D hD (N + 1)))
          (ofQ (mul (⟨1, 3⟩ : Q) (mul (mul (logBound T D N) (logBound T D N)) (logBound T D N)))
            (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos Ld Ld) Ld))))
        (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (logBound T D N) (logBound T D N)) (⟨1, N + 1⟩ : Q)))
          (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos Ld Ld) (Nat.succ_pos N)))))
      (hSeq N) :=
    Rsub_le_sub (Rsub_le_sub (lnSqSumLo_le T D hD hT (N + 1)) hcube) (halfSqOver_le T D N hD)
  exact Rle_trans (Rle_of_Req (Req_symm (Req_of_seq_Qeq (fun n => Qeq_refl _)))) hlow

set_option maxRecDepth 40000 in
/-- The numeric heart: `−1/50 ≤ gBound2 3 10⁸ 199 − 1/200` — one big-integer kernel `decide` (≈3s). -/
theorem gamma2_decide :
    Qle (⟨-1, 50⟩ : Q) (Qsub (gBound2 3 100000000 199) (⟨1, 199 + 1⟩ : Q)) := by decide

/-- **`γ₂ ≥ −1/50` (`= −0.02`)** — the certified bracket on the second Stieltjes constant.  `γ₂ ≥
    hSeq(199) − 1/200` (`Rgamma2_ge_hSeq`), `hSeq(199) ≥ ofQ(gBound2 3 10⁸ 199)` (`hSeq_ge_gBound2`),
    `gBound2 3 10⁸ 199 − 1/200 ≥ −1/50` (`gamma2_decide`). -/
theorem Rgamma2_ge_neg002 : Rle (ofQ (⟨-1, 50⟩ : Q) (by decide)) Rgamma2 := by
  have hD : 0 < 100000000 := by decide
  refine Rle_trans ?_ (Rgamma2_ge_hSeq (show 1 ≤ 199 by decide) (show 199 ≤ 256 by decide))
  refine Rle_trans ?_
    (Rsub_le_sub (hSeq_ge_gBound2 3 100000000 199 hD (by decide)) (Rle_of_Req (Req_refl _)))
  exact Rle_trans
    (Rle_ofQ_ofQ (by decide)
      (add_den_pos (gBound2_den_pos 3 100000000 199 hD) (Nat.succ_pos 199)) gamma2_decide)
    (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ (gBound2_den_pos 3 100000000 199 hD) (Nat.succ_pos 199))))

end UOR.Bridge.F1Square.Analysis
