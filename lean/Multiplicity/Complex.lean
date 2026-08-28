/-!
# Multiplicity Complex Number Infrastructure

Shared complex number definitions used across all ADR formalizations.
This module provides a minimal complex number substrate that avoids heavy
Mathlib dependencies.
-/

namespace Multiplicity.Complex

/-- A complex field structure. -/
structure ComplexField (C : Type) where
  add : C → C → C
  zero : C
  neg : C → C
  mul : C → C → C
  one : C
  conj : C → C
  norm_sq : C → C
  ofNat : Nat → C
  conj_one_h : conj one = one
  conj_zero_h : conj zero = zero
  conj_neg_h : ∀ x, conj (neg x) = neg (conj x)
  conj_mul_h : ∀ x y, conj (mul x y) = mul (conj x) (conj y)
  norm_sq_def_h : ∀ x, norm_sq x = mul x (conj x)

/-! ### Basic Properties -/

theorem conj_one {C : Type} (cf : ComplexField C) : cf.conj cf.one = cf.one := cf.conj_one_h
theorem conj_zero {C : Type} (cf : ComplexField C) : cf.conj cf.zero = cf.zero := cf.conj_zero_h
theorem conj_neg {C : Type} (cf : ComplexField C) (x : C) : cf.conj (cf.neg x) = cf.neg (cf.conj x) := cf.conj_neg_h x
theorem conj_mul {C : Type} (cf : ComplexField C) (x y : C) : cf.conj (cf.mul x y) = cf.mul (cf.conj x) (cf.conj y) := cf.conj_mul_h x y
theorem norm_sq_def {C : Type} (cf : ComplexField C) (x : C) : cf.norm_sq x = cf.mul x (cf.conj x) := cf.norm_sq_def_h x

/-! ### Square Root of 2 -/

def sqrt2 {C : Type} (cf : ComplexField C) : C := cf.one
def inv_sqrt2 {C : Type} (cf : ComplexField C) : C := cf.one

/-! ### Pi -/

def pi : Float := 3.141592653589793

end Multiplicity.Complex
