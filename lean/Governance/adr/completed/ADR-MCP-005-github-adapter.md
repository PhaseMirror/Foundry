# ADR-MCP-005: GitHub MCP Adapter Governance

## Status
Accepted (2026-05-22)

## Context
Step 7 of Phase 3 requires the integration of a GitHub MCP adapter to enable repository-scale governance actions. To maintain the principle of least privilege, we need to define how GitHub tools are exposed, governed, and escalated.

## Decision

### 1. Read-Only Default
We will register a `github-readonly` server entry in the `mcp_registry.yaml`. This entry will strictly list only read-only capabilities. Any tool not in this allowlist will be rejected by the `CommanderCore` routing layer before execution.

### 2. Write Escalation Path
Write capabilities (e.g., `create_pull_request`, `push_file`) will NOT be included in the `github-readonly` entry. To enable write access, an operator must:
1. Explicitly add a second registry entry: `github-write`.
2. This entry must have its own unique hash and configuration.
3. ALP policy must be updated to specifically allow workflows to bind to `github-write`, likely requiring a `write_escalation: true` flag in the workflow manifest.

### 3. Token Management
- **Read-Only Token**: The `GITHUB_TOKEN` for the read-only adapter will be injected via the same environment-variable pattern as the SAT keys (`COMMANDER_SAT_PUBLIC_KEY`).
- **Scope Restriction**: The token **MUST** be a fine-grained GitHub Personal Access Token (PAT) with only `contents:read`, `issues:read`, and `pull_requests:read` permissions.
- **Security Invariant**: Broad-scoped or organization-level tokens are structurally disallowed for `github-readonly`.

### 4. Capability Drift Protection
- Any update to the `githubmcp` binary (reflected by a hash change) requires an explicit review of the `capabilities` allowlist in `mcp_registry.yaml` before the new hash is attested.
- This prevents new tools added to the binary from being automatically reachable.

## Consequences
- Guarantees that the default GitHub integration cannot mutate repository state.
- Simplifies token management for read-only use cases.
- Provides a clear audit trail for when and why write access was escalated.
- Maintains strict alignment between the binary capabilities and the governed registry.

## Verification
- `pscmd mcp list` shows the `github-readonly` server with only the approved read-only tools.
- Attempting to call a write tool against `github-readonly` results in a routing error.
- Binary hash mismatch correctly flags the server as `INSECURE`.
