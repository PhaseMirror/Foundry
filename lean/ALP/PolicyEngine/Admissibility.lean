import ALP.PolicyEngine.Core
import ALP.Constitution.L0
import Mathlib

namespace ALP.PolicyEngine.Admissibility

theorem validate_action_sound :
  ∀ (pe : PolicyEngine) (a : Action) (t : TrustLevel),
  let r := pe.validate_action a t
  r.allowed = true → ALP.Constitution.L0.validate pe.constitution := by
  intro pe a t r h
  unfold validate_action at r
  unfold validate_action
  cases t with
  | Internal =>
    simp at h
    exact h
  | External =>
    simp at h
    have h_conj : !a.mutating ∧ a.server_binding.isNone ∧ ALP.Constitution.L0.validate pe.constitution := by
      cases h with
      | intro h₁ h₂ =>
        simp at h₁
        simp at h₂
        exact And.intro h₁ (And.intro h₂ ?)
    sorry

theorem validate_action_veto_implies_constitution_fail :
  ∀ (pe : PolicyEngine) (a : Action) (t : TrustLevel),
  pe.validate_action a t = { allowed := false, reason := _ } →
    ¬ALP.Constitution.L0.validate pe.constitution := by
  sorry

end ALP.PolicyEngine.Admissibility
