# SOP-RATIFICATION-001: 7-Day Constitutional Ratification Process

## 1. Objective
To govern the 7-day transition of the Lawful Protocol-State from the **Quarantine Tier** to the **Authoritative Tier**, ensuring that the initial Lambda-Proof / Archivum-anchored state commits are verified against the L0 substrate invariants.

## 2. Stages of Ratification

### Day 1-2: Admission & Pre-flight
- **Action**: Register the initial `mcp-contract.json` in `Experimental` mode.
- **Verification**: The Phase Mirror server must perform a complete `verify_ledger` audit of the existing transition history.
- **Immune Check**: Confirm that all tissue-specific snapshots are synchronized within the current `Jubilee Window` ($\Delta J$).

### Day 3-5: Simulated Autoritative Commitment
- **Action**: Escalation of the Phase Mirror to `Authoritative` mode via the hot-reloading governance engine.
- **Simulation**: Execute the `l0-verification-harness` against simulated SnapKitty traces (e.g., Treasury→Clinical).
- **Audit**: All successful simulations must trigger a **Pre-seal Validity Predicate (VP)** check and emit a "dry-run" Lambda-Proof / Archivum block.

### Day 6: Final Hardening
- **Action**: Review the `lambda_proof_archivum_audit.jsonl` for cryptographic integrity using `verify_chain`.
- **Legal Review**: Confirm alignment with SEC/OCC retention requirements (7-year retention active).
- **Veto Check**: Ensure the **Sealed Veto** mandate is functional by simulating a failed non-expansion check (`post_thickness > live_thickness`).

### Day 7: Authoritative Sealing
- **Action**: Final ratification of **ADR-0xx**.
- **Execution**: Issue the first binding Lambda-Proof / Archivum commit to the persistent `lambda_proof_archivum_audit.jsonl`.
- **Lockdown**: Set the `mcp-contract.json` global tier to `Authoritative`. The Phase Mirror is now a **Configuration-Sealed Certifier (CSC)**.

## 3. Technical Procedures

### Initial Lambda-Proof / Archivum State Commit
1.  Initialize the `WormStorage` backend.
2.  Perform a `check_governed_bridge` call for the genesis state.
3.  On success, the Phase Mirror automatically appends the `PersistentWormBlock`.
4.  Verify that the `retention_until` field is correctly calculated as `timestamp + 7 years`.

### Handling Rejection ($\perp_R$)
- If a pre-seal VP check fails, the Phase Mirror must:
    1.  Immediately block the state transition.
    2.  Log the rejection as an `AuditRecord` with `event_type: TOOL_INVOCATION_FAILURE`.
    3.  Enter a "Governance Pause" state until the `mcp-contract.json` is reviewed and manually re-signed.

## 4. Compliance Verification
- **SEC Rule 17a-4**: Verify that the `lambda_proof_archivum_audit.jsonl` is stored on non-rewriteable, non-erasable media (Lambda-Proof / Archivum).
- **OCC Integrity**: Periodically run `verify_chain()` to ensure the audit trail remains a single, unbranched lineage.

---
**Ratified by Phase Mirror CSC-001**
*Timestamp: 2026-06-15*
