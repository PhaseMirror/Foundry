/-
F1 square — the first transcendental: Euler's number `e` via the exponential series (the v0.8.0
analysis brick), with a rigorous rational error bound.

Standing on completeness (v0.7.0): a convergent series is a regular sequence of its partial sums, so
its value is a constructive real. Here we exhibit `e = Σ 1/i!` directly. The partial sums are
*rational*, so the (reindexed) partial-sum sequence is literally a regular sequence of rationals — a
`Real` — no real-number limit needed; completeness is what would handle genuinely real arguments.

The rigorous error bound is the telescoping observation that `U(n) := S(n) + 2/(n+1)!` is
**decreasing** (`2/(n+2)! ≤ 1/(n+1)!`), so for `a ≤ b`, `S(b) − S(a) ≤ 2/(a+1)!` — a fully rational,
explicitly computable tail bound. Reindexing `n ↦ S(n+1)` makes `2/(n+2)! ≤ 1/(n+1)`, i.e. the
sequence is regular. `e` is then a genuine constructive real, and `Pos e` is witnessed at index 0
(`e ≈ 2 + …`).

Lean core has no `Nat.factorial` (it is Mathlib), so factorial is built from scratch.

Pure Lean 4, no Mathlib, no `sorry`.
-/

import F1Square.Analysis.Complete

namespace UOR.Bridge.F1Square.Analysis

/-- Factorial, from scratch (core has no `Nat.factorial`). -/
def fct : Nat → Nat
  | 0 => 1
  | (n + 1) => (n + 1) * fct n

theorem fct_succ (n : Nat) : fct (n + 1) = (n + 1) * fct n := rfl

theorem fct_pos : ∀ n, 0 < fct n
  | 0 => by decide
  | (n + 1) => Nat.mul_pos (by omega) (fct_pos n)

/-- `n ≤ n!`. -/
theorem self_le_fct : ∀ n, n ≤ fct n
  | 0 => by decide
  | (n + 1) => by
      rw [fct_succ]
      exact Nat.le_mul_of_pos_right (n + 1) (fct_pos n)

/-- The key factorial step: `2·(k+1)! ≤ (k+2)!` (since `k+2 ≥ 2`). -/
theorem two_mul_fct_le (k : Nat) : 2 * fct (k + 1) ≤ fct (k + 1 + 1) := by
  rw [fct_succ (k + 1)]
  exact Nat.mul_le_mul (by omega) (Nat.le_refl _)

/-- The partial sums `S(N) = Σ_{i=0}^N 1/i!` of the exponential series at `1`. -/
def eSum : Nat → Q
  | 0 => ⟨1, 1⟩
  | (n + 1) => add (eSum n) ⟨1, fct (n + 1)⟩

theorem eSum_den_pos : ∀ N, 0 < (eSum N).den
  | 0 => by decide
  | (n + 1) => add_den_pos (eSum_den_pos n) (fct_pos (n + 1))

/-- The partial sums are monotone (one step). -/
theorem eSum_step (n : Nat) : Qle (eSum n) (eSum (n + 1)) :=
  Qle_self_add (Int.ofNat_nonneg _)

/-- The partial sums are monotone. -/
theorem eSum_le {a b : Nat} (hab : a ≤ b) : Qle (eSum a) (eSum b) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (eSum_den_pos _) ih (eSum_step _)

/-- The error-bound step: `1/(k+1)! + 2/(k+2)! ≤ 2/(k+1)!`. -/
theorem efac_step (k : Nat) :
    Qle (add (⟨1, fct (k + 1)⟩ : Q) ⟨2, fct (k + 1 + 1)⟩) ⟨2, fct (k + 1)⟩ := by
  have h1 : Qle (⟨2, fct (k + 1 + 1)⟩ : Q) ⟨1, fct (k + 1)⟩ := by
    show (2 : Int) * ((fct (k + 1)) : Int) ≤ 1 * ((fct (k + 1 + 1)) : Int)
    have hnat : 2 * fct (k + 1) ≤ fct (k + 1 + 1) := two_mul_fct_le k
    have : ((2 * fct (k + 1) : Nat) : Int) ≤ ((fct (k + 1 + 1) : Nat) : Int) := by exact_mod_cast hnat
    push_cast at this; omega
  exact Qle_trans (add_den_pos (fct_pos _) (fct_pos _))
    (Qadd_le_add (Qle_refl _) h1)
    (Qeq_le (by simp only [Qeq, add]; push_cast; ring_uor))

/-- The telescoping upper sequence `U(n) := S(n) + 2/(n+1)!`. -/
def eU (n : Nat) : Q := add (eSum n) ⟨2, fct (n + 1)⟩

theorem eU_den_pos (n : Nat) : 0 < (eU n).den := add_den_pos (eSum_den_pos n) (fct_pos (n + 1))

/-- `U` is decreasing (one step) — the heart of the rigorous bound. -/
theorem eU_step (n : Nat) : Qle (eU (n + 1)) (eU n) := by
  have hassoc : Qeq (eU (n + 1))
      (add (eSum n) (add (⟨1, fct (n + 1)⟩ : Q) ⟨2, fct (n + 1 + 1)⟩)) := by
    simp only [eU, eSum, Qeq, add]; push_cast; ring_uor
  refine Qle_congr_left
    (add_den_pos (eSum_den_pos n) (add_den_pos (fct_pos _) (fct_pos _)))
    (Qeq_symm hassoc) ?_
  exact Qadd_le_add (Qle_refl (eSum n)) (efac_step n)

