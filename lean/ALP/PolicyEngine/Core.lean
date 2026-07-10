import ALP.Constitution.Model
import ALP.Types.Action
import ALP.Types.TrustLevel
import ALP.Types.AdmissibilityReport
import Mathlib

namespace ALP.PolicyEngine

structure PolicyEngine where
  constitution : ConstitutionModel

def validate_action (pe : PolicyEngine) (a : Action) (t : TrustLevel) : AdmissibilityReport :=
  let constitutionValid := ALP.Constitution.L0.validate pe.constitution
  let allowed := match t with
    | TrustLevel.Internal => constitutionValid
    | TrustLevel.External => !a.mutating && a.server_binding.isNone && constitutionValid
  { allowed := allowed,
    reason := if allowed then "Admitted" else "Vetoed by constitutional policy" }

end ALP.PolicyEngine
