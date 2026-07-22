/-
F1 square — v0.22.0 crux frontier: **the certified UPPER bracket on the third Stieltjes constant `γ₃`**
via DISCRETE Euler–Maclaurin (NO constructive integration), the `λ₄` (n=4 coupling) input.

`γ₄`'s closed form (`LambdaFour.lean`) carries `γ₃` ONLY through `η₃` with coefficient `+2/3`, so
`λ₄^{arith}` carries `−(2/3)γ₃ ≈ −0.00137`. Hence `Pos λ₄` needs only a LOOSE UPPER bound on `γ₃`
(the side controlling that negative term) — this file builds it.

`γ₃ = g₃(N) + tail` (`g₃(N) = Σ_{k≤N}(ln k)³/k − ¼(ln N)⁴`, `GammaThree.lean`). The trapezoidal anchor
`½f(N)` (`f(x) = (ln x)³/x`) captures the leading tail `½(ln N)³/N`, leaving the summable residual
`s_p = O((ln p)³/p³)`. So `γ₃ ≤ g₃(N) − ½(ln N)³/N + ε = hSeq3(N) + ε`, certifiable at modest `N` with
the rational cubed/quartic-log evaluators.

THIS FILE — part (A): the cubed-log UPPER-sum evaluator `lnCubeSumUp` (a rational upper bound for
`Σ_{k=1}^N (ln k)³/k`, the `GammaTwoBracket.lnSqSumLo` analogue, upper side, via `logBound` cubed and
round-up) and the quartic- and cubed-log LOWER bounds (`logQuartic`/`lnCubeOver` via `logLowBound`), the
pieces of the upper bound on `hSeq3 N`. The accelerated sequence, residual, telescoping and final
assembly follow.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import Core.F1.Analysis.GammaThree
import Core.F1.Analysis.GammaTwoBracket

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- (A) `lnCubeSumUp` — a rational UPPER bound for `lnCubeSum N = Σ_{k=1}^N (ln k)³/k`.
-- ===========================================================================

/-- The accumulated rational upper bound for `Σ_{k=1}^N (ln k)³/k`, at fixed denominator `D`: each new
    term `(log(n+1))³/(n+1) ≤ (logBound n)³·(1/(n+1))`, then round UP. -/
def lnCubeSumUp (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (n + 1) =>
      qRoundUp (add (lnCubeSumUp T D n)
        (mul (mul (mul (logBound T D n) (logBound T D n)) (logBound T D n)) ⟨1, n + 1⟩)) D

theorem lnCubeSumUp_den_pos (T D : Nat) (hD : 0 < D) : ∀ N, 0 < (lnCubeSumUp T D N).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`lnCubeSum N ≤ ofQ(lnCubeSumUp T D N)`** — the partial sum `Σ (log k)³/k` bounded ABOVE
    term-by-term via `logCube_le` (depth-`T` `logBound` cubed), accumulated at denominator `D`
    (round up). -/
theorem lnCubeSum_le (T D : Nat) (hD : 0 < D) :
    ∀ N, Rle (lnCubeSum N) (ofQ (lnCubeSumUp T D N) (lnCubeSumUp_den_pos T D hD N)) := by
  intro N
  induction N with
  | zero =>
    have h0 : Req (ofQ (lnCubeSumUp T D 0) (lnCubeSumUp_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req (Req_symm h0)
  | succ n ih =>
    have Ld := logBound_den_pos T D hD n
    have hcubed : 0 < (mul (mul (logBound T D n) (logBound T D n)) (logBound T D n)).den :=
      Qmul_den_pos (Qmul_den_pos Ld Ld) Ld
    have hmuld : 0 < (mul (mul (mul (logBound T D n) (logBound T D n)) (logBound T D n))
        (⟨1, n + 1⟩ : Q)).den := Qmul_den_pos hcubed (Nat.succ_pos n)
    -- per-term upper bound `(ln(n+1))³·(1/(n+1)) ≤ ofQ((logBound n)³·(1/(n+1)))`
    have hterm : Rle (lnCubeOver (n + 1) (by omega))
        (ofQ (mul (mul (mul (logBound T D n) (logBound T D n)) (logBound T D n)) ⟨1, n + 1⟩) hmuld) := by
      refine Rle_trans (Rmul_le_Rmul_right
        (Rnonneg_ofQ (Nat.succ_pos n) (by show (0 : Int) ≤ 1; decide)) (logCube_le T D n hD)) ?_
      exact Rle_of_Req (Rmul_ofQ_ofQ hcubed (Nat.succ_pos n))
    have hadd := add_den_pos (lnCubeSumUp_den_pos T D hD n) hmuld
    -- accumulate: lnCubeSum n + lnCubeOver(n+1) ≤ ofQ(prev + term) ≤ ofQ(round-up)
    refine Rle_trans (Radd_le_add ih hterm) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (lnCubeSumUp_den_pos T D hD n) hmuld)) ?_
    exact Rle_ofQ_ofQ hadd (lnCubeSumUp_den_pos T D hD (n + 1))
      (qRoundUp_ge (add (lnCubeSumUp T D n)
        (mul (mul (mul (logBound T D n) (logBound T D n)) (logBound T D n)) ⟨1, n + 1⟩)) hadd D)

-- ===========================================================================
-- (B) Quartic-/cubed-log LOWER bounds (`logLowBound`) — for the subtracted terms of `hSeq3`.
-- ===========================================================================

/-- `ofQ(logLowBound T D M) ≥ 0`. -/
theorem logLowBound_ofQ_nonneg (T D M : Nat) (hD : 0 < D) :
    Rnonneg (ofQ (logLowBound T D M) (logLowBound_den_pos T D hD M)) :=
  Rnonneg_ofQ (logLowBound_den_pos T D hD M) (logLowBound_num_nonneg T D M)

/-- **Cubed-log lower bound** `(logLowBound M)³ ≤ (ln(M+1))³` (`logCube`), depth `T ≤ 21`. -/
theorem logCube_ge (T D M : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (mul (mul (logLowBound T D M) (logLowBound T D M)) (logLowBound T D M))
          (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD M) (logLowBound_den_pos T D hD M))
            (logLowBound_den_pos T D hD M)))
        (logCube (M + 1) (Nat.succ_pos M)) := by
  have LLd := logLowBound_den_pos T D hD M
  refine Rle_trans (Rle_of_Req ?_) (cube_mono (logLowBound_ofQ_nonneg T D M hD)
    (Rnonneg_logN (M + 1) (Nat.succ_pos M)) (logN_ge_logLowBound T D hD hT M))
  exact Req_symm (Req_trans (Rmul_congr (Rmul_ofQ_ofQ LLd LLd) (Req_refl _))
    (Rmul_ofQ_ofQ (Qmul_den_pos LLd LLd) LLd))

/-- **Quartic-log lower bound** `(logLowBound M)⁴ ≤ (ln(M+1))⁴` (`logQuartic = logCube·logN`). -/
theorem logQuartic_ge (T D M : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (mul (mul (mul (logLowBound T D M) (logLowBound T D M)) (logLowBound T D M))
            (logLowBound T D M))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD M)
            (logLowBound_den_pos T D hD M)) (logLowBound_den_pos T D hD M))
            (logLowBound_den_pos T D hD M)))
        (logQuartic (M + 1) (Nat.succ_pos M)) := by
  have LLd := logLowBound_den_pos T D hD M
  have hcubed : 0 < (mul (mul (logLowBound T D M) (logLowBound T D M)) (logLowBound T D M)).den :=
    Qmul_den_pos (Qmul_den_pos LLd LLd) LLd
  have hcubenn : Rnonneg (ofQ (mul (mul (logLowBound T D M) (logLowBound T D M)) (logLowBound T D M))
      hcubed) :=
    Rnonneg_congr (Req_trans (Rmul_congr (Rmul_ofQ_ofQ LLd LLd) (Req_refl _))
        (Rmul_ofQ_ofQ (Qmul_den_pos LLd LLd) LLd))
      (Rnonneg_Rmul (Rnonneg_Rmul (logLowBound_ofQ_nonneg T D M hD) (logLowBound_ofQ_nonneg T D M hD))
        (logLowBound_ofQ_nonneg T D M hD))
  -- (LL)⁴ = (LL)³·LL ≤ (ln)³·LL ≤ (ln)³·(ln) = logQuartic
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hcubed LLd)) ?_
  refine Rle_trans (Rmul_le_Rmul_right (logLowBound_ofQ_nonneg T D M hD) (logCube_ge T D M hD hT)) ?_
  exact Rmul_le_Rmul_left (logCube_nonneg (M + 1) (Nat.succ_pos M)) (logN_ge_logLowBound T D hD hT M)

/-- **Cubed-log-over-`N` lower bound** `(logLowBound M)³·(1/(M+1)) ≤ (ln(M+1))³/(M+1)` (`lnCubeOver`)
    — the trapezoidal anchor `f(M+1)`, bounded below. -/
theorem lnCubeOver_ge (T D M : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (mul (mul (mul (logLowBound T D M) (logLowBound T D M)) (logLowBound T D M))
            (⟨1, M + 1⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD M)
            (logLowBound_den_pos T D hD M)) (logLowBound_den_pos T D hD M)) (Nat.succ_pos M)))
        (lnCubeOver (M + 1) (Nat.succ_pos M)) := by
  have LLd := logLowBound_den_pos T D hD M
  have hcubed : 0 < (mul (mul (logLowBound T D M) (logLowBound T D M)) (logLowBound T D M)).den :=
    Qmul_den_pos (Qmul_den_pos LLd LLd) LLd
  have hovnn : Rnonneg (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)) :=
    Rnonneg_ofQ (Nat.succ_pos M) (by show (0 : Int) ≤ 1; decide)
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ hcubed (Nat.succ_pos M))) ?_
  exact Rmul_le_Rmul_right hovnn (logCube_ge T D M hD hT)

-- ===========================================================================
-- (C1) The accelerated sequence `hSeq3 j = g₃(j) − ½·(ln(j+1))³/(j+1)` (`→ γ₃`), whose per-step
-- increment is the trapezoidal residual `sStep3` (`f(x) = (ln x)³/x`, ∫ = ¼(ln x)⁴).
-- ===========================================================================

/-- The Euler–Maclaurin **accelerated sequence** `hSeq3 j = g₃(j) − ½·(ln(j+1))³/(j+1)` — same limit
    `γ₃` as `g₃`, but its increment is the summable trapezoidal residual. -/
def hSeq3 (j : Nat) : Real :=
  Rsub (g3Seq j) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (j + 1) (Nat.succ_pos j)))

/-- The **per-step trapezoidal residual** `s_p = ½[(ln(p+1))³/(p+1) + (ln p)³/p] − ¼[(ln(p+1))⁴ −
    (ln p)⁴]` (`p ≥ 1`) — `O((ln p)³/p³)`, the increment of `hSeq3`. -/
def sStep3 (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (p + 1) (Nat.succ_pos p)))
             (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver p hp)))
       (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
         (Rsub (logQuartic (p + 1) (Nat.succ_pos p)) (logQuartic p hp)))

/-- **`hSeq3(j+1) − hSeq3 j ≈ s_{j+1}`** — the increment of the accelerated sequence is the trapezoidal
    residual (`g3Seq_step_eq` gives `e_{j+1}`; `half_add_self`/`resid_regroup` move the correction). -/
theorem hSeq3_step_eq (j : Nat) :
    Req (Rsub (hSeq3 (j + 1)) (hSeq3 j)) (sStep3 (j + 1) (Nat.succ_pos j)) := by
  unfold hSeq3 sStep3
  refine Req_trans (Rsub_sub_sub (g3Seq (j + 1))
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (j + 2) (Nat.succ_pos (j + 1))))
    (g3Seq j) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (j + 1) (Nat.succ_pos j)))) ?_
  refine Req_trans (Rsub_congr (g3Seq_step_eq j) (Req_refl _)) ?_
  -- e_{j+1} = (ln(j+2))³/(j+2) − ¼Δ; rewrite the leading `(ln(j+2))³/(j+2)` as ½·+½·
  show Req
    (Rsub (Rsub (lnCubeOver (j + 2) (Nat.succ_pos (j + 1)))
        (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
          (Rsub (logQuartic (j + 2) (Nat.succ_pos (j + 1))) (logQuartic (j + 1) (Nat.succ_pos j)))))
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (j + 2) (Nat.succ_pos (j + 1))))
        (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (j + 1) (Nat.succ_pos j))))) _
  refine Req_trans (Rsub_congr
    (Rsub_congr (half_add_self (lnCubeOver (j + 2) (Nat.succ_pos (j + 1)))) (Req_refl _))
    (Req_refl _)) ?_
  exact resid_regroup (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (j + 2) (Nat.succ_pos (j + 1))))
    (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (j + 1) (Nat.succ_pos j)))
    (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
      (Rsub (logQuartic (j + 2) (Nat.succ_pos (j + 1))) (logQuartic (j + 1) (Nat.succ_pos j))))