/-- `U` is decreasing. -/
theorem eU_le {a b : Nat} (hab : a ≤ b) : Qle (eU b) (eU a) := by
  induction hab with
  | refl => exact Qle_refl _
  | step _ ih => exact Qle_trans (eU_den_pos _) (eU_step _) ih

/-- Subtracting a fixed rational is monotone. -/
theorem Qsub_le_sub {x y z : Q} (h : Qle x y) : Qle (Qsub x z) (Qsub y z) :=
  Qadd_le_add h (Qle_refl (neg z))

/-- `(a + b) − a = b` (value). -/
theorem Qsub_add_cancel (a b : Q) : Qeq (Qsub (add a b) a) b := by
  simp only [Qeq, Qsub, add, neg]; push_cast; ring_uor

/-- **The rigorous error bound**: for `a ≤ b`, the partial-sum gap `S(b) − S(a) ≤ 2/(a+1)!`. -/
theorem ediff_bound {a b : Nat} (hab : a ≤ b) :
    Qle (Qsub (eSum b) (eSum a)) ⟨2, fct (a + 1)⟩ := by
  -- S(b) ≤ S(b) + 2/(b+1)! = U(b) ≤ U(a) = S(a) + 2/(a+1)!
  have hb : Qle (eSum b) (add (eSum a) ⟨2, fct (a + 1)⟩) :=
    Qle_trans (eU_den_pos b) (Qle_self_add (Int.ofNat_nonneg _)) (eU_le hab)
  -- subtract S(a) from both sides
  have hsub := Qsub_le_sub (z := eSum a) hb
  refine Qle_trans
    (Qsub_den_pos (add_den_pos (eSum_den_pos a) (fct_pos _)) (eSum_den_pos a)) hsub ?_
  exact Qeq_le (Qsub_add_cancel (eSum a) ⟨2, fct (a + 1)⟩)

/-- For a non-negative rational, `|y| ≤ c` reduces to `y ≤ c`. -/
theorem Qabs_le_of_nonneg {y c : Q} (hy : 0 ≤ y.num) (h : Qle y c) : Qle (Qabs y) c := by
  unfold Qle Qabs at *
  have he : (y.num.natAbs : Int) = y.num := by omega
  rw [he]; exact h

/-- The gap as an absolute value (the diff is non-negative, so `|·|` is the diff). -/
theorem eabs_bound {a b : Nat} (hab : a ≤ b) :
    Qle (Qabs (Qsub (eSum b) (eSum a))) ⟨2, fct (a + 1)⟩ := by
  have hnn : 0 ≤ (Qsub (eSum b) (eSum a)).num := by
    have h := eSum_le hab
    unfold Qle at h
    simp only [Qsub, add, neg]
    rw [Int.neg_mul]; omega
  exact Qabs_le_of_nonneg hnn (ediff_bound hab)

/-- Reindex bound: `2/(n+2)! ≤ 1/(n+1)` (so the reindexed sequence is regular). -/
theorem efct_reindex (n : Nat) : Qle (⟨2, fct (n + 1 + 1)⟩ : Q) ⟨1, n + 1⟩ := by
  show (2 : Int) * ((n + 1 : Nat) : Int) ≤ 1 * ((fct (n + 1 + 1)) : Int)
  -- 2(n+1) ≤ 2·(n+1)! ≤ (n+2)!
  have h1 : 2 * (n + 1) ≤ 2 * fct (n + 1) := Nat.mul_le_mul (Nat.le_refl 2) (self_le_fct (n + 1))
  have h2 : 2 * fct (n + 1) ≤ fct (n + 1 + 1) := two_mul_fct_le n
  have hnat : 2 * (n + 1) ≤ fct (n + 1 + 1) := Nat.le_trans h1 h2
  have : ((2 * (n + 1) : Nat) : Int) ≤ ((fct (n + 1 + 1) : Nat) : Int) := by exact_mod_cast hnat
  push_cast at this; omega

/-- The reindexed partial-sum sequence `n ↦ S(n+1)` — the regular ℚ-sequence whose value is `e`. -/
def eSeq (n : Nat) : Q := eSum (n + 1)

/-- The reindexed partial sums are a regular sequence (so they define a constructive real):
    `|S(m+1) − S(n+1)| ≤ 2/(min+2)! ≤ 1/(min+1) ≤ 1/(m+1) + 1/(n+1)`. -/
theorem eSeq_regular : IsRegular eSeq := by
  intro m n
  simp only [eSeq]
  rcases Nat.le_total m n with hmn | hnm
  · refine Qle_trans (Qbound_den_pos m) ?_ (Qle_self_add (Int.ofNat_nonneg _))
    rw [Qabs_Qsub_comm]
    exact Qle_trans (fct_pos (m + 1 + 1)) (eabs_bound (by omega)) (efct_reindex m)
  · refine Qle_trans (Qbound_den_pos n) ?_ (Qle_add_self (Int.ofNat_nonneg _))
    exact Qle_trans (fct_pos (n + 1 + 1)) (eabs_bound (by omega)) (efct_reindex n)

/-- **Euler's number `e`** as a constructive real: the value of the exponential series `Σ 1/i!`. -/
def e : Real := ⟨eSeq, eSeq_regular, fun n => eSum_den_pos (n + 1)⟩

/-- `e`'s `n`-th rational approximant is the `(n+1)`-th partial sum (definitional). -/
theorem e_seq (n : Nat) : e.seq n = eSum (n + 1) := rfl

/-- `e` is positive (witnessed at index 0: its `0`-th approximant is `2 = 1+1 > 1`). -/
theorem e_pos : Pos e := ⟨0, by decide⟩

end UOR.Bridge.F1Square.Analysis
