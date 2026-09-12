import Foundations.PolicyEngine.Core
import Foundations.PolicyEngine.Proofs

/-!
# Foundations.TrustArbitration.Core — MCP Server Binding & Trust Arbitration Contracts

Formalizes MCP server descriptors, arbitration contracts, and proves trust-gated admission
and rejection of external governed MCP bindings.
-/

namespace Foundations.TrustArbitration

open Multiplicity.ALP.PolicyEngine Multiplicity.ALP.Types Multiplicity.ALP.PolicyEngine.Proofs

/-- MCP Server Descriptor record. -/
structure McpServerDescriptor where
  descriptor_id : String
  alp_required  : Bool
  deriving Repr, DecidableEq

/-- Theorem: Internal trust level admits actions with MCP server bindings under valid constitution. -/
theorem internal_admits_mcp (pe : PolicyEngine) (a : Action) (s : McpServerDescriptor)
    (_h_bind : a.server_binding = some s.descriptor_id)
    (h_const : Multiplicity.ALP.Constitution.L0.validate pe.constitution = true) :
    (validate_action pe a TrustLevel.Internal).allowed = true := by
  simp [validate_action, h_const]

/-- Theorem: External trust level strictly blocks actions with governed MCP server bindings. -/
theorem external_blocks_governed_mcp (pe : PolicyEngine) (a : Action) (s : McpServerDescriptor)
    (h_bind : a.server_binding = some s.descriptor_id) :
    (validate_action pe a TrustLevel.External).allowed = false := by
  have h_some : a.server_binding.isSome = true := by
    rw [h_bind]
    rfl
  exact external_with_server_binding_blocked pe a h_some

end Foundations.TrustArbitration