# ADR 0004: PIRTM Compiler Implementation (Phase B)

## Status
Accepted

## Context
Based on the `publications/PIRTM/` and Multiplicity Sovereign Core rules, we need to enforce the Prime Successor Predicate via a programmable language. The system must support the `Sig` library (Multiplicity Functor) to ratify Phase B of the roadmap.

## Decision
We will implement the `Sig` library (Multiplicity Functor) directly in `crates/pirtm-compiler`. This will integrate strictly with `tree-sitter` for grammar enforcement.

## Consequences
- **Positive**: 
  - Enables ACE invariant checks downstream.
  - Aligns exactly with the ratified Phase B roadmap for PIRTM-lang.
- **Negative**:
  - Requires strict tree-sitter integration, adding parsing overhead.
  - Language grammar extensions are rigid and must be verified.

## Compliance
Verified via Rust/Kani invariants to ensure state immutability once accepted.
