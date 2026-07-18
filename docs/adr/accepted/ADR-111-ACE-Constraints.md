# ADR-111: ACE Invariant & Budget Constraint Verification

## 1. Executive Summary
This Architecture Decision Record outlines the implementation of **Phase C (Constraint Verification)** of the PIRTM-lang roadmap. It defines the formal invariant checks (ACE Invariant and Budget Checks) executed by the compiler over the Multiplicity Functor (`Sig<T>`).

## 2. Design Rationale & Formal Model
Governance-as-Compilation asserts that illegal or mathematically unsound governance mutations must result in a strict compilation failure, preventing the code from executing.
We introduce the **ACE Invariant** (Automorphic Contractive Energy):
- The aggregate sum of topological defects across all `Sig` functors must not exceed the globally defined ACE budget.
- Energy Budget Check: Total Multiplicity Weight * Topological Defect $\le E_{max}$.

## 3. Production Implementation Scaffolding
- **`crates/pirtm-compiler/src/ace.rs`**: Core verifier holding `ACEVerifier`.
- The verifier will ingest a vector of `Sig<T>`, calculate the global autormorphic contractive energy, and hard-reject (compile error) if $E_{total} > E_{max}$.

## 4. Next Steps
1. Create `ace.rs`.
2. Hook `ace.rs` into `lib.rs`.
3. Add a Kani harness to formally verify the budget bounds.

## 5. Status
**PROPOSED** - Proceeding with constraint verification implementation.
