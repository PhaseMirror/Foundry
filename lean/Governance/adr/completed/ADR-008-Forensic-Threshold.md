# ADR-008: Metadata Minimization & The Forensic Threshold

**Status:** Proposed

**Date:** 2026-06-16

**Owner:** Governance & Clinical Audit

## 1. Context & Tension
The Archivum Ledger must balance clinical forensic reconstruction with absolute PHI minimization. Logging too much metadata creates a secondary PHI repository; logging too little renders the audit chain useless for clinical investigation.

## 2. Decision: The Forensic Threshold
We distinguish between **Forensic Context** (required for audit reconstruction) and **Privacy Prohibited** (any field that could lead to re-identification or PHI leak).

### LambdaTraceAtom Schema (Conceptual)
```rust
pub struct LambdaTraceAtom {
    pub forensic_context: ForensicContext,
    pub validity_proof: ValidityProof,
}

pub struct ForensicContext {
    pub transaction_id: String, // UUID only
    pub timestamp: String,
    pub circuit_version: String,
    pub policy_id_hash: String, // Opaque hash of applied policy
}

pub struct ValidityProof {
    pub proof_digest: String,
    pub state_root: String,
}
```

## 3. Forensic Threshold Policy
- **Audit Mandatory**: Transaction UUID, timestamp, circuit version, policy ID hash (all non-PHI).
- **Privacy Prohibited**: Patient names, DOBs, MRNs, raw observation values (these exist only within the ZK witness computation and are discarded after proof generation).

## 4. Consequences
- **Privacy**: Ledger remains PHI-free.
- **Auditability**: Forensic reconstruction is possible *that* a transaction happened, *when*, and under *what* policy, without knowing *to whom* or *what* data.

## 5. Verification Plan
1. Validate schema definitions in `src/audit.rs`.
2. Ensure the Prover backend explicitly strips all fields outside `ForensicContext` before finalizing the `LambdaTraceAtom`.
3. Validation via integration test: Verify that a `LambdaTraceAtom` payload fails to map to any existing patient record in the EMR.
