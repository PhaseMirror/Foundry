# ADR-MCP-001: MCP Exposure Through Native Authority Boundaries

## Status
Accepted

## Context
MCP servers are useful as outward-facing tool interfaces, but exposing tools directly to execution surfaces would allow clients and connectors to bypass native authority. The architecture instead favors explicit authority boundaries and validated execution gates.

## Decision
MCP servers will expose capability surfaces outwardly, but all actionable tool invocations must route through ALP admission and Sigma execution.

In this pattern, MCP is a protocol shell, not the policy or execution authority.

## Consequences
- External agents can consume capabilities without bypassing governance.
- MCP becomes a distribution layer for native tools rather than a replacement for native architecture.
- Tool monetization becomes possible without surrendering runtime sovereignty.

## Verification
- Every MCP tool that mutates state references an ALP contract.
- Every mutating MCP action returns or links to a Sigma receipt / Unified Witness.
- Read-only tools are explicitly classified and separated from mutating tools.
