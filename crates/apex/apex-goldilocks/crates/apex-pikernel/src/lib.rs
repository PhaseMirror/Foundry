//! # apex-pikernel
//!
//! Exact-arithmetic Rust implementation of π-kernel for ACE and PETC.
//! Complies with the Sedona Spine mandate of zero floating-point reliance.

pub mod projectors;
pub mod l1proj;
pub mod kernel;
pub mod ledger;
pub mod certificates;
pub mod mub_audit;
pub mod poseidon;
pub mod routing;
pub mod hologram_adapter;
pub mod rns;

// Re-exports
pub use projectors::*;
pub use l1proj::{project_weighted_l1_ball, Rational};
pub use kernel::*;
pub use ledger::*;
pub use certificates::{slope_upper_bound, gap_lower_bound};
pub use mub_audit::*;
pub use poseidon::*;
pub use routing::*;
pub use hologram_adapter::*;
pub use rns::*;
