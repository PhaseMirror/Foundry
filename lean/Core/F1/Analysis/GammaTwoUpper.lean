/-
F1 square — v0.22.0 crux frontier: **the LOOSE UPPER bracket on the second Stieltjes constant `γ₂`**
(`γ₂ ≤ 1/40`), the last constant input to `Pos Rlambda4` (the n=4 prime–archimedean coupling).

`λ₄`'s arithmetic side carries `−2γγ₂` through `η₃`; with `γ > 0` a LOOSE UPPER bound `γ₂ ≤ ε`
(`ε` modest, here `1/40`) suffices to control it (the `Pos λ₄` margin is `≈ +0.054` once `γ₁ ≤ −0.0677`
and `γ₃ ≤ 1/8` are in place). This file builds that upper bracket by the SAME DISCRETE Euler–Maclaurin
acceleration as `GammaTwoBracket` (the `γ₂` LOWER bound) — but in the UPPER direction, mirroring the
`γ₃`/`γ₁` upper pipelines.

The per-step trapezoidal residual `sStep ≈ decompForm = b²·C2 + b·R1 + R0` (`b = ln p`, `δ = a−b`,
`u0 = 1/p`, `u1 = 1/(p+1)`):
  b²·C2 ≤ 1/(p(p+1))   (C2 = ½(u0+u1)−δ ≤ 1/(2p(p+1)(2p+1)) (`C2_le`), b² ≤ 4p (`logSq_le_self4`))
  b·R1  ≤ 0            (R1 = δ(u1−δ),  u1 ≤ δ)
  R0    ≤ 1/(p(p+1))   (R0 = ½δ²u1 − ⅓δ³ ≤ ½δ²u1, δ² ≤ 1/p²)
so `sStep ≤ 2/(p(p+1))`, telescoping to `γ₂ ≤ hSeq(N) + 2/(N+1) + corr + 1/(j+1)`.

The only new ingredient is `(ln p)² ≤ 4p` (`logSq_le_self4`): with `M = L/2`, `exp(M) ≥ 1+M ≥ M`, so
`exp(L) = exp(M)² ≥ M²`, i.e. `4·exp(L) ≥ L²`; `exp(ln p) = p`.  No `RrpowPos`.

Pure Lean 4 core, no Mathlib, no `sorry`/`native_decide`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import Core.F1.Analysis.GammaThreeBracket

namespace UOR.Bridge.F1Square.Analysis

set_option maxHeartbeats 4000000

-- `logN` opaque downstream: prevents exponential `whnf`/`isDefEq` blowup on the nested `δ = ln(p+1)−ln p`.
attribute [local irreducible] logN

-- ===========================================================================
-- (S1) The square-root cap `(ln p)² ≤ 4p`.
-- ===========================================================================

/-- **Square monotonicity** `0 ≤ A ≤ B ⟹ A² ≤ B²`. -/
theorem sq_le_sq {A B : Real} (hA : Rnonneg A) (hB : Rnonneg B) (hAB : Rle A B) :
    Rle (Rmul A A) (Rmul B B) :=
  Rle_trans (Rmul_le_Rmul_right hA hAB) (Rmul_le_Rmul_left hB hAB)

/-- **`L² ≤ 4·exp(L)`** for `L ≥ 0`.  With `M = L/2`: `exp(M) ≥ 1+M ≥ M ≥ 0`, so
    `exp(L) = exp(M+M) = exp(M)² ≥ M²`, and `4·M² = L²`. -/
