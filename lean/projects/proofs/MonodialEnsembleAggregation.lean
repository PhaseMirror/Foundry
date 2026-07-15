import Kernel

/-!
# MonodialEnsembleAggregation — monoid-fold associativity

Formalizes the Monodial Ensemble Aggregation invariant: folding a list under an
associative aggregation operator respects list segmentation (fold of append equals
fold-then-combine). No `Mathlib`, no `sorry`.
-/
namespace MonodialEnsembleAggregation

open proofs.Kernel

/-- A monoid over `Nat`. -/
structure Monoid where
  op : Nat → Nat → Nat
  unit : Nat
  assoc : ∀ x y z, op x (op y z) = op (op x y) z
  unit_l : ∀ x, op unit x = x
  unit_r : ∀ x, op x unit = x

/-- Right fold of a list under the monoid. -/
def fold (m : Monoid) : List Nat → Nat
  | [] => m.unit
  | x :: xs => m.op x (fold m xs)

/-- Folding a concatenation equals folding each part and combining. -/
theorem fold_append (m : Monoid) (xs ys : List Nat) :
    fold m (xs ++ ys) = m.op (fold m xs) (fold m ys) := by
  induction xs generalizing ys <;> simp [*]
  rw [m.assoc]

end MonodialEnsembleAggregation
