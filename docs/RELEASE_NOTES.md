# Release Notes: Substrates v1.0.0

We are proud to announce the formal 1.0 release of the **Phase Mirror Substrates**, establishing a robust, cryptographically verifiable foundation for the Governance Engine.

## Highlights
1. **Verified Contraction Dynamics**: The `umc-parom` and `zeta-schrodinger` dynamics are completely verified in Lean 4 without relying on `Mathlib`'s heavy automation (e.g. no `ring` or `field_simp` tactics). All properties use localized foundational axioms, strictly complying with the Sedona Spine Mandate.
2. **WASM Integration**: The mathematical kernel directly compiles to WASM (`umc_parom.wasm`), providing a stable, portable witness that can be safely loaded into the execution layer.
3. **Rust Multiplicity Engine**: The core `moc-v2-tools`, `multiplicity-meta-ensemble`, and `governance-circuits` crates have been robustly audited and seamlessly evaluate the WASM-backed proofs. 

## Clean Architecture
- **Zero "Sorry"**: Our Lean formalization enforces absolute mathematical certainty, free of any incomplete proof stubs.
- **Stand-alone Provenance**: ADRs, architecture plans, and governance constitutions are consolidated into `/docs/architecture/` to serve as a single source of truth for the codebase's lineage.

We welcome feedback and forks as we push these verified invariants into live production contexts.
