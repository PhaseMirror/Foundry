# ADR-ALP-001: ALP as Native Policy and Contract Plane

## Status
Accepted

## Context
The current architectural trajectory enforces governance-first behavior through contract references, validation gates, and fail-closed execution paths. Legacy interfaces press to define workflow semantics, risking relocating authority away from native governance and into adapter code.

## Decision
ALP (Atomic Language Policy) will be the canonical policy, contract, and admissibility layer for all externally initiated actions.

All inbound actions from legacy platforms, operator dashboards, automation layers, and MCP tool surfaces must be normalized into ALP-native contracts before they are eligible for execution.

## Consequences
- Policy logic becomes native rather than inherited from legacy APIs.
- A single canonical place defines action admissibility, role semantics, contracts, and approval structure.
- Adapter complexity decreases as they only map to ALP contracts rather than reproducing domain logic.
- ALP becomes the durable control plane for governance-first product packaging.

## Verification
- Every externally triggered action maps to an ALP contract ID.
- No execution path bypasses ALP normalization.
- CI rejects adapters lacking ALP contract bindings.
