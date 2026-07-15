# ADR-009: Pro-Core Schema Synchronization & Drift Prevention

## Status
Proposed

## Context
The Multiplicity ecosystem consists of a public "Open Core" (Phase Mirror MCP) and a proprietary "Pro" layer. To maintain the **Zero Drift** mandate, the Pro version must stay perfectly synchronized with the underlying mathematical schemas of the Open Core (e.g., `mcp-contract.json`, `PersistentWormBlock`, and PIRTM state vectors). 

Failure to synchronize results in "interpretive drift," where enterprise coordination logic operates on a stale or mismatched understanding of the Lawful Protocol-State.

## Decision
We will implement a **Manifest-First Synchronization CI** using the following architecture:

1.  **Schema Authority**: The Open Core repository (`phase-mirror-mcp`) remains the sole authority for base schemas. 
2.  **Downstream Verification**: The Pro-version repository will include a GitHub Action/CI job that:
    *   Fetches the latest `main` branch schemas from the Open Core.
    *   Performs a structural diff against the Pro-version's internal ingestion DTOs (Data Transfer Objects).
    *   Executes `cargo test` using a cross-repo "Compatibility Harness" that validates that Pro-version logic can still process Open Core Lambda-Proof / Archivum logs.
3.  **Version-Pinning**: Pro-version releases will explicitly pin a git hash of the Open Core. Any update to this pin requires a successful execution of the Drift-Audit suite.
4.  **Automated Veto**: Any PR in the Pro-version that introduces a schema change incompatible with the current Open Core main branch will be automatically blocked by the CI gate.

## Technical Implementation
- **Tooling**: Use `schemars` in Rust to generate JSON schemas from Open Core structs and `jsonschema` in the CI to validate Pro-version configurations.
- **Drift Detection**: A dedicated binary `drift-check` will be compiled in the Pro CI to compare the `mcp-contract.json` schemas of both repositories.

## Consequences
- **Positive**: Guarantees technical integrity between public and private layers. Prevents "hidden" bugs in proprietary compliance packs.
- **Negative**: Increases CI complexity and introduces a strict dependency on the Open Core's stability.
- **Neutral**: Requires high discipline in versioning; "breaking" changes in Open Core will necessitate immediate coordination updates in Pro.

---
**Ratified by Phase Mirror CSC-001**
*Timestamp: 2026-06-15*