theorem sq_le_4_exp (L : Real) (hL : Rnonneg L) :
    Rle (Rmul L L) (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide)) (RexpReal L)) := by
  have hMnn : Rnonneg (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L) :=
    Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide)) hL
  have hEnn : Rnonneg (RexpReal (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L)) := RexpReal_nonneg _
  have hMleE : Rle (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L)
      (RexpReal (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L)) :=
    Rle_trans (Rle_self_Radd_left Rnonneg_one) (RexpReal_ge_one_add_nonneg hMnn)
  have hsq := sq_le_sq hMnn hEnn hMleE
  -- M+M ≈ L
  have hcoef : Req (Radd (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L)) L := by
    refine Req_trans (Req_symm (Rmul_distrib_right _ _ L)) ?_
    refine Req_trans (Rmul_congr ?_ (Req_refl L)) (Rone_mul L)
    exact Req_trans (Radd_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  -- E² ≈ exp(L)
  have hE2 : Req (Rmul (RexpReal (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L))
        (RexpReal (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L))) (RexpReal L) :=
    Req_trans (Req_symm (RexpReal_add _ _)) (RexpReal_congr hcoef)
  -- L² ≈ 4·M²
  have hconst : Req (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2⟩ : Q) (by decide)))) one := by
    refine Req_trans (Rmul_congr (Req_refl _) (Rmul_ofQ_ofQ (by decide) (by decide))) ?_
    exact Req_trans (Rmul_ofQ_ofQ (by decide) (by decide)) (ofQ_congr (by decide) (by decide) (by decide))
  have hL2 : Req (Rmul L L)
      (Rmul (ofQ (⟨4, 1⟩ : Q) (by decide))
        (Rmul (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L) (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) L))) := by
    refine Req_symm ?_
    refine Req_trans (Rmul_congr (Req_refl _) (prod_sq_reassoc (ofQ (⟨1, 2⟩ : Q) (by decide)) L)) ?_
    refine Req_trans (Req_symm (Rmul_assoc (ofQ (⟨4, 1⟩ : Q) (by decide))
        (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (ofQ (⟨1, 2⟩ : Q) (by decide))) (Rmul L L))) ?_
    exact Req_trans (Rmul_congr hconst (Req_refl _)) (Rone_mul _)
  refine Rle_trans (Rle_of_Req hL2) ?_
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) hsq) ?_
  exact Rle_of_Req (Rmul_congr (Req_refl _) hE2)

/-- **`(ln p)² ≤ 4·p`** — the square-root cap. -/
theorem logSq_le_self4 (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logN p hp) (logN p hp)) (ofQ (⟨4 * (p : Int), 1⟩ : Q) Nat.one_pos) := by
  refine Rle_trans (sq_le_4_exp (logN p hp) (Rnonneg_logN p hp)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _) (Rexp_logN p hp))) ?_
  exact Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) Nat.one_pos)
    (ofQ_congr (Qmul_den_pos (by decide) Nat.one_pos) Nat.one_pos
      (by show Qeq (mul (⟨4, 1⟩ : Q) (⟨(p : Int), 1⟩ : Q)) (⟨4 * (p : Int), 1⟩ : Q)
          simp only [Qeq, mul])))

-- ===========================================================================
-- (S2) The per-step UPPER bound `sStep p ≤ 2/(p(p+1))` on the squared-log trapezoidal residual.
-- ===========================================================================

/-- **`b²·C2 ≤ 1/(p(p+1))`** — `b² = (ln p)² ≤ 4p` (`logSq_le_self4`), `C2 ≤ 1/(2p(p+1)(2p+1))`
    (`C2_le`), so `b²·C2 ≤ 4p/(2p(p+1)(2p+1)) ≤ 1/(p(p+1))`. -/
theorem b2C2_le (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (Rmul (logN p hp) (logN p hp))
          (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
              (Radd (ofQ (⟨1, p⟩ : Q) hp) (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
            (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))))
        (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
  have h4nn : Rnonneg (ofQ (⟨4 * (p : Int), 1⟩ : Q) Nat.one_pos) :=
    Rnonneg_ofQ Nat.one_pos (by show (0 : Int) ≤ 4 * (p : Int); omega)
  refine Rle_trans (Rmul_le_Rmul_right (C2_nonneg p hp) (logSq_le_self4 p hp)) ?_
  refine Rle_trans (Rmul_le_Rmul_left h4nn (C2_le p hp)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨4 * (p : Int), 1⟩ : Q))
    (b := (⟨1, 2 * p * (p + 1) * (2 * p + 1)⟩ : Q)) Nat.one_pos
    (Nat.mul_pos (Nat.mul_pos (Nat.mul_pos (by decide) hp) (Nat.succ_pos p)) (by omega)))) ?_
  refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
  show Qle (mul (⟨4 * (p : Int), 1⟩ : Q) (⟨1, 2 * p * (p + 1) * (2 * p + 1)⟩ : Q))
    (⟨1, p * (p + 1)⟩ : Q)
  simp only [Qle, mul, Int.one_mul, Int.mul_one, Nat.one_mul, Nat.mul_one]
  have key : 4 * p * (p * (p + 1)) ≤ 2 * p * (p + 1) * (2 * p + 1) := by
    have e1 : ((2 * p * (p + 1) * (2 * p + 1) : Nat) : Int)
        = ((4 * p * (p * (p + 1)) + 2 * p * (p + 1) : Nat) : Int) := by push_cast; ring_uor
    have n1 : 2 * p * (p + 1) * (2 * p + 1) = 4 * p * (p * (p + 1)) + 2 * p * (p + 1) := by
      exact_mod_cast e1
    omega
  exact_mod_cast key

