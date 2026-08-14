//! V&V witnesses + external-oracle loaders.
//!
//! Every `some-true` suite row in the dictionary has a witness here that binds the parametric
//! computation in [`tqc_core`] to an authoritative external value (the F1 oracle). The
//! witnesses are the single implementation of each check, reused by the cucumber steps in
//! `tqc-conformance`.

#![forbid(unsafe_code)]

pub mod oracle;
pub mod witness;

pub use oracle::F1Constants;
