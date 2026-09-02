//! # Λ^p-Archivum (Prime-Indexed Content-Addressed Store)
//!
//! The canonical, permanent storage container where historical objects are stored
//! with complete provenance. Every artifact factors uniquely into prime-irreducible
//! components (PIRs) and is indexed into the prime-factorized Archivum multigraph (Ξ).

pub mod ledger;
pub mod prime_index;
pub mod proofs;

pub use ledger::{ArchivumLedger, Witness, ArchivumError};
pub type WitnessLedger = ArchivumLedger;
pub use prime_index::{LambdaPStore, ContentAddress, PrimeIndex, PrimeFactor, StoredArtifact};
pub use proofs::*;