/-- **`b·R1 = b·δ(u1−δ) ≤ 0`** (`u1 ≤ δ`, so `δ(u1−δ) ≤ 0`). -/
theorem bR1_le_sq (p : Nat) (hp : 1 ≤ p) :
    Rle (Rmul (logN p hp)
          (Rsub (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
            (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
        zero := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  -- δ·u1 ≤ δ·δ  (u1 ≤ δ)
  have hδu1 : Rle (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)))
      (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
        (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))) :=
    Rmul_le_Rmul_left hδnn (deltaLog_lower p hp)
  exact Rmul_nonpos_left (Rnonneg_logN p hp) (Rle_sub_zero hδu1)

/-- **`R0 = ½δ²u1 − ⅓δ³ ≤ 1/(p(p+1))`** (drop `−⅓δ³ ≤ 0`, `δ² ≤ 1/p²`, `u1 = 1/(p+1)`,
    `p(p+1) ≤ 2p²(p+1)`). -/
theorem R0_le_sq (p : Nat) (hp : 1 ≤ p) :
    Rle (Rsub (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide))
            (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p))))
          (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide))
            (Rmul (Rmul (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp))
                (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))
              (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)))))
        (ofQ (⟨1, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
  have hδnn : Rnonneg (Rsub (logN (p + 1) (Nat.succ_pos p)) (logN p hp)) :=
    Rnonneg_Rsub_of_Rle (logN_mono hp (Nat.le_succ p))
  have hu1nn : Rnonneg (ofQ (⟨1, p + 1⟩ : Q) (Nat.succ_pos p)) :=
    Rnonneg_ofQ (Nat.succ_pos p) (by show (0 : Int) ≤ 1; decide)
  -- drop −⅓δ³: R0 ≤ ½δ²u1
  refine Rle_trans (Rsub_le_self _ (Rnonneg_Rmul (Rnonneg_ofQ (by decide) (by decide))
    (Rnonneg_Rmul (Rnonneg_Rmul_self _) hδnn))) ?_
  -- ½δ²u1 ≤ ½·(1/p²)·(1/(p+1))
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_right hu1nn (dsq_self_le p hp))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Rmul_ofQ_ofQ (a := mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (b := (⟨1, p + 1⟩ : Q))
      (Qmul_den_pos hp hp) (Nat.succ_pos p)))) ?_
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (a := (⟨1, 2⟩ : Q))
    (b := mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p + 1⟩ : Q)) (by decide)
    (Qmul_den_pos (Qmul_den_pos hp hp) (Nat.succ_pos p)))) ?_
  refine Rle_ofQ_ofQ _ (Nat.mul_pos hp (Nat.succ_pos p)) ?_
  show Qle (mul (⟨1, 2⟩ : Q) (mul (mul (⟨1, p⟩ : Q) (⟨1, p⟩ : Q)) (⟨1, p + 1⟩ : Q)))
    (⟨1, p * (p + 1)⟩ : Q)
  simp only [Qle, mul, Int.one_mul, Int.mul_one, Nat.one_mul, Nat.mul_one]
  have key : p * (p + 1) ≤ 2 * (p * p * (p + 1)) := by
    have h2 : p * (p + 1) ≤ (p * p) * (p + 1) :=
      Nat.mul_le_mul_right (p + 1) (Nat.le_mul_of_pos_left p hp)
    omega
  exact_mod_cast key

/-- **The per-step UPPER bound** `sStep p ≤ 2/(p(p+1))` (`sStep_decomp`, `1 + 0 + 1`). -/
theorem sStep_le (p : Nat) (hp : 1 ≤ p) :
    Rle (sStep p hp) (ofQ (⟨2, p * (p + 1)⟩ : Q) (Nat.mul_pos hp (Nat.succ_pos p))) := by
  have hD : 0 < p * (p + 1) := Nat.mul_pos hp (Nat.succ_pos p)
  refine Rle_trans (Rle_of_Req (sStep_decomp p hp)) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (b2C2_le p hp) (bR1_le_sq p hp)) (R0_le_sq p hp)) ?_
  refine Rle_of_Req ?_
  refine Req_trans (Radd_congr (Radd_zero _) (Req_refl _)) ?_
  exact Radd_ofQ_same 1 1 (p * (p + 1)) hD

