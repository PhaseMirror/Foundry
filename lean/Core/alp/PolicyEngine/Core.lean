import Core.alp.Constitution.Model
import Core.alp.Constitution.L0
import Core.alp.Types.Action
import Core.alp.Types.TrustLevel
import Core.alp.Types.AdmissibilityReport

namespace ALP.PolicyEngine

open ALP.Types

structure PolicyEngine where
  constitution : ALP.Constitution.ConstitutionModel

def validate_action (pe : PolicyEngine) (a : Action) (t : TrustLevel) : AdmissibilityReport :=
  let constitutionValid := ALP.Constitution.L0.validate pe.constitution
  let allowed := match t with
    | TrustLevel.Internal => constitutionValid
    | TrustLevel.External => !a.mutating && a.server_binding.isNone && constitutionValid
  { allowed := allowed,
    reason := if allowed then "Admitted" else "Vetoed by constitutional policy" }

end ALP.PolicyEngine
