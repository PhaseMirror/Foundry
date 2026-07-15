# ADR-CODE-002: Coding Agent MCP Contract

## Status
Proposed

## Context
To enable modularity in the coding agent stack, we need a stable protocol contract between the Commander (Governor) and any coding agent (Planner). This ensures that Commander can delegate planning tasks to different agents (OpenCode, custom Rust agent, etc.) without changing its core orchestration logic.

## Decision
We define a "Coding Agent" role as an MCP server that exposes the following tools. All inputs and outputs must follow these structured schemas to remain machine-verifiable by Commander's ALP gate.

### 1. `coding.plan`
**Input**:
- `goal`: A string describing the desired change (e.g., "Implement a new CLI command").
- `context_files`: A list of file objects `{ path: string, content: string }`.
- `constraints`: A list of strings (e.g., "no new dependencies", "must pass existing tests").

**Output**:
- `steps`: An array of actions:
    - `{ type: "read", path: string }`
    - `{ type: "edit", path: string, patch: string }` (Unified Diff format)
    - `{ type: "run", command: string, args: string[] }` (Limited to test/build commands)
    - `{ type: "explain", message: string }`

### 2. `coding.patch`
**Input**:
- `path`: The target file path.
- `original_content`: The content before the change.
- `proposed_change`: Either a patch or the full new content.

**Output**:
- `unified_diff`: The validated, minimal diff to be applied.
- `explanation`: Why this change satisfies the goal.

### 3. `coding.explain`
**Input**:
- `diff`: A unified diff.
- `scope`: Optional string (e.g., "security", "performance").

**Output**:
- `analysis`: A detailed natural language explanation.
- `risk_level`: `Low`, `Medium`, or `High`.

## Consequences
- **Interoperability**: Any MCP-compliant agent can become a "Commander Coding Agent" by implementing this spec.
- **Validation**: Commander can use the structured `steps` from `coding.plan` to pre-validate every proposed action against ALP policies.
- **Minimalism**: Agents are not required to handle file I/O or Git; they only process the data provided by Commander.

## Verification
- MCP tool definitions in `crates/mcp/src/coding_agent.rs` (or equivalent) must match this spec.
- Automated tests using a mock agent must verify that Commander correctly parses and executes the `steps` array.
- Schema validation for the `coding.plan` response in the `UnifiedWitness`.
