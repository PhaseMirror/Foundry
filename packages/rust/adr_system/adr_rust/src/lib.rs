//! # ADR-0004 Euclid Multiplicity — Rust/Kani Formal Verification
//!
//! Production-grade scaffolding for the Architecture Decision Record defining
//! Euclid's arithmetic as a primitive theory of multiplicative structure.
//!
//! **Verification strategy:** Rust model checking via Kani (`cargo kani`) in
//! place of Lean4/mathlib.  Every theorem below has a corresponding `#[kani::proof]`
//! harness that exhaustively checks the invariant over bounded inputs.
//!
//! ## Modules
//! - `core` — ADR governance primitives (status, transition, registry, history)
//! - `euclidean` — integer hierarchy, prime factorization, divisor poset, multiplicity
//! - `proof` — Kani verification harnesses for all invariants
//! - `examples` — 3+ realistic ADR-0004 instances used by integration tests

pub mod core;
pub mod euclidean;
pub mod proof;
pub mod examples;
