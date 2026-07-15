# ADR-012: Inter-Ensemble Consensus & Dissonance Resolution Protocol

**Status:** Proposed
**Date:** 2026-06-16
**Owner:** The Commander / The Examiner

## 1. Context & Tension
Individual agents operate under strict domain-specific mandates. Conflict arises when mandates intersect (e.g., security lockdown vs. clinical innovation). The system requires a deterministic, machine-verifiable arbitration mechanism to ensure "Systemic Liveness" while preserving "Sovereign Integrity."

## 2. Decision: The Precedence Table
We adopt a hierarchical arbitration protocol based on a predefined Precedence Table to resolve dissonance between ensembles.

| Priority | Ensemble | Core Invariant | Conflict Resolution Role |
| :--- | :--- | :--- | :--- |
| 1 | **The Guardian** | Security/Safety | Veto Power on all actions. |
| 2 | **The Scopist** | Compliance/Legal | Veto Power on evidence-related actions. |
| 3 | **The Genius** | Innovation/Action | Proposer; yields to 1 & 2. |

### Dissonance Gating Logic
When cross-ensemble requests diverge:
1. **Detection**: The Examiner ensemble logs the dissonance via the Archivum Ledger.
2. **Arbitration**: If a deadlock is detected (t > 50ms without resolution), the arbiter (The Commander) enforces the hierarchy defined in the Precedence Table.
3. **Commit**: The winning action is recorded as a verified transition on the Archivum Ledger, invalidating the losing request.

## 3. Governance Mapping (Regulatory Compliance)
*   **Security Posture**: Deterministic conflict resolution prevents "stasis loops" which could be exploited to cause denial-of-service in critical clinical workflows.
*   **Compliance Control**: **45 CFR §164.308(a)(1)(ii)(B) Risk Management**. Ensures that operational conflicts are managed systematically rather than randomly.

## 4. Consequences
*   **Performance**: Adds deterministic latency (arbiter lookup).
*   **Risk**: If the Precedence Table is improperly ordered, critical clinical actions could be erroneously vetoed by over-conservative security invariants.

## 5. Verification Plan
Stress-test in the simulated Meta-Ensemble environment:
1. Inject contradictory directives between The Guardian and The Genius.
2. Verify that the arbiter resolves the conflict according to the Precedence Table within the deterministic time limit.
3. Confirm that the final state transition is correctly anchored in the Archivum Ledger.
