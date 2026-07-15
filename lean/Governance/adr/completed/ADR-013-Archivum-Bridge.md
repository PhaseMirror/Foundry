# ADR-013: Cross-Ensemble Data Plane & Archivum Bridge

**Status:** Proposed
**Date:** 2026-06-16
**Owner:** Substrates / Publisher Ensemble

## 1. Context & Tension
As individual ensembles (Examiner, Publisher, Genius) operate with local autonomy, their state can diverge, threatening the Triple-Lock governance model. We must bridge these ensembles into a unified, audit-traceable data plane without sacrificing their modular sovereignty.

## 2. Decision: The Archivum Bridge (IPC)
We will implement an Inter-Process Communication (IPC) bridge as the mandatory path for cross-ensemble data exchange.
1. **Protocol Contract**: A shared Rust crate (`/Multiplicity/Ensembles/shared/bridge`) will define all IPC message schemas.
2. **Transport**: Unix Domain Sockets (UDS) for high-performance, OS-level secured local communication, mandated by PRODUCTION_STRICT posture.
3. **Immutability**: All bridge transactions must be cryptographically signed by the originating ensemble’s key and anchored into the Archivum Ledger.

## 3. Governance Mapping (Regulatory Compliance)
*   **Security Posture**: IPC via UDS is invisible to network-level sniffers; access is restricted by filesystem permissions.
*   **Compliance Control**: **45 CFR §164.312(e)(1) Transmission Security**. Ensures that data transmitted between ensemble processes is guarded against unauthorized access or tampering.

## 4. Consequences
*   **Performance**: Low-latency IPC; minimal overhead compared to network-based RPC.
*   **Risk**: If the UDS permissions are incorrectly configured, ensembles could potentially bypass the Bridge and interact directly, weakening the Triple-Lock.

## 5. Verification Plan
1. **Contract Integrity**: Compiler-enforced usage of the shared `bridge` crate.
2. **Access Control**: Unit test UDS listener permissions during ensemble startup.
3. **Audit Trail**: Every bridge message must result in a `LambdaTraceAtom` entry on the Archivum Ledger.