-- ===========================================================================
-- (C2a) Coefficient-consolidation helpers (the rational `RMulNF` collapses for the quartic residual)
-- and the cube-binomial / W-expansion (the `a = b + δ` substitution algebra).
-- ===========================================================================

/-- **`½·(3·x) ≈ (3/2)·x`** — the coefficient collapse `½·3 = 3/2` (via `Rmul_ofQ_ofQ` then `ofQ_congr`). -/
theorem half_three (x : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) x) := by
  have hc : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨3, 1⟩ : Q) (by decide)))
      (ofQ (⟨3, 2⟩ : Q) (by decide)) :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  exact Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨3, 1⟩ : Q) (by decide)) x))
    (Rmul_congr hc (Req_refl x))

/-- **`¼·(6·x) ≈ (3/2)·x`** — the coefficient collapse `¼·6 = 3/2`. -/
theorem quarter_six (x : Real) :
    Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) x) := by
  have hc : Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨6, 1⟩ : Q) (by decide)))
      (ofQ (⟨3, 2⟩ : Q) (by decide)) :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  exact Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨6, 1⟩ : Q) (by decide)) x))
    (Rmul_congr hc (Req_refl x))

/-- **`¼·(4·x) ≈ x`** — the coefficient collapse `¼·4 = 1`. -/
theorem quarter_four (x : Real) :
    Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x)) x := by
  have hc : Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨4, 1⟩ : Q) (by decide))) one :=
    Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  exact Req_trans (Req_symm (Rmul_assoc (ofQ (⟨1, 4⟩ : Q) (by decide)) (ofQ (⟨4, 1⟩ : Q) (by decide)) x))
    (Req_trans (Rmul_congr hc (Req_refl x)) (Rone_mul x))

/-- `x + x + x ≈ 3·x` (the additive-to-scalar `3` merge, `ofQ⟨3,1⟩`). -/
theorem three_merge (x : Real) :
    Req (Radd (Radd x x) x) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x) := by
  have h3 : Req (Radd (Radd one one) one) (ofQ (⟨3, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr (Radd_congr hx1 hx1) hx1) ?_
  refine Req_trans (Radd_congr (Req_symm (Rmul_distrib_right one one x)) (Req_refl _)) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right (Radd one one) one x)) (Rmul_congr h3 (Req_refl x))

/-- `x + x + x + x ≈ 4·x` (the additive-to-scalar `4` merge, `ofQ⟨4,1⟩`). -/
theorem four_merge (x : Real) :
    Req (Radd (Radd (Radd x x) x) x) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x) := by
  have h4 : Req (Radd (Radd (Radd one one) one) one) (ofQ (⟨4, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr hx1 hx1) hx1) hx1) ?_
  refine Req_trans (Radd_congr (Radd_congr
    (Req_symm (Rmul_distrib_right one one x)) (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Req_symm (Rmul_distrib_right (Radd one one) one x)) (Req_refl _)) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right (Radd (Radd one one) one) one x))
    (Rmul_congr h4 (Req_refl x))

/-- `2·x + x + x + x + x + x ≈ 6·x` — used to merge the six `b²d²` copies of `W`'s cross expansion into
    `6·(b²d²)` (the `¼·6 = 3/2` consolidation feeds on this). Built as `(2x+x)+x+x+x = ...`. -/
theorem six_merge (x : Real) :
    Req (Radd (Radd (Radd (Radd (Radd x x) x) x) x) x) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) x) := by
  have h6 : Req (Radd (Radd (Radd (Radd (Radd one one) one) one) one) one)
      (ofQ (⟨6, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Radd_congr (Radd_congr hx1 hx1) hx1) hx1)
    hx1) hx1) ?_
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Radd_congr
    (Req_symm (Rmul_distrib_right one one x)) (Req_refl _)) (Req_refl _)) (Req_refl _))
    (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr
    (Req_symm (Rmul_distrib_right (Radd one one) one x)) (Req_refl _)) (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr
    (Req_symm (Rmul_distrib_right (Radd (Radd one one) one) one x)) (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr
    (Req_symm (Rmul_distrib_right (Radd (Radd (Radd one one) one) one) one x)) (Req_refl _)) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right (Radd (Radd (Radd (Radd one one) one) one) one) one x))
    (Rmul_congr h6 (Req_refl x))

/-- `x + 3·x ≈ 4·x` (coefficient merge `1 + 3 = 4`). -/
theorem one_plus_three (x : Real) :
    Req (Radd x (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x)) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x) := by
  have h4 : Req (Radd one (ofQ (⟨3, 1⟩ : Q) (by decide))) (ofQ (⟨4, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr hx1 (Req_refl _)) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right one (ofQ (⟨3, 1⟩ : Q) (by decide)) x))
    (Rmul_congr h4 (Req_refl x))

/-- `3·x + x ≈ 4·x` (coefficient merge `3 + 1 = 4`). -/
theorem three_plus_one (x : Real) :
    Req (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x) x) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) x) := by
  have h4 : Req (Radd (ofQ (⟨3, 1⟩ : Q) (by decide)) one) (ofQ (⟨4, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, one, ofQ, add, Qeq]; push_cast
  have hx1 : Req x (Rmul one x) := Req_symm (Req_trans (Rmul_comm one x) (Rmul_one x))
  refine Req_trans (Radd_congr (Req_refl _) hx1) ?_
  exact Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨3, 1⟩ : Q) (by decide)) one x))
    (Rmul_congr h4 (Req_refl x))

/-- `3·x + 3·x ≈ 6·x` (coefficient merge `3 + 3 = 6`). -/
theorem three_plus_three (x : Real) :
    Req (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) x))
        (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) x) := by
  have h6 : Req (Radd (ofQ (⟨3, 1⟩ : Q) (by decide)) (ofQ (⟨3, 1⟩ : Q) (by decide)))
      (ofQ (⟨6, 1⟩ : Q) (by decide)) := by
    apply Req_of_seq_Qeq; intro n; simp only [Radd, ofQ, add, Qeq]; push_cast
  exact Req_trans (Req_symm (Rmul_distrib_right (ofQ (⟨3, 1⟩ : Q) (by decide))
    (ofQ (⟨3, 1⟩ : Q) (by decide)) x)) (Rmul_congr h6 (Req_refl x))

/-- Left-nested degree-4 flattening: `((x·y)·z)·w ≈ RprodL [x,y,z,w]`. -/
theorem Rmul_eq_RprodL4L (x y z w : Real) :
    Req (Rmul (Rmul (Rmul x y) z) w) (RprodL [x, y, z, w]) :=
  Req_trans (Rmul_congr (Rmul_eq_RprodL3 x y z) (Req_refl w))
    (Req_trans (Rmul_congr (Req_refl (RprodL [x, y, z])) (Req_symm (Rmul_one w)))
      (Req_symm (RprodL_append [x, y, z] [w])))

/-- Left-nested degree-5 flattening: `(((x·y)·z)·w)·v ≈ RprodL [x,y,z,w,v]`. -/
theorem Rmul_eq_RprodL5L (x y z w v : Real) :
    Req (Rmul (Rmul (Rmul (Rmul x y) z) w) v) (RprodL [x, y, z, w, v]) :=
  Req_trans (Rmul_congr (Rmul_eq_RprodL4L x y z w) (Req_refl v))
    (Req_trans (Rmul_congr (Req_refl (RprodL [x, y, z, w])) (Req_symm (Rmul_one v)))
      (Req_symm (RprodL_append [x, y, z, w] [v])))

/-- **Monomial normalizer `X·(c·u) → RprodL`** where `X = (x₁·x₂)·x₃` is a left-nested cube: reassociate
    `X·(c·u) ≈ ((X·c)·u)` then flatten to `RprodL [x₁,x₂,x₃,c,u]`. -/
theorem cube_times_pair (x₁ x₂ x₃ c u : Real) :
    Req (Rmul (Rmul (Rmul x₁ x₂) x₃) (Rmul c u))
        (RprodL [x₁, x₂, x₃, c, u]) :=
  Req_trans (Req_symm (Rmul_assoc (Rmul (Rmul x₁ x₂) x₃) c u))
    (Rmul_eq_RprodL5L x₁ x₂ x₃ c u)

/-- **Monomial normalizer `(x·y)·(c·(z·w)) → RprodL [x,y,c,z,w]`** (reassociate to left-nested 5). -/
theorem pair_times_triple (x y c z w : Real) :
    Req (Rmul (Rmul x y) (Rmul c (Rmul z w))) (RprodL [x, y, c, z, w]) :=
  Req_trans (Req_symm (Rmul_assoc (Rmul x y) c (Rmul z w)))
    (Req_trans (Req_symm (Rmul_assoc (Rmul (Rmul x y) c) z w))
      (Rmul_eq_RprodL5L x y c z w))

/-- **Monomial normalizer `x·((z₁·z₂)·(c·w)) → RprodL [x,z₁,z₂,c,w]`** (reassociate to left-nested 5). -/
theorem single_times_sqpair (x z₁ z₂ c w : Real) :
    Req (Rmul x (Rmul (Rmul z₁ z₂) (Rmul c w))) (RprodL [x, z₁, z₂, c, w]) :=
  Req_trans (Req_symm (Rmul_assoc x (Rmul z₁ z₂) (Rmul c w)))
    (Req_trans (Rmul_congr (Req_symm (Rmul_assoc x z₁ z₂)) (Req_refl _))
      (Req_trans (Req_symm (Rmul_assoc (Rmul (Rmul x z₁) z₂) c w))
        (Rmul_eq_RprodL5L x z₁ z₂ c w)))

set_option maxHeartbeats 8000000 in
/-- **The cube binomial** `(b+d)³ ≈ b³ + 3·(b²d) + 3·(bd²) + d³` (`b³ = (b·b)·b`, etc.; the `3`s as
    `ofQ⟨3,1⟩` factors), for the `a = b+δ` substitution in `partA`/`partC`.  Expand `(b+d)²` via
    `sq_binom2`, distribute the trailing `(b+d)`, normalize each monomial, and merge `2X + X = 3X`
    (`two_plus_one`). -/
