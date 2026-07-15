# ADR-048: Triple-Lock Governance Ensembles (The Examiner & The Publisher)

**Status:** Proposed  
**Date:** 2026-06-16  
**Owner:** Governance  

## Context

As the agiOS framework matures, the risk of runtime semantic drift or policy bypass increases. An agentic AI or compromised service could override stability limits or record fraudulent facts to the ledger. To guarantee that actual operations never drift from stated intent, we require an independent, autonomous monitoring loop that validates state transitions and codifies them into immutable governance records.

## Decision

We commit to implementing the **Triple-Lock Governance Ensembles**:
1. **The Examiner**: A specialized, out-of-band monitoring ensemble that regularly audits the active state against the contractivity threshold ($\delta < 10^{-4}$). In the event of a drift breach, the Examiner broadcasts a high-priority `SIG_GOV_KILL` signal, halting all clinical transitions immediately.
2. **The Publisher**: A specialized verification ensemble that packages, hashes, and signs all runtime changes (ADRs, schemas, configuration manifests) before committing them to the immutable Archivum ledger.
3. **Workspace Invariants**: Declare these ensembles as workspace crates (`Phase Mirror/phasemirror-agency/ensembles/the-examiner/harness` and `the-publisher/harness`) to enforce isolation from the main transaction data plane.

This maps to the `Ξ-Constitutional-Core` by establishing automated, independent safety feedback loops.

## Consequences

- **Security Posture**: Protects the system against rogue actors or policy drift. The runtime is monitored by non-privileged auditor processes.
- **Performance**: The Examiner executes asynchronously and out-of-band to ensure zero latency overhead on client mTLS streams.
- **Compliance**: Satisfies **45 CFR §164.312(b) (Audit Controls)**.

## Verification Plan

We will stress-test the drift monitor:
1. **Drift Escalation Probe**: Inject synthetic telemetry drift exceeding $\delta = 10^{-4}$ and assert that the Examiner intercepts this and triggers `SIG_GOV_KILL` to lock the gateway.
2. **Immutability Sign-Off Test**: Verify that the Publisher successfully computes the `LawfulRecursionHash` and commits artifacts to the ledger.