-- ===========================================================================
-- (S3) Telescoping `Σ sStep ≤ 2/(N+1)` → `γ₂ ≤ hSeq(N) + 2/(N+1)`, then a rational ceiling.
-- ===========================================================================

/-- **Telescoping tail (upper)**: `hSeq(N+k) ≤ hSeq(N) + (2/(N+1) − 2/(N+k+1))` (`N ≥ 1`). -/
theorem hSeq_tele_up (N : Nat) (hN : 1 ≤ N) : ∀ k,
    Rle (hSeq (N + k))
        (Radd (hSeq N) (Rsub (ofQ (⟨2, N + 1⟩ : Q) (Nat.succ_pos N))
            (ofQ (⟨2, N + k + 1⟩ : Q) (Nat.succ_pos (N + k))))) := by
  intro k
  induction k with
  | zero =>
    refine Rle_of_Req ?_
    exact Req_trans (Req_symm (Radd_zero (hSeq N)))
      (Radd_congr (Req_refl _) (Req_symm (Radd_neg (ofQ (⟨2, N + 1⟩ : Q) (Nat.succ_pos N)))))
  | succ k ih =>
    refine Rle_trans (Rle_of_Req (sub_add_cancel_real (hSeq (N + k + 1)) (hSeq (N + k)))) ?_
    refine Rle_trans (Rle_of_Req (Radd_congr (Req_refl _) (hSeq_step_eq (N + k)))) ?_
    refine Rle_trans (Radd_le_add ih (sStep_le (N + k + 1) (Nat.succ_pos (N + k)))) ?_
    refine Rle_of_Req (Req_trans (Radd_assoc (hSeq N) _ _) ?_)
    refine Radd_congr (Req_refl (hSeq N)) ?_
    apply Req_of_seq_Qeq; intro _
    show Qeq (add (add (⟨2, N + 1⟩ : Q) (neg (⟨2, N + k + 1⟩ : Q)))
        (⟨2, (N + k + 1) * ((N + k + 1) + 1)⟩ : Q))
      (add (⟨2, N + 1⟩ : Q) (neg (⟨2, N + (k + 1) + 1⟩ : Q)))
    simp only [Qeq, add, neg, mul]; push_cast; ring_uor

/-- **`hSeq(N+k) ≤ hSeq(N) + 2/(N+1)`** (uniform in `k`, `N ≥ 1`). -/
theorem hSeq_upper_const (N : Nat) (hN : 1 ≤ N) (k : Nat) :
    Rle (hSeq (N + k)) (Radd (hSeq N) (ofQ (⟨2, N + 1⟩ : Q) (Nat.succ_pos N))) := by
  refine Rle_trans (hSeq_tele_up N hN k) (Radd_le_add (Rle_refl _) ?_)
  exact Rsub_le_self _ (Rnonneg_ofQ (Nat.succ_pos (N + k)) (by show (0 : Int) ≤ 2; decide))