theorem cube_binom (b d : Real) :
    Req (Rmul (Rmul (Radd b d) (Radd b d)) (Radd b d))
        (Radd (Radd (Radd (Rmul (Rmul b b) b)
                  (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
              (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)))
          (Rmul (Rmul d d) d)) := by
  -- (b+d)² = b² + 2(bd) + d²
  refine Req_trans (Rmul_congr (sq_binom2 b d) (Req_refl (Radd b d))) ?_
  -- distribute the trailing (b+d): X·(b+d) = X·b + X·d
  refine Req_trans (Rmul_distrib
    (Radd (Radd (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d))) (Rmul d d)) b d) ?_
  -- expand X·b and X·d into their three monomials each
  refine Req_trans (Radd_congr
    (Req_trans (Rmul_distrib_right (Radd (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)))
        (Rmul d d) b)
      (Radd_congr (Rmul_distrib_right (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)) b)
        (Req_refl _)))
    (Req_trans (Rmul_distrib_right (Radd (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)))
        (Rmul d d) d)
      (Radd_congr (Rmul_distrib_right (Rmul b b) (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)) d)
        (Req_refl _)))) ?_
  -- now: ((b³ + (2bd)·b) + d²·b) + ((b²d + (2bd)·d) + d³)
  -- normalize the six monomials to canonical and regroup
  -- m_bbb = b³, m1 = (2bd)·b ≈ 2·(b²d), m_ddb = d²·b ≈ bd², m_bbd = b²d, m2 = (2bd)·d ≈ 2·(bd²), m_ddd = d³
  have e1 : Req (Rmul (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)) b)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)) :=
    Req_trans (Rmul_assoc (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d) b)
      (Rmul_congr (Req_refl _)
        (Req_trans (Rmul_assoc b d b)
          (Req_trans (Rmul_congr (Req_refl b) (Rmul_comm d b))
            (Req_symm (Rmul_assoc b b d)))))
  have e2 : Req (Rmul (Rmul d d) b) (Rmul (Rmul b d) d) :=
    Req_trans (Rmul_comm (Rmul d d) b) (Req_symm (Rmul_assoc b d d))
  have e3 : Req (Rmul (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d)) d)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) :=
    Rmul_assoc (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul b d) d
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr (Req_refl _) e1) e2)
    (Radd_congr (Radd_congr (Req_refl _) e3) (Req_refl _))) ?_
  -- ((b³ + 2·b²d) + bd²) + ((b²d + 2·bd²) + d³); flatten, permute pairs adjacent, regroup, merge
  refine Req_trans (Radd_congr
    (Radd_eq_RsumL3 (Rmul (Rmul b b) b)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)) (Rmul (Rmul b d) d))
    (Radd_eq_RsumL3 (Rmul (Rmul b b) d)
      (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) (Rmul (Rmul d d) d))) ?_
  refine Req_trans (Req_symm (RsumL_append
    [Rmul (Rmul b b) b, Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d), Rmul (Rmul b d) d]
    [Rmul (Rmul b b) d, Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d), Rmul (Rmul d d) d])) ?_
  refine Req_trans (RsumL_perm (List.Perm.cons (Rmul (Rmul b b) b)
    (List.Perm.cons (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
      ((List.Perm.swap (Rmul (Rmul b b) d) (Rmul (Rmul b d) d)
          [Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d), Rmul (Rmul d d) d]).trans
        (List.Perm.cons (Rmul (Rmul b b) d)
          (List.Perm.swap (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
            (Rmul (Rmul b d) d) [Rmul (Rmul d d) d])))))) ?_
  -- RsumL[b³, 2b²d, b²d, 2bd², bd², d³] = Radd b³ (Radd 2b²d (Radd b²d REST))
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
      (Rmul (Rmul b b) d)
      (Radd (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
        (Radd (Rmul (Rmul b d) d) (Radd (Rmul (Rmul d d) d) zero)))))) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_congr (two_plus_one (Rmul (Rmul b b) d)) (Req_refl _))) ?_
  -- Radd b³ (Radd 3b²d REST), REST = Radd 2bd² (Radd bd² (Radd d³ zero))
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨2, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
      (Rmul (Rmul b d) d) (Radd (Rmul (Rmul d d) d) zero))))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (two_plus_one (Rmul (Rmul b d) d)) (Req_refl _)))) ?_
  -- Radd b³ (Radd 3b²d (Radd 3bd² (Radd d³ zero)))
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (Req_refl _) (Radd_zero (Rmul (Rmul d d) d))))) ?_
  -- Radd b³ (Radd 3b²d (Radd 3bd² d³)) → reassociate to ((b³ + 3b²d) + 3bd²) + d³
  refine Req_trans (Req_symm (Radd_assoc (Rmul (Rmul b b) b)
    (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
    (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) (Rmul (Rmul d d) d)))) ?_
  exact Req_symm (Radd_assoc
    (Radd (Rmul (Rmul b b) b) (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
    (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)) (Rmul (Rmul d d) d))

set_option maxHeartbeats 8000000 in
/-- **PART A** of `lhsForm3`: `½·a³·u1 → ½b³u1 + (3/2)b²δu1 + (3/2)bδ²u1 + ½δ³u1` (`a = b+δ`,
    `cube_binom`, distribute, `½·3 = 3/2` via `half_three`), as the 4 canonical monomials
    `n2, n4, n6, n8` (`δ = a − b`). -/
theorem partA3_eq (a b u1 : Real) :
    Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul a a) a) u1))
      (Radd (Radd (Radd
          (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1])
          (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1]))
          (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1]))
          (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1])) := by
  have ha := sub_add_cancel_real a b
  -- a³ ≈ b³ + 3b²δ + 3bδ² + δ³
  have ha3 : Req (Rmul (Rmul a a) a)
      (Radd (Radd (Radd (Rmul (Rmul b b) b)
                (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
            (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
          (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))) :=
    Req_trans (Rmul_congr (Rmul_congr ha ha) ha) (cube_binom b (Rsub a b))
  -- ½·(a³·u1): rewrite a³, distribute u1 then ½
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr ha3 (Req_refl u1))) ?_
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (Rmul_distrib_right (Radd (Radd (Rmul (Rmul b b) b)
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
      (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) u1)
      (Radd_congr (Req_trans (Rmul_distrib_right (Radd (Rmul (Rmul b b) b)
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))) u1)
        (Radd_congr (Rmul_distrib_right (Rmul (Rmul b b) b)
          (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))) u1) (Req_refl _)))
        (Req_refl _)))) ?_
  refine Req_trans (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Radd (Radd (Rmul (Rmul (Rmul b b) b) u1)
        (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))) u1))
      (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))) u1))
    (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) u1)) ?_
  refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Radd (Rmul (Rmul (Rmul b b) b) u1)
      (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))) u1))
    (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))) u1))
    (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide))
    (Rmul (Rmul (Rmul b b) b) u1)
    (Rmul (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))) u1))
    (Req_refl _)) (Req_refl _)) ?_
  -- now normalize the four monomials
  refine Radd_congr (Radd_congr (Radd_congr ?_ ?_) ?_) ?_
  · exact Rmul_congr (Req_refl _) (Rmul_eq_RprodL4L b b b u1)
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b)) u1))
      (Req_trans (half_three (Rmul (Rmul (Rmul b b) (Rsub a b)) u1))
        (Rmul_congr (Req_refl _) (Rmul_eq_RprodL4L b b (Rsub a b) u1)))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b)) u1))
      (Req_trans (half_three (Rmul (Rmul (Rmul b (Rsub a b)) (Rsub a b)) u1))
        (Rmul_congr (Req_refl _) (Rmul_eq_RprodL4L b (Rsub a b) (Rsub a b) u1)))
  · exact Rmul_congr (Req_refl _) (Rmul_eq_RprodL4L (Rsub a b) (Rsub a b) (Rsub a b) u1)

set_option maxHeartbeats 40000000 in
/-- The collect step of `W_expand` (abstract `d`): `(b³+3b²d+3bd²+d³) + (3b³+3b²d+bd²) ≈
    4b³+6b²d+4bd²+d³`.  Kept abstract in `d` so the heavy flatten/perm/merge elaborates cheaply
    (instantiated at `d = a−b` in `W_expand`). -/
theorem W_collect (b d : Real) :
    Req (Radd (Radd (Radd (Radd (Rmul (Rmul b b) b)
                  (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
                (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)))
              (Rmul (Rmul d d) d))
          (Radd (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
                  (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
                (Rmul (Rmul b d) d)))
        (Radd (Radd (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
                  (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
              (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)))
          (Rmul (Rmul d d) d)) := by
  refine Req_trans (Radd_congr
    (Req_trans (Radd_congr (Radd_eq_RsumL3 (Rmul (Rmul b b) b)
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)))
      (RsumL_singleton (Rmul (Rmul d d) d)))
      (Req_symm (RsumL_append [Rmul (Rmul b b) b,
        Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d),
        Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d)]
        [Rmul (Rmul d d) d])))
    (Radd_eq_RsumL3 (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
      (Rmul (Rmul b d) d))) ?_
  refine Req_trans (Req_symm (RsumL_append
    [Rmul (Rmul b b) b, Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d),
     Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d),
     Rmul (Rmul d d) d]
    [Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b),
     Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d),
     Rmul (Rmul b d) d])) ?_
  -- perm to group like terms, then regroup + merge
  have s1 := List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
    (List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
      (List.Perm.swap (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
        (Rmul (Rmul d d) d)
        [Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d),
         Rmul (Rmul b d) d]))
  have s2 := List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
    (List.Perm.swap (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
      [Rmul (Rmul d d) d,
       Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d),
       Rmul (Rmul b d) d])
  have s3 := List.Perm.swap (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
    (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
    [Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d),
     Rmul (Rmul d d) d,
     Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d),
     Rmul (Rmul b d) d]
  have t1 := List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
    (List.Perm.swap (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
      (Rmul (Rmul d d) d)
      [Rmul (Rmul b d) d])
  have t2 := List.Perm.swap (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
    (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
    [Rmul (Rmul d d) d, Rmul (Rmul b d) d]
  have t3 := List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
    (List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
      (List.Perm.swap (Rmul (Rmul b d) d)
        (Rmul (Rmul d d) d) []))
  refine Req_trans (RsumL_perm (List.Perm.cons (Rmul (Rmul b b) b)
    ((s1.trans (s2.trans s3)).trans
      (List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
        (List.Perm.cons (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
          (t1.trans (t2.trans t3))))))) ?_
  -- RsumL[b³, 3b³, 3b²δ, 3b²δ, 3bδ², bδ², δ³] → regroup + merge
  -- merge b³+3b³ = 4b³ (outermost two terms; NOT wrapped in Radd_congr)
  refine Req_trans (Req_symm (Radd_assoc (Rmul (Rmul b b) b)
    (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
    (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
      (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
        (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
          (Radd (Rmul (Rmul b d) d)
            (Radd (Rmul (Rmul d d) d) zero))))))) ?_
  refine Req_trans (Radd_congr (one_plus_three (Rmul (Rmul b b) b)) (Req_refl _)) ?_
  -- group + merge 3b²δ+3b²δ = 6b²δ
  refine Req_trans (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
      (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
      (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
        (Radd (Rmul (Rmul b d) d)
          (Radd (Rmul (Rmul d d) d) zero)))))) ?_
  refine Req_trans (Radd_congr (Req_refl _)
    (Radd_congr (three_plus_three (Rmul (Rmul b b) d)) (Req_refl _))) ?_
  -- group + merge 3bδ²+bδ² = 4bδ²
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Req_symm (Radd_assoc (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
      (Rmul (Rmul b d) d)
      (Radd (Rmul (Rmul d d) d) zero))))) ?_
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (three_plus_one (Rmul (Rmul b d) d)) (Req_refl _)))) ?_
  -- drop the trailing zero and reassociate to the target shape
  refine Req_trans (Radd_congr (Req_refl _) (Radd_congr (Req_refl _)
    (Radd_congr (Req_refl _) (Radd_zero (Rmul (Rmul d d) d))))) ?_
  refine Req_trans (Req_symm (Radd_assoc (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
    (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d))
    (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
      (Rmul (Rmul d d) d)))) ?_
  exact Req_symm (Radd_assoc
    (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
      (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) d)))
    (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b d) d))
    (Rmul (Rmul d d) d))

set_option maxHeartbeats 8000000 in
/-- **W-expansion** `W = a³ + a²b + ab² + b³ ≈ 4b³ + 6b²δ + 4bδ² + δ³` (`δ = a − b`), for `partC`.
    Factored route: regroup `W = a³ + ((a²b+ab²)+b³)`; the last three terms all end in `·b` so
    `Rmul_distrib_right` (backward) factors them as `((a·a+a·b)+b·b)·b`; that inner sum is
    `inner_merge`'s `3b²+3bδ+δ²` (after `a = b+δ`); distribute `·b` → `3b³+3b²δ+bδ²`; add `cube_binom`'s
    `a³ = b³+3b²δ+3bδ²+δ³` and collect (`1+3=4`, `3+3=6`, `3+1=4`). -/
