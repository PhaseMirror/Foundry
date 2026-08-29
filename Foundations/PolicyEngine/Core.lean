import Foundations.Constitution.Model
import Foundations.Constitution.L0
import Foundations.Types.Action
import Foundations.Types.TrustLevel
import Foundations.Types.AdmissibilityReport

namespace Multiplicity.ALP.PolicyEngine

open ALP.Types

structure PolicyEngine where
  constitution : ALP.Constitution.ConstitutionModel

def validate_action (pe : PolicyEngine) (a : Action) (t : TrustLevel) : AdmissibilityReport :=
  match ALP.Constitution.L0.validate pe.constitution, t with
  | false, _ =>
    { allowed := false, reason := "Vetoed by constitutional policy" }
  | true, TrustLevel.Internal =>
    { allowed := true, reason := "Admitted" }
  | true, TrustLevel.External =>
    if a.mutating then
      { allowed := false, reason := "Mutating action blocked for external trust" }
    else if a.server_binding.isSome then
      { allowed := false, reason := "Server binding blocked for external trust" }
    else
      { allowed := true, reason := "Admitted" }

end Multiplicity.ALP.PolicyEngine
