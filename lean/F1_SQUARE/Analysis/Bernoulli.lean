/-
F1 square — the **Bernoulli numbers** `Bₙ` as exact rationals (the v0.16.0 foundation for the
Euler–Maclaurin summation formula that continues `ζ` into the critical strip).

`Bₙ` is defined by the standard recurrence (the convention with `B₁ = −1/2`, the one Euler–Maclaurin
uses): `B₀ = 1` and, for `n ≥ 1`,

    Σ_{j=0}^{n} C(n+1, j) · Bⱼ = 0      ⟹      Bₙ = −1/(n+1) · Σ_{j=0}^{n−1} C(n+1, j) · Bⱼ.

We realize this as a `Nat → Nat → Q` table `bernTable n` that is correct on `[0, n]` (each row extends
the previous by one new entry computed from the recurrence), so the recursion is structural in the row
index and `bernoulli n := bernTable n n`. Everything is exact rational arithmetic, so the values hold by
reduction: `B₀ = 1`, `B₁ = −1/2`, `B₂ = 1/6`, `B₃ = 0`, `B₄ = −1/30`, `B₆ = 1/42`.

Pure Lean 4, no Mathlib, no `sorry`/`native_decide`, choice-free.
-/

import F1Square.Analysis.Binomial

namespace UOR.Bridge.F1Square.Analysis

/-- `bernTable n k` — a table of Bernoulli numbers correct for `k ≤ n`. Row `n+1` reuses row `n` for
    `k ≤ n` and computes the one new entry `B_{n+1}` from the recurrence
    `B_{n+1} = −1/(n+2) · Σ_{j=0}^{n} C(n+2, j)·Bⱼ`. -/
def bernTable : Nat → Nat → Q
  | 0, _ => ⟨1, 1⟩
  | (n + 1), k =>
    if k ≤ n then bernTable n k
    else mul ⟨-1, n + 2⟩ (Fsum (fun j => mul ⟨(choose (n + 2) j : Int), 1⟩ (bernTable n j)) n)

/-- The **`n`-th Bernoulli number** `Bₙ` (the `B₁ = −1/2` convention). -/
def bernoulli (n : Nat) : Q := bernTable n n

/-- Every table entry has positive denominator. -/
theorem bernTable_den_pos : ∀ (n k : Nat), 0 < (bernTable n k).den := by
  intro n
  induction n with
  | zero => intro k; exact Nat.one_pos
  | succ n ih =>
    intro k
    simp only [bernTable]
    split
    · exact ih k
    · exact Qmul_den_pos (by show (0:Nat) < n + 2; omega)
        (Fsum_den_pos (fun j => Qmul_den_pos Nat.one_pos (ih j)) n)

/-- `Bₙ` has positive denominator (so it is a genuine rational). -/
theorem bernoulli_den_pos (n : Nat) : 0 < (bernoulli n).den := bernTable_den_pos n n

-- The defining values (exact, by reduction).

/-- `B₀ = 1`. -/
theorem bernoulli_zero : Qeq (bernoulli 0) ⟨1, 1⟩ := by decide

/-- `B₁ = −1/2`. -/
theorem bernoulli_one : Qeq (bernoulli 1) ⟨-1, 2⟩ := by decide

/-- `B₂ = 1/6`. -/
theorem bernoulli_two : Qeq (bernoulli 2) ⟨1, 6⟩ := by decide

/-- `B₃ = 0` (the odd Bernoulli numbers vanish past `B₁`). -/
theorem bernoulli_three : Qeq (bernoulli 3) ⟨0, 1⟩ := by decide

/-- `B₄ = −1/30`. -/
theorem bernoulli_four : Qeq (bernoulli 4) ⟨-1, 30⟩ := by decide

/-- `B₅ = 0`. -/
theorem bernoulli_five : Qeq (bernoulli 5) ⟨0, 1⟩ := by decide

/-- `B₆ = 1/42`. -/
theorem bernoulli_six : Qeq (bernoulli 6) ⟨1, 42⟩ := by decide

end UOR.Bridge.F1Square.Analysis
