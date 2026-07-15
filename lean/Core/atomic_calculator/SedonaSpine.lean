-- import UAC.Core
import Core.moc.Resonance
-- import ALP.PolicyEngine.Core
-- import ALP.Types.TrustLevel
-- import ALP.Types.AdmissibilityReport

namespace UAC.SedonaSpine

open Sovereign.Policy
open MOC.Resonance
open ALP.PolicyEngine
open ALP.Types

/-- Sedona Spine Mandate: UAC ERE Resonance bridge -/
def verify_ere_resonance (cert : ResonanceCertificate) : Verdict :=
  if meets_threshold cert then
    Verdict.approve "ERE-THRESHOLD-MET"
  else
    Verdict.reject "ERE-THRESHOLD-FAILED"

/-- Sedona Spine Mandate: All decisions must route through ALP -/
def evaluate_snap_kitty_with_alp (pe : PolicyEngine) (a : Action) (cert : ResonanceCertificate) : AdmissibilityReport :=
  let sk_verdict := verify_ere_resonance cert
  let alp_verdict := validate_action pe a TrustLevel.Internal
  
  if sk_verdict.isFinal && (sk_verdict == Verdict.approve "ERE-THRESHOLD-MET") && alp_verdict.allowed then
    { allowed := true, reason := "UAC Approved & ALP Admitted" }
  else
    { allowed := false, reason := "Vetoed by ALP or UAC" }

end UAC.SedonaSpine
