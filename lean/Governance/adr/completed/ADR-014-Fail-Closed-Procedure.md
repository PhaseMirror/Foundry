# ADR-014: Emergency Fail-Closed Procedure

**Status:** Proposed
**Date:** 2026-06-16
**Owner:** Substrates / Clinical Audit

## 1. Context & Tension
Clinical data ingestion relies on the Archivum Ledger for cryptographic anchoring. If the Ledger becomes unreachable or the Archivum Bridge fails, the system faces a critical choice: continue processing (potentially creating unanchored PHI) or halt (causing service denial).

## 2. Decision: Absolute Fail-Closed Posture
We mandate an absolute fail-closed posture for all production ingestion pipelines.
1. **Trigger Condition**: If the `ArchivumEmitter` fails to receive an acknowledgment from the Ledger within 500ms, or if the Archivum Bridge IPC returns an `Error` status.
2. **Immediate Action**: The ingestion pipeline MUST trigger an immediate shutdown of the ingress process.
3. **Safety Guarantee**: No clinical data shall be processed, transformed, or anchored if the integrity chain is broken.

## 3. Governance Mapping (Regulatory Compliance)
*   **Security Posture**: Protects against unverified data entry into clinical systems.
*   **Compliance Control**: **45 CFR §164.308(a)(7)(i) Contingency Plan**. Ensures that in the event of an infrastructure failure, clinical operations cease rather than proceed in an unverified or insecure state.

## 4. Consequences
*   **Reliability**: Increased risk of service denial in the event of ledger/bridge instability.
*   **Integrity**: Eliminates the risk of "ghost" unanchored records.

## 5. Verification Plan
1. Simulated Failure: Inject network partitioning in the simulation environment between the Emitter and the Ledger.
2. Verification: Confirm the ingestion spine shuts down within <1s of the failure injection.