theorem W_expand (a b : Real) :
    Req (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
          (Rmul (Rmul b b) b))
        (Radd (Radd (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
                  (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
              (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
          (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))) := by
  have ha := sub_add_cancel_real a b
  -- a³ ≈ b³ + 3b²δ + 3bδ² + δ³
  have ha3 : Req (Rmul (Rmul a a) a)
      (Radd (Radd (Radd (Rmul (Rmul b b) b)
                (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
            (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
          (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))) :=
    Req_trans (Rmul_congr (Rmul_congr ha ha) ha) (cube_binom b (Rsub a b))
  -- ((a²b+ab²)+b³) ≈ ((a·a+a·b)+b·b)·b  (factor `·b` out of the three terms)
  have hfac : Req (Radd (Radd (Rmul (Rmul a a) b) (Rmul (Rmul a b) b)) (Rmul (Rmul b b) b))
      (Rmul (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b)) b) :=
    Req_trans (Radd_congr (Req_symm (Rmul_distrib_right (Rmul a a) (Rmul a b) b)) (Req_refl _))
      (Req_symm (Rmul_distrib_right (Radd (Rmul a a) (Rmul a b)) (Rmul b b) b))
  -- inner sum ≈ 3b² + 3bδ + δ²
  have hinner : Req (Radd (Radd (Rmul a a) (Rmul a b)) (Rmul b b))
      (Radd (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
                (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))
            (Rmul (Rsub a b) (Rsub a b))) :=
    Req_trans (Radd_congr (Radd_congr (Rmul_congr ha ha) (Rmul_congr ha (Req_refl b))) (Req_refl _))
      (inner_merge b (Rsub a b))
  -- (3b²+3bδ+δ²)·b ≈ 3b³ + 3b²δ + bδ²
  have hbdb : Req (Rmul (Rmul b (Rsub a b)) b) (Rmul (Rmul b b) (Rsub a b)) :=
    Req_trans (Rmul_assoc b (Rsub a b) b)
      (Req_trans (Rmul_congr (Req_refl b) (Rmul_comm (Rsub a b) b))
        (Req_symm (Rmul_assoc b b (Rsub a b))))
  have hddb : Req (Rmul (Rmul (Rsub a b) (Rsub a b)) b) (Rmul (Rmul b (Rsub a b)) (Rsub a b)) :=
    Req_trans (Rmul_comm (Rmul (Rsub a b) (Rsub a b)) b)
      (Req_symm (Rmul_assoc b (Rsub a b) (Rsub a b)))
  have hdist : Req
      (Rmul (Radd (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
                  (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))))
                (Rmul (Rsub a b) (Rsub a b))) b)
      (Radd (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
                (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
            (Rmul (Rmul b (Rsub a b)) (Rsub a b))) := by
    refine Req_trans (Rmul_distrib_right (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b)))) (Rmul (Rsub a b) (Rsub a b)) b) ?_
    refine Radd_congr (Req_trans (Rmul_distrib_right (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b))
        (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b))) b) ?_) hddb
    refine Radd_congr ?_ ?_
    · exact Req_trans (Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b b) b) (Req_refl _)
    · exact Req_trans (Rmul_assoc (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul b (Rsub a b)) b)
        (Rmul_congr (Req_refl _) hbdb)
  -- assemble S2 = ((a²b+ab²)+b³) ≈ 3b³ + 3b²δ + bδ²
  have hS2 : Req (Radd (Radd (Rmul (Rmul a a) b) (Rmul (Rmul a b) b)) (Rmul (Rmul b b) b))
      (Radd (Radd (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
                (Rmul (ofQ (⟨3, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
            (Rmul (Rmul b (Rsub a b)) (Rsub a b))) :=
    Req_trans hfac (Req_trans (Rmul_congr hinner (Req_refl b)) hdist)
  -- regroup W = a³ + ((a²b+ab²)+b³)
  refine Req_trans (Req_trans (Radd_congr (Radd_assoc (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)
      (Rmul (Rmul a b) b)) (Req_refl _))
    (Radd_assoc (Rmul (Rmul a a) a) (Radd (Rmul (Rmul a a) b) (Rmul (Rmul a b) b))
      (Rmul (Rmul b b) b))) ?_
  exact Req_trans (Radd_congr ha3 hS2) (W_collect b (Rsub a b))

set_option maxHeartbeats 8000000 in
/-- **PART C** of `lhsForm3`: `¼·δ·W → b³δ + (3/2)b²δ² + bδ³ + ¼δ⁴` (`δ = a−b`, `W = a³+a²b+ab²+b³`),
    the POSITIVE monomials `n3,n5,n7,n9` (which `lhsForm3` then subtracts).  `W_expand`, distribute `δ`
    and `¼`, collapse `¼·4 = 1` (`quarter_four`) / `¼·6 = 3/2` (`quarter_six`), normalize. -/
theorem partC3_eq (a b : Real) :
    Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
          (Rmul (Rsub a b)
            (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
              (Rmul (Rmul b b) b))))
      (Radd (Radd (Radd (RprodL [b, b, b, Rsub a b])
            (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]))
          (RprodL [b, Rsub a b, Rsub a b, Rsub a b]))
        (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])) := by
  -- W ≈ 4b³+6b²δ+4bδ²+δ³
  refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl (Rsub a b)) (W_expand a b))) ?_
  -- distribute δ over the 4-term sum
  refine Req_trans (Rmul_congr (Req_refl _)
    (Req_trans (Rmul_distrib (Rsub a b)
        (Radd (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
            (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
        (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)))
      (Radd_congr (Req_trans (Rmul_distrib (Rsub a b)
          (Radd (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
            (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
        (Radd_congr (Rmul_distrib (Rsub a b)
          (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b))
          (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b)))) (Req_refl _)))
        (Req_refl _)))) ?_
  -- distribute ¼ over the 4-term sum
  refine Req_trans (Rmul_distrib (ofQ (⟨1, 4⟩ : Q) (by decide))
    (Radd (Radd (Rmul (Rsub a b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b)))
        (Rmul (Rsub a b) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b)))))
      (Rmul (Rsub a b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b)))))
    (Rmul (Rsub a b) (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)))) ?_
  refine Req_trans (Radd_congr (Rmul_distrib (ofQ (⟨1, 4⟩ : Q) (by decide))
    (Radd (Rmul (Rsub a b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b)))
        (Rmul (Rsub a b) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b)))))
      (Rmul (Rsub a b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b)))))
    (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_congr (Rmul_distrib (ofQ (⟨1, 4⟩ : Q) (by decide))
    (Rmul (Rsub a b) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b)))
    (Rmul (Rsub a b) (Rmul (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b)))))
    (Req_refl _)) (Req_refl _)) ?_
  -- normalize the four monomials
  refine Radd_congr (Radd_congr (Radd_congr ?_ ?_) ?_) ?_
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_left_comm3 (Rsub a b) (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) b)))
      (Req_trans (quarter_four (Rmul (Rsub a b) (Rmul (Rmul b b) b)))
        (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul b b) b))
          (Rmul_eq_RprodL4L b b b (Rsub a b))))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_left_comm3 (Rsub a b) (ofQ (⟨6, 1⟩ : Q) (by decide)) (Rmul (Rmul b b) (Rsub a b))))
      (Req_trans (quarter_six (Rmul (Rsub a b) (Rmul (Rmul b b) (Rsub a b))))
        (Rmul_congr (Req_refl _)
          (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul b b) (Rsub a b)))
            (Rmul_eq_RprodL4L b b (Rsub a b) (Rsub a b)))))
  · exact Req_trans (Rmul_congr (Req_refl _)
      (Rmul_left_comm3 (Rsub a b) (ofQ (⟨4, 1⟩ : Q) (by decide)) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
      (Req_trans (quarter_four (Rmul (Rsub a b) (Rmul (Rmul b (Rsub a b)) (Rsub a b))))
        (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul b (Rsub a b)) (Rsub a b)))
          (Rmul_eq_RprodL4L b (Rsub a b) (Rsub a b) (Rsub a b))))
  · exact Rmul_congr (Req_refl _)
      (Req_trans (Rmul_comm (Rsub a b) (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)))
        (Rmul_eq_RprodL4L (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b)))

-- ===========================================================================
-- (C2b) The quartic residual decomposition `sStep3 ≈ decompForm3 = b³·C2 + b²·R2 + b·R1 + R0`
-- (`d = a − b`, `C2 = ½(u0+u1) − d`, `R2 = (3/2)·d·(u1−d)`, `R1 = d²·((3/2)u1 − d)`,
-- `R0 = ½d³u1 − ¼d⁴`).  The keystone: `b²·R2 ≤ 0` (drops), leaving only the clean-telescoping terms.
-- ===========================================================================

/-- The **stage-1 residual form** (`sStep3` after `quartic_diff_identity`), parameterized:
    `½a³u1 + ½b³u0 − ¼·(a−b)·(a³+a²b+ab²+b³)`. -/
def lhsForm3 (a b u0 u1 : Real) : Real :=
  Rsub (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul a a) a) u1))
             (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) u0)))
       (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
         (Rmul (Rsub a b)
           (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
             (Rmul (Rmul b b) b))))

/-- The **bound-ready decomposition** `b³·C2 + b²·R2 + b·R1 + R0` of the trapezoidal residual
    (`d = a − b`, `C2 = ½(u0+u1) − d`, `R2 = (3/2)·d·(u1−d)`, `R1 = d²·((3/2)u1 − d)`,
    `R0 = ½d³u1 − ¼d⁴`). -/
def decompForm3 (a b u0 u1 : Real) : Real :=
  Radd (Radd (Radd
      (Rmul (Rmul (Rmul b b) b)
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)))
      (Rmul (Rmul b b)
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub u1 (Rsub a b))))))
      (Rmul b
        (Rmul (Rmul (Rsub a b) (Rsub a b))
          (Rsub (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) u1) (Rsub a b)))))
    (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) u1))
          (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
            (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b))))

/-- **`decompForm3` expands to its 9 canonical monomials** (coefficient-first `RprodL`, `d = a − b` an
    atom): distribute each of the four grouped terms and normalize. -/
