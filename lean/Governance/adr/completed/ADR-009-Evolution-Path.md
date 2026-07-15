# ADR-009: The Evolution Path (t25 to t26)

**Status:** Proposed

**Date:** 2026-06-16

**Owner:** Phase Mirror / Substrates

## Context
The t25 archive currently serves as the "Gold Master" baseline for cryptographic integrity and auditability. As we transition to production-grade proving backends (Track E), we face a conflict between maintaining this immutable baseline ("Integrity Stasis") and the need for evolutionary development ("Operational Evolution").

## Decision: Versioned Stasis
We will transition from a single-state stasis model to a "Versioned Stasis" model.
1. **t25 Baseline Protection**: The t25 artifact is officially designated as "Immutable Read-Only" for compliance replay.
2. **t26 Evolutionary Path**: We are initializing the t26 development branch to serve as the integration environment for production-grade SNARK backend (e.g., arkworks/bellman).
3. **Traceability**: All transitions between these versions must be cryptographically linked through the Archivum Ledger, ensuring the lineage from t25 to t26 is verifiable.

## Consequences
- **Integrity**: Compliance baseline (t25) remains undisturbed and verifiable.
- **Velocity**: Development for Prover Hookup (Track E) proceeds without violating the t25 integrity seal.

## Implementation Path
1. Archive t25 checksum in `Governance/`.
2. Initialize `Track-E` environment inheriting from the verified t25 codebase.
3. Hook up ArchivumEmitter to production SNARK backend.
