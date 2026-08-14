import Multiplicity.Std
import Multiplicity.IntegrativeSolver.Core
open Classical

namespace Multiplicity.IntegrativeSolver

namespace Multiplicity.Intervention

/-!
# IntegrativeSolver.Intervention

Channel intervention dynamics for the M-Integrative Solver.

Design notes
- This module provides a minimal, provably correct intervention primitive.
- The current model is a single-channel load addition.
- The `sorry`-free guarantee holds for this file.
-/

open IntegrativeSolver.Core

/-- A single-channel intervention: add `delta` load to channel `target`. -/
def intervene {K : Nat} (target : Fin K) (delta : Nat) (v : SCV K) : SCV K where
  counts := fun k => if k = target then v.counts k + delta else v.counts k

theorem intervene_preserves_nonneg {K : Nat} (target : Fin K) (delta : Nat) (v : SCV K) :
    ∀ k, (intervene target delta v).counts k ≥ 0 := by
  unfold intervene
  intro k
  by_cases hk : k = target
  · subst k
    simp
  · simp [hk]

end Multiplicity.Intervention

end Multiplicity.IntegrativeSolver