theorem decompForm3_eq_RsumL (a b u0 u1 : Real) :
    Req (decompForm3 a b u0 u1)
      (RsumL [ RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1],
               Rneg (RprodL [b, b, b, Rsub a b]),
               RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
               Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]),
               RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
               Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b]),
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1],
               Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b]) ]) := by
  -- the 9 canonical monomials
  -- hP : P ≈ RsumL [n1, n2, n3]
  have hn1 : Req (Rmul (Rmul (Rmul b b) b) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u0))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0]) :=
    Req_trans (cube_times_pair b b b (ofQ (⟨1, 2⟩ : Q) (by decide)) u0)
      (RprodL_perm
        (((List.Perm.cons b (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [u0]))).trans
          (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, u0]))).trans
          (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, b, u0])))
  have hn2 : Req (Rmul (Rmul (Rmul b b) b) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u1))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1]) :=
    Req_trans (cube_times_pair b b b (ofQ (⟨1, 2⟩ : Q) (by decide)) u1)
      (RprodL_perm
        (((List.Perm.cons b (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [u1]))).trans
          (List.Perm.cons b (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, u1]))).trans
          (List.Perm.swap (ofQ (⟨1, 2⟩ : Q) (by decide)) b [b, b, u1])))
  have hPb : Req (Rmul (Rmul (Rmul b b) b) (Rsub a b)) (RprodL [b, b, b, Rsub a b]) :=
    Rmul_eq_RprodL4L b b b (Rsub a b)
  have hP : Req (Rmul (Rmul (Rmul b b) b)
        (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)))
      (RsumL [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0],
              RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1],
              Rneg (RprodL [b, b, b, Rsub a b])]) := by
    refine Req_trans (Rmul_sub_distrib (Rmul (Rmul b b) b)
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Radd u0 u1)) (Rsub a b)) ?_
    refine Req_trans (Radd_congr ?_ (Rneg_congr hPb)) (Radd_eq_RsumL3 _ _ _)
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_distrib (ofQ (⟨1, 2⟩ : Q) (by decide)) u0 u1)) ?_
    refine Req_trans (Rmul_distrib (Rmul (Rmul b b) b)
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u0) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) u1)) ?_
    exact Radd_congr hn1 hn2
  -- hQ2 : Q2 ≈ RsumL [n4, n5]
  have hQ2a : Req (Rmul (Rmul b b)
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rmul (Rsub a b) u1)))
      (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1]) :=
    Req_trans (pair_times_triple b b (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rsub a b) u1)
      (RprodL_perm
        ((List.Perm.cons b (List.Perm.swap (ofQ (⟨3, 2⟩ : Q) (by decide)) b [Rsub a b, u1])).trans
          (List.Perm.swap (ofQ (⟨3, 2⟩ : Q) (by decide)) b [b, Rsub a b, u1])))
  have hQ2b : Req (Rmul (Rmul b b)
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub a b))))
      (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]) :=
    Req_trans (pair_times_triple b b (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rsub a b) (Rsub a b))
      (RprodL_perm
        ((List.Perm.cons b (List.Perm.swap (ofQ (⟨3, 2⟩ : Q) (by decide)) b [Rsub a b, Rsub a b])).trans
          (List.Perm.swap (ofQ (⟨3, 2⟩ : Q) (by decide)) b [b, Rsub a b, Rsub a b])))
  have hQ2 : Req (Rmul (Rmul b b)
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub u1 (Rsub a b)))))
      (RsumL [RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
              Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b])]) := by
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
      (Rmul_sub_distrib (Rsub a b) u1 (Rsub a b)))) ?_
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_sub_distrib (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rmul (Rsub a b) u1)
        (Rmul (Rsub a b) (Rsub a b)))) ?_
    refine Req_trans (Rmul_sub_distrib (Rmul b b)
      (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rmul (Rsub a b) u1))
      (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rmul (Rsub a b) (Rsub a b)))) ?_
    exact Req_trans (Radd_congr hQ2a (Rneg_congr hQ2b)) (Radd_eq_RsumL _ _)
  -- hQ1 : Q1 ≈ RsumL [n6, n7]
  have hQ1a : Req (Rmul b (Rmul (Rmul (Rsub a b) (Rsub a b))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) u1)))
      (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1]) :=
    Req_trans (single_times_sqpair b (Rsub a b) (Rsub a b) (ofQ (⟨3, 2⟩ : Q) (by decide)) u1)
      (RprodL_perm
        (((List.Perm.cons b (List.Perm.cons (Rsub a b)
            (List.Perm.swap (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rsub a b) [u1]))).trans
          (List.Perm.cons b (List.Perm.swap (ofQ (⟨3, 2⟩ : Q) (by decide)) (Rsub a b) [Rsub a b, u1]))).trans
          (List.Perm.swap (ofQ (⟨3, 2⟩ : Q) (by decide)) b [Rsub a b, Rsub a b, u1])))
  have hQ1b : Req (Rmul b (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)))
      (RprodL [b, Rsub a b, Rsub a b, Rsub a b]) :=
    Req_trans (Req_symm (Rmul_assoc b (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)))
      (Req_trans (Rmul_congr (Req_symm (Rmul_assoc b (Rsub a b) (Rsub a b))) (Req_refl _))
        (Rmul_eq_RprodL4L b (Rsub a b) (Rsub a b) (Rsub a b)))
  have hQ1 : Req (Rmul b (Rmul (Rmul (Rsub a b) (Rsub a b))
        (Rsub (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) u1) (Rsub a b))))
      (RsumL [RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
              Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b])]) := by
    refine Req_trans (Rmul_congr (Req_refl _)
      (Rmul_sub_distrib (Rmul (Rsub a b) (Rsub a b))
        (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) u1) (Rsub a b))) ?_
    refine Req_trans (Rmul_sub_distrib b
      (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) u1))
      (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b))) ?_
    exact Req_trans (Radd_congr hQ1a (Rneg_congr hQ1b)) (Radd_eq_RsumL _ _)
  -- hQ0 : Q0 ≈ RsumL [n8, n9]
  have hQ0a : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) u1))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1]) :=
    Rmul_congr (Req_refl _) (Rmul_eq_RprodL4L (Rsub a b) (Rsub a b) (Rsub a b) u1)
  have hQ0b : Req (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b)))
      (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b]) :=
    Rmul_congr (Req_refl _) (Rmul_eq_RprodL4L (Rsub a b) (Rsub a b) (Rsub a b) (Rsub a b))
  have hQ0 : Req
      (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
              (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) u1))
            (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
              (Rmul (Rmul (Rmul (Rsub a b) (Rsub a b)) (Rsub a b)) (Rsub a b))))
      (RsumL [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1],
              Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])]) :=
    Req_trans (Radd_congr hQ0a (Rneg_congr hQ0b)) (Radd_eq_RsumL _ _)
  -- assemble: decompForm3 = Radd(Radd(Radd P Q2)Q1)Q0
  unfold decompForm3
  refine Req_trans (Radd_congr (Radd_congr (Radd_congr hP hQ2) hQ1) hQ0) ?_
  refine Req_trans (Radd_congr (Radd_congr (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1], Rneg (RprodL [b, b, b, Rsub a b])]
      [RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
       Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b])]))
      (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1], Rneg (RprodL [b, b, b, Rsub a b]),
       RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
       Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b])]
      [RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
       Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b])])) (Req_refl _)) ?_
  exact Req_symm (RsumL_append
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1], Rneg (RprodL [b, b, b, Rsub a b]),
     RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
     Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]),
     RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
     Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b])]
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1],
     Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])])

set_option maxHeartbeats 8000000 in
/-- **`lhsForm3` expands to its 9 canonical monomials** in the order `[n2,n4,n6,n8,n1,n3,n5,n7,n9]`
    (partA gives `n2,n4,n6,n8`; `½b³u0 = n1`; `−partC` gives `n3,n5,n7,n9`). -/
theorem lhsForm3_eq_RsumL (a b u0 u1 : Real) :
    Req (lhsForm3 a b u0 u1)
      (RsumL [ RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1],
               RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
               RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1],
               RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0],
               Rneg (RprodL [b, b, b, Rsub a b]),
               Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]),
               Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b]),
               Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b]) ]) := by
  -- ½b³u0 ≈ n1
  have hb3u0 : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (Rmul (Rmul (Rmul b b) b) u0))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0]) :=
    Rmul_congr (Req_refl _) (Rmul_eq_RprodL4L b b b u0)
  -- −partC ≈ [n3,n5,n7,n9]
  have hnegC : Req
      (Rneg (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
        (Rmul (Rsub a b)
          (Radd (Radd (Radd (Rmul (Rmul a a) a) (Rmul (Rmul a a) b)) (Rmul (Rmul a b) b))
            (Rmul (Rmul b b) b)))))
      (Radd (Radd (Radd (Rneg (RprodL [b, b, b, Rsub a b]))
            (Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b])))
          (Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b])))
        (Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b]))) := by
    refine Req_trans (Rneg_congr (partC3_eq a b)) ?_
    refine Req_trans (Rneg_Radd (Radd (Radd (RprodL [b, b, b, Rsub a b])
        (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]))
        (RprodL [b, Rsub a b, Rsub a b, Rsub a b]))
      (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])) ?_
    refine Radd_congr ?_ (Req_refl _)
    refine Req_trans (Rneg_Radd (Radd (RprodL [b, b, b, Rsub a b])
        (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]))
      (RprodL [b, Rsub a b, Rsub a b, Rsub a b])) ?_
    exact Radd_congr (Rneg_Radd (RprodL [b, b, b, Rsub a b])
      (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b])) (Req_refl _)
  -- assemble: lhsForm3 = Radd (Radd (½a³u1) (½b³u0)) (Rneg partC)
  unfold lhsForm3
  refine Req_trans (Radd_congr (Radd_congr (partA3_eq a b u1) hb3u0) hnegC) ?_
  -- flatten Radd (Radd PA n1) NC to RsumL[n2,n4,n6,n8,n1,n3,n5,n7,n9]
  -- PA = Radd(Radd(Radd n2 n4) n6) n8 → RsumL[n2,n4,n6,n8]
  have hPA : Req (Radd (Radd (Radd (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1])
        (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1]))
      (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1]))
      (RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1]))
      (RsumL [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1],
              RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
              RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
              RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1]]) :=
    Req_trans (Radd_congr (Radd_eq_RsumL3 _ _ _) (RsumL_singleton _))
      (Req_symm (RsumL_append
        [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1],
         RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
         RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1]]
        [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1]]))
  have hNC : Req (Radd (Radd (Radd (Rneg (RprodL [b, b, b, Rsub a b]))
          (Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b])))
        (Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b])))
      (Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])))
      (RsumL [Rneg (RprodL [b, b, b, Rsub a b]),
              Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]),
              Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b]),
              Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])]) :=
    Req_trans (Radd_congr (Radd_eq_RsumL3 _ _ _) (RsumL_singleton _))
      (Req_symm (RsumL_append
        [Rneg (RprodL [b, b, b, Rsub a b]),
         Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]),
         Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b])]
        [Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])]))
  -- Radd (Radd PA n1) NC → Radd (RsumL[n2,n4,n6,n8,n1]) (RsumL[n3,n5,n7,n9]) → RsumL all 9
  refine Req_trans (Radd_congr (Req_trans (Radd_congr hPA (RsumL_singleton _))
    (Req_symm (RsumL_append
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1],
       RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
       RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
       RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1]]
      [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0]]))) hNC) ?_
  exact Req_symm (RsumL_append
    [RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u1],
     RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, u1],
     RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, Rsub a b, Rsub a b, u1],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, u1],
     RprodL [ofQ (⟨1, 2⟩ : Q) (by decide), b, b, b, u0]]
    [Rneg (RprodL [b, b, b, Rsub a b]),
     Rneg (RprodL [ofQ (⟨3, 2⟩ : Q) (by decide), b, b, Rsub a b, Rsub a b]),
     Rneg (RprodL [b, Rsub a b, Rsub a b, Rsub a b]),
     Rneg (RprodL [ofQ (⟨1, 4⟩ : Q) (by decide), Rsub a b, Rsub a b, Rsub a b, Rsub a b])])

set_option maxHeartbeats 8000000 in
/-- **The keystone identity** `lhsForm3 ≈ decompForm3` — both expand to the same 9 canonical monomials
    (`lhsForm3_eq_RsumL` / `decompForm3_eq_RsumL`), matched by a 9-element permutation
    `[n2,n4,n6,n8,n1,n3,n5,n7,n9] ~ [n1,…,n9]` (explicit `List.Perm`, swap elements inferred). -/
theorem decomp_generic3 (a b u0 u1 : Real) :
    Req (lhsForm3 a b u0 u1) (decompForm3 a b u0 u1) := by
  refine Req_trans (lhsForm3_eq_RsumL a b u0 u1)
    (Req_trans (RsumL_perm ?_) (Req_symm (decompForm3_eq_RsumL a b u0 u1)))
  exact (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))).trans ((List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))).trans ((List.Perm.cons _ (List.Perm.swap _ _ _)).trans ((List.Perm.swap _ _ _).trans ((List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))))).trans ((List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))).trans ((List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))).trans ((List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))).trans ((List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _))))).trans (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.cons _ (List.Perm.swap _ _ _)))))))))))))))

set_option maxHeartbeats 8000000 in
/-- **`sStep3 p ≈ decompForm3`** at the log/reciprocal atoms (`a = ln(p+1)`, `b = ln p`, `u0 = 1/p`,
    `u1 = 1/(p+1)`): `sStep3` matches `lhsForm3` on the nose except the quartic difference
    `(ln(p+1))⁴ − (ln p)⁴`, which `quartic_diff_identity` rewrites to `(a−b)(a³+a²b+ab²+b³)`; then
    `decomp_generic3`. -/
