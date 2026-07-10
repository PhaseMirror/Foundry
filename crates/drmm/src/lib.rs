pub mod primes;
pub mod spectral;
pub mod optimizer;
pub mod operators;
pub mod tensor_core;
pub mod feedback;
pub mod moonshine;
pub mod langlands;

pub use primes::generate_first_n_primes;
pub use spectral::{SpectralTransform, compute_bin_energies};
pub use optimizer::{DRMMOptimizer, OptimizerConfig};
pub use operators::{Xi, LambdaM};
pub use tensor_core::{prime_indexed_tensor, normalize_tensor, tensor_spectrum};
pub use feedback::{EntropicFeedbackLoop, ConvergenceController, EthicalModulator};
pub use moonshine::MoonshineOperator;
pub use langlands::{AutomorphicForm, GaloisTensor, langlands_bridge};
