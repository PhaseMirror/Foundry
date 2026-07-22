/-
F1 square — v0.22.0 crux frontier: **the two-sided bracket on the first Stieltjes constant `γ₁`** via
the DISCRETE Euler–Maclaurin acceleration (NO constructive integration), the dominant constant brick
for `Pos Rlambda3` (the `n = 3` coupling coefficient).

The defining sequence `gSeq(N) = Σ_{k≤N+1}(ln k)/k − ½(ln(N+1))²` converges to `γ₁` but OVERSHOOTS by
the leading Euler–Maclaurin term `+½·(ln(N+1))/(N+1)` (a *convergence* limit, not a bound-depth limit —
so the existing one-sided `γ₁ ≤ −0.055` cannot be tightened by deeper artanh). Subtracting that
trapezoidal anchor gives the **accelerated sequence**

    hSeq1(j) = gSeq(j) − ½·(ln(j+1))/(j+1),

whose per-step increment is the trapezoidal residual `sStep1(p) = ½(f(p)+f(p+1)) − ∫_p^{p+1} f`,
`f(x) = (ln x)/x`. Because `∫(ln x)/x = ½(ln x)²`, the residual is the SQUARE-difference analogue of
`GammaTwoBracket`'s cube residual (much simpler): `sStep1(p) = ½·WStep(p)` with
`WStep(p) = (f(p)+f(p+1)) − ((ln(p+1))² − (ln p)²)`, and the clean algebraic lower bound

    WStep(p) ≥ −(ln(p+1) − ln p)² ≥ −1/p²       (so  sStep1(p) ≥ −1/(2p²)),

via the trapezoid-≥-integral cancellation `2δ ≤ 1/p + 1/(p+1)` (`deltaLog_le_mid`, `δ = ln(p+1)−ln p`).
Telescoping the `1/(2p²)` tail (the existing `Usum` machinery) gives `γ₁ ≥ hSeq1(N) − 1/(2N)`, a
TIGHT lower bound (`hSeq1(N) ≈ γ₁ + O(1/N²)`), the genuinely missing `λ₃` input.

