# ADR-003: Data Normalization & Bus-Net Bridge

**Status:** Proposed
**Date:** 2026-06-16
**Owner:** Substrates

## 1. Context & Tension
The ingestion pipeline must normalize heterogeneous clinical data before it enters the proving backend. The tension lies in the velocity required to process high-volume clinical streams versus the rigid requirement that every normalization step must be cryptographically anchored to prevent data corruption or provenance loss.

## 2. Decision: The Implementation Approach
We will implement a stateless normalization layer that maps incoming data structures directly to the `LambdaTraceAtom` schema defined in ADR-008. This normalization logic will operate within the TEE, ensuring the transformation itself is part of the witness generation. This aligns with the `Ξ-Constitutional-Core` mandate of "Governance-by-Design".

## 3. Governance Mapping (Regulatory Compliance)
*   **Security Posture**: Data is normalized within the TEE boundary before crossing the Bus-Net Bridge to the Archivum Ledger.
*   **Compliance Control**: **45 CFR §164.312(b) Audit Controls**. This bridge ensures that every normalized datum has a corresponding immutable audit record on the Ledger, satisfying the requirement to implement hardware, software, and procedural mechanisms that record and examine activity in information systems.

## 4. Consequences
*   **Performance**: Introducing normalization within the TEE will increase latency by ~2-5ms per atom.
*   **Risk**: If the normalization logic fails, the downstream Prover backend will receive malformed witnesses, triggering a "Fail-Closed" state.

## 5. Verification Plan
Stress-test within `agios-staging-package-t25`: Must pass 10^5 randomized ingestion cycles through the normalization layer, verifying that 100% of generated atoms match the expected `LambdaTraceAtom` schema and have valid cryptographic links to the t25 baseline.
