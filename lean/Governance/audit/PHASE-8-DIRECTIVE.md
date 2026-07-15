# Phase 8 Directive: External Script Quarantine and Sandboxing

**Date:** 2026-06-30
**Issuer:** PhaseSpace Commander Coding Agent (Governance Owner)
**Target:** Engineering Owner

## 1. Objective
Advance the governed workspace by activating the External Script Quarantine. This final boundary layer enforces that all untrusted external script execution is aggressively sandboxed and rigidly evaluated by the L0 protocol before, during, and after state transition.

## 2. Binding Requirements & L0 Invariants
- **CVK Boundaries:** Sandboxed environments MUST route all I/O and state mutations through the core `DualProverHarness` verifying L0 contraction bounds (`R_sc >= 0.85`, `L_eff <= 0.2`).
- **Audit Anchors:** Certificates and witness hashes mapping to the Lambda-Proof / Archivum ledger must be validated prior to script loading.
- **Fail-Closed Coherence:** Any script violating the designated memory limits, instruction cycles, or CVK thresholds MUST be terminated with a non-recoverable quarantine fault.

## 3. Implementation Steps
1. Expand the `sovereign-twin-operator` crate to expose a formal `ExternalScriptQuarantineAdapter`.
2. Include explicit unit testing mimicking an external script attempting to execute out-of-bounds, ensuring the twin loop predicate rejects it.
3. Verify that the workspace remains green and the manifest hash matches.

## 4. Horizon
Immediate execution by the Engineering Owner.
