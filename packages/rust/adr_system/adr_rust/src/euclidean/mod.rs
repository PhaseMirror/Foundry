//! Euclidean multiplicity primitives.
//!
//! Formalizes the mathematical content of ADR-0004:
//! - Integer hierarchy: Unit → Number → Prime → Composite
//! - Prime factorization (existence + uniqueness, bounded by Kani)
//! - Divisor poset D(n)
//! - Multiplicity profiles: v_p(n), τ(n), σ(n), ω(n), Ω(n)
//!
//! **Bounded verification note:** Kani is a bounded model checker.
//! All mathematical theorems are verified up to a compile-time constant
//! `MAX_INT` (default 1024).  This is sound for the intended application
//! because the properties are monotonic and the bound is easily raised.

pub mod types;
pub mod arithmetic;
pub mod proof;

pub use types::*;
pub use arithmetic::*;
