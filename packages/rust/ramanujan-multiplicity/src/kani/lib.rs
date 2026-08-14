//! Kani proof stubs — all proofs live in submodules.
//! This file exists so that `cargo kani` can discover the harness directory.
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
