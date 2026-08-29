#![deny(missing_docs)]
#![allow(clippy::excessive_precision)]

//! # certificate-runtime
//!
//! Production-grade certified graph learning runtime (ADR-0027).
//!
//! This crate implements the spectral contraction certificate for graph
//! heat-flow smoothing with memory safety and predictable performance.
//!
//! ## Architecture
//!
//! ```text
//! certificate-runtime
//! ├── certificate  — Safe public API (CertifiedState, step, check certificate)
//! ├── graph        — Graph representation and validation
//! ├── spectral     — Spectral gap / radius estimation
//! └── ffi          — FFI bridge to the Lean 4 certificate core
//! ```
//!
//! ## Verification
//!
//! The Rust implementation is verified against the Lean 4 specification
//! using Kani bounded model checking (`tests/kani/*.rs`). The Lean proof
//! of the spectral contraction theorem lives in `certificate-core`.

#![cfg_attr(kani, allow(unused_imports))]

pub mod certificate;
pub mod ffi;
pub mod graph;
pub mod spectral;

pub use certificate::{CertificateError, CertificateResult, CertifiedState};