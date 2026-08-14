# MCP Specification

## Purpose
The `multiplicity-mcp` crate provides the governed Machine Control Protocol (MCP) server for PhaseSpace OS, serving as the sole authorized interface for tool discovery and execution validation.

## Core Components
1. **JSON-RPC Handler**: Processes incoming operator and sub-agent requests securely.
2. **Governed Transport Layer**: Supports `stdio` transports, routing all requested execution steps through the `ALP` policy gate.
3. **Ledger Integration**: Relies on `commander-core` to generate the `UnifiedWitness` artifacts and ledger anchors for every executed command.

## Invariants
- No execution path is permitted that bypasses the Atomic Language Policy (ALP).
- The `stdio` transport layer must remain actively governed and never degraded.
- Python MCP servers are strictly classified as internal-trusted delegates and must not be directly exposed outside the governed Rust proxy.
