import Foundations.Int.Basic

namespace Foundations.Rat

/-! ## Rational Number Laws -/

theorem add_comm (a b : Rat) : a + b = b + a := _root_.Rat.add_comm a b
theorem add_assoc (a b c : Rat) : (a + b) + c = a + (b + c) := _root_.Rat.add_assoc a b c
theorem add_zero (a : Rat) : a + 0 = a := _root_.Rat.add_zero a
theorem zero_add (a : Rat) : 0 + a = a := _root_.Rat.zero_add a

theorem mul_comm (a b : Rat) : a * b = b * a := _root_.Rat.mul_comm a b
theorem mul_assoc (a b c : Rat) : (a * b) * c = a * (b * c) := _root_.Rat.mul_assoc a b c
theorem mul_one (a : Rat) : a * 1 = a := _root_.Rat.mul_one a
theorem one_mul (a : Rat) : 1 * a = a := _root_.Rat.one_mul a
theorem mul_zero (a : Rat) : a * 0 = 0 := _root_.Rat.mul_zero a
theorem zero_mul (a : Rat) : 0 * a = 0 := _root_.Rat.zero_mul a
theorem mul_neg (a b : Rat) : a * (-b) = -(a * b) := _root_.Rat.mul_neg a b
theorem neg_mul (a b : Rat) : (-a) * b = -(a * b) := _root_.Rat.neg_mul a b
theorem neg_mul_neg (a b : Rat) : (-a) * (-b) = a * b := by
  rw [_root_.Rat.neg_mul, _root_.Rat.mul_neg, _root_.Rat.neg_neg]

/-! ## Distributivity -/

theorem mul_add (a b c : Rat) : a * (b + c) = a * b + a * c := _root_.Rat.mul_add a b c
theorem add_mul (a b c : Rat) : (a + b) * c = a * c + b * c := _root_.Rat.add_mul a b c

/-! ## Inversion -/

theorem inv_inv (a : Rat) : a⁻¹⁻¹ = a := _root_.Rat.inv_inv a
theorem mul_inv_cancel {a : Rat} (h : a ≠ 0) : a * a⁻¹ = 1 := _root_.Rat.mul_inv_cancel a h
theorem inv_mul_cancel {a : Rat} (h : a ≠ 0) : a⁻¹ * a = 1 := _root_.Rat.inv_mul_cancel a h
theorem inv_one : (1 : Rat)⁻¹ = 1 := by
  have h := _root_.Rat.inv_mul_cancel (a := (1 : Rat)) (by decide)
  rw [_root_.Rat.mul_one] at h
  exact h

end Foundations.Rat
