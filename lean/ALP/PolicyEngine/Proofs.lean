import ALP.PolicyEngine.Core
import ALP.PolicyEngine.Admissibility
import ALP.Constitution.L0
import Mathlib

namespace ALP.PolicyEngine.Proofs

theorem internal_valid_action_admitted :
  ∀ (pe : PolicyEngine) (a : Action),
  ALP.Constitution.L0.validate pe.constitution →
    (pe.validate_action a TrustLevel.Internal).allowed = true := by
  intro pe a h
  simp [PolicyEngine.validate_action, TrustLevel.isInternal]
  exact h

theorem external_mutating_action_blocked :
  ∀ (pe : PolicyEngine) (a : Action),
  a.mutating →
    (pe.validate_action a TrustLevel.External).allowed = false := by
  intro pe a h
  simp [PolicyEngine.validate_action, TrustLevel.isExternal]
  sorry

theorem external_with_server_binding_blocked :
  ∀ (pe : PolicyEngine) (a : Action),
  a.server_binding.isSome →
    (pe.validate_action a TrustLevel.External).allowed = false := by
  sorry

end ALP.PolicyEngine.Proofs
