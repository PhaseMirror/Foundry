# ADR-112: Phase D - UnifiedWitness and Dual-Signature Protocol

## 1. Executive Summary
This Architecture Decision Record outlines the implementation of **Phase D (Recovery)** within the PIRTM-lang roadmap. It introduces the `UnifiedWitness` structure and the Dual-Signature Protocol. When an ACE constraint budget is exhausted or a governance mutation is rejected, recovery and re-certification require a cryptographically bound dual-signature that asserts manual override approval linked mathematically to the tensor compilation hash.

## 2. Design Rationale & Formal Model
To prevent unilateral overrides of the engine's compilation limits:
1. **UnifiedWitness:** A payload that tightly couples the `tensor_hash`, `compilation_timestamp`, and the `ace_deficit` into a single canonical message.
2. **Dual-Signature Protocol:** Recovery commands are only accepted if signed by two distinct, authorized operator keys (e.g., Primary Human Operator + Sentinel Agent).
3. Both signatures must independently resolve against the `UnifiedWitness` hash.

## 3. Production Implementation Scaffolding
- **`crates/pirtm-compiler/src/unified_witness.rs`**: Implements the `UnifiedWitness` struct and the verification traits for the dual signatures.

## 4. Next Steps
1. Create `unified_witness.rs`.
2. Hook `unified_witness.rs` into `lib.rs`.
3. Provide a Kani harness or Rust test logic to verify that omitting a signature causes rejection.

## 5. Status
**PROPOSED** - Proceeding with implementation in `pirtm-compiler`.
