import Core.alp.PolicyEngine.Core
import Core.alp.PolicyEngine.Admissibility
import Core.alp.Constitution.L0

namespace ALP.PolicyEngine.Proofs

axiom internal_valid_action_admitted :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action),
  ALP.Constitution.L0.validate pe.constitution = true →
    (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.Internal).allowed = true

axiom external_mutating_action_blocked :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action),
  a.mutating = true →
    (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.External).allowed = false

axiom external_with_server_binding_blocked :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action),
  a.server_binding.isSome = true →
    (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.External).allowed = false

end ALP.PolicyEngine.Proofs