/-- **`γ₂ ≤ g2SeqDyadic j + 1/(j+1)`** — the dyadic Cauchy tail `g2_pair_le` carried to the limit. -/
theorem Rgamma2_le_dyadic (j : Nat) :
    Rle Rgamma2 (Radd (g2SeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  apply Rle_of_Rsub_le_all (C := 2)
  intro k
  have htend : Rle (Rsub Rgamma2 (g2SeqDyadic (j + k))) (ofQ (⟨2, k + 1⟩ : Q) (Nat.succ_pos k)) := by
    refine Rle_trans (RTendsTo_to_Rle_lower (Rlim_tendsTo g2SeqDyadic g2SeqDyadic_RReg) (j + k)) ?_
    exact Rle_ofQ_ofQ (Nat.succ_pos (j + k)) (Nat.succ_pos k)
      (by show (2 : Int) * ((k : Int) + 1) ≤ 2 * ((j : Int) + (k : Int) + 1); omega)
  have hanchor : Rle (g2SeqDyadic (j + k))
      (Radd (g2SeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) :=
    Rle_add_of_Rsub_le (g2_pair_le (Nat.le_add_right j k))
  refine Rle_trans (Rle_of_Req (Req_symm (Rsub_split Rgamma2 (g2SeqDyadic (j + k))
    (Radd (g2SeqDyadic j) (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j)))))) ?_
  exact Rle_trans (Radd_le_add htend (Rle_sub_zero hanchor)) (Rle_of_Req (Radd_zero _))

/-- **`g2Seq M = hSeq M + ½·(ln(M+1))²/(M+1)`** — the accelerator correction made explicit. -/
theorem g2Seq_eq_hSeq_add (M : Nat) :
    Req (g2Seq M) (Radd (hSeq M)
        (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (M + 1) (Nat.succ_pos M)))) := by
  unfold hSeq
  refine Req_symm (Req_trans (Radd_assoc (g2Seq M) (Rneg _) _) ?_)
  refine Req_trans (Radd_congr (Req_refl _) (Req_trans (Radd_comm (Rneg _) _) (Radd_neg _))) ?_
  exact Radd_zero (g2Seq M)

/-- **Block square cap at an arbitrary argument** `logN K · logN K ≤ (a+2)²` for `2 ≤ K ≤ 2^{a+2}`. -/
theorem logSq_le_cap (K a : Nat) (hK : 1 ≤ K) (hK2 : 2 ≤ K) (h : K ≤ 2 ^ (a + 2)) :
    Rle (Rmul (logN K hK) (logN K hK))
      (ofQ (⟨((a : Int) + 2) * ((a : Int) + 2), 1⟩ : Q) Nat.one_pos) := by
  obtain ⟨m, rfl⟩ : ∃ m, K = m + 2 := ⟨K - 2, by omega⟩
  exact logSq_le_block a m h

/-- **The correction `½·(ln(M+1))²/(M+1)` at `M = 2^{2j+8}` is `≤ (2j+9)²/(2(M+1))`** (`logSq_le_cap`). -/
theorem corr2_le (j : Nat) :
    Rle (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (2 ^ (2 * j + 8) + 1) (Nat.succ_pos _)))
        (ofQ (⟨(2 * (j : Int) + 9) * (2 * (j : Int) + 9), 2 * (2 ^ (2 * j + 8) + 1)⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.succ_pos _))) := by
  have hbnd : 2 ^ (2 * j + 8) + 1 ≤ 2 ^ ((2 * j + 7) + 2) := by
    have h1 : 2 ^ ((2 * j + 7) + 2) = 2 ^ (2 * j + 8) + 2 ^ (2 * j + 8) := by
      have heq : 2 ^ ((2 * j + 7) + 2) = 2 ^ ((2 * j + 8) + 1) := by
        rw [show (2 * j + 7) + 2 = (2 * j + 8) + 1 from by omega]
      rw [heq, Nat.pow_succ]; omega
    have hpow : 1 ≤ 2 ^ (2 * j + 8) := Nat.pos_pow_of_pos _ (by decide)
    omega
  have hcap := logSq_le_cap (2 ^ (2 * j + 8) + 1) (2 * j + 7) (Nat.succ_pos _)
    (by have h := Nat.pos_pow_of_pos (2 * j + 8) (show 0 < 2 by decide); omega) hbnd
  unfold lnSqOver
  refine Rle_trans (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide))
    (Rmul_le_Rmul_right (Rnonneg_ofQ (Nat.succ_pos _) (by show (0 : Int) ≤ 1; decide)) hcap)) ?_
  refine Rle_trans (Rle_of_Req (Rmul_congr (Req_refl _)
    (Rmul_ofQ_ofQ (a := (⟨((2 * (j : Int) + 7) + 2) * ((2 * (j : Int) + 7) + 2), 1⟩ : Q))
      (b := (⟨1, 2 ^ (2 * j + 8) + 1⟩ : Q)) Nat.one_pos (Nat.succ_pos _)))) ?_
  refine Rle_of_Req (Req_trans (Rmul_ofQ_ofQ (by decide) (Qmul_den_pos Nat.one_pos (Nat.succ_pos _)))
    (ofQ_congr _ _ ?_))
  show Qeq (mul (⟨1, 2⟩ : Q) (mul (⟨((2 * (j : Int) + 7) + 2) * ((2 * (j : Int) + 7) + 2), 1⟩ : Q)
        (⟨1, 2 ^ (2 * j + 8) + 1⟩ : Q)))
    (⟨(2 * (j : Int) + 9) * (2 * (j : Int) + 9), 2 * (2 ^ (2 * j + 8) + 1)⟩ : Q)
  simp only [Qeq, mul]; push_cast; ring_uor

