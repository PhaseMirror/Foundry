import Foundations.Algebra.Field

/-! # Metric Spaces -/

namespace Foundations.Analysis

/-! ## Metric Space Structure -/

class MetricSpace (α : Type) where
  dist : α → α → Rat
  dist_self : ∀ x, dist x x = 0
  dist_comm : ∀ x y, dist x y = dist y x
  dist_triangle : ∀ x y z, dist x z ≤ dist x y + dist y z
  dist_nonneg : ∀ x y, 0 ≤ dist x y
  eq_of_dist_eq_zero : ∀ x y, dist x y = 0 → x = y

/-! ## Convergence in Metric Spaces -/

def SeqConv {α : Type} [MetricSpace α] (x : Nat → α) (a : α) : Prop :=
  ∀ ε, 0 < ε → ∃ N, ∀ n, n ≥ N → MetricSpace.dist (x n) a < ε

def SeqCauchy {α : Type} [MetricSpace α] (x : Nat → α) : Prop :=
  ∀ ε, 0 < ε → ∃ N, ∀ m n, m ≥ N → n ≥ N → MetricSpace.dist (x m) (x n) < ε

end Foundations.Analysis
