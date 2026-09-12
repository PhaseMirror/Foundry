pub mod group;
pub mod mask;
pub mod unitary;
pub mod spectral;
pub mod projection;
pub mod cert;
pub mod prequal;

pub use group::{AgpGroup, CrtEmbedding, legendre_symbol};
pub use mask::{ResidueMask, AdditiveLogits};
pub use unitary::{UnitaryPath, UnitaryError, SinkhornParams};
pub use spectral::{SatotTateConfig, BootstrapConfig, eigen_phases, SpectralError};
pub use projection::{ProjectionConfig, ProjectionCertificate, project_weighted_l1, ProjectionError};
pub use cert::{SoftmaxUB, SlopeUB, UnitarityResidual, PermutationKS};
pub use prequal::{Preregistration, PrequalError};