/-- **`γ₂ ≤ hSeq(N) + 2/(N+1) + (2j+9)²/(2(2^{2j+8}+1)) + 1/(j+1)`** — dyadic limit + correction
    extracted + anchor telescoped to `N` + correction capped. -/
theorem Rgamma2_le_hSeq2_up (N j : Nat) (hN : 1 ≤ N) (hNj : N ≤ 2 ^ (2 * j + 8)) :
    Rle Rgamma2
      (Radd (Radd (Radd (hSeq N) (ofQ (⟨2, N + 1⟩ : Q) (Nat.succ_pos N)))
          (ofQ (⟨(2 * (j : Int) + 9) * (2 * (j : Int) + 9), 2 * (2 ^ (2 * j + 8) + 1)⟩ : Q)
            (Nat.mul_pos (by decide) (Nat.succ_pos _))))
        (ofQ (⟨1, j + 1⟩ : Q) (Nat.succ_pos j))) := by
  refine Rle_trans (Rgamma2_le_dyadic j) (Radd_le_add ?_ (Rle_refl _))
  refine Rle_trans (Rle_of_Req (g2Seq_eq_hSeq_add (2 ^ (2 * j + 8)))) ?_
  refine Radd_le_add ?_ (corr2_le j)
  obtain ⟨k, hk⟩ := Nat.le.dest hNj
  rw [← hk]
  exact hSeq_upper_const N hN k

-- ===========================================================================
-- (S4) The rational ceiling `hSeq(N) ≤ gBound2up` and the final `decide`: `γ₂ ≤ 1/40`.
-- ===========================================================================

/-- The accumulated rational upper bound for `Σ_{k=1}^N (ln k)²/k` (round up, denominator `D`). -/
def lnSqSumUp (T D : Nat) : Nat → Q
  | 0 => ⟨0, D⟩
  | (n + 1) =>
      qRoundUp (add (lnSqSumUp T D n) (mul (mul (logBound T D n) (logBound T D n)) ⟨1, n + 1⟩)) D

theorem lnSqSumUp_den_pos (T D : Nat) (hD : 0 < D) : ∀ N, 0 < (lnSqSumUp T D N).den
  | 0 => hD
  | (_ + 1) => hD

/-- **`lnSqSum N ≤ ofQ(lnSqSumUp T D N)`** — partial sum `Σ(ln k)²/k` bounded above (`logNsq_le`). -/
theorem lnSqSum_le (T D : Nat) (hD : 0 < D) :
    ∀ N, Rle (lnSqSum N) (ofQ (lnSqSumUp T D N) (lnSqSumUp_den_pos T D hD N)) := by
  intro N
  induction N with
  | zero =>
    have h0 : Req (ofQ (lnSqSumUp T D 0) (lnSqSumUp_den_pos T D hD 0)) zero :=
      Req_of_seq_Qeq (fun n => by show Qeq (⟨0, D⟩ : Q) ⟨0, 1⟩; simp only [Qeq]; push_cast; ring_uor)
    exact Rle_of_Req (Req_symm h0)
  | succ n ih =>
    have Ld := logBound_den_pos T D hD n
    have hsqd : 0 < (mul (logBound T D n) (logBound T D n)).den := Qmul_den_pos Ld Ld
    have hmuld : 0 < (mul (mul (logBound T D n) (logBound T D n)) (⟨1, n + 1⟩ : Q)).den :=
      Qmul_den_pos hsqd (Nat.succ_pos n)
    have hterm : Rle (lnSqOver (n + 1) (by omega))
        (ofQ (mul (mul (logBound T D n) (logBound T D n)) ⟨1, n + 1⟩) hmuld) := by
      refine Rle_trans (Rmul_le_Rmul_right (c := ofQ (⟨1, n + 1⟩ : Q) (Nat.succ_pos n))
        (Rnonneg_ofQ (Nat.succ_pos n) (by show (0 : Int) ≤ 1; decide)) (logNsq_le T D n hD)) ?_
      exact Rle_of_Req (Rmul_ofQ_ofQ hsqd (Nat.succ_pos n))
    have hadd := add_den_pos (lnSqSumUp_den_pos T D hD n) hmuld
    refine Rle_trans (Radd_le_add ih hterm) ?_
    refine Rle_trans (Rle_of_Req (Radd_ofQ_ofQ (lnSqSumUp_den_pos T D hD n) hmuld)) ?_
    exact Rle_ofQ_ofQ hadd (lnSqSumUp_den_pos T D hD (n + 1))
      (qRoundUp_ge (add (lnSqSumUp T D n)
        (mul (mul (logBound T D n) (logBound T D n)) ⟨1, n + 1⟩)) hadd D)

