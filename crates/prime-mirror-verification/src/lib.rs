//! prime-mirror-verification
//!
//! Rust implementation and Kani verification of ADR-401 (Identity Integration)
//! and ADR-402 (Phase Mirror Dissonance) invariants.
//!
//! All production invariants are verified here with Kani model checking.
//! The Lean 4 modules provide type-level specifications only.

pub mod identity;
pub mod dissonance;

pub use identity::*;
pub use dissonance::*;
