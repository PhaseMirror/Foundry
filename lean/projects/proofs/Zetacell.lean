import Kernel

/-!
# Zetacell — partial-sum bounds for the zeta-cell contribution

Formalizes the ZetaCell invariant: a partial sum of non-negative cell contributions
is non-negative and bounded by `n · b` when every term is at most `b`. No `Mathlib`,
no `sorry`.
-/
namespace Zetacell

open proofs.Kernel

/-- Partial sum of `f` over the first `n` indices. -/
def partialSum (f : Nat → Nat) (n : Nat) : Nat := lsum ((List.range n).map f)

/-- The partial sum is non-negative. -/
theorem partial_sum_nonneg (f : Nat → Nat) (n : Nat) : 0 ≤ partialSum f n := lsum_nonneg _

/-- The partial sum is bounded by `n · b` when every term is at most `b`. -/
theorem partial_sum_bounded_by_max (f : Nat → Nat) (n b : Nat) (h : ∀ i, f i ≤ b) :
    partialSum f n ≤ n * b := by
  simp [partialSum]
  induction n <;> simp [*] <;> omega

end Zetacell
