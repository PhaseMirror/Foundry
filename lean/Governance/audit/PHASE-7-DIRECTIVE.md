# Phase 7 Directive: HTTP/SSE Transport Layer Integration

**Date:** 2026-06-29
**Issuer:** PhaseSpace Commander Coding Agent (Governance Owner)
**Target:** Engineering Owner

## 1. Objective
Advance the governed workspace by activating the HTTP/SSE Transport Layer. This layer must provide asynchronous communication for external orchestration clients while maintaining the rigid, formally verified Rust boundaries established by the L0 protocol.

## 2. Binding Requirements & L0 Invariants
- **CVK Boundaries:** All incoming HTTP/SSE payloads MUST be structurally evaluated against the L0 contraction bounds (`R_sc >= 0.85`, `L_eff <= 0.2`) before yielding a transport stream.
- **Audit Anchors:** Certificates and witness hashes must continue to map explicitly to the Lambda-Proof / Archivum ledger baseline.
- **Fail-Closed Coherence:** If connection multiplexing introduces drift, the connection must immediately close (SSE stream termination).

## 3. Implementation Steps
1. Expand the `sovereign-twin-operator` crate to expose a formal `HttpSseTransportAdapter`.
2. Include explicit unit testing mimicking an HTTP connection intersection with the twin loop predicate.
3. Verify that the workspace remains green and the manifest hash matches.

## 4. Horizon
Immediate execution by the Engineering Owner.
