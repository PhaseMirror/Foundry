import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Algebra.Ring.Defs

/-- A function f: ℕ → R is multiplicative if f(0)=0, f(1) = 1 and 
    f(a * b) = f(a) * f(b) for all coprime a, b > 0. -/
def IsMultiplicative {R : Type} [CommSemiring R] (f : ℕ → R) : Prop :=
  f 0 = 0 ∧ f 1 = 1 ∧ ∀ a b : ℕ, a > 0 → b > 0 → Nat.Coprime a b → f (a * b) = f a * f b

/-- The lawful subspace consists of functions that are multiplicative. -/
def IsLawful {R : Type} [CommSemiring R] (f : ℕ → R) : Prop :=
  IsMultiplicative f
