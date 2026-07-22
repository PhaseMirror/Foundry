# ADR-034: Lambda-Proof / Archivum Ledger Specification (Hyperledger Fabric)

## Status
Proposed

## Context
The monitoring suite requires immutable append-only storage for `LawfulRecursionHash`, `verify-word` results, `λ_eff` bounds, and ZKP receipts to comply with Tier 2 audit requirements.

## Decision
Adopt Hyperledger Fabric as the primary Lambda-Proof / Archivum backend.
- **Chaincode**: `AppendDigest(digest, metadata, receipt_hash)` with strict endorsement policy enforced by `AND('GovernanceMSP.member', 'CoreMSP.peer')`.
- **State-Based Granularity**: Use SBEP for tiered enforcement:
    - **Routine**: Default chaincode policy (`AND('GovernanceMSP.member', 'CoreMSP.peer')`).
    - **Critical (Quarantine, High-Stakes BudgetToken, λ_eff Violations)**: Stricter SBEP enforced by `AND('GovernanceMSP.member', 'RefereeMSP.member')`.
- **Querying**: `VerifyHistory(query)` for audit trails.
- **Integration**: `monitor_governance.py` will utilize the Fabric Python SDK to `submit_transaction` on every governance heartbeat.
- **Escalation**: All critical stability deviations trigger a human-in-the-loop escalation gate before automatic quarantine.
- **Endorsement Enforcement**: All transactions proposing Lambda-Proof / Archivum appends MUST be endorsed by the required MSPs based on key severity. Failures to collect these endorsements MUST trigger immediate quarantine of the monitor.
## Consequences
- **Security**: Fail-closed immutability.
- **Compliance**: Tier 2 audit provenance.
- **Risk**: Minimal drift; ledger integrity tied to existing endorsement policies.
