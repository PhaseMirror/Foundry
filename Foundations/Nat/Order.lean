import Foundations.Peano.Peano

namespace Foundations.NatOrder

open Foundations.Peano

/-! ## Order Laws -/

/-- `a < b` implies `a ≤ b`. -/
theorem le_of_lt {a b : Nat} (h : a < b) : a ≤ b := Nat.le_of_lt h

/-- `a ≤ b` and `b < a` is impossible. -/
theorem not_le_of_lt {a b : Nat} (h : a < b) : ¬ (b ≤ a) := Nat.not_le.mpr h

/-- Order is antisymmetric. -/
theorem le_antisymm {m n : Nat} (h1 : m ≤ n) (h2 : n ≤ m) : m = n :=
  Nat.le_antisymm h1 h2

/-- Trichotomy: exactly one of `m < n`, `m = n`, `n < m` holds. -/
theorem trichotomy (m n : Nat) : m < n ∨ m = n ∨ n < m :=
  Nat.lt_trichotomy m n

/-! ## Max and Min -/

/-- `max m n ≥ m`. -/
theorem le_max_left (m n : Nat) : m ≤ Nat.max m n := Nat.le_max_left m n

/-- `max m n ≥ n`. -/
theorem le_max_right (m n : Nat) : n ≤ Nat.max m n := Nat.le_max_right m n

/-- `min m n ≤ m`. -/
theorem min_le_left (m n : Nat) : Nat.min m n ≤ m := Nat.min_le_left m n

/-- `min m n ≤ n`. -/
theorem min_le_right (m n : Nat) : Nat.min m n ≤ n := Nat.min_le_right m n

/-! ## Monotonicity of Addition -/

/-- Addition is monotone on the left. -/
theorem add_le_add_left {m n : Nat} (h : m ≤ n) (k : Nat) : k + m ≤ k + n :=
  Nat.add_le_add_left h k

/-- Addition is monotone on the right. -/
theorem add_le_add_right {m n : Nat} (h : m ≤ n) (k : Nat) : m + k ≤ n + k :=
  Nat.add_le_add_right h k

/-- Multiplication is monotone on the left. -/
theorem mul_le_mul_left {a b : Nat} (h : a ≤ b) (c : Nat) : c * a ≤ c * b :=
  Nat.mul_le_mul_left c h

/-- Multiplication is monotone on the right. -/
theorem mul_le_mul_right {a b : Nat} (h : a ≤ b) (c : Nat) : a * c ≤ b * c :=
  Nat.mul_le_mul_right c h

end Foundations.NatOrder
