# ADR-PM-024: Direct MCP-over-WebSocket Integration for Workbench Tool-Use

- Status: proposed
- Date: 2026-06-16
- Owners: Agency Team, Frontend Team, Governance Team
- Tags: mcp, websocket, tool-use, agency, agios
- Depends On: ADR-MCP-004, ADR-PM-006, ADR-PM-023
- Phase: phase-3

## 1. Context
The PhaseMirror Workbench (Angular) currently utilizes a simulated `McpService` with a custom message schema. While this provided initial UI feedback, it lacks the ability to execute real tools across the Phase Mirror Agency and AGIOS ensembles. 

The Model Context Protocol (MCP) provides a standardized JSON-RPC 2.0 framework for tool discovery and execution. While ADR-MCP-004 defined an HTTP/SSE transport for read-only logging, a full-duplex **WebSocket transport** is required for interactive tool use in the Workbench to:
1.  Allow real-time tool discovery (`tools/list`).
2.  Enable low-latency tool execution (`tools/call`).
3.  Support streaming responses and progress notifications.
4.  Maintain a persistent, stateful connection between the UI and the Agency.

## 2. Decision
We will implement a direct **MCP-over-WebSocket** integration between the PhaseMirror Workbench and the Phase Mirror Agency.

### 2.1 Backend: Agency MCP Server
- **Host**: `Agency/agency-server` (Node.js).
- **Transport**: `WebSocketServerTransport` (using the `@modelcontextprotocol/sdk`).
- **Port**: `3001` (to align with "The Commander" reference in `AGENTS.md`).
- **Capability**: Proxy tool calls to the Sedona Spine (Rust), AGIOS (Fastify/Hardhat), and local MCP agents.
- **Security**: Validate Signed Admission Tokens (SAT) for all tool calls, as per ADR-MCP-003.

### 2.2 Frontend: Workbench MCP Client
- **Service**: `McpClientService` in `workbench/src/app/core/services/mcp.service.ts`.
- **Transport**: `WebsocketTransport` (from `@modelcontextprotocol/sdk` or custom RxJS implementation of the MCP spec).
- **Integration**: The `McpDashboardComponent` will be refactored to use real tool data returned from `tools/list` instead of hardcoded signals.

### 2.3 Protocol Logic
- Use standard JSON-RPC 2.0 frames as defined in the MCP specification.
- `initialize`: Exchange capabilities between Workbench and Agency.
- `tools/list`: Retrieve available governance and system tools.
- `tools/call`: Execute tools (e.g., `checkpoint_write`, `ledger_query`) with SAT-bound parameters.

## 3. Implementation Plan
1.  **Dependency Update**:
    - Add `ws` and `@modelcontextprotocol/sdk` to `Agency/agency-server`.
    - Add `@modelcontextprotocol/sdk` to `workbench`.
2.  **Agency Server Refactor**:
    - Implement `Agency/agency-server/src/mcp-server.js`.
    - Integrate with the existing `express` app in `Agency/agency-server/src/index.js`.
3.  **Workbench Service Refactor**:
    - Update `McpService` to use the standard MCP client logic.
    - Wire `McpDashboardComponent` to the new reactive tool signals.
4.  **Validation**:
    - Verify that `tools/list` correctly returns Agency tools (`health_check`, `sovereign_posture`).
    - Verify that `tools/call` triggers actual logic in the Sedona Spine or Agency.

## 4. Alternatives Considered
- **HTTP/SSE + POST**: (ADR-MCP-004) Rejected for interactive tool-use due to higher latency and lack of full-duplex progress reporting.
- **Direct gRPC**: Rejected. Overkill for web-based UI integration and requires more complex browser-side proxying.

## 5. Risks
- **Concurrency**: Handling multiple simultaneous tool calls over a single WebSocket requires robust request ID tracking (built into MCP/JSON-RPC).
- **Security**: The WebSocket port (`3001`) must be bound to `127.0.0.1` by default for local development.

## 6. Consequences
- **Positive**: Standardized tool-use interface across the entire PhaseMirror ecosystem.
- **Positive**: Real-time feedback and progress for long-running governance tasks.
- **Negative**: Increased complexity in the Agency server's transport management.
- **Positive**: High-fidelity UI that accurately reflects the state of the underlying engines.
