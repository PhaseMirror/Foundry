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

/-! ### Basic Properties -/

axiom conj_one {C : Type} (cf : ComplexField C) : cf.conj cf.one = cf.one
axiom conj_zero {C : Type} (cf : ComplexField C) : cf.conj cf.zero = cf.zero
axiom conj_neg {C : Type} (cf : ComplexField C) (x : C) : cf.conj (cf.neg x) = cf.neg (cf.conj x)
axiom conj_mul {C : Type} (cf : ComplexField C) (x y : C) : cf.conj (cf.mul x y) = cf.mul (cf.conj x) (cf.conj y)
axiom norm_sq_def {C : Type} (cf : ComplexField C) (x : C) : cf.norm_sq x = cf.mul x (cf.conj x)

/-! ### Square Root of 2 -/

axiom sqrt2 {C : Type} (cf : ComplexField C) : C
axiom sqrt2_sq {C : Type} (cf : ComplexField C) : cf.mul (sqrt2 cf) (sqrt2 cf) = cf.ofNat 2

axiom inv_sqrt2 {C : Type} (cf : ComplexField C) : C
axiom inv_sqrt2_mul {C : Type} (cf : ComplexField C) : cf.mul (inv_sqrt2 cf) (sqrt2 cf) = cf.one

/-! ### Pi -/

def pi : Float := 3.141592653589793

end Multiplicity.Complex
