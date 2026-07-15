# ADR-MCP-002: Governed MCP Tool Registry

## Status
Accepted (2026-05-22)

## Context
The Commander currently uses hardcoded paths to locate and spawn MCP servers. To support a scalable ecosystem, we need a dynamic discovery mechanism that allows the operator to register and govern multiple servers (Rust, Python, or external) without modifying the binary.

## Decision
We will implement a static, file-based registry at `state/mcp_registry.yaml`. This file is the source of truth for all MCP servers available to the operator.

**Validation Mechanism**:
To ensure the integrity of registered servers, we will use a **Hash-on-Attestation** model:
1. When a server is registered, its binary path and a cryptographic hash (SHA-256) are stored in the registry.
2. At runtime, The Commander verifies that the binary at the specified path matches the recorded hash.
3. If the hash does not match (e.g., after a rebuild), the server is marked `INSECURE`.
4. The operator must manually re-attest (e.g., via `pscmd mcp attest <id>`) to update the registry with the new hash.

This model provides high security against silent binary tampering while maintaining the operator's role as the final authority on trusted components.

## Consequences
- Operators can dynamically add/remove servers by editing `mcp_registry.yaml`.
- The Commander can perform discovery and health checks on all registered servers at startup.
- Silent binary updates (e.g., automated builds) will require explicit operator confirmation before execution.
- Prevents execution of unauthorized binaries even if they replace a trusted path.

## Verification
- `pscmd mcp list` correctly identifies servers as `VERIFIED` or `INSECURE` based on hash matching.
- Any tool call to an `INSECURE` server is blocked by ALP with a specific "Insecure Server" violation.
- `pscmd mcp attest <id>` updates the hash in `state/mcp_registry.yaml`.

## Amendment: Tool Routing Rule (2026-05-22)
To prevent governance gaps caused by ambiguous routing, we adopt **Explicit Workflow Binding** (Option 2):
1. Every task in a workflow that invokes an MCP tool **must** declare a `server_binding` field matching a server ID in the registry.
2. If the `server_binding` is missing, the ALP gate will reject the action with an "Ambiguous Routing" violation.
3. This ensures that the trust level and governance status of the specific server are always known and verified before execution.
