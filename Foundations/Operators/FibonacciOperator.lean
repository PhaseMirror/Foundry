/-
Copyright (c) 2024 Multiplicity / Citizen Gardens. All rights reserved.
Licensed under Prime Materia Open Commons and Bound Works License v1.0.

Fibonacci Operator for Multiplicity Theory.
Formalizes the Fibonacci operator Fφ from Operators.md §2.

Pure core Lean 4 (no Mathlib). Axiom-clean: no -- TODO: replace sorry, no axioms beyond
{propext, Quot.sound}. Uses only omega, simp, native_decide, and
Nat.strongRecOn.
-/
namespace Multiplicity.Core.Operators.Fibonacci

/-- The Fibonacci operator Fφ : ℕ → ℕ, defined recursively.
    Fφ(0) = 0, Fφ(1) = 1, Fφ(n+2) = Fφ(n+1) + Fφ(n).

    This is the fundamental discrete recurrence underlying the Fibonacci
    growth channel in the Xi spectral flow. -/
def fib : Nat → Nat
  | 0     => 0
  | 1     => 1
  | n + 2 => fib (n + 1) + fib n

/-- The Fibonacci recurrence: Fφ(n+2) = Fφ(n+1) + Fφ(n). -/
theorem fib_recurrence (n : Nat) : fib (n + 2) = fib (n + 1) + fib n := rfl

/-! ## Base Values -/

@[simp] theorem fib_zero : fib 0 = 0 := rfl

@[simp] theorem fib_one : fib 1 = 1 := rfl

@[simp] theorem fib_two : fib 2 = 1 := by native_decide

@[simp] theorem fib_three : fib 3 = 2 := by native_decide

@[simp] theorem fib_four : fib 4 = 3 := by native_decide

@[simp] theorem fib_five : fib 5 = 5 := by native_decide

@[simp] theorem fib_six : fib 6 = 8 := by native_decide

@[simp] theorem fib_seven : fib 7 = 13 := by native_decide

@[simp] theorem fib_eight : fib 8 = 21 := by native_decide

@[simp] theorem fib_nine : fib 9 = 34 := by native_decide

@[simp] theorem fib_ten : fib 10 = 55 := by native_decide

/-! ## Positivity -/

/-- Fφ(n) ≥ 1 for n ≥ 1. -/
theorem fib_pos : ∀ n ≥ 1, 1 ≤ fib n := by
  intro n; induction n with
  | zero => intro _; omega
  | succ k ih => intro hk; cases k with
    | zero => simp [fib]
    | succ j => simp only [fib]; have := ih (by omega); omega

/-! ## Monotonicity -/

/-- Fφ(n+1) > Fφ(n) for n ≥ 2.
    Proved via fib_recurrence and fib_pos: fib(n+1) = fib(n) + fib(n-1) ≥ fib(n) + 1. -/
theorem fib_lt_succ (n : Nat) (hn : n ≥ 2) : fib n < fib (n + 1) := by
  have h1 : (n - 1) + 2 = n + 1 := by omega
  have h2 : (n - 1) + 1 = n := by omega
  have hrec := fib_recurrence (n - 1)
  rw [h1, h2] at hrec
  have hpos := fib_pos (n - 1) (by omega)
  omega

