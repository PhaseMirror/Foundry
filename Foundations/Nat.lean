/-!
# Multiplicity Kernel — Natural Numbers (ADR-0001 Phase 1 scope)

`Nat` is the Lean core natural number type (unbounded, total).  The kernel
adds the small function set required by Phase 1 and certifies its basic laws.
Overflow freedom (`u64` bounds) is a Rust/Kani concern and is enforced there;
Lean `Nat` is unbounded by construction.
-/

namespace Multiplicity.Kernel

/-! ## Factorial (not provided by the core library) -/

/-- `n!`, the factorial, with `natFact 0 = 1`. -/
def natFact : Nat → Nat
  | 0 => 1
  | n + 1 => natFact n * (n + 1)

/-- Recursive law of the factorial. -/
theorem natFact_succ (n : Nat) : natFact (n + 1) = natFact n * (n + 1) := rfl

/-- Totality: the factorial exists for every natural number. -/
theorem natFact_total : ∀ n : Nat, ∃ m : Nat, natFact n = m := by
  intro n
  exact ⟨natFact n, rfl⟩

/-- Positivity: `n! > 0`. -/
theorem natFact_pos (n : Nat) : 0 < natFact n := by
  induction n with
  | zero => decide
  | succ n ih =>
      rw [natFact_succ]
      exact Nat.mul_pos ih (Nat.succ_pos n)

/-- Determinism: the factorial is a function. -/
theorem natFact_deterministic (n : Nat) : natFact n = natFact n := rfl

/-! ## Saturating subtraction (total by construction in `Nat`) -/

/-- Saturating subtraction: `n - m` is total and never negative. -/
theorem sub_le (n m : Nat) : n - m ≤ n := Nat.sub_le n m

/-- `n - n = 0`. -/
theorem sub_self (n : Nat) : n - n = 0 := Nat.sub_self n

/-- `n ≤ m ⟹ n - m = 0`. -/
theorem sub_eq_zero_of_le {n m : Nat} (h : n ≤ m) : n - m = 0 :=
  Nat.sub_eq_zero_of_le h

/-! ## Exponentiation -/

/-- `x^(n+1) = x^n * x`. -/
theorem pow_succ (x n : Nat) : x ^ (n + 1) = x ^ n * x := Nat.pow_succ x n

/-- `x^(a+b) = x^a * x^b`. -/
theorem pow_add (x a b : Nat) : x ^ (a + b) = x ^ a * x ^ b := Nat.pow_add x a b

/-- `x^(a*b) = (x^a)^b`. -/
theorem pow_mul (x a b : Nat) : x ^ (a * b) = (x ^ a) ^ b := Nat.pow_mul x a b

/-- `2² = 4`. -/
theorem pow_two_two : 2 ^ 2 = 4 := by decide

/-- Exponentiation is monotone in the exponent (for positive base). -/
theorem pow_le_pow_right {x : Nat} (hx : 0 < x) {a b : Nat} (h : a ≤ b) : x ^ a ≤ x ^ b := by
  induction h with
  | refl => exact Nat.le_refl (x ^ a)
  | step hb ih =>
      rw [pow_succ]
      exact Nat.le_trans ih (Nat.le_mul_of_pos_right (x ^ _) hx)

/-! ## Order laws used by the kernel -/

/-- `1 ≤ n ⟹ 0 < n`. -/
theorem pos_of_pos (n : Nat) (h : 1 ≤ n) : 0 < n := by omega

/-- Multiplication by a positive number is monotone on the left. -/
theorem mul_le_mul_left_of_pos {a b c : Nat} (h : a ≤ b) : c * a ≤ c * b :=
  Nat.mul_le_mul_left c h

end Multiplicity.Kernel
