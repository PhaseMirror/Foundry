import Foundations.Peano.Peano
import Foundations.Nat.Order

namespace Foundations.NatArith

open Foundations.Peano
open Foundations.NatOrder

/-! ## Cancellation -/

/-- Left cancellation for addition. -/
theorem add_left_cancel {m n k : Nat} (h : k + m = k + n) : m = n :=
  Nat.add_left_cancel h

/-- Right cancellation for addition. -/
theorem add_right_cancel {m n k : Nat} (h : m + k = n + k) : m = n :=
  Nat.add_right_cancel h

/-- Left cancellation for multiplication by a positive number. -/
theorem mul_left_cancel {m n k : Nat} (hk : 0 < k) (h : k * m = k * n) : m = n :=
  Nat.mul_left_cancel hk h

/-! ## Inequalities -/

/-- `0 ≤ n` for all natural numbers. -/
theorem zero_le (n : Nat) : 0 ≤ n := Nat.zero_le n

/-- If `a + b = 0` then `a = 0` and `b = 0`. -/
theorem add_eq_zero {a b : Nat} (h : a + b = 0) : a = 0 ∧ b = 0 :=
  Nat.eq_zero_of_add_eq_zero h

/-- `a ≤ b` implies `a ≤ b + c`. -/
theorem le_add_right {a b : Nat} (h : a ≤ b) (c : Nat) : a ≤ b + c :=
  Nat.le_add_right_of_le h

/-- `a + b ≤ a + c → b ≤ c`. -/
theorem add_le_cancel_left {a b c : Nat} : a + b ≤ a + c → b ≤ c :=
  Nat.add_le_add_iff_left.mp

/-! ## Subtraction -/

/-- `a - a = 0`. -/
theorem sub_self (a : Nat) : a - a = 0 := Nat.sub_self a

/-- `a - 0 = a`. -/
theorem sub_zero (a : Nat) : a - 0 = a := Nat.sub_zero a

/-- `0 - a = 0`. -/
theorem zero_sub (a : Nat) : 0 - a = 0 := Nat.zero_sub a

/-! ## Multiplication Inequalities -/

/-- `a * b = 0` implies `a = 0` or `b = 0`. -/
theorem mul_eq_zero {a b : Nat} (h : a * b = 0) : a = 0 ∨ b = 0 :=
  Nat.mul_eq_zero.mp h

/-- A positive number times a positive number is positive. -/
theorem mul_pos {a b : Nat} (ha : 0 < a) (hb : 0 < b) : 0 < a * b :=
  Nat.mul_pos ha hb

/-- `1 * n = n`. -/
theorem one_mul (n : Nat) : 1 * n = n := Nat.one_mul n

/-- `n * 1 = n`. -/
theorem mul_one (n : Nat) : n * 1 = n := Nat.mul_one n

/-- `2 * n = n + n`. -/
theorem two_mul (n : Nat) : 2 * n = n + n := Nat.two_mul n

end Foundations.NatArith
