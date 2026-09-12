//! # Ramanujan Multiplicity Project — Kani Harnesses (ADR-233)
//!
//! Executable verification of every exported theorem in the Ramanujan
//! multiplicity crate.  Each harness lives behind `#[cfg(kani)]` and is
//! excluded from plain `cargo build` / `cargo test`.
//!
//! Properties are verified on bounded domains via `kani::assume` +
//! `#[kani::unwind]`.  Loop-free arithmetic is verified over the full
//! `u64` domain where Kani can handle it.

#[cfg(kani)]
pub mod primes;
#[cfg(kani)]
pub mod divisor;
#[cfg(kani)]
pub mod hcn;
#[cfg(kani)]
pub mod entropy;
#[cfg(kani)]
pub mod tau;
#[cfg(kani)]
pub mod partitions;
