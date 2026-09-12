import Foundations.IntegrativeSolver.Core

/-!
# Foundations.IntegrativeSolver.Intervention — Channel Intervention Dynamics
-/

namespace Foundations.IntegrativeSolver

def intervene {K : Nat} (target : Fin K) (delta : Nat) (v : SCV K) : SCV K where
  counts := fun k => if k = target then v.counts k + delta else v.counts k

theorem intervene_preserves_nonneg {K : Nat} (target : Fin K) (delta : Nat) (v : SCV K) :
    ∀ k, (intervene target delta v).counts k ≥ 0 := by
  intro k
  simp [intervene]

end Foundations.IntegrativeSolver
