import Core.alp.PolicyEngine.Core
import Core.alp.Constitution.L0

namespace ALP.Archivum.WitnessContract

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

axiom witness_after_veto_implies_disallowed :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action) (w : UnifiedWitness),
  w.action_id = a.id →
  w.veto_status = "VETOED" →
    (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.Internal).allowed = false

axiom witness_after_admit_implies_constitution_valid :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action) (w : UnifiedWitness),
  w.action_id = a.id →
  w.veto_status = "ADMITTED" →
    ALP.Constitution.L0.validate pe.constitution

end ALP.Archivum.WitnessContract
