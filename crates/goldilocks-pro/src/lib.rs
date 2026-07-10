pub mod scalar;
pub mod simd;
pub mod indexing;
pub mod resonance;
pub mod hamiltonian;
pub mod certification;
pub mod circuit;
pub mod simulation;
pub mod poseidon2;
pub mod ace_air;
pub mod consensus;
pub mod pell_vdf;

pub const MODULUS: u64 = 0xFFFF_FFFF_0000_0001;
pub const SCALE_GOLDILOCKS: u64 = 1 << 40;

pub use scalar::GoldilocksField;
pub use indexing::PrimeMask;
pub use resonance::ResonanceWord;
pub use hamiltonian::{Hamiltonian, HamiltonianTerm};
pub use certification::{SpectralWitness, FormalStabilityCertificate, CertificationStatus};
pub use circuit::ConvergencePublicInputsPro;
pub use simulation::AzTftcSimulation;
pub use poseidon2::*;
pub use ace_air::*;
pub use consensus::*;
