use thiserror::Error;

#[derive(Error, Debug)]
pub enum ComplexKappaError {
    #[error("invalid parameter: {0}")]
    InvalidParameter(String),
    #[error("convergence failed after {0} iterations")]
    ConvergenceFailure(usize),
    #[error("numerical instability: {0}")]
    NumericalInstability(String),
}

pub type Result<T> = std::result::Result<T, ComplexKappaError>;

pub mod zeta_zeros;
pub mod hilbert_transform;
pub mod effective_coupling;
pub mod pair_correlation;

pub use zeta_zeros::zeta_zero;
pub use hilbert_transform::{hilbert_transform, hilbert_self_inverse};
pub use effective_coupling::{effective_coupling, noise_kernel_zeta, complex_kappa_eff};
pub use pair_correlation::{empirical_pair_correlation, gue_pair_correlation, compute_beat_frequencies, verify_equal_vectors};
