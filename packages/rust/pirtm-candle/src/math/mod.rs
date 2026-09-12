pub mod spectral;
pub mod recurrence;
pub mod lambda_bridge;
pub mod gate;
pub mod types;
pub mod projection;
pub mod audit;
pub mod certify;

// Re-exports
pub use spectral::{SpectralGovernor, SpectralReport, SpectralMetrics, GershgorinCertificate, GershgorinDisk};
pub use recurrence::step;
pub use lambda_bridge::LambdaTraceBridge;
pub use gate::{EmissionGate, EmissionPolicy};
pub use types::{Status, PrimeMask, ResonanceWord, StepInfo};
