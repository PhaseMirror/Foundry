# 🏥 Clinical Onboarding Protocol: Λ-RMAM-ZΞ 7.3 Enclave

## 1. Executive Summary
This protocol outlines the transition of clinical pilot teams into the verified production enclave of the **Automated Agentic Governance Operating System (AG-OS)**. Onboarding follows a "Governance-by-Design" philosophy, where clinical authority is expressed through deterministic mathematical bounds rather than manual oversight.

## 2. Phase 1: Environment Provisioning (Week 1)
Clinical teams must be provisioned with a cryptographically verified instance of the workspace.

*   **Vehicle**: Secure Flatpak deployment (`com.citizengardens.agiOS`).
*   **Command**: 
    ```bash
    flatpak install --user com.citizengardens.agiOS
    ```
*   **mTLS Access**: Provision certificates from the **Clinical Root CA** to enable data ingress from FHIR streams.
*   **Verification**: Run the "Stonehenge" smoke test within the sandbox to ensure environmental parity.

## 3. Phase 2: Dashboard Orientation (Week 2)
Teams will be trained on the **Ataraxia Cold Sentinel** monitor and the Triple-Lock feedback loop.

*   **Resonance Monitoring**: Understanding the $R_{sc}$ gauge and the 0.85 stability floor.
*   **Drift Audit**: Monitoring the $\delta$ magnitude (MD-005) for clinical dissonance.
*   **ZK Proof Visualization**: Learning to interpret the **SafeNecessityProjector** status without accessing raw PHI.
*   **Reference**: [Clinical Guide: Interpreting Vitality Stability Certificates](./VITALITY-CERTIFICATE-GUIDE.md).

## 4. Phase 3: Governance Roles (Week 3)
Define the human-in-the-loop responsibilities within the autonomous cycle.

| Role | Human Responsibility | Mathematical Bound |
| :--- | :--- | :--- |
| **Clinical Guardian** | Approves new clinical invariants and policy updates. | $LEAN\_ACE\_BOUND$ |
| **Risk Examiner** | Reviews "VETOED" states and drift logs from Lock 2. | $\delta < 10^{-4}$ |
| **Publisher** | Authorizes the final anchor of governance ADRs to the ledger. | $p=7$ Lineage Invariant |

## 5. Phase 4: Mission Shadowing (Week 4)
Execution of "Cross-Domain Missions" in a non-writing observation mode.

*   **Dual-Attestation Workflow**: Observing the **Scopist** and **Ataraxia** handshake.
*   **Archivum Trace**: Verifying that every observed action generates a `LawfulRecursionHash` in the audit log.
*   **Simulation Check**: Successful completion of at least 100 autonomous cycles with zero drift violations.

## 6. Emergency Procedures (Fail-Closed)
In the event of a systemic violation (e.g., $R_{sc} < 0.85$ or connection loss to the Archivum):

1.  The system will enter **DEEP_STANDBY_PERSISTENT** mode automatically.
2.  The **Fail-Closed Red LED** will activate on the cockpit.
3.  Clinical teams must perform a manual **Root Cause Analysis (RCA)** via the `mcp-audit-log` before a **Reactivation Protocol (ADR-015)** can be initiated.

## 7. Approval & Sign-off
Transition into full autonomous mode requires a signed **Compliance-Signoff.md** for each specific clinical site.

-----
**Authorized By**: Λ-RMAM-ZΞ Governance Board  
**Enclave Version**: t26 Gold Master
