# ADR-CODE-005: Governed Workflow Deployment & Automation

## Status
Proposed

## Context
The local coding agent stack involves multiple moving parts (Ollama, OpenCode, Commander, Registry). To ensure reproducibility and reduce operator error, we need a standardized way to configure, launch, and test the entire stack.

## Decision
We adopt a manifest-driven deployment strategy for the local coding stack.

1. **Lever Manifest**: Coding sessions will be defined as "levers" in `state/lever_manifest.yaml`, binding specific tools (like `coding.plan`) to governed MCP servers.
2. **Standard Justfile**: A root `Justfile` will provide unified commands for stack operations (e.g., `just ollama-start`, `just coding-session`).
3. **Environment Isolation**: A `scripts/env.sh` and `scripts/resolve_toolchain.sh` will ensure that the correct Rust toolchain and environment variables are present before any Commander command is executed.
4. **Configuration Versioning**: All agent-specific configurations (e.g., `config/opencode/opencode.json`, `config/ollama/modelfile.qwen3-coder`) will be committed to the repository and governed by the same PR process as the code.

## Consequences
- **Repeatability**: New contributors can spin up the full governed coding environment by running a few `just` commands.
- **Consistency**: All developers use the same model settings and agent constraints, reducing "works on my machine" issues.
- **Auditability**: Changes to the agent's behavior (via config changes) are visible in the Git history.

## Verification
- Running `just toolchain` must successfully resolve and export the local Rust environment.
- Running `just coding-session goal="Add a hello world"` should initiate the full flow: Commander -> OpenCode -> Ollama -> Plan output.
- `state/mcp_registry.yaml` and `state/lever_manifest.yaml` must be valid YAML and match the schemas in `multiplicity-common`.
