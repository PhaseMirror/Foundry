//! The parametric MTC framework — the DRY core of the UTQC realization.
//!
//! Everything here is generic over a [`params::UseCaseParams`] `{ scope, modality, context }`.
//! The UOR Atlas `(q=4, T=3, O=8)` is *one instance*; no Atlas literal appears in this crate.
//! Each module realizes one row of the dictionary (`model/dictionary.toml`):
//!
//! | module | dictionary row |
//! |---|---|
//! | [`params`], [`labels`] | `objects-labels`, `label-space-belt` |
//! | [`inner`] | `inner-product` |
//! | [`generators`] | `reflection-generators` |
//! | [`spectrum`] | `spectrum` |
//! | [`coxeter`] | `coxeter-weyl` |
//! | [`modular`] | `modular-identities` |
//!
//! All numerics are integer/exact (no floating point), keeping the core no_std-clean and
//! the witnesses reproducible.

#![no_std]
#![forbid(unsafe_code)]

extern crate alloc;
#[cfg(test)]
extern crate std;

pub mod amplitude;
pub mod anchor;
pub mod coxeter;
pub mod generators;
pub mod inner;
pub mod labels;
pub mod modular;
pub mod octonion;
pub mod params;
pub mod spectrum;

pub use params::{ParamError, UseCaseParams};
