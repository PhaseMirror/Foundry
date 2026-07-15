# ADR-ALP-002: Workflow Trust Levels and Execution Sandboxing

## Status
Accepted (2026-05-22)

## Context
Step 8 of Phase 3 requires a sandboxed execution path for untrusted external scripts. We need to distinguish between internal-trusted components and external-untrusted scripts, ensuring that the latter cannot access sensitive environment variables (SAT keys, GitHub tokens) or the Archivum ledger directly.

## Decision

### 1. Trust Level Taxonomy
We will introduce a `TrustLevel` enum in the `alp` crate:
- `Internal`: Full access to repository resources and environment variables. Used for co-developed scripts in `scripts/`.
- `External`: Restricted execution. No access to parent environment variables. No access to governed MCP tools.

### 2. Sandbox Execution Model (Phase 3)
To ensure portability and immediate implementation, we will use a **Structural Environment Sandbox**:
- **Environment Clearing**: `CommanderCore` will use `Command::env_clear()` for `External` workflows. Only explicitly allowed variables (e.g., `PATH`) will be re-injected.
- **Directory Isolation**: External scripts will execute in a dedicated `state/sandbox/<workflow_id>/` directory. They will have no write access to the parent repository.
- **Network Isolation**: For Phase 3, network isolation is enforced via **environment omission** (removing proxies and credentials). OS-level isolation (seccomp) is deferred to Phase 4.

### 3. Proxy Witness Authorship
- External scripts cannot commit to Archivum directly.
- `CommanderCore` will act as a **Proxy Author**, writing the `UnifiedWitness` on behalf of the external script.
- The `caller_identity` field in the witness will reflect the script name (e.g., `external-script.sh`), ensuring auditability while maintaining execution isolation.

### 4. Policy Enforcement
- The `ALP` engine will reject any `External` workflow attempting to call a governed MCP resource.
- This is enforced at the admission layer (`admission.rs`) before the process is spawned.

## Consequences
- Protects the repository from silent mutation or credential theft by untrusted scripts.
- Maintains a complete governance trail for all executions, regardless of trust level.
- Simplifies cross-platform support by using standard Rust `Command` APIs.
- External scripts are "governed-but-blind": they are recorded in the ledger but cannot read or write to it.

## Verification
- `cargo test --test governance` includes a fixture where an `External` script attempts to read `GITHUB_TOKEN` and fails (empty environment).
- Integration test verifies that an `External` script attempting to call an MCP tool is blocked by ALP.
