import Foundations.Peano.Peano
import Foundations.Nat.Order
import Foundations.Nat.Arith

namespace Foundations.Algebra

/-!
# Algebraic Structures

Prop-valued algebraic structure definitions.
-/

class Semigroup (α : Type) where
  mul : α → α → α
  mul_assoc : ∀ a b c, mul (mul a b) c = mul a (mul b c)

class Monoid (α : Type) extends Semigroup α where
  one : α
  one_mul : ∀ a, mul one a = a
  mul_one : ∀ a, mul a one = a

class Group (α : Type) extends Monoid α where
  inv : α → α
  inv_mul_cancel : ∀ a, mul (inv a) a = one
  mul_inv_cancel : ∀ a, mul a (inv a) = one

class AbelianGroup (α : Type) extends Group α where
  mul_comm : ∀ a b, mul a b = mul b a

class Semiring (α : Type) where
  add : α → α → α
  mul : α → α → α
  zero : α
  one : α
  add_assoc : ∀ a b c, add (add a b) c = add a (add b c)
  add_comm : ∀ a b, add a b = add b a
  zero_add : ∀ a, add zero a = a
  add_zero : ∀ a, add a zero = a
  mul_assoc : ∀ a b c, mul (mul a b) c = mul a (mul b c)
  zero_mul : ∀ a, mul zero a = zero
  mul_zero : ∀ a, mul a zero = zero
  one_mul : ∀ a, mul one a = a
  mul_one : ∀ a, mul a one = a
  add_mul : ∀ a b c, mul (add a b) c = add (mul a c) (mul b c)
  mul_add : ∀ a b c, mul a (add b c) = add (mul a b) (mul a c)

class Ring (α : Type) extends Semiring α where
  neg : α → α
  add_left_neg : ∀ a, add (neg a) a = zero

class CommRing (α : Type) extends Ring α where
  mul_comm : ∀ a b, mul a b = mul b a

class Field (α : Type) extends CommRing α where
  one_ne_zero : one ≠ zero
  inv : α → α
  inv_zero : inv zero = zero
  inv_mul_cancel : ∀ a, a ≠ zero → mul (inv a) a = one

end Foundations.Algebra
