import alp.Tests.L0_Specs
import alp.Contracts.NonBypassability
import alp.Contracts.TrustArbitration
import alp.MCP.GovernanceBinding
import alp.Archivum.WitnessContract

namespace ALP.Tests.Integration

open ALP.PolicyEngine ALP.Types ALP.Constitution.L0

theorem e2e_internal_workflow_receives_witness (pe : PolicyEngine) (a : Action)
    (h_const : validate pe.constitution = true) :
    validate_action pe a TrustLevel.Internal = { allowed := true, reason := "Admitted" } := by
  unfold validate_action
  split
  · simp_all
  · rfl
  · simp_all

theorem e2e_external_workflow_blocked_from_governed_mcp (pe : PolicyEngine) (a : Action)
    (s : ALP.Contracts.TrustArbitration.McpServerDescriptor)
    (_h_alp : s.alp_required = true)
    (h_bind : a.server_binding = some s.descriptor_id) :
    (validate_action pe a TrustLevel.External).allowed = false := by
  unfold validate_action
  split
  · rfl
  · next hc _ => simp_all
  · next hc =>
    split
    · simp_all
    · simp_all

end ALP.Tests.Integration