theorem sStep3_decomp (p : Nat) (hp : 1 ≤ p) :
    Req (sStep3 p hp)
      (decompForm3 (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
        (ofQ (⟨1, p⟩ : Q) (by show 0 < p; omega)) (ofQ (⟨1, p + 1⟩ : Q) (by show 0 < p + 1; omega))) := by
  refine Req_trans ?_ (decomp_generic3 (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
    (ofQ (⟨1, p⟩ : Q) (by show 0 < p; omega)) (ofQ (⟨1, p + 1⟩ : Q) (by show 0 < p + 1; omega)))
  unfold sStep3 lhsForm3 lnCubeOver logCube logQuartic
  exact Rsub_congr (Req_refl _)
    (Rmul_congr (Req_refl _)
      (Req_symm (quartic_diff_identity (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))

-- ===========================================================================
-- (C3) The cube-root bound `(ln p)³ ≤ 27·p`.  With `L = ln p ≥ 0`, `M = L/3`:
-- `exp(M) ≥ 1+M ≥ M ≥ 0`, so `exp(L) = exp(M+M+M) = exp(M)³ ≥ M³`, hence
-- `27·exp(L) ≥ 27·M³ = L³`; with `exp(ln p) = p` (`Rexp_logN`) this is `(ln p)³ ≤ 27p`.
-- No `RrpowPos`: only `exp`-additivity and `1+t ≤ exp t`.
-- ===========================================================================

/-- **`(a·x)³ ≈ a³·x³`** (cube of a product splits) — both flatten to the factor multiset
    `{a,x,a,x,a,x} = {a,a,a,x,x,x}`; matched by an explicit `List.Perm` (choice-free). -/
theorem cube_prod_split (a x : Real) :
    Req (Rmul (Rmul (Rmul a x) (Rmul a x)) (Rmul a x))
        (Rmul (Rmul (Rmul a a) a) (Rmul (Rmul x x) x)) := by
  -- LHS ≈ RprodL [a,x,a,x,a,x]
  have hL : Req (Rmul (Rmul (Rmul a x) (Rmul a x)) (Rmul a x)) (RprodL [a, x, a, x, a, x]) :=
    Req_trans (Rmul_congr (Rmul_pair_eq_RprodL4 a x a x) (Req_refl (Rmul a x)))
      (Req_trans (Rmul_congr (Req_refl (RprodL [a, x, a, x])) (Rmul_eq_RprodL a x))
        (Req_symm (RprodL_append [a, x, a, x] [a, x])))
  -- RHS ≈ RprodL [a,a,a,x,x,x]
  have hR : Req (Rmul (Rmul (Rmul a a) a) (Rmul (Rmul x x) x)) (RprodL [a, a, a, x, x, x]) :=
    Req_trans (Rmul_congr (Rmul_eq_RprodL3 a a a) (Rmul_eq_RprodL3 x x x))
      (Req_symm (RprodL_append [a, a, a] [x, x, x]))
  -- [a,x,a,x,a,x] ~ [a,a,a,x,x,x]
  refine Req_trans hL (Req_trans (RprodL_perm ?_) (Req_symm hR))
  exact List.Perm.cons a
    ((List.Perm.swap a x [x, a, x]).trans
      (List.Perm.cons a
        ((List.Perm.cons x (List.Perm.swap a x [x])).trans (List.Perm.swap a x [x, x]))))

/-- **Cube monotonicity** `0 ≤ A ≤ B ⟹ A³ ≤ B³`. -/
theorem cube_le_cube {A B : Real} (hA : Rnonneg A) (hB : Rnonneg B) (hAB : Rle A B) :
    Rle (Rmul (Rmul A A) A) (Rmul (Rmul B B) B) := by
  have hAA_le_BB : Rle (Rmul A A) (Rmul B B) :=
    Rle_trans (Rmul_le_Rmul_left hA hAB) (Rmul_le_Rmul_right hB hAB)
  exact Rle_trans (Rmul_le_Rmul_right hA hAA_le_BB)
    (Rmul_le_Rmul_left (Rnonneg_Rmul hB hB) hAB)

/-- **`L³ ≤ 27·exp(L)`** for `L ≥ 0`.  With `M = L/3`: `exp(M) ≥ 1+M ≥ M ≥ 0`, so
    `exp(L) = exp(M+M+M) = exp(M)³ ≥ M³`, and `27·M³ = L³`. -/
theorem cube_le_27_exp (L : Real) (hL : Rnonneg L) :
    Rle (Rmul (Rmul L L) L) (Rmul (ofQ (⟨27, 1⟩ : Q) (by decide)) (RexpReal L)) := by
  have hMnn : Rnonneg (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hL
  have hEnn : Rnonneg (RexpReal (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)) := RexpReal_nonneg _
  -- M ≤ 1+M ≤ exp(M)
  have hMleE : Rle (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)
      (RexpReal (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)) :=
    Rle_trans (Rle_self_Radd_left Rnonneg_one) (RexpReal_ge_one_add_nonneg hMnn)
  -- M³ ≤ E³
  have hcube := cube_le_cube hMnn hEnn hMleE
  -- M+M+M ≈ L
  have hcoef : Req (Radd (Radd (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)
        (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)) (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)) L := by
    refine Req_trans (Radd_congr (Req_symm (Rmul_distrib_right _ _ L)) (Req_refl _)) ?_
    refine Req_trans (Req_symm (Rmul_distrib_right _ _ L)) ?_
    refine Req_trans (Rmul_congr ?_ (Req_refl L)) (Rone_mul L)
    refine Req_trans (Radd_congr (Radd_ofQ_ofQ (by decide) (by decide)) (Req_refl _)) ?_
    exact Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  -- E³ ≈ exp(L)
  have hE3 : Req (Rmul (Rmul (RexpReal (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L))
          (RexpReal (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)))
        (RexpReal (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L))) (RexpReal L) := by
    refine Req_trans (Rmul_congr (Req_symm (RexpReal_add _ _)) (Req_refl _)) ?_
    exact Req_trans (Req_symm (RexpReal_add _ _)) (RexpReal_congr hcoef)
  -- L³ ≈ 27·M³
  have hconst : Req (Rmul (ofQ (⟨27, 1⟩ : Q) (by decide))
      (Rmul (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)))
        (ofQ (⟨1, 3⟩ : Q) (by decide)))) one := by
    refine Req_trans (Rmul_congr (Req_refl _)
        (Req_trans (Rmul_congr (Rmul_ofQ_ofQ (by decide) (by decide)) (Req_refl _))
          (Rmul_ofQ_ofQ (by decide) (by decide)))) ?_
    exact Req_trans (Rmul_ofQ_ofQ (by decide) (by decide))
      (ofQ_congr (by decide) (by decide) (by decide))
  have hL3 : Req (Rmul (Rmul L L) L)
      (Rmul (ofQ (⟨27, 1⟩ : Q) (by decide))
        (Rmul (Rmul (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)
            (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L)) (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) L))) := by
    refine Req_symm ?_
    refine Req_trans (Rmul_congr (Req_refl _) (cube_prod_split (ofQ (⟨1, 3⟩ : Q) (by decide)) L)) ?_
    refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨27, 1⟩ : Q) (by decide))
        (Rmul (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (ofQ (⟨1, 3⟩ : Q) (by decide)))
          (ofQ (⟨1, 3⟩ : Q) (by decide))) (Rmul (Rmul L L) L))) ?_
    exact Req_trans (Rmul_congr hconst (Req_refl _)) (Rone_mul _)
  -- combine: L³ = 27·M³ ≤ 27·E³ = 27·exp(L)
  refine Rle_trans (Rle_of_Req hL3) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hcube) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) hE3)

/-- **`(ln p)³ ≤ 27·p`** — the cube-root cap (`logCube p ≤ 27p`), via `cube_le_27_exp` and
    `exp(ln p) = p` (`Rexp_logN`). -/
theorem logCube_le_self27 (p : Nat) (hp : 1 ≤ p) :
    Rle (logCube p hp) (ofQ (⟨27 * (p : Int), 1⟩ : Q) Nat.one_pos) := by
  unfold logCube
  refine Rle_trans (cube_le_27_exp (logN p hp) (Rnonneg_logN p hp)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _) (Rexp_logN p hp))) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) Nat.one_pos)
    (ofQ_congr (Qmul_den_pos (by decide) Nat.one_pos) Nat.one_pos
      (by show Qeq (mul (⟨27, 1⟩ : Q) (⟨(p : Int), 1⟩ : Q)) (⟨27 * (p : Int), 1⟩ : Q)
          simp only [Qeq, mul])))

-- ===========================================================================
-- (C4) The per-step UPPER bound `sStep3 p ≤ 11/(p(p+1))` on the trapezoidal residual `decompForm3`.
-- The four terms (`b = ln p`, `δ = a−b`, `u0 = 1/p`, `u1 = 1/(p+1)`):
--   b³·C2 ≤ 7/(p(p+1))    (C2 = ½(u0+u1)−δ ≤ 1/(2p(p+1)(2p+1)), b³ ≤ 27p, 27/(2(p+1)(2p+1))≤7/(p(p+1)))
--   b²·R2 ≤ 0             (R2 = (3/2)δ(u1−δ),  u1 ≤ δ)
--   b·R1  ≤ 3/(p(p+1))    (R1 = δ²((3/2)u1−δ) ≤ (3/2)δ²u1, b ≤ p, δ² ≤ 1/p², drop −δ)
--   R0    ≤ 1/(p(p+1))    (R0 = ½δ³u1 − ¼δ⁴ ≤ ½δ³u1, δ³ ≤ 1/p³, drop −¼δ⁴)
-- The crude denominators (all `p(p+1)`) keep the sum a single `⟨11, p(p+1)⟩` — a loose bound, which
-- is all `Pos λ₄` needs (`−(2/3)γ₃` enters with tiny coefficient).
-- ===========================================================================

/-- **The tight `C2` ceiling** `C2 = ½(1/p+1/(p+1)) − δ ≤ 1/(2p(p+1)(2p+1))` — the trapezoidal error
    is `Θ(1/p³)`.  `δ ≥ 2/(2p+1)` (`deltaLog_lower_tight` at depth `T = 0`, the first artanh term), and
    `dPlusQ 0 p − dMinusQ 0 p = 1/(2p(p+1)(2p+1))` exactly. -/
theorem C2_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (ofQ (⟨1, 2 * p * (p + 1) * (2 * p + 1)⟩ : Q)
          (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)) (by omega))) := by
  have hMd : 0 < (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))).den :=
    Qmul_den_pos (by decide)
      (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p))
  -- M_real ≈ ofQ(M_Q)
  have hMeq : Req (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
        (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
      (ofQ (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))) hMd) :=
    Req_trans (Rmul_congr (Req_refl _)
        (Radd_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)))
      (Rmul_ofQ_ofQ (by decide)
        (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)))
  -- δ ≥ ofQ(dMinusQ 0 p)
  have hδlo := deltaLog_lower_tight p 0 hp (by omega)
  -- C2 = M_real − δ ≤ ofQ(M_Q) − ofQ(dMinusQ 0 p) ≈ ofQ(M_Q − dMinusQ) ≈ target
  refine Rle_trans (Rle_of_Req (Rsub_congr hMeq (Req_refl _))) ?_
  refine Rle_trans (Radd_le_add (Rle_refl _) (Rle_Rneg hδlo)) ?_
  refine Rle_of_Req (Req_trans (Rsub_ofQ_ofQ hMd (dMinusQ_den_pos 0 p)) ?_)
  apply ofQ_congr
  show Qeq (add (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q)))
      (neg (dMinusQ 0 p))) (⟨1, 2 * p * (p + 1) * (2 * p + 1)⟩ : Q)
  simp only [Qeq, dMinusQ, artSum, artTerm, qpow, npow, mul, add, neg]
  push_cast
  ring_uor

/-- `X − Y ≤ X` when `Y ≥ 0`. -/
theorem Rsub_le_self (X : Real) {Y : Real} (hY : Rnonneg Y) : Rle (Rsub X Y) X :=
  Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (Rsub_sub_self X Y)) hY)

/-- `X·Y ≤ 0` when `X ≥ 0` and `Y ≤ 0`. -/
theorem Rmul_nonpos_left {X Y : Real} (hX : Rnonneg X) (hY : Rle Y zero) : Rle (Rmul X Y) zero :=
  Rle_trans (Rmul_le_Rmul_left hX hY) (Rle_of_Req (Rmul_zero X))

/-- `x − y ≤ 0` when `x ≤ y`. -/
theorem Rle_sub_zero {x y : Real} (h : Rle x y) : Rle (Rsub x y) zero := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  exact Req_symm (Req_trans (Req_trans (Radd_comm zero (Rneg (Rsub x y))) (Radd_zero _))
    (Rneg_Rsub_swap x y))

/-- `1/ad ≤ 1/bd` (as `ofQ`) when `bd ≤ ad`. -/
theorem Rle_ofQ_num1 {ad bd : Nat} (had : 0 < ad) (hbd : 0 < bd) (h : bd ≤ ad) :
    Rle (ofQ (⟨1, ad⟩ : Q) had) (ofQ (⟨1, bd⟩ : Q) hbd) :=
  Rle_ofQ_ofQ had hbd (by show (1 : Int) * (bd : Int) ≤ (1 : Int) * (ad : Int); omega)

/-- `⟨c,D⟩ + ⟨c',D⟩ ≈ ⟨c+c',D⟩` (same denominator). -/
theorem Radd_ofQ_same (c1 c2 : Int) (D : Nat) (hD : 0 < D) :
    Req (Radd (ofQ (⟨c1, D⟩ : Q) hD) (ofQ (⟨c2, D⟩ : Q) hD)) (ofQ (⟨c1 + c2, D⟩ : Q) hD) := by
  refine Req_trans (Radd_ofQ_ofQ hD hD) (ofQ_congr (add_den_pos hD hD) hD ?_)
  show Qeq (add (⟨c1, D⟩ : Q) (⟨c2, D⟩ : Q)) (⟨c1 + c2, D⟩ : Q)
  simp only [Qeq, add]
  push_cast
  ring_uor

/-- **`R0 = ½δ³u1 − ¼δ⁴ ≤ 1/(p(p+1))`** (drop `−¼δ⁴ ≤ 0`, `δ³ ≤ 1/p³`, `u1 = 1/(p+1)`,
    `p(p+1) ≤ 2p³(p+1)`). -/
