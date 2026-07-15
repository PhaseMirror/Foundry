# Phase 6 Directive: Python MCP Policy Proxy Integration

**Date:** 2026-06-29
**Issuer:** PhaseSpace Commander Coding Agent (Governance Owner)
**Target:** Engineering Owner

## 1. Objective
Advance the governed workspace by activating the Python MCP Policy Proxy. This layer will govern untrusted internal delegate servers (Python-based MCP servers) by proxying all requests through the formally verified Rust operator layer.

## 2. Binding Requirements & L0 Invariants
- **CVK Boundaries:** The proxy MUST enforce the L0 structural bounds (`R_sc >= 0.85`, `L_eff <= 0.2`) on every call transiting to or from the Python server.
- **Audit Anchors:** Certificates and witness hashes must continue to map explicitly to the Lambda-Proof / Archivum configuration (`CERT-DRIFT-MCP-REG-20260629-006` foundation).
- **Fail-Closed Coherence:** Python-based delegate tools must only be invoked if they have an active `TrustLevel::Internal` classification, and fail immediately if they drift.

## 3. Implementation Steps
1. Expand the `sovereign-twin-operator` crate to expose a formal `PythonMcpProxyAdapter`.
2. Include explicit unit testing mimicking a Python MCP request intersecting the twin loop predicate.
3. Verify that the workspace remains green and the manifest hash matches.

## 4. Horizon
Immediate execution by the Engineering Owner.
