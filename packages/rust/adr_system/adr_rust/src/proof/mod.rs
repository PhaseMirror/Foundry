//! Verification harnesses — re-exported for `cargo kani`.
//!
//! Kani compiles this crate when the `kani` cfg is active.
//! The harness functions live in submodules and are gated on `#[cfg(kani)]`.

pub mod adr_harnesses;
pub mod euclidean_harnesses;
