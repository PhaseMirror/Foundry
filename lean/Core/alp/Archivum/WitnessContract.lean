import Core.alp.PolicyEngine.Core
import Core.alp.Constitution.L0

namespace ALP.Archivum.WitnessContract

open ALP.PolicyEngine ALP.Constitution.L0

structure UnifiedWitness where
  witness_id : String
  action_id : String
  timestamp : String
  compliance_evidence : String
  execution_receipt : String
  contractivity_score : Float
  veto_status : String
  witness_hash : Option String
  p_lineage : Option String

/--
A witness with veto_status = "VETOED" for an action implies the action is disallowed.

This is a record-level invariant: the Archivum records the outcome of the ALP gate.
If the witness records a veto, the action was blocked. The hypothesis `h_veto_recorded`
encodes the architectural invariant that veto_status in a witness faithfully reflects
the PolicyEngine outcome.
-/
theorem witness_after_veto_implies_disallowed (pe : ALP.PolicyEngine.PolicyEngine)
    (a : ALP.Types.Action) (w : UnifiedWitness)
    (_h_id : w.action_id = a.id)
    (h_veto_recorded : w.veto_status = "VETOED")
    (h_archivum_invariant :
      w.veto_status = "VETOED" →
        (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.Internal).allowed = false) :
    (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.Internal).allowed = false :=
  h_archivum_invariant h_veto_recorded

/--
A witness with veto_status = "ADMITTED" for an action implies the constitution is valid.

The witness faithfully records the ALP gate outcome. If the action was admitted, the
constitution must have been valid at the time of admission.
-/
theorem witness_after_admit_implies_constitution_valid (pe : ALP.PolicyEngine.PolicyEngine)
    (a : ALP.Types.Action) (w : UnifiedWitness)
    (_h_id : w.action_id = a.id)
    (h_admit_recorded : w.veto_status = "ADMITTED")
    (h_archivum_invariant :
      w.veto_status = "ADMITTED" →
        ALP.Constitution.L0.validate pe.constitution = true) :
    ALP.Constitution.L0.validate pe.constitution :=
  h_archivum_invariant h_admit_recorded

end ALP.Archivum.WitnessContract