/-- **`(logLowBound M)²·(1/(M+1)) ≤ (ln(M+1))²/(M+1)`** (`lnSqOver`), the trapezoidal anchor lower. -/
theorem lnSqOver_ge (T D M : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (ofQ (mul (mul (logLowBound T D M) (logLowBound T D M)) (⟨1, M + 1⟩ : Q))
          (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD M) (logLowBound_den_pos T D hD M))
            (Nat.succ_pos M)))
        (lnSqOver (M + 1) (Nat.succ_pos M)) := by
  have LLd := logLowBound_den_pos T D hD M
  have hloglow := logN_ge_logLowBound T D hD hT M
  have hsq : Rle (ofQ (mul (logLowBound T D M) (logLowBound T D M)) (Qmul_den_pos LLd LLd))
      (Rmul (logN (M + 1) (Nat.succ_pos M)) (logN (M + 1) (Nat.succ_pos M))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ LLd LLd)))
      (Rle_trans (Rmul_le_Rmul_right (logLowBound_ofQ_nonneg T D M hD) hloglow)
        (Rmul_le_Rmul_left (Rnonneg_logN (M + 1) (Nat.succ_pos M)) hloglow))
  have hovnn : Rnonneg (ofQ (⟨1, M + 1⟩ : Q) (Nat.succ_pos M)) :=
    Rnonneg_ofQ (Nat.succ_pos M) (by show (0 : Int) ≤ 1; decide)
  refine Rle_trans (Rle_of_Req (Rmul_ofQ_ofQ (Qmul_den_pos LLd LLd) (Nat.succ_pos M))) ?_
  exact Rmul_le_Rmul_right hovnn hsq

/-- The **rational upper bound on `hSeq N`** (`γ₂`, depth `T`, denominator `D`). -/
def gBound2up (T D N : Nat) : Q :=
  Qsub (Qsub (lnSqSumUp T D (N + 1))
      (mul (⟨1, 3⟩ : Q) (mul (mul (logLowBound T D N) (logLowBound T D N)) (logLowBound T D N))))
    (mul (⟨1, 2⟩ : Q) (mul (mul (logLowBound T D N) (logLowBound T D N)) (⟨1, N + 1⟩ : Q)))

theorem gBound2up_den_pos (T D N : Nat) (hD : 0 < D) : 0 < (gBound2up T D N).den :=
  Qsub_den_pos (Qsub_den_pos (lnSqSumUp_den_pos T D hD (N + 1))
      (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD N)
        (logLowBound_den_pos T D hD N)) (logLowBound_den_pos T D hD N))))
    (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos (logLowBound_den_pos T D hD N)
      (logLowBound_den_pos T D hD N)) (Nat.succ_pos N)))