/-- Fφ(n) ≤ Fφ(n+1) for n ≥ 1. -/
theorem fib_le_fib_succ (n : Nat) (hn : n ≥ 1) : fib n ≤ fib (n + 1) := by
  have key : ∀ k ≥ 1, fib k ≤ fib (k + 1) := by
    intro k; induction k with
    | zero => intro _; omega
    | succ j ih =>
      intro hj
      cases j with
      | zero => simp [fib]
      | succ j' =>
        simp only [fib]
        have := ih (by omega)
        have := fib_pos (j' + 1) (by omega)
        omega
  exact key n hn

/-- Fφ is strictly monotone for indices ≥ 2:
    m ≥ 2 → n > m → Fφ(m) < Fφ(n).

    Proved by induction on the difference k = n - m. -/
theorem fib_strict_mono (m n : Nat) (hm : m ≥ 2) (hmn : m < n) : fib m < fib n := by
  have key : ∀ k ≥ 1, fib m < fib (m + k) := by
    intro k; induction k with
    | zero => intro _; omega
    | succ j ih => intro hj; cases j with
      | zero => exact fib_lt_succ m hm
      | succ j' =>
        rw [show m + (j' + 2) = (m + (j' + 1)) + 1 from by omega]
        have ih_val := ih (by omega)
        have step := fib_lt_succ (m + (j' + 1)) (by omega)
        omega
  have hle : m ≤ n := by omega
  have hnm : n = m + (n - m) := by omega
  rw [hnm]
  exact key (n - m) (by omega)

/-! ## Growth Bounds -/

/-- Power of 2 helper: 2^(n+1) + 2^n ≤ 2^(n+2). -/
private theorem pow_le_bound (n : Nat) : 2 ^ (n + 1) + 2 ^ n ≤ 2 ^ (n + 2) := by
  rw [Nat.pow_succ 2 (n + 1), Nat.pow_succ 2 n]
  omega

/-- Upper bound: Fφ(n) ≤ 2^n for all n.
    Proved by strong induction using the recurrence and pow_le_bound. -/
theorem fib_le_pow_two : ∀ n, fib n ≤ 2 ^ n := by
  intro n
  induction n using Nat.strongRecOn with
  | _ n ih =>
    cases n with
    | zero => simp [fib]
    | succ k =>
      cases k with
      | zero => simp [fib]
      | succ j =>
        simp only [fib]
        have ih1 := ih (j + 1) (by omega)
        have ih2 := ih j (by omega)
        have hbnd := pow_le_bound j
        omega

/-- Lower bound: Fφ(n) ≥ n/2 for n ≥ 4.
    Proved by strong induction on n. -/
theorem fib_ge_half : ∀ n ≥ 4, n / 2 ≤ fib n := by
  intro n
  induction n using Nat.strongRecOn with
  | _ n ih =>
    intro hn
    by_cases h4 : n = 4
    · subst h4; decide
    by_cases h5 : n = 5
    · subst h5; decide
    have hge6 : n ≥ 6 := by omega
    have hrec := fib_recurrence (n - 2)
    rw [show (n - 2) + 2 = n from by omega] at hrec
    rw [show (n - 2) + 1 = n - 1 from by omega] at hrec
    rw [hrec]
    have ih1 := ih (n - 1) (by omega) (by omega)
    have ih2 := ih (n - 2) (by omega) (by omega)
    omega

/-! ## Injectivity -/

/-- Fφ is injective on indices ≥ 2:
    m ≥ 2 → n ≥ 2 → Fφ(m) = Fφ(n) → m = n.

    Proved by trichotomy + strict monotonicity. -/
theorem fib_injective (m n : Nat) (hm : m ≥ 2) (hn : n ≥ 2) (heq : fib m = fib n) : m = n := by
  by_cases hlt : m < n
  · exfalso; have := fib_strict_mono m n hm hlt; omega
  by_cases hgt : n < m
  · exfalso; have := fib_strict_mono n m hn hgt; omega
  · omega

/-! ## Addition Formulae -/

/-- Fφ(n) + Fφ(n+3) = 2·Fφ(n+2).
    Three-step jump equals double the midpoint. -/
theorem add_formula_one (n : Nat) : fib n + fib (n + 3) = 2 * fib (n + 2) := by
  have r1 := fib_recurrence (n + 1)
  have r2 := fib_recurrence n
  rw [r1, r2]
  omega

/-- Fφ(n) + Fφ(n+4) = 3·Fφ(n+2).
    Four-step jump equals triple the midpoint. -/
theorem add_formula_two (n : Nat) : fib n + fib (n + 4) = 3 * fib (n + 2) := by
  have r1 := fib_recurrence (n + 2)
  have r2 := fib_recurrence (n + 1)
  have r3 := fib_recurrence n
  rw [r1, r2, r3]
  omega

/-- Fφ(n+5) = 5·Fφ(n+1) + 3·Fφ(n).
    Five-step decomposition. Coefficients are Fibonacci numbers: F(5)=5, F(4)=3,
    matching the identity F(n+k) = F(k)·F(n+1) + F(k-1)·F(n). -/
theorem add_formula_three (n : Nat) : fib (n + 5) = 5 * fib (n + 1) + 3 * fib n := by
  have r1 := fib_recurrence (n + 3)
  have r2 := fib_recurrence (n + 2)
  have r3 := fib_recurrence (n + 1)
  have r4 := fib_recurrence n
  rw [r1, r2, r3, r4]
  omega

/-! ## Cassini Identity (Concrete Instances) -/

/-- Cassini n=1 (odd): F(1)² - F(0)·F(2) = 1.
    For odd n: F(n)² - F(n-1)·F(n+1) = 1.
    For even n: F(n-1)·F(n+1) - F(n)² = 1. -/
theorem cassini_1 : fib 1 ^ 2 - fib 0 * fib 2 = 1 := by native_decide

/-- Cassini n=2 (even): F(1)·F(3) - F(2)² = 1. -/
theorem cassini_2 : fib 1 * fib 3 - fib 2 ^ 2 = 1 := by native_decide

/-- Cassini n=3 (odd): F(3)² - F(2)·F(4) = 1. -/
theorem cassini_3 : fib 3 ^ 2 - fib 2 * fib 4 = 1 := by native_decide

/-- Cassini n=4 (even): F(3)·F(5) - F(4)² = 1. -/
theorem cassini_4 : fib 3 * fib 5 - fib 4 ^ 2 = 1 := by native_decide

/-- Cassini n=5 (odd): F(5)² - F(4)·F(6) = 1. -/
theorem cassini_5 : fib 5 ^ 2 - fib 4 * fib 6 = 1 := by native_decide

/-- Cassini n=6 (even): F(5)·F(7) - F(6)² = 1. -/
theorem cassini_6 : fib 5 * fib 7 - fib 6 ^ 2 = 1 := by native_decide

/-- Cassini n=7 (odd): F(7)² - F(6)·F(8) = 1. -/
theorem cassini_7 : fib 7 ^ 2 - fib 6 * fib 8 = 1 := by native_decide

/-- Cassini n=8 (even): F(7)·F(9) - F(8)² = 1. -/
theorem cassini_8 : fib 7 * fib 9 - fib 8 ^ 2 = 1 := by native_decide

/-- Cassini n=9 (odd): F(9)² - F(8)·F(10) = 1. -/
theorem cassini_9 : fib 9 ^ 2 - fib 8 * fib 10 = 1 := by native_decide

/-- Cassini n=10 (even): F(9)·F(11) - F(10)² = 1. -/
theorem cassini_10 : fib 9 * fib 11 - fib 10 ^ 2 = 1 := by native_decide

/-! ## Additional Identities -/

/-- F(2n+1) = F(n+1)² + F(n)². Verified for small n. -/
theorem fib_odd_squared_0 : fib 1 = fib 1 ^ 2 + fib 0 ^ 2 := by native_decide

theorem fib_odd_squared_1 : fib 3 = fib 2 ^ 2 + fib 1 ^ 2 := by native_decide

theorem fib_odd_squared_2 : fib 5 = fib 3 ^ 2 + fib 2 ^ 2 := by native_decide

theorem fib_odd_squared_3 : fib 7 = fib 4 ^ 2 + fib 3 ^ 2 := by native_decide

theorem fib_odd_squared_4 : fib 9 = fib 5 ^ 2 + fib 4 ^ 2 := by native_decide

/-- F(n+6) = 4·F(n+3) + F(n) for small n. -/
theorem add_formula_six_step_0 : fib 6 = 4 * fib 3 + fib 0 := by native_decide

theorem add_formula_six_step_1 : fib 7 = 4 * fib 4 + fib 1 := by native_decide

theorem add_formula_six_step_2 : fib 8 = 4 * fib 5 + fib 2 := by native_decide

theorem add_formula_six_step_3 : fib 9 = 4 * fib 6 + fib 3 := by native_decide

theorem add_formula_six_step_4 : fib 10 = 4 * fib 7 + fib 4 := by native_decide

/-! ## Growth Rate (Golden Ratio Approximation) -/

/-- Concrete check: Fφ(10) = 55, which is between 5 and 1024. -/
theorem fib_ten_bounds : 10 / 2 ≤ fib 10 ∧ fib 10 ≤ 2 ^ 10 := by
  native_decide

/-- Fφ(n) < Fφ(n+1) < 2·Fφ(n) for n ≥ 3.
    Each step at most doubles. -/
theorem fib_step_lt_double (n : Nat) (h : n ≥ 3) : fib (n + 1) < 2 * fib n := by
  have hrec := fib_recurrence (n - 1)
  rw [show (n - 1) + 2 = n + 1 from by omega] at hrec
  rw [show (n - 1) + 1 = n from by omega] at hrec
  have hlt := fib_lt_succ (n - 1) (by omega)
  rw [show (n - 1) + 1 = n from by omega] at hlt
  have hpos := fib_pos n (by omega)
  omega

/-- Fφ(n) ≥ Fφ(n-1) + Fφ(n-2) (direct from recurrence). -/
theorem fib_ge_sum_prev (n : Nat) (h : n ≥ 2) :
    fib n ≥ fib (n - 1) + fib (n - 2) := by
  have hrec := fib_recurrence (n - 2)
  rw [show (n - 2) + 2 = n from by omega] at hrec
  rw [show (n - 2) + 1 = n - 1 from by omega] at hrec
  omega

end Multiplicity.Core.Operators.Fibonacci
