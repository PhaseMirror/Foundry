//! # Monodial Ensemble Aggregation (MEA)
//!
//! Production-grade Rust framework for monoidal ensemble aggregation
//! with formally verified algebraic laws.
//!
//! ## Design Principles
//!
//! - **Monoidal Structure**: Objects, morphisms, tensor product ⊗, unit I
//! - **Ensemble Combination**: Verified combination of multiple predictions
//! - **Aggregation Laws**: Associativity, identity, distributivity
//! - **Soundness First**: All algebraic laws verified with Kani

#![warn(missing_docs)]
#![warn(unsafe_code)]
#![cfg_attr(kani, allow(dead_code, unused_mut))]

#[cfg(kani)]
pub mod kani_proofs;

/// Core monoidal category structures.
pub mod monodial;

/// Ensemble types and combination operations.
pub mod ensemble;

/// Aggregation operations with verified laws.
pub mod aggregate;

/// Verification properties and algebraic law checks.
pub mod verify;

/// Error types and recovery strategies.
pub mod error;

/// Serialization and deserialization with verified round-trips.
pub mod codec;

/// Re-export core types for convenience.
pub use monodial::{MonoidalObject, MonoidalMorphism, MonoidalCategory};
pub use ensemble::{Ensemble, WeightedElement};
pub use aggregate::{AggregateOp, AggregationResult};
pub use verify::{AlgebraicLaw, LawVerification};
pub use error::{Error, Result};