set_option maxHeartbeats 8000000 in
/-- **`hSeq N ≤ ofQ(gBound2up T D N)`** (`T ≤ 21`) — upper `lnSqSum` minus lower `⅓log³`, `½log²/(N+1)`. -/
theorem hSeq2_le_gBound2up (T D N : Nat) (hD : 0 < D) (hT : T ≤ 21) :
    Rle (hSeq N) (ofQ (gBound2up T D N) (gBound2up_den_pos T D N hD)) := by
  have LLd := logLowBound_den_pos T D hD N
  have hcube : Rle (ofQ (mul (⟨1, 3⟩ : Q) (mul (mul (logLowBound T D N) (logLowBound T D N))
          (logLowBound T D N)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos LLd LLd) LLd)))
      (Rmul (ofQ (⟨1, 3⟩ : Q) (by decide)) (logCube (N + 1) (Nat.succ_pos N))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide) (Qmul_den_pos (Qmul_den_pos LLd LLd) LLd))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (logCube_ge T D N hD hT))
  have hsqover : Rle (ofQ (mul (⟨1, 2⟩ : Q) (mul (mul (logLowBound T D N) (logLowBound T D N)) (⟨1, N + 1⟩ : Q)))
        (Qmul_den_pos (by decide) (Qmul_den_pos (Qmul_den_pos LLd LLd) (Nat.succ_pos N))))
      (Rmul (ofQ (⟨1, 2⟩ : Q) (by decide)) (lnSqOver (N + 1) (Nat.succ_pos N))) :=
    Rle_trans (Rle_of_Req (Req_symm (Rmul_ofQ_ofQ (by decide)
        (Qmul_den_pos (Qmul_den_pos LLd LLd) (Nat.succ_pos N)))))
      (Rmul_le_Rmul_left (Rnonneg_ofQ (by decide) (by decide)) (lnSqOver_ge T D N hD hT))
  unfold hSeq g2Seq
  refine Rle_trans (Rsub_le_sub (Rsub_le_sub (lnSqSum_le T D hD (N + 1)) hcube) hsqover) ?_
  exact Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))

/-- **`corr ≤ 1/(j+1)²` at `j = 100`** — `(2·100+9)²·101² ≤ 2(2^{208}+1)` (poly ≤ exp). -/
theorem corr2_weaken100 :
    Rle (ofQ (⟨(2 * (100 : Int) + 9) * (2 * (100 : Int) + 9), 2 * (2 ^ (2 * 100 + 8) + 1)⟩ : Q)
          (Nat.mul_pos (by decide) (Nat.succ_pos _)))
        (ofQ (⟨1, (100 + 1) * (100 + 1)⟩ : Q) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) := by
  refine Rle_ofQ_ofQ (Nat.mul_pos (by decide) (Nat.succ_pos _))
    (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _)) ?_
  simp only [Qle]
  have hpow : (445580881 : Nat) ≤ 2 ^ (2 * 100 + 8) :=
    Nat.le_trans (show (445580881 : Nat) ≤ 2 ^ 29 by decide)
      (Nat.pow_le_pow_right (by decide) (by decide))
  omega

set_option maxRecDepth 40000 in
/-- The numeric heart: `gBound2up 4 10⁶ 200 + 2/201 + 1/101² + 1/101 ≤ 1/40` — one `decide`. -/
theorem gamma2_up_decide :
    Qle (add (add (add (gBound2up 4 1000000 200) (⟨2, 200 + 1⟩ : Q)) (⟨1, (100 + 1) * (100 + 1)⟩ : Q))
        (⟨1, 100 + 1⟩ : Q))
      (⟨1, 40⟩ : Q) := by decide

set_option maxRecDepth 40000 in
/-- **`γ₂ ≤ 1/40`** — the certified LOOSE upper bracket on the second Stieltjes constant, the last
    constant input to `Pos λ₄`.  `γ₂ ≤ hSeq(200) + 2/201 + corr + 1/101` (`Rgamma2_le_hSeq2_up`,
    `j = 100`), `hSeq(200) ≤ gBound2up 4 10⁶ 200`, `corr ≤ 1/101²`, and one big-integer `decide`. -/
theorem Rgamma2_le : Rle Rgamma2 (ofQ (⟨1, 40⟩ : Q) (by decide)) := by
  refine Rle_trans (Rgamma2_le_hSeq2_up 200 100 (by decide)
    (Nat.le_trans (show (200 : Nat) ≤ 2 ^ 8 by decide)
      (Nat.pow_le_pow_right (by decide) (by decide)))) ?_
  refine Rle_trans (Radd_le_add (Radd_le_add (Radd_le_add
    (hSeq2_le_gBound2up 4 1000000 200 (by decide) (by decide)) (Rle_refl _)) corr2_weaken100)
    (Rle_refl _)) ?_
  refine Rle_trans (Rle_of_Req (Req_of_seq_Qeq (fun _ => Qeq_refl _))) ?_
  exact Rle_ofQ_ofQ (add_den_pos (add_den_pos (add_den_pos (gBound2up_den_pos 4 1000000 200 (by decide))
      (by decide)) (Nat.mul_pos (Nat.succ_pos _) (Nat.succ_pos _))) (Nat.succ_pos _)) (by decide)
    gamma2_up_decide

end UOR.Bridge.F1Square.Analysis