THIS FILE — part (A): the accelerated sequence, its increment identity, and the per-step lower bound.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by
`scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.GammaOne
import Core.F1.Analysis.GammaTwoBracket

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- ===========================================================================
-- (A0) Small reusable algebraic identities (the square-difference analogues).
-- ===========================================================================

/-- **`(a+b) − (a−b) ≈ 2b`** — the `b`-companion of `addsub_linear`. -/
theorem addsub_linear_b (a b : Real) :
    Req (Rsub (Radd a b) (Rsub a b)) (Radd b b) := by
  refine Req_trans (Radd_congr (Req_refl (Radd a b))
    (Req_trans (Rneg_Rsub a b) (Radd_comm b (Rneg a)))) ?_
  refine Req_trans (Radd_swap a b (Rneg a) b) ?_
  exact Req_trans (Radd_congr (Radd_neg a) (Req_refl (Radd b b)))
    (Req_trans (Radd_comm zero (Radd b b)) (Radd_zero (Radd b b)))

/-- **`(a²−b²) − (a−b)² ≈ b·(2(a−b))`** ( = `2b·δ`) — the square-difference identity, `b`-grouped so the
    `2δ` factor is bounded by `1/p+1/(p+1)`. -/
theorem sq_diff_identity_b (a b : Real) :
    Req (Rsub (Rsub (Rmul a a) (Rmul b b)) (Rmul (Rsub a b) (Rsub a b)))
        (Rmul b (Radd (Rsub a b) (Rsub a b))) := by
  refine Req_trans (Rsub_congr (Req_symm (Rmul_sub_add_self a b)) (Req_refl _)) ?_
  refine Req_trans (Req_symm (Rmul_sub_distrib (Rsub a b) (Radd a b) (Rsub a b))) ?_
  refine Req_trans (Rmul_congr (Req_refl (Rsub a b)) (addsub_linear_b a b)) ?_
  -- δ·(2b) ≈ b·(2δ)
  refine Req_trans (Rmul_distrib (Rsub a b) b b) ?_
  refine Req_trans (Radd_congr (Rmul_comm (Rsub a b) b) (Rmul_comm (Rsub a b) b)) ?_
  exact Req_symm (Rmul_distrib b (Rsub a b) (Rsub a b))

/-- **`(X+Y) − (X+Z) ≈ Y − Z`** — left-term cancellation. -/
theorem add_sub_add_cancel_left (X Y Z : Real) :
    Req (Rsub (Radd X Y) (Radd X Z)) (Rsub Y Z) := by
  refine Req_trans (Radd_congr (Req_refl (Radd X Y)) (Rneg_Radd X Z)) ?_
  refine Req_trans (Radd_swap X Y (Rneg X) (Rneg Z)) ?_
  exact Req_trans (Radd_congr (Radd_neg X) (Req_refl (Rsub Y Z)))
    (Req_trans (Radd_comm zero (Rsub Y Z)) (Radd_zero (Rsub Y Z)))

-- ===========================================================================
-- (A1) The accelerated sequence and its increment.
-- ===========================================================================

/-- The Euler–Maclaurin **accelerated sequence** `hSeq1(j) = gSeq(j) − ½·(ln(j+1))/(j+1)` — same limit
    `γ₁` as `gSeq`, but its increment is the summable trapezoidal residual. -/
def hSeq1 (j : Nat) : Real :=
  Rsub (gSeq j) (Rhalf (lnOver (j + 1) (Nat.succ_pos j)))

/-- The **(doubled) trapezoidal residual** `WStep(p) = (f(p+1)+f(p)) − ((ln(p+1))² − (ln p)²)`,
    `f(x) = (ln x)/x`. -/
def WStep (p : Nat) (hp : 1 ≤ p) : Real :=
  Rsub (Radd (lnOver (p + 1) (Nat.succ_pos p)) (lnOver p hp))
       (Rsub (Rmul (logN (p + 1) (Nat.succ_pos p)) (logN (p + 1) (Nat.succ_pos p)))
             (Rmul (logN p hp) (logN p hp)))

/-- The **per-step trapezoidal residual** `s_p = ½·WStep(p)` — the increment of `hSeq1`. -/
def sStep1 (p : Nat) (hp : 1 ≤ p) : Real := Rhalf (WStep p hp)

/-- The regroup identity behind `hSeq1_step_eq`: `(L2 − (½A−½B)) − (½L2 − ½L1) ≈ ½((L2+L1) − (A−B))`. -/
theorem step_regroup (L2 L1 A B : Real) :
    Req (Rsub (Rsub L2 (Rsub (Rhalf A) (Rhalf B))) (Rsub (Rhalf L2) (Rhalf L1)))
        (Rhalf (Rsub (Radd L2 L1) (Rsub A B))) := by
  have hRHS : Req (Rhalf (Rsub (Radd L2 L1) (Rsub A B)))
      (Rsub (Radd (Rhalf L2) (Rhalf L1)) (Rsub (Rhalf A) (Rhalf B))) :=
    Req_trans (Rhalf_Rsub (Radd L2 L1) (Rsub A B))
      (Rsub_congr (Rhalf_Radd L2 L1) (Rhalf_Rsub A B))
  refine Req_trans ?_ (Req_symm hRHS)
  refine Req_trans (Rsub_congr (Rsub_congr (Req_symm (Rhalf_double L2)) (Req_refl _)) (Req_refl _)) ?_
  exact resid_regroup (Rhalf L2) (Rhalf L1) (Rsub (Rhalf A) (Rhalf B))

/-- **`hSeq1(j+1) − hSeq1(j) ≈ s_{j+1}`** — the increment of the accelerated sequence is the
    trapezoidal residual (`gSeq_step_eq` for the `gSeq` part, `step_regroup` for the correction). -/
theorem hSeq1_step_eq (j : Nat) :
    Req (Rsub (hSeq1 (j + 1)) (hSeq1 j)) (sStep1 (j + 1) (Nat.succ_pos j)) := by
  refine Req_trans (Rsub_sub_sub (gSeq (j + 1)) (Rhalf (lnOver (j + 2) (Nat.succ_pos (j + 1))))
    (gSeq j) (Rhalf (lnOver (j + 1) (Nat.succ_pos j)))) ?_
  refine Req_trans (Rsub_congr (gSeq_step_eq j) (Req_refl _)) ?_
  exact step_regroup (lnOver (j + 2) (Nat.succ_pos (j + 1))) (lnOver (j + 1) (Nat.succ_pos j))
    (Rmul (logN (j + 2) (Nat.succ_pos (j + 1))) (logN (j + 2) (Nat.succ_pos (j + 1))))
    (Rmul (logN (j + 1) (Nat.succ_pos j)) (logN (j + 1) (Nat.succ_pos j)))

-- ===========================================================================
-- (A2) The per-step lower bound `s_{j+1} ≥ −1/(2(j+1)²)` (the clean trapezoidal cancellation).
-- ===========================================================================

/-- **Abstract trapezoid cancellation**: `(a·u1 + b·u0) − (a²−b²) ≥ −(a−b)²` whenever `b ≥ 0`,
    `a−b ≥ 0`, `u1 ≥ 0`, and `2(a−b) ≤ u0+u1`.  `LHS + δ² ≈ (a·u1+b·u0) − b·2δ ≥ … = δ·u1 ≥ 0`. -/
theorem WStep_ge_negDsq_gen (a b u0 u1 : Real) (hbnn : Rnonneg b)
    (hδnn : Rnonneg (Rsub a b)) (hu1nn : Rnonneg u1)
    (h2δ : Rle (Radd (Rsub a b) (Rsub a b)) (Radd u0 u1)) :
    Rle (Rneg (Rmul (Rsub a b) (Rsub a b)))
        (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rsub (Rmul a a) (Rmul b b))) := by
  -- (1) Radd LHS' δ² ≈ Rsub S (b·2δ), where S = a·u1 + b·u0, δ = a−b
  have hWid : Req (Radd (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rsub (Rmul a a) (Rmul b b)))
        (Rmul (Rsub a b) (Rsub a b)))
      (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd (Rsub a b) (Rsub a b)))) := by
    have hstep : Req (Radd (Radd (Radd (Rmul a u1) (Rmul b u0))
          (Rneg (Rsub (Rmul a a) (Rmul b b)))) (Rmul (Rsub a b) (Rsub a b)))
        (Radd (Radd (Rmul a u1) (Rmul b u0))
          (Rneg (Rsub (Rsub (Rmul a a) (Rmul b b)) (Rmul (Rsub a b) (Rsub a b))))) := by
      refine Req_trans (Radd_assoc (Radd (Rmul a u1) (Rmul b u0))
        (Rneg (Rsub (Rmul a a) (Rmul b b))) (Rmul (Rsub a b) (Rsub a b))) ?_
      refine Radd_congr (Req_refl _) ?_
      refine Req_trans (Radd_comm (Rneg (Rsub (Rmul a a) (Rmul b b)))
        (Rmul (Rsub a b) (Rsub a b))) ?_
      exact Req_symm (Rneg_Rsub (Rsub (Rmul a a) (Rmul b b)) (Rmul (Rsub a b) (Rsub a b)))
    refine Req_trans hstep ?_
    exact Rsub_congr (Req_refl _) (sq_diff_identity_b a b)
  have h2bd : Rle (Rmul b (Radd (Rsub a b) (Rsub a b))) (Rmul b (Radd u0 u1)) :=
    Rmul_le_Rmul_left hbnn h2δ
  -- (3) Rsub S (b·(u0+u1)) ≈ δ·u1
  have hScancel : Req (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd u0 u1)))
      (Rmul (Rsub a b) u1) := by
    refine Req_trans (Rsub_congr (Req_refl _) (Rmul_distrib b u0 u1)) ?_
    refine Req_trans (Rsub_congr (Radd_comm (Rmul a u1) (Rmul b u0)) (Req_refl _)) ?_
    refine Req_trans (add_sub_add_cancel_left (Rmul b u0) (Rmul a u1) (Rmul b u1)) ?_
    exact Req_symm (Rmul_sub_distrib_right a b u1)
  have hchain : Rle zero (Radd (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rsub (Rmul a a) (Rmul b b)))
      (Rmul (Rsub a b) (Rsub a b))) :=
    Rle_trans (Rle_zero_of_Rnonneg (Rnonneg_Rmul hδnn hu1nn))
      (Rle_trans (Rle_of_Req (Req_symm hScancel))
        (Rle_trans (Rsub_le_sub (Rle_refl _) h2bd)
          (Rle_of_Req (Req_symm hWid))))
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_of_Rle_zero hchain))
  exact Radd_congr (Req_refl _) (Req_symm (Rneg_neg (Rmul (Rsub a b) (Rsub a b))))

/-- **`2δ ≤ 1/p + 1/(p+1)`** (`δ = ln(p+1) − ln p`) — the trapezoid-≥-integral cancellation,
    from `deltaLog_le_mid` (`δ ≤ ½(1/p+1/(p+1))`). -/
theorem two_delta_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Radd (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
        (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))) := by
  have hmid := deltaLog_le_mid p hp
  have hMd : 0 < (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))).den :=
    Qmul_den_pos (by decide)
      (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p))
  refine Rle_trans (Radd_le_add hmid hmid) (Rle_of_Req ?_)
  refine Req_trans (Radd_ofQ_ofQ hMd hMd) ?_
  refine Req_trans (ofQ_congr (add_den_pos hMd hMd)
    (add_den_pos (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)) ?_) ?_
  · show Qeq (add (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q)))
        (mul (⟨1, 2⟩ : Q) (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))))
      (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q))
    simp only [Qeq, add, mul]; push_cast; ring_uor
  · exact Req_symm (Radd_ofQ_ofQ (a := (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p))

/-- **`WStep(p) ≥ −(ln(p+1) − ln p)²`** — `WStep_ge_negDsq_gen` at the log/reciprocal atoms. -/
theorem WStep_ge_negDsq (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                    (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
        (WStep p hp) :=
  WStep_ge_negDsq_gen (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
    (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))
    (Rnonneg_logN p hp) (Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p)))
    (Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)) (two_delta_le p hp)

/-- **`WStep(p) ≥ −1/p²`** — the numeric per-step lower bound (`δ² ≤ 1/p²`, `dsq_self_le`). -/
theorem WStep_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (Qmul_den_pos hp hp))) (WStep p hp) :=
  Rle_trans (Rle_Rneg (dsq_self_le p hp)) (WStep_ge_negDsq p hp)

/-- **`s_{j+1} ≥ −1/(2(j+1)²)`** — the per-step lower bound on the accelerated increment. -/
theorem sStep1_ge (p : Nat) (hp : 1 ≤ p) :
    Rle (Rneg (ofQ (⟨1, 2 * p * p⟩ : Q) (Nat.mul_pos (Nat.mul_pos (by decide) hp) hp)))
        (sStep1 p hp) := by
  have hppd : 0 < (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)).den := Qmul_den_pos hp hp
  refine Rle_trans (Rle_of_Req ?_) (Rhalf_le_Rhalf (WStep_ge p hp))
  -- −1/(2p²) ≈ ½·(−1/p²)
  refine Req_trans ?_ (Req_symm (Req_trans
    (Rhalf_Rneg (ofQ (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) hppd))
    (Rneg_congr (Rhalf_ofQ (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) hppd))))
  refine Rneg_congr (ofQ_congr (Nat.mul_pos (Nat.mul_pos (by decide) hp) hp)
    (Qmul_den_pos (by decide) hppd) ?_)
  show Qeq (⟨1, 2 * p * p⟩ : Q) (mul (⟨1, 2⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)))
  simp only [Qeq, mul]; push_cast; ring_uor

-- ===========================================================================
-- (A3) Telescoping the `1/(2p²)` tail (the `Usum` machinery) → `γ₁ ≥ hSeq1(N) − 1/(2N)`.
-- ===========================================================================

/-- **Per-step accelerated lower bound** `hSeq1(j+1) − hSeq1 j ≥ −1/(2(j+1)²)`. -/
theorem hSeq1_step_ge (j : Nat) :
    Rle (Rneg (ofQ (⟨1, 2 * (j + 1) * (j + 1)⟩ : Q)
          (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos j))))
        (Rsub (hSeq1 (j + 1)) (hSeq1 j)) :=
  Rle_trans (sStep1_ge (j + 1) (Nat.succ_pos j)) (Rle_of_Req (Req_symm (hSeq1_step_eq j)))

/-- **Lower gap bound, U-form** (`d`-induction): `hSeq1(N+d) − hSeq1 N ≥ −(Usum(N+d) − Usum N)`.
    Mirrors `gSeq_diff_ge_block` on the `Usum` (`1/(2p²)`) telescoping. -/
theorem hSeq1_diff_ge_U (N : Nat) : ∀ (d : Nat),
    Rle (Rneg (ofQ (Qsub (Usum (N + d)) (Usum N))
          (Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N))))
        (Rsub (hSeq1 (N + d)) (hSeq1 N)) := by
  intro d
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans ?_ (Req_symm (Radd_neg (hSeq1 N)))
      apply Req_of_seq_Qeq; intro n
      simp only [Rneg, ofQ, zero, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      have hstepd : 0 < (⟨1, 2 * ((N + d) + 1) * ((N + d) + 1)⟩ : Q).den :=
        Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos (N + d))) (Nat.succ_pos (N + d))
      have hgapd : 0 < (Qsub (Usum (N + d)) (Usum N)).den :=
        Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N)
      have heq : Req (Rneg (ofQ (Qsub (Usum (N + d + 1)) (Usum N))
            (Qsub_den_pos (Usum_den_pos (N + d + 1)) (Usum_den_pos N))))
          (Radd (Rneg (ofQ (⟨1, 2 * ((N + d) + 1) * ((N + d) + 1)⟩ : Q) hstepd))
                (Rneg (ofQ (Qsub (Usum (N + d)) (Usum N)) hgapd))) :=
        Req_trans (Rneg_congr (Req_trans
          (ofQ_congr _ _ (Qeq_symm (Qadd_Qsub_comm _ (Usum (N + d)) (Usum N))))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd)))) (Rneg_Radd _ _)
      exact Rle_trans (Rle_of_Req heq)
        (Rle_trans (Radd_le_add (hSeq1_step_ge (N + d)) ih)
          (Rle_of_Req (Rsub_split (hSeq1 (N + d + 1)) (hSeq1 (N + d)) (hSeq1 N))))

/-- **The lower gap bound** `hSeq1(N+d) − hSeq1 N ≥ −1/(2N)` (for `N ≥ 1`). -/
theorem hSeq1_diff_ge (N : Nat) (hN : 1 ≤ N) (d : Nat) :
    Rle (Rneg (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN)))
        (Rsub (hSeq1 (N + d)) (hSeq1 N)) := by
  refine Rle_trans (Rle_Rneg ?_) (hSeq1_diff_ge_U N d)
  have hmid : 0 < (Qsub (⟨1, 2 * N⟩ : Q) (⟨1, 2 * (N + d)⟩ : Q)).den :=
    Qsub_den_pos (Nat.mul_pos (by decide) hN) (Nat.mul_pos (by decide) (by omega))
  refine Rle_trans (Rle_ofQ_ofQ (Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N)) hmid
    (Usum_tail_le N hN d)) ?_
  exact Rle_ofQ_ofQ hmid (Nat.mul_pos (by decide) hN) (Qsub_unit_le (2 * N) (2 * (N + d)))

/-- **`hSeq1(N+d) ≥ hSeq1 N − 1/(2N)`** (uniform in `d`, `N ≥ 1`). -/
theorem hSeq1_lower_const (N : Nat) (hN : 1 ≤ N) (d : Nat) :
    Rle (Rsub (hSeq1 N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) (hSeq1 (N + d)) := by
  refine Rle_trans (Radd_le_add (Rle_refl (hSeq1 N)) (hSeq1_diff_ge N hN d)) (Rle_of_Req ?_)
  exact Req_symm (sub_add_cancel_real (hSeq1 (N + d)) (hSeq1 N))

/-- **`hSeq1 M ≤ gSeq M`** — the correction `½·(ln(M+1))/(M+1)` is `≥ 0`. -/
theorem hSeq1_le_gSeq (M : Nat) : Rle (hSeq1 M) (gSeq M) := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr (Req_symm (Rsub_sub_self (gSeq M)
    (Rhalf (lnOver (M + 1) (Nat.succ_pos M))))) ?_)
  exact Rhalf_nonneg (lnOver_nonneg (M + 1) (Nat.succ_pos M))

/-- **`γ₁ ≥ hSeq1 N − 1/(2N)`** for `N ∈ [1, 256]` — each reindexed `gSeqDyadic k = gSeq(2^{2k+8})`
    (`2^{2k+8} ≥ 256 ≥ N`) is `≥ hSeq1(2^{2k+8}) ≥ hSeq1 N − 1/(2N)`, so the limit `γ₁` is too. -/
theorem Rgamma1_ge_hSeq1 {N : Nat} (hN : 1 ≤ N) (hN256 : N ≤ 256) :
    Rle (Rsub (hSeq1 N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) Rgamma1 := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have hN2k : N ≤ 2 ^ (2 * k + 8) := by
    have h8 : (2 : Nat) ^ 8 ≤ 2 ^ (2 * k + 8) := Nat.pow_le_pow_right (by omega) (by omega)
    have h256 : (256 : Nat) = 2 ^ 8 := by decide
    omega
  have htend : Rle (Rsub (gSeqDyadic k) Rgamma1) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) :=
    RTendsTo_to_Rle (Rlim_tendsTo gSeqDyadic gSeqDyadic_RReg) k
  have hanchor : Rle (Rsub (hSeq1 N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN)))
      (gSeqDyadic k) := by
    obtain ⟨d, hd⟩ := Nat.le.dest hN2k
    have h1 : Rle (Rsub (hSeq1 N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN)))
        (hSeq1 (N + d)) := hSeq1_lower_const N hN d
    rw [hd] at h1
    exact Rle_trans h1 (hSeq1_le_gSeq (2 ^ (2 * k + 8)))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split
    (Rsub (hSeq1 N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) (gSeqDyadic k) Rgamma1))) ?_
  refine Rle_trans (Radd_le_add
    (Rsub_le_of_le_add (Rle_trans hanchor (Rle_of_Req
      (Req_symm (Req_trans (Radd_comm zero (gSeqDyadic k)) (Radd_zero (gSeqDyadic k)))))))
    htend) ?_
  exact Rle_of_Req (Req_trans (Radd_comm zero _) (Radd_zero _))

-- ===========================================================================
-- (A4) **THE BRACKET: `γ₁ ≥ −0.0754`** — the new tight lower bound. `γ₁ ≥ hSeq1(200) − 1/400`, with
-- `hSeq1(200)` bounded below by the single rational `gBound1lo 4 10⁸ 200` (the lower `lnSum` bound minus
-- the upper `½log²` and `½log/(N+1)` bounds), then the residual `1/400` and one `decide`.
-- ===========================================================================

/-- `lnSumLo T D k` is a rational *lower* bound for `lnSum k = Σ_{i=1}^k (log i)/i`, at fixed
    denominator `D` (each new term `(log(k+1))/(k+1) ≥ logLowBound k · 1/(k+1)`, round down). -/
def lnSumLo (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (k + 1) => qRoundDown (add (lnSumLo T D k) (mul (logLowBound T D k) ⟨1, k + 1⟩)) D

theorem lnSumLo_den_pos (T D : Nat) (hD : 0 < D) : ∀ N, 0 < (lnSumLo T D N).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`ofQ(lnSumLo T D k) ≤ lnSum k`** — the partial-sum `Σ (log i)/i` bounded BELOW term-by-term via
    `logN_ge_logLowBound` (depth `T ≤ 21`), accumulated at fixed denominator `D` (round down). -/
theorem lnSum_ge_lnSumLo (T D : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    ∀ k, Rle (ofQ (lnSumLo T D k) (lnSumLo_den_pos T D hD k)) (lnSum k) := by
  intro k
  induction k with
  | zero =>
    have h0 : Req (ofQ (lnSumLo T D 0) (lnSumLo_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req h0
  | succ k ih =>
    have hLLd := logLowBound_den_pos T D hD k
    have hmuld : 0 < (mul (logLowBound T D k) (⟨1, k + 1⟩ : Q)).den :=
      Qmul_den_pos hLLd (Nat.succ_pos k)
    have hadd := add_den_pos (lnSumLo_den_pos T D hD k) hmuld
    have hov : Rle (ofQ (mul (logLowBound T D k) ⟨1, k + 1⟩) hmuld) (lnOver (k + 1) (Nat.succ_pos k)) := by
      refine Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ hLLd (Nat.succ_pos k)))) ?_
      exact Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos k) (by show (0 : Int) ≤ 1; decide))
        (logN_ge_logLowBound T D hD hT k)
    refine Rle_trans (Rle_ofQ_ofQ (lnSumLo_den_pos T D hD (k + 1)) hadd
      (qRoundDown_le (add (lnSumLo T D k) (mul (logLowBound T D k) ⟨1, k + 1⟩)) hadd D)) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (lnSumLo_den_pos T D hD k) hmuld)) ?_
    exact Radd_le_add ih hov

/-- The **rational lower bound on `hSeq1 N`** (depth `T`, denominator `D`): the lower `lnSum` bound
    minus the upper `½log²` and `½log/(N+1)` bounds. -/
def gBound1lo (T D N : Nat) : Q :=
  Qsub (Qsub (lnSumLo T D (N + 1)) (mul (⟨1, 2⟩ : Q) (mul (logBound T D N) (logBound T D N))))
    (mul (⟨1, 2⟩ : Q) (mul (logBound T D N) (⟨1, N + 1⟩ : Q)))

theorem gBound1lo_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound1lo T D N).den :=
  Qsub_den_pos (Qsub_den_pos (lnSumLo_den_pos T D hD (N + 1))
      (Qmul_den_pos (by decide) (Qmul_den_pos (logBound_den_pos T D hD N) (logBound_den_pos T D hD N))))
    (Qmul_den_pos (by decide) (Qmul_den_pos (logBound_den_pos T D hD N) (Nat.succ_pos N)))

/-- **`ofQ(gBound1lo T D N) ≤ hSeq1 N`** (`T ≤ 21`) — `hSeq1 N = lnSum(N+1) − ½log²(N+1) − ½log(N+1)/(N+1)`
    bounded below by the lower `lnSum` bound minus the upper `½log²`/`½log/(N+1)` bounds, all at `D`. -/
theorem hSeq1_ge_gBound1lo (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (gBound1lo T D N) (gBound1lo_den_pos T D N hD)) (hSeq1 N) := by
  have LBd := logBound_den_pos T D hD N
  have hlogsq : Rle (Rhalf (Rmul (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N))))
      (ofQ (mul (⟨1, 2⟩ : Q) (mul (logBound T D N) (logBound T D N)))
        (Qmul_den_pos (by decide) (Qmul_den_pos LBd LBd))) :=
    Rle_trans (Rhalf_le_Rhalf (logNsq_le T D N hD))
      (Rle_of_Req (Req_trans (Rhalf_congr (Rmul_ofQ_ofQ LBd LBd))
        (Rhalf_ofQ _ (Qmul_den_pos LBd LBd))))
  have hlnover : Rle (Rhalf (lnOver (N + 1) (Nat.succ_pos N)))
      (ofQ (mul (⟨1, 2⟩ : Q) (mul (logBound T D N) (⟨1, N + 1⟩ : Q)))
        (Qmul_den_pos (by decide) (Qmul_den_pos LBd (Nat.succ_pos N)))) := by
    refine Rle_trans (Rhalf_le_Rhalf ?_) (Rle_of_Req (Rhalf_ofQ _ (Qmul_den_pos LBd (Nat.succ_pos N))))
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos N) (by show (0 : Int) ≤ 1; decide))
      (logN_le_logBound T D hD N)) ?_
    exact Rle_of_Req (Rmul_ofQ_ofQ LBd (Nat.succ_pos N))
  have hsum := lnSum_ge_lnSumLo T D hD hT (N + 1)
  exact Rle_trans (Rle_of_Req (Req_symm (Req_of_seq_Qeq (fun n => Qeq_refl _))))
    (Rsub_le_sub (Rsub_le_sub hsum hlogsq) hlnover)

set_option maxRecDepth 40000 in
/-- The numeric heart: `−762/10000 ≤ gBound1lo 4 10⁶ 200 − 1/400` — one big-integer kernel `decide`
    (no `native_decide`).  (≈ `−0.07613`, vs the true `γ₁ ≈ −0.07282`; denominator `D = 10⁶` to match
    the `Rgamma1_le_neg055` upper-bound setup, keeping the downstream defeq shallow.) -/
theorem gamma1_lo_decide :
    Qle (⟨-762, 10000⟩ : Q) (add (gBound1lo 4 1000000 200) (neg (⟨1, 2 * 200⟩ : Q))) := by decide

/-- **`γ₁ ≥ −0.0762`** (`= −762/10000`) — the certified TIGHT lower bracket on the first Stieltjes
    constant (true `≈ −0.07282`), via the Euler–Maclaurin accelerated sequence. `γ₁ ≥ hSeq1(200) − 1/400`
    (`Rgamma1_ge_hSeq1`), `hSeq1(200) ≥ ofQ(gBound1lo 4 10⁶ 200)` (`hSeq1_ge_gBound1lo`), and
    `gBound1lo 4 10⁶ 200 − 1/400 ≥ −762/10000` (`gamma1_lo_decide`). With `Rgamma1_le_neg055`
    (`γ₁ ≤ −0.055`) this brackets `γ₁` two-sided — the dominant `Pos Rlambda3` (`λ₃`) input. -/
theorem Rgamma1_ge_neg0762 : Rle (ofQ (⟨-762, 10000⟩ : Q) (by decide)) Rgamma1 := by
  refine Rle_trans ?_ (Rgamma1_ge_hSeq1 (show 1 ≤ 200 by decide) (show 200 ≤ 256 by decide))
  refine Rle_trans ?_ (Rsub_le_sub (hSeq1_ge_gBound1lo 4 1000000 200 (by decide) (by decide))
    (Rle_of_Req (Req_refl _)))
  have hgbd : 0 < (gBound1lo 4 1000000 200).den := gBound1lo_den_pos 4 1000000 200 (by decide)
  have h400 : 0 < (⟨1, 2 * 200⟩ : Q).den := Nat.mul_pos (by decide) (by decide)
  have h400n : 0 < (neg (⟨1, 2 * 200⟩ : Q)).den := h400
  refine Rle_trans ?_ (Rle_of_Req (Req_symm (Rsub_ofQ_ofQ hgbd h400)))
  exact Rle_ofQ_ofQ (by decide) (add_den_pos hgbd h400n) gamma1_lo_decide

-- ===========================================================================
-- (B) The UPPER direction: `γ₁ ≤ hSeq1(N) + 1/(2N)` → `γ₁ ≤ −0.07` (the dominant `Pos λ₄` input).
-- Mirrors (A) flipped: per-step `WStep ≤ δ²`, telescoping up, dyadic limit with the correction.
-- ===========================================================================

-- `logN` opaque downstream: keeps `isDefEq`/`whnf` from expanding the heavy `RexpReal`/artanh
-- definition when matching the nested `δ = log(p+1) − log p` atoms (avoids exponential blowup).
attribute [local irreducible] logN

/-- `(x+y) − y ≈ x`. -/
theorem Radd_sub_self_cancel (x y : Real) : Req (Rsub (Radd x y) y) x :=
  Req_trans (Radd_assoc x y (Rneg y)) (Req_trans (Radd_congr (Req_refl x) (Radd_neg y)) (Radd_zero x))

/-- `n + 1 ≤ 2ⁿ` (replaces the renamed `Nat.lt_two_pow`). -/
theorem nat_succ_le_two_pow : ∀ n : Nat, n + 1 ≤ 2 ^ n
  | 0 => by decide
  | (n + 1) => by
    have ih := nat_succ_le_two_pow n
    have h2 : 1 ≤ 2 ^ n := Nat.pos_pow_of_pos n (by decide)
    have hps : 2 ^ (n + 1) = 2 ^ n + 2 ^ n := by rw [Nat.pow_succ]; omega
    omega

/-- `x ≤ y ⟹ x − y ≤ 0`. -/
theorem Rsub_nonpos_of_le {x y : Real} (h : Rle x y) : Rle (Rsub x y) zero := by
  refine Rle_of_Rnonneg_Rsub (Rnonneg_congr ?_ (Rnonneg_Rsub_of_Rle h))
  exact Req_symm (Req_trans (Req_trans (Radd_comm zero (Rneg (Rsub x y))) (Radd_zero _))
    (Rneg_Rsub_swap x y))

/-- `(X+Y) − W ≈ (X−W) + Y`. -/
theorem Rsub_add_swap (X Y W : Real) : Req (Rsub (Radd X Y) W) (Radd (Rsub X W) Y) :=
  Req_trans (Radd_assoc X Y (Rneg W))
    (Req_trans (Radd_congr (Req_refl X) (Radd_comm Y (Rneg W))) (Req_symm (Radd_assoc X (Rneg W) Y)))

/-- **Abstract trapezoid UPPER cancellation**: `(a·u1+b·u0) − (a²−b²) ≤ (a−b)²` whenever `b ≥ 0`,
    `u1 ≤ a−b`, and the keystone `b·((u0+u1)−2δ) ≤ δ²` holds (`δ = a−b`).  `WStep ≈ Z − δ²` with
    `Z = S − 2bδ ≈ b·((u0+u1)−2δ) + δ·u1 ≤ δ² + δ² = 2δ²`, so `WStep ≤ δ²`. -/
theorem WStep_le_Dsq_gen (a b u0 u1 : Real) (hbnn : Rnonneg b) (hδnn : Rnonneg (Rsub a b))
    (hu1δ : Rle u1 (Rsub a b))
    (hkey : Rle (Rmul b (Rsub (Radd u0 u1) (Radd (Rsub a b) (Rsub a b)))) (Rmul (Rsub a b) (Rsub a b))) :
    Rle (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rsub (Rmul a a) (Rmul b b)))
        (Rmul (Rsub a b) (Rsub a b)) := by
  -- hWid : WStep + δ² ≈ Z := S − b·2δ
  have hWid : Req (Radd (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rsub (Rmul a a) (Rmul b b)))
        (Rmul (Rsub a b) (Rsub a b)))
      (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd (Rsub a b) (Rsub a b)))) := by
    have hstep : Req (Radd (Radd (Radd (Rmul a u1) (Rmul b u0))
          (Rneg (Rsub (Rmul a a) (Rmul b b)))) (Rmul (Rsub a b) (Rsub a b)))
        (Radd (Radd (Rmul a u1) (Rmul b u0))
          (Rneg (Rsub (Rsub (Rmul a a) (Rmul b b)) (Rmul (Rsub a b) (Rsub a b))))) := by
      refine Req_trans (Radd_assoc (Radd (Rmul a u1) (Rmul b u0))
        (Rneg (Rsub (Rmul a a) (Rmul b b))) (Rmul (Rsub a b) (Rsub a b))) ?_
      refine Radd_congr (Req_refl _) ?_
      refine Req_trans (Radd_comm (Rneg (Rsub (Rmul a a) (Rmul b b)))
        (Rmul (Rsub a b) (Rsub a b))) ?_
      exact Req_symm (Rneg_Rsub (Rsub (Rmul a a) (Rmul b b)) (Rmul (Rsub a b) (Rsub a b)))
    refine Req_trans hstep ?_
    exact Rsub_congr (Req_refl _) (sq_diff_identity_b a b)
  -- hScancel : S − b(u0+u1) ≈ δ·u1
  have hScancel : Req (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd u0 u1)))
      (Rmul (Rsub a b) u1) := by
    refine Req_trans (Rsub_congr (Req_refl _) (Rmul_distrib b u0 u1)) ?_
    refine Req_trans (Rsub_congr (Radd_comm (Rmul a u1) (Rmul b u0)) (Req_refl _)) ?_
    refine Req_trans (add_sub_add_cancel_left (Rmul b u0) (Rmul a u1) (Rmul b u1)) ?_
    exact Req_symm (Rmul_sub_distrib_right a b u1)
  -- WStep ≈ Z − δ²
  have hWStep_eq : Req (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rsub (Rmul a a) (Rmul b b)))
      (Rsub (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd (Rsub a b) (Rsub a b))))
        (Rmul (Rsub a b) (Rsub a b))) :=
    Req_symm (Req_trans (Rsub_congr (Req_symm hWid) (Req_refl _)) (Radd_sub_self_cancel _ _))
  -- Z ≈ b·((u0+u1)−2δ) + δ·u1
  have hZeq : Req (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd (Rsub a b) (Rsub a b))))
      (Radd (Rmul b (Rsub (Radd u0 u1) (Radd (Rsub a b) (Rsub a b)))) (Rmul (Rsub a b) u1)) := by
    have hS_eq : Req (Radd (Rmul a u1) (Rmul b u0))
        (Radd (Rmul b (Radd u0 u1)) (Rmul (Rsub a b) u1)) :=
      Req_trans (sub_add_cancel_real (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd u0 u1)))
        (Radd_congr (Req_refl _) hScancel)
    refine Req_trans (Rsub_congr hS_eq (Req_refl _)) ?_
    refine Req_trans (Rsub_add_swap (Rmul b (Radd u0 u1)) (Rmul (Rsub a b) u1)
      (Rmul b (Radd (Rsub a b) (Rsub a b)))) ?_
    exact Radd_congr (Req_symm (Rmul_sub_distrib b (Radd u0 u1) (Radd (Rsub a b) (Rsub a b))))
      (Req_refl _)
  -- Z ≤ δ² + δ²
  have hZle : Rle (Rsub (Radd (Rmul a u1) (Rmul b u0)) (Rmul b (Radd (Rsub a b) (Rsub a b))))
      (Radd (Rmul (Rsub a b) (Rsub a b)) (Rmul (Rsub a b) (Rsub a b))) :=
    Rle_trans (Rle_of_Req hZeq) (Radd_le_add hkey (Rmul_le_Rmul_left hδnn hu1δ))
  exact Rle_trans (Rle_of_Req hWStep_eq) (Rsub_le_of_le_add hZle)

/-- **`δ ≥ 2/(2p+1)`** — the first artanh term (`deltaLog_lower_tight T=0`, `dMinusQ 0 p = 2/(2p+1)`). -/
theorem delta_ge_2over (p : Nat) (hp : 1 ≤ p) :
    Rle (ofQ (⟨2, 2 * p + 1⟩ : Q) (Nat.succ_pos (2 * p)))
      (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) := by
  refine Rle_trans (Rle_of_Req (ofQ_congr (Nat.succ_pos (2 * p)) (dMinusQ_den_pos 0 p) ?_))
    (deltaLog_lower_tight p 0 hp (by omega))
  show Qeq (⟨2, 2 * p + 1⟩ : Q) (dMinusQ 0 p)
  simp only [Qeq, dMinusQ, artSum, artTerm, qpow, npow, mul]; push_cast; ring_uor

set_option maxHeartbeats 8000000 in
/-- **`(u0+u1) − 2δ ≤ 1/(p(p+1)(2p+1))`** — `2δ ≥ 4/(2p+1)` (`delta_ge_2over`), and
    `(1/p+1/(p+1)) − 4/(2p+1) = 1/(p(p+1)(2p+1))` exactly. -/
theorem sum_2delta_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Radd (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
      (ofQ (⟨1, p * (p + 1) * (2 * p + 1)⟩ : Q)
        (Nat.mul_pos (Nat.mul_pos hp (Nat.succ_pos p)) (Nat.succ_pos (2 * p)))) := by
  have h2p1 : 0 < 2 * p + 1 := by omega
  have heq4 : Req (ofQ (⟨4, 2 * p + 1⟩ : Q) h2p1)
      (Radd (ofQ (⟨2, 2 * p + 1⟩ : Q) h2p1) (ofQ (⟨2, 2 * p + 1⟩ : Q) h2p1)) :=
    Req_symm (Req_trans (Radd_ofQ_ofQ h2p1 h2p1) (ofQ_congr (add_den_pos h2p1 h2p1) h2p1
      (by show Qeq (add (⟨2, 2 * p + 1⟩ : Q) (⟨2, 2 * p + 1⟩ : Q)) (⟨4, 2 * p + 1⟩ : Q)
          simp only [Qeq, add]; push_cast; ring_uor)))
  have h2dlo : Rle (ofQ (⟨4, 2 * p + 1⟩ : Q) h2p1)
      (Radd (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) :=
    Rle_trans (Rle_of_Req heq4) (Radd_le_add (delta_ge_2over p hp) (delta_ge_2over p hp))
  refine Rle_trans (Rsub_le_sub (Rle_refl _) h2dlo) ?_
  refine Rle_trans (Rle_of_Req (Rsub_congr (Radd_ofQ_ofQ (a := (⟨1, p⟩ : Q))
    (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)) (Req_refl _))) ?_
  refine Rle_of_Req (Req_trans (Rsub_ofQ_ofQ (add_den_pos (a := (⟨1, p⟩ : Q))
    (b := (⟨1, p + 1⟩ : Q)) hp (Nat.succ_pos p)) h2p1) ?_)
  apply ofQ_congr
  show Qeq (add (add (⟨1, p⟩ : Q) (⟨1, p + 1⟩ : Q)) (neg (⟨4, 2 * p + 1⟩ : Q)))
    (⟨1, p * (p + 1) * (2 * p + 1)⟩ : Q)
  simp only [Qeq, add, neg]; push_cast; ring_uor

set_option maxHeartbeats 8000000 in
/-- **`δ² ≥ 4/(2p+1)²`** — from `δ ≥ 2/(2p+1)` (`delta_ge_2over`), squared. -/
theorem dsq_ge_4over (p : Nat) (hp : 1 ≤ p) :
    Rle (ofQ (⟨4, (2 * p + 1) * (2 * p + 1)⟩ : Q) (Nat.mul_pos (Nat.succ_pos (2 * p)) (Nat.succ_pos (2 * p))))
      (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
  have h2p1 : 0 < 2 * p + 1 := by omega
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have heqsq : Req (ofQ (⟨4, (2 * p + 1) * (2 * p + 1)⟩ : Q) (Nat.mul_pos h2p1 h2p1))
      (Rmul (ofQ (⟨2, 2 * p + 1⟩ : Q) h2p1) (ofQ (⟨2, 2 * p + 1⟩ : Q) h2p1)) :=
    Req_symm (Req_trans (Rmul_ofQ_ofQ h2p1 h2p1) (ofQ_congr (Qmul_den_pos h2p1 h2p1)
      (Nat.mul_pos h2p1 h2p1)
      (by show Qeq (mul (⟨2, 2 * p + 1⟩ : Q) (⟨2, 2 * p + 1⟩ : Q)) (⟨4, (2 * p + 1) * (2 * p + 1)⟩ : Q)
          simp only [Qeq, mul]; push_cast; ring_uor)))
  exact Rle_trans (Rle_of_Req heqsq)
    (Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ h2p1 (by show (0 : Int) ≤ 2; decide)) (delta_ge_2over p hp))
      (Rmul_le_Rmul_left hδnn (delta_ge_2over p hp)))

set_option maxHeartbeats 8000000 in
/-- **The keystone** `b·((u0+u1)−2δ) ≤ δ²` (`sum_2delta_le`, `b ≤ p`, `dsq_ge_4over`,
    `1/((p+1)(2p+1)) ≤ 4/(2p+1)²`). -/
theorem WStep_hkey (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logN p hp) (Rsub (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Radd (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
  have h2p1 : 0 < 2 * p + 1 := by omega
  have hden3 : 0 < p * (p + 1) * (2 * p + 1) := Nat.mul_pos (Nat.mul_pos hp (Nat.succ_pos p)) h2p1
  have hsqden : 0 < (2 * p + 1) * (2 * p + 1) := Nat.mul_pos h2p1 h2p1
  have hbm : Rle (Rmul (logN p hp) (Rsub (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
        (Radd (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
      (ofQ (⟨(p : Int), p * (p + 1) * (2 * p + 1)⟩ : Q) hden3) := by
    refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_logN p hp) (sum_2delta_le p hp)) ?_
    refine Rle_trans (Rmul_le_Rmul_right (Rnonneg_ofQ hden3 (by show (0 : Int) ≤ 1; decide))
      (logN_le_self p hp)) ?_
    refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ Nat.one_pos hden3) (ofQ_congr
      (Qmul_den_pos Nat.one_pos hden3) hden3 ?_))
    show Qeq (mul (⟨(p : Int), 1⟩ : Q) (⟨1, p * (p + 1) * (2 * p + 1)⟩ : Q))
      (⟨(p : Int), p * (p + 1) * (2 * p + 1)⟩ : Q)
    simp only [Qeq, mul]; push_cast; ring_uor
  refine Rle_trans hbm (Rle_trans (Rle_ofQ_ofQ hden3 hsqden ?_) (dsq_ge_4over p hp))
  show Qle (⟨(p : Int), p * (p + 1) * (2 * p + 1)⟩ : Q) (⟨4, (2 * p + 1) * (2 * p + 1)⟩ : Q)
  simp only [Qle]
  have key : p * ((2 * p + 1) * (2 * p + 1)) ≤ 4 * (p * (p + 1) * (2 * p + 1)) := by
    have hid : 4 * (p * (p + 1) * (2 * p + 1))
        = p * ((2 * p + 1) * (2 * p + 1)) + p * (2 * p + 3) * (2 * p + 1) := by
      have : ((4 * (p * (p + 1) * (2 * p + 1)) : Nat) : Int)
          = ((p * ((2 * p + 1) * (2 * p + 1)) + p * (2 * p + 3) * (2 * p + 1) : Nat) : Int) := by
        push_cast; ring_uor
      exact_mod_cast this
    omega
  exact_mod_cast key

/-- **`WStep(p) ≤ δ²`** — the per-step trapezoidal residual upper bound (`WStep_le_Dsq_gen` + `WStep_hkey`). -/
theorem WStep_le_Dsq (p : Nat) (hp : 1 ≤ p) :
    Rle (WStep p hp) (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                          (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) := by
  unfold WStep lnOver
  exact WStep_le_Dsq_gen (logN (p + 1) (Nat.succ_pos p)) (logN p hp)
    (ofQ (⟨1, p⟩ : Q) (by show 0 < p; omega)) (ofQ (⟨1, p + 1⟩ : Q) (by show 0 < p + 1; omega))
    (Rnonneg_logN p hp) (Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p)))
    (deltaLog_lower p hp) (WStep_hkey p hp)

/-- **`s_{j+1} ≤ 1/(2(j+1)²)`** — the per-step upper bound on the accelerated increment. -/
theorem sStep1_le (p : Nat) (hp : 1 ≤ p) :
    Rle (sStep1 p hp) (ofQ (⟨1, 2 * p * p⟩ : Q) (Nat.mul_pos (Nat.mul_pos (by decide) hp) hp)) := by
  have hppd : 0 < (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)).den := Qmul_den_pos hp hp
  have hWle : Rle (WStep p hp) (ofQ (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) hppd) :=
    Rle_trans (WStep_le_Dsq p hp) (dsq_self_le p hp)
  refine Rle_trans (Rhalf_le_Rhalf hWle) (Rle_of_Req ?_)
  refine Req_trans (Rhalf_ofQ (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) hppd) ?_
  exact ofQ_congr (Qmul_den_pos (by decide) hppd) (Nat.mul_pos (Nat.mul_pos (by decide) hp) hp)
    (by show Qeq (mul (⟨1, 2⟩ : Q) (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q))) (⟨1, 2 * p * p⟩ : Q)
        simp only [Qeq, mul]; push_cast; ring_uor)

/-- **`s_{j+1} = hSeq1(j+1) − hSeq1 j ≤ 1/(2(j+1)²)`** — the per-step upper increment. -/
theorem hSeq1_step_le (j : Nat) :
    Rle (Rsub (hSeq1 (j + 1)) (hSeq1 j))
        (ofQ (⟨1, 2 * (j + 1) * (j + 1)⟩ : Q)
          (Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos j)) (Nat.succ_pos j))) :=
  Rle_trans (Rle_of_Req (hSeq1_step_eq j)) (sStep1_le (j + 1) (Nat.succ_pos j))

/-- **Upper gap bound, U-form** (`d`-induction): `hSeq1(N+d) − hSeq1 N ≤ Usum(N+d) − Usum N`. -/
theorem hSeq1_diff_le_U (N : Nat) : ∀ (d : Nat),
    Rle (Rsub (hSeq1 (N + d)) (hSeq1 N))
        (ofQ (Qsub (Usum (N + d)) (Usum N))
          (Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N))) := by
  intro d
  induction d with
  | zero =>
      simp only [Nat.add_zero]
      apply Rle_of_Req
      refine Req_trans (Radd_neg (hSeq1 N)) ?_
      apply Req_of_seq_Qeq; intro n
      simp only [ofQ, zero, Qsub, add, neg, Qeq]; push_cast; ring_uor
  | succ d ih =>
      have hstepd : 0 < (⟨1, 2 * ((N + d) + 1) * ((N + d) + 1)⟩ : Q).den :=
        Nat.mul_pos (Nat.mul_pos (by decide) (Nat.succ_pos (N + d))) (Nat.succ_pos (N + d))
      have hgapd : 0 < (Qsub (Usum (N + d)) (Usum N)).den :=
        Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N)
      have heq : Req (ofQ (Qsub (Usum (N + d + 1)) (Usum N))
            (Qsub_den_pos (Usum_den_pos (N + d + 1)) (Usum_den_pos N)))
          (Radd (ofQ (⟨1, 2 * ((N + d) + 1) * ((N + d) + 1)⟩ : Q) hstepd)
                (ofQ (Qsub (Usum (N + d)) (Usum N)) hgapd)) :=
        Req_trans (ofQ_congr _ _ (Qeq_symm (Qadd_Qsub_comm _ (Usum (N + d)) (Usum N))))
          (Req_symm (Radd_ofQ_ofQ hstepd hgapd))
      exact Rle_trans (Rle_of_Req (Req_symm (Rsub_split (hSeq1 (N + d + 1)) (hSeq1 (N + d)) (hSeq1 N))))
        (Rle_trans (Radd_le_add (hSeq1_step_le (N + d)) ih) (Rle_of_Req (Req_symm heq)))

/-- **The upper gap bound** `hSeq1(N+d) − hSeq1 N ≤ 1/(2N)` (for `N ≥ 1`). -/
theorem hSeq1_diff_le (N : Nat) (hN : 1 ≤ N) (d : Nat) :
    Rle (Rsub (hSeq1 (N + d)) (hSeq1 N)) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN)) := by
  refine Rle_trans (hSeq1_diff_le_U N d) ?_
  have hmid : 0 < (Qsub (⟨1, 2 * N⟩ : Q) (⟨1, 2 * (N + d)⟩ : Q)).den :=
    Qsub_den_pos (Nat.mul_pos (by decide) hN) (Nat.mul_pos (by decide) (by omega))
  exact Rle_trans (Rle_ofQ_ofQ (Qsub_den_pos (Usum_den_pos (N + d)) (Usum_den_pos N)) hmid
      (Usum_tail_le N hN d))
    (Rle_ofQ_ofQ hmid (Nat.mul_pos (by decide) hN) (Qsub_unit_le (2 * N) (2 * (N + d))))

/-- **`hSeq1(N+d) ≤ hSeq1 N + 1/(2N)`** (uniform in `d`, `N ≥ 1`). -/
theorem hSeq1_upper_const (N : Nat) (hN : 1 ≤ N) (d : Nat) :
    Rle (hSeq1 (N + d)) (Radd (hSeq1 N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN))) :=
  Rle_add_of_Rsub_le (hSeq1_diff_le N hN d)

/-- **`γ₁ ≤ gSeqDyadic j + 1/(j+1)`** — the raw-`gSeq` upper gap (`gSeq_le_anchor`) carried to the limit. -/
theorem Rgamma1_le_dyadic (j : Nat) :
    Rle Rgamma1 (Radd (gSeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have htend : Rle (Rsub Rgamma1 (gSeqDyadic (j + k))) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (RTendsTo_to_Rle_lower (Rlim_tendsTo gSeqDyadic gSeqDyadic_RReg) (j + k)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos (j + k)) (Nat.succ_pos k)
      (by show (2 : Int) * ((k : Int) + 1) ≤ 2 * ((j : Int) + (k : Int) + 1); omega)
  have hMpos : 0 < 2 ^ gammaMidx j := Nat.pos_pow_of_pos _ (by decide)
  have hanchor : Rle (gSeqDyadic (j + k))
      (Radd (gSeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) := by
    refine Rle_trans (gSeq_le_anchor hMpos
      (Nat.pow_le_pow_right (by decide) (gammaMidx_mono (Nat.le_add_right j k)))) ?_
    refine Radd_le_add (Rle_refl _) (Rle_ofQ_ofQ (Nat.mul_pos (by decide) hMpos) (Nat.succ_pos j) ?_)
    show Qle (⟨1, 2 * 2 ^ gammaMidx j⟩ : Q) (⟨1, j + 1⟩ : Q)
    show (1 : Int) * ((j : Int) + 1) ≤ (1 : Int) * (2 * 2 ^ gammaMidx j : Nat)
    simp only [gammaMidx, Int.one_mul]
    have h1 := nat_succ_le_two_pow j
    have h2 : 2 ^ j ≤ 2 ^ (2 * j + 8) := Nat.pow_le_pow_right (by decide) (by omega)
    have : j + 1 ≤ 2 * 2 ^ (2 * j + 8) := by omega
    exact_mod_cast this
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split Rgamma1 (gSeqDyadic (j + k))
    (Radd (gSeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)))))) ?_
  exact Rle_trans (Radd_le_add htend (Rsub_nonpos_of_le hanchor)) (Rle_of_Req (Radd_zero _))

/-- **`gSeq M = hSeq1 M + ½·(ln(M+1))/(M+1)`** — the accelerator correction made explicit. -/
theorem gSeq_eq_hSeq1_add (M : Nat) :
    Req (gSeq M) (Radd (hSeq1 M) (Rhalf (lnOver (M + 1) (Nat.succ_pos M)))) := by
  unfold hSeq1
  refine Req_symm (Req_trans (Radd_assoc (gSeq M) (Rneg _) _) ?_)
  refine Req_trans (Radd_congr (Req_refl _) (Req_trans (Radd_comm (Rneg _) _) (Radd_neg _))) ?_
  exact Radd_zero (gSeq M)

/-- **Block log cap at an arbitrary argument** `logN K ≤ a+2` for `2 ≤ K ≤ 2^{a+2}`. -/
theorem logN_le_cap (K a : Nat) (hK : 1 ≤ K) (hK2 : 2 ≤ K) (h : K ≤ 2 ^ (a + 2)) :
    Rle (logN K hK) (ofQ (⟨(a + 2 : Int), 1⟩ : Q) Nat.one_pos) := by
  obtain ⟨m, rfl⟩ : ∃ m, K = m + 2 := ⟨K - 2, by omega⟩
  exact logN_le_block a m h

/-- **The correction `½·ln(M+1)/(M+1)` at `M = 2^{2j+8}` is `≤ (2j+9)/(2(M+1))`** (`logN_le_cap`). -/
theorem corr1_le (j : Nat) :
    Rle (Rhalf (lnOver (2 ^ (2 * j + 8) + 1) (Nat.succ_pos _)))
        (ofQ (⟨2 * (j : Int) + 9, 2 * (2 ^ (2 * j + 8) + 1)⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.succ_pos _))) := by
  have hbnd : 2 ^ (2 * j + 8) + 1 ≤ 2 ^ ((2 * j + 7) + 2) := by
    have h1 : 2 ^ ((2 * j + 7) + 2) = 2 ^ (2 * j + 8) + 2 ^ (2 * j + 8) := by
      have heq : 2 ^ ((2 * j + 7) + 2) = 2 ^ ((2 * j + 8) + 1) := by
        rw [show (2 * j + 7) + 2 = (2 * j + 8) + 1 from by omega]
      rw [heq, Nat.pow_succ]; omega
    have hpow : 1 ≤ 2 ^ (2 * j + 8) := Nat.pos_pow_of_pos _ (by decide)
    omega
  have hcap := logN_le_cap (2 ^ (2 * j + 8) + 1) (2 * j + 7) (Nat.succ_pos _)
    (by have h := Nat.pos_pow_of_pos (2 * j + 8) (show 0 < 2 by decide); omega) hbnd
  unfold lnOver
  refine Rle_trans (Rhalf_le_Rhalf (Rmul_le_Rmul_right
    (Rnonneg_ofQ (Nat.succ_pos _) (by show (0 : Int) ≤ 1; decide)) hcap)) ?_
  refine Rle_of_Req (Req_trans (Rhalf_congr (Rmul_ofQ_ofQ Nat.one_pos (Nat.succ_pos _))) ?_)
  refine Req_trans (Rhalf_ofQ _ (Qmul_den_pos Nat.one_pos (Nat.succ_pos _))) ?_
  apply ofQ_congr
  show Qeq (mul (⟨1, 2⟩ : Q) (mul (⟨(2 * j + 7 : Int) + 2, 1⟩ : Q) (⟨1, 2 ^ (2 * j + 8) + 1⟩ : Q)))
    (⟨2 * (j : Int) + 9, 2 * (2 ^ (2 * j + 8) + 1)⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **`γ₁ ≤ hSeq1(N) + 1/(2N) + (2j+9)/(2(2^{2j+8}+1)) + 1/(j+1)`** — dyadic limit
    (`Rgamma1_le_dyadic`), correction extracted (`gSeq_eq_hSeq1_add`), anchor telescoped to `N`
    (`hSeq1_upper_const`), correction capped (`corr1_le`). -/
theorem Rgamma1_le_hSeq1_up (N j : Nat) (hN : 1 ≤ N) (hNj : N ≤ 2 ^ (2 * j + 8)) :
    Rle Rgamma1
      (Radd (Radd (Radd (hSeq1 N) (ofQ (⟨1, 2 * N⟩ : Q) (Nat.mul_pos (by decide) hN)))
          (ofQ (⟨2 * (j : Int) + 9, 2 * (2 ^ (2 * j + 8) + 1)⟩ : Q)
            (Nat.mul_pos (by decide) (Nat.succ_pos _))))
        (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  refine Rle_trans (Rgamma1_le_dyadic j) (Radd_le_add ?_ (Rle_refl _))
  refine Rle_trans (Rle_of_Req (gSeq_eq_hSeq1_add (2 ^ (2 * j + 8)))) ?_
  refine Radd_le_add ?_ (corr1_le j)
  obtain ⟨k, hk⟩ := Nat.le.dest hNj
  rw [← hk]
  exact hSeq1_upper_const N hN k

/-- The **rational upper bound on `hSeq1 N`** (depth `T`, denominator `D`): the upper `lnSum` bound
    minus the lower `½log²` and `½log/(N+1)` bounds. -/
def gBound1up (T D N : Nat) : Q :=
  Qsub (Qsub (lnSumBound T D (N + 1)) (mul (⟨1, 2⟩ : Q) (mul (logLowBound T D N) (logLowBound T D N))))
    (mul (⟨1, 2⟩ : Q) (mul (logLowBound T D N) (⟨1, N + 1⟩ : Q)))

theorem gBound1up_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound1up T D N).den :=
  Qsub_den_pos (Qsub_den_pos (lnSumBound_den_pos T D hD (N + 1))
      (Qmul_den_pos (by decide) (Qmul_den_pos (logLowBound_den_pos T D hD N) (logLowBound_den_pos T D hD N))))
    (Qmul_den_pos (by decide) (Qmul_den_pos (logLowBound_den_pos T D hD N) (Nat.succ_pos N)))

set_option maxHeartbeats 8000000 in
/-- **`hSeq1 N ≤ ofQ(gBound1up T D N)`** (`T ≤ 21`) — the upper `lnSum` bound minus the lower
    `½log²`/`½log/(N+1)` bounds (`lnSum_le_lnSumBound`, `logN_ge_logLowBound`), collapsed to `gBound1up`. -/
theorem hSeq1_le_gBound1up (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (hSeq1 N) (ofQ (gBound1up T D N) (gBound1up_den_pos T D N hD)) := by
  have LLd := logLowBound_den_pos T D hD N
  have LLnn : Rnonneg (ofQ (logLowBound T D N) LLd) := Rnonneg_ofQ LLd (logLowBound_num_nonneg T D N)
  have hloglow := logN_ge_logLowBound T D hD hT N
  have hlogsq_lo : Rle (ofQ (mul (⟨1, 2⟩ : Q) (mul (logLowBound T D N) (logLowBound T D N)))
        (Qmul_den_pos (by decide) (Qmul_den_pos LLd LLd)))
      (Rhalf (Rmul (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N)))) := by
    have hsq : Rle (ofQ (mul (logLowBound T D N) (logLowBound T D N)) (Qmul_den_pos LLd LLd))
        (Rmul (logN (N + 1) (Nat.succ_pos N)) (logN (N + 1) (Nat.succ_pos N))) :=
      Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ LLd LLd)))
        (Rle_trans (Rmul_le_Rmul_right LLnn hloglow)
          (Rmul_le_Rmul_left (Rnonneg_logN (N + 1) (Nat.succ_pos N)) hloglow))
    exact Rle_trans (Rle_of_Req (Req_symm (Rhalf_ofQ (mul (logLowBound T D N) (logLowBound T D N))
      (Qmul_den_pos LLd LLd)))) (Rhalf_le_Rhalf hsq)
  have hlnover_lo : Rle (ofQ (mul (⟨1, 2⟩ : Q) (mul (logLowBound T D N) (⟨1, N + 1⟩ : Q)))
        (Qmul_den_pos (by decide) (Qmul_den_pos LLd (Nat.succ_pos N))))
      (Rhalf (lnOver (N + 1) (Nat.succ_pos N))) := by
    have hov : Rle (ofQ (mul (logLowBound T D N) (⟨1, N + 1⟩ : Q)) (Qmul_den_pos LLd (Nat.succ_pos N)))
        (lnOver (N + 1) (Nat.succ_pos N)) :=
      Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ LLd (Nat.succ_pos N))))
        (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos N) (by show (0 : Int) ≤ 1; decide)) hloglow)
    exact Rle_trans (Rle_of_Req (Req_symm (Rhalf_ofQ (mul (logLowBound T D N) (⟨1, N + 1⟩ : Q))
      (Qmul_den_pos LLd (Nat.succ_pos N))))) (Rhalf_le_Rhalf hov)
  unfold hSeq1 gSeq
  refine Rle_trans (Rsub_le_sub (Rsub_le_sub (lnSum_le_lnSumBound T D hD (N + 1)) hlogsq_lo)
    hlnover_lo) ?_
  exact Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))

/-- **`corr ≤ 1/(j+1)²` at `j = 300`** — `(2·300+9)·301² ≤ 2(2^{608}+1)` (poly ≤ exp, one `decide`). -/
theorem corr1_weaken800 :
    Rle (ofQ (⟨2 * (800 : Int) + 9, 2 * (2 ^ (2 * 800 + 8) + 1)⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.succ_pos _)))
        (ofQ (⟨1, (800 + 1) * (800 + 1)⟩ : Q) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) := by
  refine Rle_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos _))
    (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)) ?_
  simp only [Qle]
  have hpow : (1032336009 : Nat) ≤ 2 ^ (2 * 800 + 8) :=
    Nat.le_trans (show (1032336009 : Nat) ≤ 2 ^ 31 by decide)
      (Nat.pow_le_pow_right (by decide) (by decide))
  omega

set_option maxRecDepth 40000 in
/-- The numeric heart: `gBound1up 4 10⁶ 200 + 1/400 + 1/801² + 1/801 ≤ −677/10000` — one `decide`. -/
theorem gamma1_up_decide :
    Qle (add (add (add (gBound1up 4 1000000 200) (⟨1, 2 * 200⟩ : Q)) (⟨1, (800 + 1) * (800 + 1)⟩ : Q))
        (⟨1, 800 + 1⟩ : Q))
      (⟨-677, 10000⟩ : Q) := by decide

set_option maxRecDepth 40000 in
/-- **`γ₁ ≤ −0.0677`** — the tightened UPPER bracket (vs the raw-`gSeq` `−0.055`), via the `hSeq1`
    acceleration upper: `γ₁ ≤ hSeq1(200) + 1/400 + corr + 1/801` (`Rgamma1_le_hSeq1_up`, `j = 800`),
    `hSeq1(200) ≤ gBound1up 4 10⁶ 200`, `corr ≤ 1/801²`, and one big-integer `decide`. The dominant
    `Pos λ₄` input (the loose `−0.055` made `λ₄` infeasible). -/
theorem Rgamma1_le_neg0677 : Rle Rgamma1 (ofQ (⟨-677, 10000⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma1_le_hSeq1_up 200 800 (by decide)
    (Nat.le_trans (show (200 : Nat) ≤ 2 ^ 8 by decide)
      (Nat.pow_le_pow_right (by decide) (by decide)))) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add
    (hSeq1_le_gBound1up 4 1000000 200 (by decide) (by decide)) (Rle_refl _)) corr1_weaken800)
    (Rle_refl _)) ?_
  refine Rle_trans (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (add_den_pos (gBound1up_den_pos 4 1000000 200 (by decide))
      (by decide)) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (Nat.succ_pos _)) (by decide)
    gamma1_up_decide

end UOR.Bridge.F1Square.Analysis
