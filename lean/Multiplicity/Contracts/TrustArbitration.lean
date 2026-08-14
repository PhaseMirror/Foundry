import Multiplicity.alp.PolicyEngine.Core
import Multiplicity.alp.Types.TrustLevel
import Multiplicity.alp.Types.Action

namespace Multiplicity.ALP.Contracts.TrustArbitration

open ALP.PolicyEngine ALP.Types ALP.Constitution.L0

structure McpServerDescriptor where
  descriptor_id : String
  alp_required : Bool

theorem internal_admits_mcp (pe : PolicyEngine) (a : Action) (s : McpServerDescriptor)
    (_h_bind : a.server_binding = some s.descriptor_id)
    (h_const : validate pe.constitution = true) :
    (validate_action pe a TrustLevel.Internal).allowed = true := by
  unfold validate_action
  split
  · simp_all
  · rfl
  · simp_all

theorem external_blocks_governed_mcp (pe : PolicyEngine) (a : Action) (s : McpServerDescriptor)
    (_h_alp : s.alp_required = true)
    (h_bind : a.server_binding = some s.descriptor_id) :
    (validate_action pe a TrustLevel.External).allowed = false := by
  unfold validate_action
  split
  · rfl
  · next hc _ => simp_all
  · next hc =>
    split
    · rfl
    · have h_some : a.server_binding.isSome = true := by rw [h_bind]; rfl
      split
      · rfl
      · exact absurd h_some (by simp_all)

end Multiplicity.ALP.Contracts.TrustArbitration
