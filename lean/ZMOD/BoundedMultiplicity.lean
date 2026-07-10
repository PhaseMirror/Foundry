import ZMOD.Core

namespace ZMOD

/-- Lemma: Step interaction is bounded by `scale` (1.0). -/
theorem step_interaction_le_scale (grad : Nat) (p : Nat) :
  step_interaction grad p ≤ scale := by
  unfold step_interaction
  split
  · exact Nat.le_refl _
  · exact Nat.zero_le _

/-- The Bounded Multiplicity Theorem: 
Accumulation of interactions over T steps is bounded by T * scale.
This replaces the legacy unverified floating-point `multiplicity_tensor_le_T`. -/
theorem multiplicity_tensor_le_T (grads : List Nat) (p : Nat) :
  multiplicityTensor grads p ≤ grads.length * scale := by
  induction grads with
  | nil =>
    unfold multiplicityTensor
    simp
  | cons g gs ih =>
    unfold multiplicityTensor
    simp
    have h1 := step_interaction_le_scale g p
    have h2 := ih
    have h_add := Nat.add_le_add h1 h2
    have h_eq : (gs.length + 1) * scale = scale + gs.length * scale := by
      rw [Nat.add_mul, Nat.one_mul, Nat.add_comm]
    rw [h_eq]
    exact h_add

end ZMOD
