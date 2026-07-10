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

import F1Square.Analysis.GammaOne
import F1Square.Analysis.GammaTwoBracket

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

end UOR.Bridge.F1Square.Analysis
