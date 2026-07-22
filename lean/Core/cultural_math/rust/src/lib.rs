//! Cultural Mathematics - Verified Implementations
//!
//! This crate provides verified implementations of algorithms from
//! various mathematical traditions, with specifications matching
//! the Lean4 formalization in the CulturalMath module.

pub mod egyptian;
pub mod chinese;
pub mod vedic;
pub mod pythagorean;
pub mod african;
pub mod russian;
pub mod grtf;

pub use egyptian::egyptian_mul;
pub use chinese::chinese_crt;
pub use vedic::vedic_mul;
pub use pythagorean::pythagorean_triple;
pub use african::african_halve;
pub use russian::boundary_op;
pub use grtf::grtf_iterate;
