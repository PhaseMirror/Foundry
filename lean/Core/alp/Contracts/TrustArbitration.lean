import Core.alp.PolicyEngine.Core
import Core.alp.Types.TrustLevel
import Core.alp.Types.Action

namespace ALP.Contracts.TrustArbitration

structure McpServerDescriptor where
  descriptor_id : String
  alp_required : Bool

axiom internal_admits_mcp :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action) (s : McpServerDescriptor),
  a.server_binding = some s.descriptor_id →
    ALP.Constitution.L0.validate pe.constitution = true →
      (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.Internal).allowed = true

axiom external_blocks_governed_mcp :
  ∀ (pe : ALP.PolicyEngine.PolicyEngine) (a : ALP.Types.Action) (s : McpServerDescriptor),
  s.alp_required = true →
    (ALP.PolicyEngine.validate_action pe a ALP.Types.TrustLevel.External).allowed = false

end ALP.Contracts.TrustArbitration
