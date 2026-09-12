//! # MCPE — Formal Verification Framework
//!
//! Production-grade Rust framework for verifying perception, robotics and
//! intelligent machines protocols with bit-precision using Kani.
//!
//! ## Design Principles
//!
//! - **Soundness First**: All public API invariants are verified with Kani.
//! - **Zero-Cost Abstractions**: Verified code compiles to efficient machine code.
//! - **Modular Verification**: Each module owns its invariants and proofs.
//! - **Fail-Safe Defaults**: Unsafe operations require explicit opt-in.
//!
//! ## Verification Strategy
//!
//! | Layer | Tool | Scope |
//! |-------|------|-------|
//! | Unit tests | `cargo test` | Functional correctness |
//! | Proofs | `cargo kani` | Bit-precision, memory safety, protocol invariants |
//! | Fuzzing | `cargo fuzz` (optional) | Property-based stress testing |

#![warn(missing_docs)]
#![warn(unsafe_code)]
#![cfg_attr(kani, allow(dead_code, unused_mut))]

#[cfg(kani)]
pub mod kani_proofs;

/// Core protocol primitives and verified state machines.
pub mod protocol;

/// Formal state space definitions with verified transitions.
pub mod state;

/// Bit-precision numeric types with verified arithmetic.
pub mod numeric;

/// Error types with structured recovery strategies.
pub mod error;

/// Serialization and deserialization with verified round-trips.
pub mod codec;

/// Re-export core types for convenience.
pub use protocol::{Message, Session};
pub use state::{StateVector, Transition};
pub use numeric::{FixedPoint, UInt256};
pub use error::{Error, Result, StateId};
