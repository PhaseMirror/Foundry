import SnapKitty.Core
import MOC.Resonance
import ALP.PolicyEngine.Core
import ALP.Types.TrustLevel
import ALP.Types.AdmissibilityReport

namespace SnapKitty.SedonaSpine

open Sovereign.Policy
open MOC.Resonance
open ALP.PolicyEngine
open ALP.Types

/-- Sedona Spine Mandate: SnapKitty ERE Resonance bridge -/
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
    { allowed := true, reason := "SnapKitty Approved & ALP Admitted" }
  else
    { allowed := false, reason := "Vetoed by ALP or SnapKitty" }

end SnapKitty.SedonaSpine
