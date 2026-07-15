# ADR-MCP-004: HTTP/SSE Transport Layer

## Status
Accepted (2026-05-22)

## Context
Step 6 of the Phase 3 roadmap requires adding an HTTP/SSE transport layer to the Multiplicity MCP server. While `stdio` remains the default and most secure transport for local operation, HTTP/SSE unlocks dashboard integration and remote-node participation. We need to define the execution and security model for this new surface.

## Decision
We will implement an **Internal-only, Stateless HTTP** transport model:

1. **Surface Reachability**:
   - **Internal-only**: The transport will default to binding to `127.0.0.1` (loopback).
   - **Optional LAN**: Operators may explicitly configure a LAN bind (e.g., `0.0.0.0`) via CLI flags, but this emits a governance warning.
   - **TLS**: Deferred to Step 7+. For Phase 3, we assume the transport layer is protected by the host network (LAN/VPN) or restricted to loopback.

2. **Authentication (Stateless)**:
   - **Per-call SAT**: The Signed Admission Token (SAT) protocol (ADR-MCP-003) is the **sole** authentication mechanism.
   - **No Session Tokens**: We will not implement separate HTTP session tokens or cookies. Every tool call must carry its own valid SAT in the `arguments._sat` field.
   - This ensures identical policy semantics between `stdio` and `HTTP`.

3. **Concurrency & State**:
   - **Shared Replay Cache**: All clients (stdio or multiple HTTP connections) share the same `_REPLAY_CACHE`. 
   - **Thread-Safety**: The Python verifier's replay cache will be refactored to use thread-safe locks to prevent race conditions during concurrent HTTP requests.

4. **SSE (Server-Sent Events) Role**:
   - **Log Channel**: SSE is implemented as a read-only observer channel (`sse_role: log_channel`). It streams `UnifiedWitness` entries in real-time as they are committed.
   - **Unidirectional**: SSE does not initiate tool calls. Calls are always initiated via `POST /tools/call`.

5. **Authentication & Authorization**:
   - **POST /tools/call**: Requires a valid Signed Admission Token (SAT) in the request body.
   - **GET /tools/log (SSE)**: Requires a **Static Bearer Token** passed in the `Authorization` header.
   - **SSE Token Source**: The token is read from the `COMMANDER_SSE_BEARER_TOKEN` environment variable.
   - **Fail-Closed**: If `COMMANDER_SSE_BEARER_TOKEN` is missing, the SSE endpoint returns 401 Unauthorized.

6. **Execution Consistency**:
   - Both transports will route through the same `CommanderCore` instance and produce identical `UnifiedWitness` entries.
   - `pscmd archivum log` will not distinguish between transport paths, as the action itself is what is witnessed.

## Consequences
- Enables concurrent tool calls via HTTP/SSE.
- Simplifies client implementation: any standard HTTP client can call tools if it holds a valid SAT.
- Maintains transport parity: moving from `stdio` to `HTTP` requires zero changes to the underlying policy or tool handlers.
- Increases the importance of SAT replay protection and clock-sync between the orchestrator and the server.

## Verification
- `cargo test --test governance` passes when triggered via an HTTP mock client.
- `sat-e2e.yml` includes a job that verifies SAT acceptance over the HTTP path.
- Concurrent requests using the same token ID are correctly rejected by the thread-safe replay cache.
