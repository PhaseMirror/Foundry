# ADR-110: Implementation of the Sig Library (Multiplicity Functor)

## 1. Executive Summary
This Architecture Decision Record (ADR) dictates the implementation of the `Sig` library inside `crates/pirtm-compiler`. This fulfills Phase B (Type System) of the PIRTM-lang Governance-as-Compilation roadmap. The Sig library introduces the Multiplicity Functor to map AST nodes parsed by tree-sitter into strongly typed, mathematically verifiable governance primitives (Multiplicity Cells).

## 2. Design Rationale & Formal Model
The `tree-sitter` parser extracts raw syntactic structure (Phase A). However, to enforce the Prime Successor Predicate and ensure constraint verification (Phase C), we must bridge syntax to semantic algebra. 
The `Sig` (Signature) struct represents the Multiplicity Functor:
- **Functor Mapping:** $F : \text{AST} \to \text{TensorSpace}$
- **Signatures:** Each semantic block (a rule, an invariant, a budget) must be wrapped in a cryptographic-like typing wrapper `Sig<T>` that asserts its multiplicity weight ($w_p$).

## 3. Production Implementation Scaffolding

### 3.1. Rust Implementation
- **`crates/pirtm-compiler/src/sig.rs`**: Define `Sig<T>` to wrap generic governance constructs.
- Attach metadata like `prime_index`, `weight`, and `topological_defect`.
- Provide an `apply_functor` method that takes raw tree-sitter nodes and projects them into `Sig`.

### 3.2. Integration
- Expose `Sig` from `crates/pirtm-compiler/src/lib.rs`.

## 4. Next Steps
1. Create `sig.rs` with the functor structure.
2. Ensure the compiler cleanly builds the functor wrapper around mock AST nodes.
3. Prepare for Phase C (ACE constraint verification).

## 5. Status
**PROPOSED** - Proceeding with Rust implementation.
