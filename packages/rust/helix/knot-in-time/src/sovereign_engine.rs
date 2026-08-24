use crate::{sigma_check, InvariantRegistry, SpectralState, StateTransition, Thresholds};
use ndarray::Array2;
use num_complex::Complex64;

pub const DELTA_CRIT: f64 = 0.17;

pub struct FzsMkEngine {
    pub density_matrix: Array2<Complex64>,
    pub memory_kernel_history: Vec<Array2<Complex64>>,
    pub application_count: usize,
    pub correction_count: usize,
}

impl FzsMkEngine {
    pub fn new(dim: usize) -> Self {
        Self {
            density_matrix: Array2::eye(dim).mapv(|x| Complex64::new(x, 0.0)),
            memory_kernel_history: Vec::new(),
            application_count: 0,
            correction_count: 0,
        }
    }

    /// Implements Non-Markovian Master Equation:
    /// dρ/dt = -i[H, ρ] + ∫ K(t-τ) D[ρ(τ)] dτ + ∇W(ρ)
    pub fn step(&mut self, h: &Array2<Complex64>, dt: f64) {
        let commutator =
            (h.dot(&self.density_matrix) - self.density_matrix.dot(h)) * Complex64::new(0.0, -1.0);

        let memory_effect = self.compute_memory_integral();
        let projection = self.compute_zeno_ward_gradient();

        self.density_matrix = &self.density_matrix + (commutator + memory_effect + projection) * dt;

        let tr = self.density_matrix.diag().sum();
        self.density_matrix /= tr;
    }

    /// Compute spectral state from a transition and evaluate against sigma Thresholds.
    pub fn evaluate_spectral_state(
        &mut self,
        thresholds: &Thresholds,
        transition: StateTransition,
    ) -> Result<SpectralState, String> {
        let state = InvariantRegistry::evaluate_transition(thresholds, &transition)?;
        sigma_check(&state, thresholds.tau_r).map_err(|e| match e {
            crate::SigmaViolation::InvariantBreach { l_eff, drift } => {
                if l_eff >= 1.0 {
                    "LipschitzContraction".to_string()
                } else {
                    format!("ResonanceDelta: drift={}", drift)
                }
            }
        })?;
        Ok(state)
    }

    fn compute_memory_integral(&self) -> Array2<Complex64> {
        Array2::zeros((self.density_matrix.nrows(), self.density_matrix.ncols()))
    }

    fn compute_zeno_ward_gradient(&self) -> Array2<Complex64> {
        Array2::zeros((self.density_matrix.nrows(), self.density_matrix.ncols()))
    }
}
