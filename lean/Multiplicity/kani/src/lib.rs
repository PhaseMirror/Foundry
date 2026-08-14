//! # Multiplicity Kernel — Kani harnesses (ADR-0001)
//!
//! Executable verification half of the three-form contract: every Lean
//! `FormWitness` names a harness here (`kani/src/proofs/*.rs`) that model-checks
//! the matching Rust function against the property the Lean statement certifies.
//!
//! Every harness lives behind `#[cfg(kani)]`: under a plain `cargo build` /
//! `cargo test` the module compiles out (no `kani` crate dependency); under
//! `cargo kani` it is included and the `kani` library crate (bundled with the
//! Kani toolchain) provides `#[kani::proof]`, `kani::any`, `kani::assume` and
//! `#[kani::unwind]`.
//!
//! Properties on looping functions are verified on bounded domains via
//! `kani::assume` + `#[kani::unwind]`; loop-free arithmetic (division, gcd/lcm
//! lattice laws, Horner evaluation, the synthetic remainder theorem) is
//! verified over the full `u64`/`i64` domain, which mirrors the unbounded
//! `Nat`/`Int` statements of the Lean layer modulo `2^64` wrapping.

#[cfg(kani)]
pub mod proofs;