theorem R0_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
          (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide))
            (Rmul (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
        (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hu1nn : Rnonneg (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) :=
    Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)
  -- drop −¼δ⁴: R0 ≤ ½δ³u1
  refine Rle_trans (Rsub_le_self _ (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
    (Rnonneg_Rmul (Rnonneg_Rmul (Rnonneg_Rmul_self _) hδnn) hδnn))) ?_
  -- ½δ³u1 ≤ ½·(1/p³)·(1/(p+1))
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_right hu1nn (dcube_self_le p hp))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Rmul_ofQ_ofQ (a := mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q))
      (Qmul_den_pos (Qmul_den_pos hp hp) hp) (Nat.succ_pos p)))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨1, 2⟩ : Q))
    (b := mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p + 1⟩ : Q)) (by decide)
    (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos hp hp) hp) (Nat.succ_pos p)))) ?_
  refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
  show Qle (mul (⟨1, 2⟩ : Q) (mul (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p⟩ : Q)) (⟨1, p + 1⟩ : Q)))
    (⟨1, p * (p + 1)⟩ : Q)
  simp only [Qle, mul, Int.one_mul, Int.mul_one]
  have hcube : p ≤ p * p * p := by
    have := Nat.le_mul_of_pos_right p (show 0 < p * p by exact Nat.mul_pos hp hp)
    simpa [Nat.mul_assoc] using this
  have key : p * (p + 1) ≤ 2 * (p * p * p * (p + 1)) := by
    have h2 : p * (p + 1) ≤ (p * p * p) * (p + 1) := Nat.mul_le_mul_right (p + 1) hcube
    have h3 : (p * p * p) * (p + 1) ≤ 2 * (p * p * p * (p + 1)) := by
      have := Nat.mul_le_mul_right (p + 1) (show p * p * p ≤ 2 * (p * p * p) by omega)
      omega
    omega
  exact_mod_cast key

/-- **`b²·R2 = b²·(3/2)δ(u1−δ) ≤ 0`** (`u1 ≤ δ`, so `u1−δ ≤ 0`; the rest is `≥ 0`). -/
theorem b2R2_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (logN p hp) (logN p hp))
          (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide))
            (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))))
        zero := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  -- u1 − δ ≤ 0
  have hu1δ : Rle (Rsub (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) zero :=
    Rle_sub_zero (deltaLog_lower p hp)
  exact Rmul_nonpos_left (Rnonneg_Rmul_self _)
    (Rmul_nonpos_left (Rnonneg_ofQ (by decide) (by decide))
      (Rmul_nonpos_left hδnn hu1δ))

/-- **`b·R1 = b·δ²((3/2)u1 − δ) ≤ 3/(p(p+1))`** (drop `−δ`, `δ² ≤ 1/p²`, `b ≤ p`, `u1 = 1/(p+1)`). -/
theorem bR1_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logN p hp)
          (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
            (Rsub (Rmul (ofQ (⟨3, 2⟩ : Q) (by decide)) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
        (ofQ (⟨3, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hbnn : Rnonneg (logN p hp) := Rnonneg_logN p hp
  have hδ2nn : Rnonneg (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := Rnonneg_Rmul_self _
  have d_p2 : 0 < (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)).den := Qmul_den_pos hp hp
  have d_X : 0 < (mul (⟨3, 2⟩ : Q) (⟨1, p + 1⟩ : Q)).den := Qmul_den_pos (by decide) (Nat.succ_pos p)
  have d_big : 0 < (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (mul (⟨3, 2⟩ : Q) (⟨1, p + 1⟩ : Q))).den :=
    Qmul_den_pos d_p2 d_X
  have hXnn : Rnonneg (ofQ (mul (⟨3, 2⟩ : Q) (⟨1, p + 1⟩ : Q)) d_X) :=
    Rnonneg_ofQ _ (by show (0 : Int) ≤ 3 * 1; decide)
  -- drop −δ: ((3/2)u1 − δ) ≤ (3/2)u1
  refine Rle_trans (Rmul_le_Rmul_left hbnn (Rmul_le_Rmul_left hδ2nn
    (Rsub_le_self _ hδnn))) ?_
  -- (3/2)u1 ≈ ofQ⟨3,2(p+1)⟩
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _) (Rmul_congr (Req_refl _)
    (Rmul_ofQ_ofQ (a := (⟨3, 2⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) (by decide) (Nat.succ_pos p))))) ?_
  -- δ²·(ofQ⟨3,2(p+1)⟩) ≤ ofQ(p²·3·2(p+1))
  refine Rle_trans (Rmul_le_Rmul_left hbnn
    (Rle_trans (Rmul_le_Rmul_right hXnn (dsq_self_le p hp))
      (Rle_of_Req (Rmul_ofQ_ofQ (a := mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q))
        (b := mul (⟨3, 2⟩ : Q) (⟨1, p + 1⟩ : Q)) d_p2 d_X)))) ?_
  -- b·(ofQ⟨3,…⟩) ≤ ofQ⟨p,1⟩·(ofQ⟨3,…⟩) ≈ ofQ⟨3p,…⟩
  refine Rle_trans (Rmul_le_Rmul_right
    (Rnonneg_ofQ d_big (by show (0 : Int) ≤ 1 * (3 * 1); decide))
    (logN_le_self p hp)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨(p : Int), 1⟩ : Q))
    (b := mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (mul (⟨3, 2⟩ : Q) (⟨1, p + 1⟩ : Q))) Nat.one_pos d_big)) ?_
  refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
  show Qle (mul (⟨(p : Int), 1⟩ : Q)
      (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (mul (⟨3, 2⟩ : Q) (⟨1, p + 1⟩ : Q))))
    (⟨3, p * (p + 1)⟩ : Q)
  simp only [Qle, mul, Int.one_mul, Int.mul_one, Nat.one_mul, Nat.mul_one]
  have key : p * 3 * (p * (p + 1)) ≤ 3 * (p * p * (2 * (p + 1))) := by
    have e1 : ((p * 3 * (p * (p + 1)) : Nat) : Int) = ((3 * (p * p * (p + 1)) : Nat) : Int) := by
      push_cast; ring_uor
    have e2 : ((3 * (p * p * (2 * (p + 1))) : Nat) : Int) = ((6 * (p * p * (p + 1)) : Nat) : Int) := by
      push_cast; ring_uor
    have n1 : p * 3 * (p * (p + 1)) = 3 * (p * p * (p + 1)) := by exact_mod_cast e1
    have n2 : 3 * (p * p * (2 * (p + 1))) = 6 * (p * p * (p + 1)) := by exact_mod_cast e2
    omega
  exact_mod_cast key

/-- **`b³·C2 ≤ 7/(p(p+1))`** — the dominant term: `b³ = (ln p)³ ≤ 27p` (`logCube_le_self27`),
    `C2 ≤ 1/(2p(p+1)(2p+1))` (`C2_le`), so `b³·C2 ≤ 27p/(2p(p+1)(2p+1)) ≤ 7/(p(p+1))`. -/
theorem b3C2_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (Rmul (logN p hp) (logN p hp)) (logN p hp))
          (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
              (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
        (ofQ (⟨7, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
  have h27nn : Rnonneg (ofQ (⟨27 * (p : Int), 1⟩ : Q) Nat.one_pos) :=
    Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ 27 * (p : Int); omega)
  refine Rle_trans (Rmul_le_Rmul_right (C2_nonneg p hp) (logCube_le_self27 p hp)) ?_
  refine Rle_trans (Rmul_le_Rmul_left h27nn (C2_le p hp)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨27 * (p : Int), 1⟩ : Q))
    (b := (⟨1, 2 * p * (p + 1) * (2 * p + 1)⟩ : Q)) Nat.one_pos
    (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)) (by omega)))) ?_
  refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
  show Qle (mul (⟨27 * (p : Int), 1⟩ : Q) (⟨1, 2 * p * (p + 1) * (2 * p + 1)⟩ : Q))
    (⟨7, p * (p + 1)⟩ : Q)
  simp only [Qle, mul, Int.one_mul, Int.mul_one, Nat.one_mul, Nat.mul_one]
  have key : 27 * p * (p * (p + 1)) ≤ 7 * (2 * p * (p + 1) * (2 * p + 1)) := by
    have e1 : ((7 * (2 * p * (p + 1) * (2 * p + 1)) : Nat) : Int)
        = ((27 * p * (p * (p + 1)) + p * (p + 1) * (p + 14) : Nat) : Int) := by
      push_cast; ring_uor
    have n1 : 7 * (2 * p * (p + 1) * (2 * p + 1))
        = 27 * p * (p * (p + 1)) + p * (p + 1) * (p + 14) := by exact_mod_cast e1
    omega
  exact_mod_cast key

/-- **The per-step UPPER bound** `sStep3 p ≤ 11/(p(p+1))` — `sStep3 ≈ decompForm3 = b³C2 + b²R2 + bR1 + R0`
    (`sStep3_decomp`), bounded termwise (`7 + 0 + 3 + 1 = 11`, common denominator `p(p+1)`). -/
theorem sStep3_le (p : Nat) (hp : 1 ≤ p) :
    Rle (sStep3 p hp) (ofQ (⟨11, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
  have hD : 0 < p * (p + 1) := Nat.mul_pos hp (Nat.succ_pos p)
  refine Rle_trans (Rle_of_Req (sStep3_decomp p hp)) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add (b3C2_le p hp) (b2R2_le p hp))
    (bR1_le p hp)) (R0_le p hp)) ?_
  refine Rle_of_Req ?_
  -- ((⟨7⟩ + 0) + ⟨3⟩) + ⟨1⟩ ≈ ⟨11⟩
  refine Req_trans (Radd_congr (Radd_congr (Radd_zero _) (Req_refl _)) (Req_refl _)) ?_
  refine Req_trans (Radd_congr (Radd_ofQ_same 7 3 (p * (p + 1)) hD) (Req_refl _)) ?_
  exact Radd_ofQ_same 10 1 (p * (p + 1)) hD

-- ===========================================================================
-- (C5) Telescoping `Σ sStep3 ≤ 11/(N+1)` → `γ₃ ≤ hSeq3(N) + 11/(N+1)`, then a rational ceiling.
-- ===========================================================================

/-- **Telescoping tail (upper)**: `hSeq3(N+k) ≤ hSeq3(N) + (11/(N+1) − 11/(N+k+1))` (`N ≥ 1`). -/
theorem hSeq3_tele (N : Nat) (hN : 1 ≤ N) : ∀ k,
    Rle (hSeq3 (N + k))
        (Radd (hSeq3 N) (Rsub (ofQ (⟨11, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨11, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))) := by
  intro k
  induction k with
  | zero =>
    refine Rle_of_Req ?_
    exact Req_trans (Req_symm (Radd_zero (hSeq3 N)))
      (Radd_congr (Req_refl _) (Req_symm (Radd_neg (ofQ (⟨11, N + 1⟩ : Q) (Nat.succ_pos N)))))
  | succ k ih =>
    refine Rle_trans (Rle_of_Req (sub_add_cancel_real (hSeq3 (N + k + 1)) (hSeq3 (N + k)))) ?_
    refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _) (hSeq3_step_eq (N + k)))) ?_
    refine Rle_trans (Radd_le_add ih (sStep3_le (N + k + 1) (Nat.succ_pos (N + k)))) ?_
    refine Rle_of_Req (Req_trans (Radd_assoc (hSeq3 N) _ _) ?_)
    refine Radd_congr (Req_refl (hSeq3 N)) ?_
    apply Req_of_seq_Qeq; intro _
    show Qeq (add (add (⟨11, N + 1⟩ : Q) (neg (⟨11, N + k + 1⟩ : Q)))
        (⟨11, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q))
      (add (⟨11, N + 1⟩ : Q) (neg (⟨11, N + (k + 1) + 1⟩ : Q)))
    simp only [Qeq, add, neg, mul]
    push_cast
    ring_uor

/-- **`hSeq3(N+k) ≤ hSeq3(N) + 11/(N+1)`** (uniform in `k`, `N ≥ 1`) — drop the nonneg `−11/(N+k+1)`. -/
theorem hSeq3_upper_const (N : Nat) (hN : 1 ≤ N) (k : Nat) :
    Rle (hSeq3 (N + k)) (Radd (hSeq3 N) (ofQ (⟨11, N + 1⟩ : Q) (Nat.succ_pos N))) := by
  refine Rle_trans (hSeq3_tele N hN k) (Radd_le_add (Rle_refl _) ?_)
  exact Rsub_le_self _ (Rnonneg_ofQ (Nat.succ_pos (N + k)) (by show (0 : Int) ≤ 11; decide))

