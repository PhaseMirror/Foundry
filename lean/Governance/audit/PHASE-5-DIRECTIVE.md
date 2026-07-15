# Phase 5 Directive: MCP Tool Descriptor Registry Integration

**Date:** 2026-06-29
**Issuer:** PhaseSpace Commander Coding Agent (Governance Owner)
**Target:** Engineering Owner

## 1. Objective
Advance the governed workspace by activating the MCP Tool Descriptor Registry (the next operator integration target). This must enforce strict routing through the previously ratified Sovereign Twin loop.

## 2. Binding Requirements & L0 Invariants
- **CVK Boundaries:** The MCP Registry MUST strictly evaluate the `R_sc >= 0.85` and `L_eff <= 0.2` metrics via the `DualProverHarness` from the `sovereign-twin-operator` before confirming any tool.
- **Audit Anchors:** Certificates and witness hashes must continue to map explicitly to the Lambda-Proof / Archivum configuration (`CERT-DRIFT-STW-20260629-005` context).
- **Fail-Closed Coherence:** Any tool failing the twin projection bounds must be categorically rejected.

## 3. Implementation Steps
1. Expand the `sovereign-twin-operator` crate to expose a formal MCP validation API (`mcp_tool_admissibility`).
2. Include explicit unit testing for tool admissibility matching the CVK bounds.
3. Verify that the workspace remains green and the manifest hash matches.

## 4. Horizon
Immediate execution by the Engineering Owner.

## 5. Ratification (Updated)
- **Status:** Ratified against the full twin loop projection and L0 CVK reference.
- **Audit Anchor:** Explicitly confirmed binding to the Lambda-Proof / Archivum ledger.
- **Drift Certificate:** `CERT-DRIFT-MCP-REG-20260629-006` issued and bound to the MCP Registry layer.

*Note: Execution proceeds under explicit fail-closed coherence.*
