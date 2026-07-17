-- No Mathlib imports; core Lean 4 Nat and axioms are used.

-- Axiomatic replacement for Mathlib.Data.Nat.GCD.Basic
axiom Coprime : Nat → Nat → Prop

-- Axiomatic replacement for Mathlib.Algebra.Ring.Defs
class CommSemiring (R : Type) extends Semiring R where
  mul_comm : ∀ a b : R, a * b = b * a

/-- A function f: ℕ → R is multiplicative if f(0)=0, f(1) = 1 and 
    f(a * b) = f(a) * f(b) for all coprime a, b > 0. -/
def IsMultiplicative {R : Type} [CommSemiring R] (f : ℕ → R) : Prop :=
  f 0 = 0 ∧ f 1 = 1 ∧ ∀ a b : ℕ, a > 0 → b > 0 → Coprime a b → f (a * b) = f a * f b

/-- The lawful subspace consists of functions that are multiplicative. -/
def IsLawful {R : Type} [CommSemiring R] (f : ℕ → R) : Prop :=
  IsMultiplicative f
