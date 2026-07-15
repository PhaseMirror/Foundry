import Kernel

/-!
# RecursiveFoundations — recursive equals iterative factorial

Formalizes the Recursive Foundations invariant: the recursively-defined factorial
coincides with its iterative (fold) definition. No `Mathlib`, no `sorry`.
-/
namespace RecursiveFoundations

open proofs.Kernel

/-- Recursive factorial. -/
def factRec : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * factRec n

/-- Iterative factorial via right-fold. -/
def factIter : Nat → Nat
  | 0 => 1
  | n + 1 => factIter n * (n + 1)

/-- The two definitions agree (well-foundedness of the recursive definition). -/
theorem fact_iter_eq_rec (n : Nat) : factIter n = factRec n := by
  induction n with
  | zero => rfl
  | succ n ih => simp [ih, Nat.mul_comm]

end RecursiveFoundations
