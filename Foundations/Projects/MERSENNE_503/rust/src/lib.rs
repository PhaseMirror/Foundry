//! # MERSENNE_503 — Formal Verification Framework
//!
//! Production-grade Rust framework for verifying mathematical structures
//! related to the Mersenne prime M503 = 2^503 - 1, including:
//! - Leech-coded expanders
//! - Emergent AdS geometry
//! - Bayesian crystallization
//! - Prime-indexed tensor fields
//! - Post-quantum cryptographic primitives
//!
//! ## Verification Strategy
//!
//! | Layer | Tool | Scope |
//! |-------|------|-------|
//! | Unit tests | `cargo test` | Functional correctness |
//! | Proofs | `cargo kani` | Bit-precision, memory safety, algebraic invariants |
//! | Property testing | `cargo test` with proptest | Statistical verification |

#![warn(missing_docs)]
#![warn(unsafe_code)]
#![cfg_attr(kani, allow(dead_code, unused_mut))]

#[cfg(kani)]
pub mod kani_proofs;

/// Mersenne prime arithmetic and modular operations.
pub mod mersenne;

/// Leech lattice coding and Golay code structures.
pub mod leech;

/// Prime-indexed tensor field operations.
pub mod tensor;

/// PSL(2,R) group dynamics and hyperbolic geometry.
pub mod psl2r;

/// AdS (anti-de Sitter) geometric structures.
pub mod ads;

/// Bayesian crystallization and entropy operators.
pub mod bayesian;

/// Post-quantum cryptographic primitives.
pub mod crypto;

/// Error types and recovery strategies.
pub mod error;

/// Serialization and deserialization with verified round-trips.
pub mod codec;

/// Re-export core types for convenience.
pub use mersenne::Mersenne503;
pub use leech::{LeechLattice, GolayCode};
pub use tensor::{TensorField, TensorCoeff};
pub use psl2r::{PSL2R, MobiusTransform};
pub use ads::{AdSCoord, BulkPoint};
pub use bayesian::{CrystalLattice, CrystalPoint, EntropyOperator};
pub use crypto::{ZenoLock, PIRTMHash};
pub use error::{Error, Result};
