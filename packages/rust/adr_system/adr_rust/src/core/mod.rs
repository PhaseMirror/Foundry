//! Core ADR governance primitives.
//!
//! Provides the data model and transition logic for Architecture Decision Records,
//! with formal invariants enforced by construction where possible and verified by
//! Kani harnesses otherwise.

pub mod types;
pub mod adr;
pub mod registry;

pub use types::{AdrId, AdrStatus, ArtifactLink, AdrError};
pub use adr::Adr;
pub use registry::AdrRegistry;