/-- **`γ₃ ≤ g3SeqDyadic j + 1/(j+1)`** — the dyadic Cauchy tail `g3_pair_le` carried to the limit. -/
theorem Rgamma3_le_dyadic (j : Nat) :
    Rle Rgamma3 (Radd (g3SeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have htend : Rle (Rsub Rgamma3 (g3SeqDyadic (j + k))) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (RTendsTo_to_Rle_lower (Rlim_tendsTo g3SeqDyadic g3SeqDyadic_RReg) (j + k)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos (j + k)) (Nat.succ_pos k)
      (by show (2 : Int) * ((k : Int) + 1) ≤ 2 * ((j : Int) + (k : Int) + 1); omega)
  have hanchor : Rle (g3SeqDyadic (j + k))
      (Radd (g3SeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) :=
    Rle_add_of_Rsub_le (g3_pair_le (Nat.le_add_right j k))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split Rgamma3 (g3SeqDyadic (j + k))
    (Radd (g3SeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)))))) ?_
  exact Rle_trans (Radd_le_add htend (Rle_sub_zero hanchor)) (Rle_of_Req (Radd_zero _))

/-- **`g3Seq M = hSeq3 M + ½·(ln(M+1))³/(M+1)`** — the accelerator's correction term, made explicit. -/
theorem g3Seq_eq_hSeq3_add (M : Nat) :
    Req (g3Seq M) (Radd (hSeq3 M)
        (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (M + 1) (Nat.succ_pos M)))) := by
  unfold hSeq3
  refine Req_symm (Req_trans (Radd_assoc (g3Seq M) (Rneg _) _) ?_)
  refine Req_trans (Radd_congr (Req_refl _) (Req_trans (Radd_comm (Rneg _) _) (Radd_neg _))) ?_
  exact Radd_zero (g3Seq M)

/-- **Block cube cap at an arbitrary argument** `logCube K ≤ (a+2)³` for `2 ≤ K ≤ 2^{a+2}`
    (`logCube_le_block` with the `j+2` form discharged by `Nat.sub_add_cancel`). -/
theorem logCube_le_cap (K a : Nat) (hK : 1 ≤ K) (hK2 : 2 ≤ K) (h : K ≤ 2 ^ (a + 2)) :
    Rle (logCube K hK)
      (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2) * ((a : Int) + 2), 1⟩ : Q) Nat.one_pos) := by
  obtain ⟨m, rfl⟩ : ∃ m, K = m + 2 := ⟨K - 2, by omega⟩
  exact logCube_le_block a m h

/-- **The correction term `½·(ln(M+1))³/(M+1)` at `M = 2^{2j+14}` is `≤ (2j+15)³/(2(M+1))`**
    (`logCube_le_cap` at `a = 2j+13`, `M+1 ≤ 2^{2j+15}`). -/
theorem corr_le (j : Nat) :
    Rle (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
          (lnCubeOver (2 ^ (2 * j + 14) + 1) (Nat.succ_pos _)))
        (ofQ (⟨(2 * (j : Int) + 15) * (2 * (j : Int) + 15) * (2 * (j : Int) + 15),
            2 * (2 ^ (2 * j + 14) + 1)⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.succ_pos _))) := by
  have hpow : 1 ≤ 2 ^ (2 * j + 14) := Nat.pos_pow_of_pos _ (by decide)
  have hbnd : 2 ^ (2 * j + 14) + 1 ≤ 2 ^ ((2 * j + 13) + 2) := by
    have he : (2 * j + 13) + 2 = (2 * j + 14) + 1 := by omega
    have hps : 2 ^ ((2 * j + 14) + 1) = 2 * 2 ^ (2 * j + 14) := by rw [Nat.pow_succ]; omega
    rw [he, hps]; omega
  have hcap := logCube_le_cap (2 ^ (2 * j + 14) + 1) (2 * j + 13) (Nat.succ_pos _) (by omega) hbnd
  -- ½·(logCube·u) ≤ ½·(ofQ(2j+15)³·u) ≈ ofQ((2j+15)³, 2(M+1))
  unfold lnCubeOver
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos _) (by show (0 : Int) ≤ 1; decide)) hcap)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Rmul_ofQ_ofQ (a := (⟨((2 * (j : Int) + 13) + 2) * ((2 * (j : Int) + 13) + 2)
        * ((2 * (j : Int) + 13) + 2), 1⟩ : Q))
      (b := (⟨1, 2 ^ (2 * j + 14) + 1⟩ : Q)) Nat.one_pos (Nat.succ_pos _)))) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) (Qmul_den_pos Nat.one_pos (Nat.succ_pos _)))
    (ofQ_congr _ _ ?_))
  show Qeq (mul (⟨1, 2⟩ : Q) (mul (⟨((2 * (j : Int) + 13) + 2) * ((2 * (j : Int) + 13) + 2)
        * ((2 * (j : Int) + 13) + 2), 1⟩ : Q) (⟨1, 2 ^ (2 * j + 14) + 1⟩ : Q)))
    (⟨(2 * (j : Int) + 15) * (2 * (j : Int) + 15) * (2 * (j : Int) + 15),
        2 * (2 ^ (2 * j + 14) + 1)⟩ : Q)
  simp only [Qeq, mul]
  push_cast
  ring_uor

/-- **`γ₃ ≤ hSeq3(N) + 11/(N+1) + (2j+15)³/(2(2^{2j+14}+1)) + 1/(j+1)`** — the dyadic limit bound
    (`Rgamma3_le_dyadic`) with the correction extracted (`g3Seq_eq_hSeq3_add`), the dyadic anchor
    telescoped down to `N` (`hSeq3_upper_const`), and the correction capped (`corr_le`). -/
theorem Rgamma3_le_hSeq3 (N j : Nat) (hN : 1 ≤ N) (hNj : N ≤ 2 ^ (2 * j + 14)) :
    Rle Rgamma3
      (Radd (Radd (Radd (hSeq3 N) (ofQ (⟨11, N + 1⟩ : Q) (Nat.succ_pos N)))
          (ofQ (⟨(2 * (j : Int) + 15) * (2 * (j : Int) + 15) * (2 * (j : Int) + 15),
              2 * (2 ^ (2 * j + 14) + 1)⟩ : Q) (Nat.mul_pos (by decide) (Nat.succ_pos _))))
        (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  refine Rle_trans (Rgamma3_le_dyadic j) (Radd_le_add ?_ (Rle_refl _))
  refine Rle_trans (Rle_of_Req (g3Seq_eq_hSeq3_add (2 ^ (2 * j + 14)))) ?_
  refine Radd_le_add ?_ (corr_le j)
  obtain ⟨k, hk⟩ := Nat.le.dest hNj
  rw [← hk]
  exact hSeq3_upper_const N hN k

/-- The **rational upper bound on `hSeq3 N`** (depth `T`, denominator `D`) as a single `Q`. -/
def gBound3 (T D N : Nat) : Q :=
  add (add (lnCubeSumUp T D (N + 1))
      (neg (mul (⟨1, 4⟩ : Q) (mul (mul (mul (logLowBound T D N) (logLowBound T D N))
        (logLowBound T D N)) (logLowBound T D N)))))
    (neg (mul (⟨1, 2⟩ : Q) (mul (mul (mul (logLowBound T D N) (logLowBound T D N))
      (logLowBound T D N)) (⟨1, N + 1⟩ : Q))))

theorem gBound3_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound3 T D N).den :=
  add_den_pos (add_den_pos (lnCubeSumUp_den_pos T D hD (N + 1))
      (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD N)
        (logLowBound_den_pos T D hD N)) (logLowBound_den_pos T D hD N)) (logLowBound_den_pos T D hD N))))
    (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD N)
      (logLowBound_den_pos T D hD N)) (logLowBound_den_pos T D hD N)) (Nat.succ_pos N)))

set_option maxRecDepth 40000 in
/-- **`hSeq3 N ≤ ofQ(gBound3 T D N)`** (`T ≤ 21`) — the rational upper bound (`lnCubeSum_le`,
    `logQuartic_ge`, `lnCubeOver_ge`), collapsing the all-`ofQ` Rsub-tower to the single `gBound3`. -/
theorem hSeq3_le_gBound3 (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (hSeq3 N) (ofQ (gBound3 T D N) (gBound3_den_pos T D N hD)) := by
  have LLd := logLowBound_den_pos T D hD N
  -- ¼·(logLowBound)⁴ ≤ ¼·(ln(N+1))⁴
  have hquart : Rle (ofQ (mul (⟨1, 4⟩ : Q) (mul (mul (mul (logLowBound T D N) (logLowBound T D N))
          (logLowBound T D N)) (logLowBound T D N)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LLd LLd) LLd) LLd)))
      (Rmul (ofQ (⟨1, 4⟩ : Q) (by decide)) (logQuartic (N + 1) (Nat.succ_pos N))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide)
        (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LLd LLd) LLd) LLd))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (logQuartic_ge T D N hD hT))
  -- ½·(logLowBound)³/(N+1) ≤ ½·(ln(N+1))³/(N+1)
  have hcube : Rle (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (mul (logLowBound T D N) (logLowBound T D N))
          (logLowBound T D N)) (⟨1, N + 1⟩ : Q)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LLd LLd) LLd) (Nat.succ_pos N))))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnCubeOver (N + 1) (Nat.succ_pos N))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide)
        (Qmul_den_pos (Qmul_den_pos (Qmul_den_pos LLd LLd) LLd) (Nat.succ_pos N)))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (lnCubeOver_ge T D N hD hT))
  unfold hSeq3 g3Seq
  refine Rle_trans (Rsub_le_sub (Rsub_le_sub (lnCubeSum_le T D hD (N + 1)) hquart) hcube) ?_
  exact Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))

-- ===========================================================================
-- (C6) **THE BRACKET: `γ₃ ≤ 1/8`** — `γ₃ ≤ hSeq3(200) + 11/201 + corr + 1/51`
-- (`Rgamma3_le_hSeq3` at `N=200, j=50`), `hSeq3(200) ≤ gBound3 3 10⁸ 200` (`hSeq3_le_gBound3`),
-- `corr ≤ 1/51`, and one big-integer `decide`.
-- ===========================================================================

/-- **`corr ≤ 1/51` at `j = 50`** — `(2·50+15)³·51 ≤ 2(2^{114}+1)` (poly ≤ exp, one `decide`). -/
theorem corr_weaken50 :
    Rle (ofQ (⟨(2 * (50 : Int) + 15) * (2 * (50 : Int) + 15) * (2 * (50 : Int) + 15),
          2 * (2 ^ (2 * 50 + 14) + 1)⟩ : Q) (Nat.mul_pos (by decide) (Nat.succ_pos _)))
        (ofQ (⟨1, 50 + 1⟩ : Q) (Nat.succ_pos 50)) :=
  Rle_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos _)) (Nat.succ_pos 50) (by decide)

set_option maxRecDepth 40000 in
/-- The numeric heart: `gBound3 3 10⁸ 200 + 11/201 + 1/51 + 1/51 ≤ 1/8` — one big-integer `decide`. -/
theorem gamma3_decide :
    Qle (add (add (add (gBound3 3 100000000 200) (⟨11, 200 + 1⟩ : Q)) (⟨1, 50 + 1⟩ : Q))
        (⟨1, 50 + 1⟩ : Q))
      (⟨1, 8⟩ : Q) := by decide

set_option maxRecDepth 40000 in
/-- **`γ₃ ≤ 1/8`** — the certified loose UPPER bracket on the third Stieltjes constant, the only
    `γ₃` input to `Pos Rlambda4` (`−(2/3)γ₃` enters with a tiny coefficient). -/
theorem Rgamma3_le : Rle Rgamma3 (ofQ (⟨1, 8⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma3_le_hSeq3 200 50 (by decide) (by decide)) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add
    (hSeq3_le_gBound3 3 100000000 200 (by decide) (by decide)) (Rle_refl _)) corr_weaken50)
    (Rle_refl _)) ?_
  refine Rle_trans (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (add_den_pos (gBound3_den_pos 3 100000000 200 (by decide))
      (Nat.succ_pos 200)) (Nat.succ_pos 50)) (Nat.succ_pos 50)) (by decide) gamma3_decide

end UOR.Bridge.F1Square.Analysis
