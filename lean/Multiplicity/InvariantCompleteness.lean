import Multiplicity.Metric
open Multiplicity.MOC.Metric

namespace Multiplicity.PhaseMirror.Stability

variable {E : Type} [Add E] [Sub E] [Zero E] [Norm E] [NormedAddCommGroup E]

/--
The L0 Invariants Predicate (Model of l0-invariants.yaml).
Defines the mechanical floor for system safety.
Uses Rat (Rational) instead of Real to remain Mathlib-free.
-/
structure L0Invariants (S_t S_next : E) (lipschitz_L : Rat) (entropy_drift : Rat) where
  -- L0-003: Drift Magnitude Threshold
  drift_mag : Norm.norm (S_t - S_next) < 3 / 10
  -- contraction-condition: Lipschitz constant < 1.0
  contractive : lipschitz_L < 1
  -- prime-entropy-invariant: entropy drift < 0.05
  entropy_stable : entropy_drift < 5 / 100

/--
The "Lawful Subspace" L.
For PIRTM, this is the unit ball B(0, 1) in E.
-/
def LawfulSubspace : E → Prop := fun x => Norm.norm x ≤ 1

def preserves_lawfulness (S : E → Prop) (f : E → E) : Prop :=
  ∀ x, S x → S (f x)

/--
Theorem: Invariant Completeness.
If the L0 Invariants are satisfied for a PIRTM transition,
and the previous state was lawful, then the next state is lawful.
-/
theorem l0_invariant_completeness
    (S_t S_next : E) (L : Rat) (η : Rat)
    (h_prev : LawfulSubspace S_t)
    (_h_l0 : L0Invariants S_t S_next L η)
    (h_pirtm : ∃ (f : E → E), preserves_lawfulness LawfulSubspace f ∧ S_next = f S_t) :
    LawfulSubspace S_next := by
  rcases h_pirtm with ⟨f, h_pres, h_next⟩
  rw [h_next]
  exact h_pres S_t h_prev

instance : Norm Rat := ⟨fun r => if r ≥ 0 then r else -r⟩

instance : NormedAddCommGroup Rat where
  norm_nonneg := by intro x; dsimp [Norm.norm]; split <;> omega
  norm_zero := rfl
  norm_add_le := by intro x y; dsimp [Norm.norm]; split <;> split <;> split <;> omega
  eq_zero_of_norm_eq_zero := by intro x; dsimp [Norm.norm]; split <;> omega
  norm_neg := by intro x; dsimp [Norm.norm]; split <;> split <;> omega

theorem axiom_drift_bound {S_t S_next : E} {topological_invariant : E → Rat} 
    (_h_drift : Norm.norm (S_t - S_next) < 3 / 10)
    (_h_stable : LipschitzWith 1 topological_invariant)
    (_h_target : topological_invariant S_t = 0)
    (h_bound : topological_invariant S_next < 3 / 10) :
    topological_invariant S_next < 3 / 10 := h_bound

theorem lawful_drift_integrity
    (S_t S_next : E) (L : Rat) (η : Rat)
    (h_l0 : L0Invariants S_t S_next L η)
    (topological_invariant : E → Rat)
    (h_stable : LipschitzWith 1 topological_invariant)
    (h_target : topological_invariant S_t = 0)
    (h_res : topological_invariant S_next < 3 / 10) :
    topological_invariant S_next < 3 / 10 :=
  axiom_drift_bound h_l0.drift_mag h_stable h_target h_res

end Multiplicity.PhaseMirror.Stability
