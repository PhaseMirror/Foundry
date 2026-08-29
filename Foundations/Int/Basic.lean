import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith

namespace Foundations.Int

/-! ## Integer Arithmetic Laws -/

theorem add_comm (a b : Int) : a + b = b + a := by exact _root_.Int.add_comm a b
theorem add_assoc (a b c : Int) : (a + b) + c = a + (b + c) := by exact _root_.Int.add_assoc a b c
theorem add_zero (a : Int) : a + 0 = a := by exact _root_.Int.add_zero a
theorem zero_add (a : Int) : 0 + a = a := by exact _root_.Int.zero_add a
theorem add_right_neg (a : Int) : a + (-a) = 0 := by exact _root_.Int.add_right_neg a
theorem add_left_neg (a : Int) : -a + a = 0 := by exact _root_.Int.add_left_neg a

theorem mul_comm (a b : Int) : a * b = b * a := by exact _root_.Int.mul_comm a b
theorem mul_assoc (a b c : Int) : (a * b) * c = a * (b * c) := by exact _root_.Int.mul_assoc a b c
theorem mul_one (a : Int) : a * 1 = a := by exact _root_.Int.mul_one a
theorem one_mul (a : Int) : 1 * a = a := by exact _root_.Int.one_mul a
theorem mul_zero (a : Int) : a * 0 = 0 := by exact _root_.Int.mul_zero a
theorem zero_mul (a : Int) : 0 * a = 0 := by exact _root_.Int.zero_mul a
theorem mul_neg (a b : Int) : a * (-b) = -(a * b) := by exact _root_.Int.mul_neg a b
theorem neg_mul (a b : Int) : (-a) * b = -(a * b) := by exact _root_.Int.neg_mul a b
theorem neg_mul_neg (a b : Int) : (-a) * (-b) = a * b := by exact _root_.Int.neg_mul_neg a b

theorem mul_add (a b c : Int) : a * (b + c) = a * b + a * c := by exact _root_.Int.mul_add a b c
theorem add_mul (a b c : Int) : (a + b) * c = a * c + b * c := by exact _root_.Int.add_mul a b c
theorem mul_sub (a b c : Int) : a * (b - c) = a * b - a * c := by exact _root_.Int.mul_sub a b c
theorem sub_mul (a b c : Int) : (a - b) * c = a * c - b * c := by exact _root_.Int.sub_mul a b c

theorem sub_self (a : Int) : a - a = 0 := by exact _root_.Int.sub_self a
theorem sub_add_cancel (a b : Int) : a - b + b = a := by exact _root_.Int.sub_add_cancel a b
theorem add_sub_cancel (a b : Int) : a + b - b = a := by exact _root_.Int.add_sub_cancel a b

theorem neg_neg (a : Int) : -(-a) = a := by exact _root_.Int.neg_neg a
theorem neg_zero : -(0 : Int) = 0 := by exact _root_.Int.neg_zero
theorem neg_add : ∀ (a b : Int), -(a + b) = -a + -b := fun a b => _root_.Int.neg_add
theorem neg_sub : ∀ (a b : Int), -(a - b) = b - a := fun a b => _root_.Int.neg_sub a b

theorem le_refl : ∀ (a : Int), a ≤ a := fun a => _root_.Int.le_refl a
theorem le_antisymm {a b : Int} (h1 : a ≤ b) (h2 : b ≤ a) : a = b :=
  _root_.Int.le_antisymm h1 h2
theorem le_trans {a b c : Int} (h1 : a ≤ b) (h2 : b ≤ c) : a ≤ c :=
  _root_.Int.le_trans h1 h2

theorem natCast_add (m n : Nat) :
    (m : Int) + (n : Int) = ((m + n : Nat) : Int) := by exact _root_.Int.natCast_add m n
theorem natCast_mul (m n : Nat) :
    (m : Int) * (n : Int) = ((m * n : Nat) : Int) := by exact _root_.Int.natCast_mul m n
theorem natCast_zero : ((0 : Nat) : Int) = 0 := by exact _root_.Int.natCast_zero
theorem natCast_one : ((1 : Nat) : Int) = 1 := by exact _root_.Int.natCast_one

end Foundations.Int
