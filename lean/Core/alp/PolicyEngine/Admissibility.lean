import Core.alp.PolicyEngine.Core
import Core.alp.Constitution.L0

namespace ALP.PolicyEngine.Admissibility

axiom validate_action_sound :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action) (t : ALP.Types.TrustLevel),
  let r := ALP.PolicyEngine.validate_action pe a t
  r.allowed = true → ALP.Constitution.L0.validate pe.constitution = true

axiom validate_action_veto_implies_constitution_fail :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action) (t : ALP.Types.TrustLevel),
  ALP.PolicyEngine.validate_action pe a t = { allowed := false, reason := "Vetoed by constitutional policy" } →
    ALP.Constitution.L0.validate pe.constitution = false

end ALP.PolicyEngine.Admissibility
