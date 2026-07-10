/-
F1 square — v0.19.0 (the genuine-pairing arc), substrate brick P2a: **finite sums of
constructive reals** — the assembly substrate for the Weil quadratic form.

`RsumN F N = Σ_{i<N} F i` by left-fold `Radd` (each step Bishop-reindexes internally, so
no regularity is owed), with the three transport lemmas every quadratic-form assembly
needs: congruence (`≈` termwise ⟹ `≈` of sums), non-negativity (termwise `≥ 0` ⟹ sum
`≥ 0` — the PSD direction), and monotonicity (termwise `≤` ⟹ sums `≤`).

Pure Lean 4 core, no Mathlib, no `sorry`, choice-free; audited by `scripts/honesty_audit.sh`.
-/

import F1Square.Analysis.Pi

namespace UOR.Bridge.F1Square.Analysis

/-- `Σ_{i<N} F i` over the constructive reals (left fold by `Radd`). -/
def RsumN (F : Nat → Real) : Nat → Real
  | 0 => zero
  | (n + 1) => Radd (RsumN F n) (F n)

/-- Sums respect `≈` termwise. -/
theorem RsumN_congr {F G : Nat → Real} (N : Nat)
    (h : ∀ i : Nat, i < N → Req (F i) (G i)) : Req (RsumN F N) (RsumN G N) := by
  induction N with
  | zero => exact Req_refl zero
  | succ n ih =>
    exact Radd_congr (ih (fun i hi => h i (Nat.lt_succ_of_lt hi))) (h n (Nat.lt_succ_self n))

/-- Termwise non-negative sums are non-negative (the PSD direction of the assembly). -/
theorem Rnonneg_RsumN {F : Nat → Real} (N : Nat)
    (h : ∀ i : Nat, i < N → Rnonneg (F i)) : Rnonneg (RsumN F N) := by
  induction N with
  | zero => exact Rnonneg_zero
  | succ n ih =>
    exact Rnonneg_Radd (ih (fun i hi => h i (Nat.lt_succ_of_lt hi))) (h n (Nat.lt_succ_self n))

/-- Sums are monotone termwise. -/
theorem RsumN_le {F G : Nat → Real} (N : Nat)
    (h : ∀ i : Nat, i < N → Rle (F i) (G i)) : Rle (RsumN F N) (RsumN G N) := by
  induction N with
  | zero => exact Rle_refl zero
  | succ n ih =>
    exact Radd_le_add (ih (fun i hi => h i (Nat.lt_succ_of_lt hi))) (h n (Nat.lt_succ_self n))

end UOR.Bridge.F1Square.Analysis
