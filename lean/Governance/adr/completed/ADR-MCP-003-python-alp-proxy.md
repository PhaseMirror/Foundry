# ADR-MCP-003: Python-Rust ALP Proxy Protocol

## Status
Proposed (2026-05-22)

## Context
Step 5 of the Phase 3 roadmap requires that all Python MCP tool calls be governed by the Rust-side Atomic Language Policy (ALP) gate. Currently, the Python server (`mcp_server/app.py`) operates as an un-governed delegate. We need a structural boundary that ensures no Python tool executes without prior ALP admission.

## Decision
We will implement a **Blocking Pre-flight Proxy** model:

1. **Gate Strategy**: The ALP check will be **blocking**. The proxy will wait for a "PASS" result from the Rust ALP engine before allowing the Python handler to proceed. 
2. **Failure Mode**: **Fail-Closed**. If the ALP service is unreachable or returns an error, the tool call is rejected. Availability is sacrificed for constitutional integrity.
3. **Validation Surface (ABAC)**: The ALP check will validate **both Identity and Capability**:
   - **Identity**: Who is requesting the tool? (Operator ID or Agent Key).
   - **Capability**: Is this specific tool allowed for this identity under the current Constitution?
4. **Trust Token**: We will use a **Signed Admission Token (SAT)** format:
   - Python sends a `ProposalRequest` to the Rust proxy.
   - Rust returns a JSON object containing `allowed: bool`, `token: String` (a HMAC-SHA256 signature of the request), and `reason: Option<String>`.
   - The Python server must verify this token before execution.

## Consequences
- Guarantees that every Python tool execution is witnessed and governed.
- Introduces latency (one IPC round-trip) per tool call.
- Simplifies auditing: Python logs can include the Rust-issued token as proof of admission.
- Requires the Python server to be "ALP-aware," making the dependency explicit.

## Verification
- `cargo test --test governance` must include a case where a Python tool call is rejected due to policy violation.
- Logs must show the "Proxy Check: PASS" entry for all successful Python calls.
- `pscmd mcp list` shows all Python servers as `ALIGNED` (governed via proxy).
