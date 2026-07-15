# ADR-CODE-004: OpenCode Integration Strategy

## Status
Proposed

## Context
OpenCode.ai is a capable, open-source coding agent that can run locally. To leverage its planning capabilities while maintaining the Commander's governance mandates, we need a clear integration strategy that prevents OpenCode from bypassing our policy gates.

## Decision
We integrate OpenCode.ai as a **Subordinate Planner** within the Commander ecosystem.

1. **Planner-Only Configuration**: OpenCode will be configured with `permissions: { shell: false, filesystem: false, git: false }` in its `opencode.json`. It will not be allowed to perform any mutations directly.
2. **Context Injection**: Commander will act as the provider for OpenCode, injecting file snapshots and repository metadata via MCP.
3. **Plan Capture**: OpenCode's output (plans and patches) will be captured by Commander, validated against ALP, and then executed by the Sigma kernel.
4. **Registry Entry**: OpenCode must be registered in `state/mcp_registry.yaml` with an `attested_sha256` hash. Commander will launch the OpenCode process directly to ensure it runs with the correct restricted configuration.

## Consequences
- **Mature UX**: We gain the powerful planning and reasoning of a dedicated coding agent without building one from scratch.
- **Strict Governance**: OpenCode cannot "run away" and delete files or commit unvetted code because it lacks the underlying system permissions.
- **Workflow Cohesion**: Coding sessions in OpenCode become native Commander workflows, complete with `UnifiedWitness` logs.

## Verification
- `opencode.json` must be present in `config/opencode/` with all mutation permissions disabled.
- Running `pscmd workflows run lever-coding-session` should trigger OpenCode, receive a plan, and pause for Commander-side approval.
- Any attempt by OpenCode to call a restricted tool (e.g., `rm`, `git push`) must be blocked by Commander's MCP server and logged as a policy violation.
