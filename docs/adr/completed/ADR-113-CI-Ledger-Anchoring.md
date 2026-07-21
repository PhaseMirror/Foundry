# ADR-113: Mandatory Witness-to-Ledger Anchoring in CI

## 1. Executive Summary
This Architecture Decision Record establishes the **Production Pipeline** enforcement for the PIRTM-lang Governance-as-Compilation framework. To ensure zero-drift integrity, all generated `UnifiedWitness` cryptographic proofs must be irrevocably anchored to a verifiable ledger before merging into the main branch.

## 2. Design Rationale & Formal Model
The compilation pipeline strictly validates Phase A (grammar), B (signatures), C (budget invariants), and D (dual-signature recovery overrides). However, local validation is vulnerable to tampering.
To achieve absolute integrity:
- **Ledger Anchor Protocol:** The continuous integration (CI) pipeline must extract the `UnifiedWitness` structure, hash it, and anchor the signature to a tamper-proof ledger (or emit an irreversible artifact hash proof). 
- Pull Requests cannot be merged if the CI environment fails to certify the ledger anchor, providing a mechanical block against rogue agent manipulation.

## 3. Production Implementation Scaffolding
- **`.github/workflows/ledger-anchoring.yml`**: A GitHub Actions CI pipeline that strictly enforces the witness extraction and ledger anchoring.
- **Workflow:** 
  1. Triggers on all Pull Requests and pushes to `main`.
  2. Compiles `crates/pirtm-compiler`.
  3. Executes a verification script checking for un-anchored `UnifiedWitness` traces.

## 4. Next Steps
1. Deploy the YAML configuration to `.github/workflows/ledger-anchoring.yml`.
2. Finalize the `PIRTM-lang` roadmap.

## 5. Status
**PROPOSED** - Proceeding with CI configuration.
