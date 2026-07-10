use ndarray::{Array1, Array2};
pub use pirtm_core::math::{ContractiveOperator, SpectralLinear, GroupSort2};

/// B_p: A low-rank operator mixer with explicit singular value control.
pub struct LowRankMixer {
    pub u: Array2<f64>,
    pub s: Array1<f64>, // Singular values (in log space or direct)
    pub v: Array2<f64>,
}

impl LowRankMixer {
    pub fn forward(&self, x: &Array1<f64>) -> Array1<f64> {
        // Enforce S <= 1.0
        let s_clamped = self.s.mapv(|val| val.min(1.0));
        
        // B_p(x) = x @ V @ diag(S) @ U.T
        // For Array1 (vector), this is x^T V diag(S) U^T
        let temp = x.dot(&self.v);
        let scaled = &temp * &s_clamped;
        scaled.dot(&self.u.t())
    }
}

/// w_p(x): Cross-modal resonance gate.
pub struct ResonanceGate {
    pub m: Array2<f64>,
    pub tau: f64,
}

impl ResonanceGate {
    pub fn forward(&self, x_gen: &Array1<f64>, x_bio: &Array1<f64>) -> f64 {
        // Bilinear resonance: x_gen^T @ M @ x_bio
        let res = x_gen.dot(&self.m).dot(x_bio);
        // Sigmoid activation
        1.0 / (1.0 + (-(res - self.tau)).exp())
    }
}

/// O_p = A_p o B_p o C_p
pub struct PrimeOperator {
    pub mixer: LowRankMixer,
    pub lin: SpectralLinear,
}

impl PrimeOperator {
    pub fn forward(&self, x: &Array1<f64>) -> Array1<f64> {
        let z = self.mixer.forward(x);
        let z = self.lin.forward(&z);
        GroupSort2::forward(&z)
    }
}
