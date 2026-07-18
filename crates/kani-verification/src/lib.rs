//! Kani verification harnesses for Lean sorry elimination.
//!
//! This crate contains Rust implementations of computable kernels that back
//! Lean axioms. Each function is proven correct with Kani.
//!
//! ## Verified Modules
//!
//! - `spectral_stability` — Gershgorin bound, power iteration, convergence rate
//! - `interval_arithmetic` — Interval operations with correctness proofs
//! - `crmf_obligations` — State transition lemmas for CRMF

pub mod spectral_stability;
pub mod interval_arithmetic;
pub mod crmf_obligations;
pub mod multiplicity_operators;
pub mod matrix_engine;
pub mod multiplicity_equations;
pub mod universal_system;
pub mod multiplicity_cell;
