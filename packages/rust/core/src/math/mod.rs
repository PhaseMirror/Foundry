pub mod traits;
pub use traits::ContractiveOperator;

use ndarray::{Array1, Array2};

/// A linear layer with spectral normalization to ensure contractivity.
pub struct SpectralLinear {
    pub weights: Array2<f64>,
    pub bias: Array1<f64>,
    pub kappa: f64, // Target Lipschitz constant
}

impl SpectralLinear {
    pub fn new(weights: Array2<f64>, bias: Array1<f64>, kappa: f64) -> Self {
        Self { weights, bias, kappa }
    }

    /// Simple power iteration to estimate the spectral norm (largest singular value).
    pub fn estimate_spectral_norm(&self, iterations: usize) -> f64 {
        let mut v = Array1::from_elem(self.weights.ncols(), 1.0);
        let mut u = Array1::zeros(self.weights.nrows());

        for _ in 0..iterations {
            u = self.weights.dot(&v);
            let u_norm = u.mapv(|x| x.powi(2)).sum().sqrt();
            u /= u_norm + 1e-12;

            v = self.weights.t().dot(&u);
            let v_norm = v.mapv(|x| x.powi(2)).sum().sqrt();
            v /= v_norm + 1e-12;
        }

        // sigma = u^T * W * v
        u.dot(&self.weights.dot(&v))
    }

    /// Returns a normalized version of the weights that respects the kappa constraint.
    pub fn normalized_weights(&self) -> Array2<f64> {
        let sigma = self.estimate_spectral_norm(5);
        let scale = (self.kappa / sigma).min(1.0);
        &self.weights * scale
    }
}

impl ContractiveOperator for SpectralLinear {
    fn forward(&self, x: &Array1<f64>) -> Array1<f64> {
        self.normalized_weights().dot(x) + &self.bias
    }

    fn lipschitz_constant(&self) -> f64 {
        self.kappa
    }
}

/// GroupSort activation function (2-group) for 1-Lipschitz non-linearity.
pub struct GroupSort2;

impl GroupSort2 {
    pub fn forward(x: &Array1<f64>) -> Array1<f64> {
        let mut out = x.clone();
        for chunk in out.as_slice_mut().unwrap().chunks_exact_mut(2) {
            if chunk[0] < chunk[1] {
                chunk.swap(0, 1);
            }
        }
        out
    }
}
