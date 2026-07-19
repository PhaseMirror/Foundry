import Core.alp.PolicyEngine.Core
import Core.alp.PolicyEngine.Admissibility
import Core.alp.Constitution.L0

namespace ALP.PolicyEngine.Proofs

open ALP.PolicyEngine ALP.Types ALP.Constitution.L0

theorem internal_valid_action_admitted (pe : PolicyEngine) (a : Action)
    (h_const : validate pe.constitution = true) :
    (validate_action pe a TrustLevel.Internal).allowed = true := by
  unfold validate_action
  split
  · simp_all
  · rfl
  · simp_all

theorem external_mutating_action_blocked (pe : PolicyEngine) (a : Action)
    (h_mut : a.mutating = true) :
    (validate_action pe a TrustLevel.External).allowed = false := by
  unfold validate_action
  split
  · rfl
  · next hc _ => simp_all
  · next hc =>
    split
    · rfl
    · simp_all

theorem external_with_server_binding_blocked (pe : PolicyEngine) (a : Action)
    (h_bind : a.server_binding.isSome = true) :
    (validate_action pe a TrustLevel.External).allowed = false := by
  unfold validate_action
  split
  · rfl
  · next hc _ => simp_all
  · next hc =>
    split
    · simp_all
    · simp_all

end ALP.PolicyEngine.Proofs
