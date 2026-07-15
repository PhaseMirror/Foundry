# ADR-005: Agency Governance & The Triple-Lock Protocol

**Status:** Accepted

**Date:** 2026-06-15

**Owner:** Phase Mirror Orchestrator

## Context
Transitioning to a multi-agent industrial complex creates a bottleneck in traditional human-led audit and compliance. We must automate the "Triple-Lock" governance loop to ensure velocity without sacrificing integrity.

## Decision: The Triple-Lock Protocol
1. **The Examiner (Drift Audit)**: An autonomous ensemble that monitors all Agency State transitions. If drift $|\delta(t)| > 10^{-4}$ against the verified baseline, the Examiner triggers an immediate halt on all pending publisher actions.
2. **The Publisher (Artifact Registrar)**: An autonomous ensemble responsible for anchoring all state transitions to the Archivum Ledger using the `LawfulRecursionHash`.
3. **The Commander (Agency Source)**: Issues state transitions that are ONLY permitted if the Examiner provides a "Zero-Drift" pass and the Publisher provides an "Immutable Registration" stamp.

## Consequences
- **Security**: Deterministic, continuous audit. No state transition bypasses the lock.
- **Velocity**: Bureaucratic audit is replaced by high-frequency, machine-to-machine validation.
- **Liability**: Liability is anchored to specific state transitions tied to verifiable ensemble signatures.

## Implementation Plan
- Examiner: Drift detection @ 1e-4 threshold.
- Publisher: LawfulRecursionHash anchoring per transition.
