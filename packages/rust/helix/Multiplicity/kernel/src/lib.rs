pub mod memory_kernel;
pub mod ward_monitor;
pub mod zeno_projector;

pub use sigma::{sigma_check, SpectralState, StateTransition, Thresholds};

use crate::memory_kernel::MemoryKernel;
use crate::ward_monitor::WardMonitor;
use crate::zeno_projector::ZenoProjector;
use ndarray::{Array1, Array2};
use num_complex::Complex64;

pub struct FzsMkEngine {
    pub memory_kernel: MemoryKernel,
    pub ward_monitor: WardMonitor,
    pub zeno_projector: ZenoProjector,
    pub application_count: usize,
    pub correction_count: usize,
}

impl FzsMkEngine {
    pub fn new(
        memory_kernel: MemoryKernel,
        ward_monitor: WardMonitor,
        zeno_projector: ZenoProjector,
    ) -> Self {
        Self {
            memory_kernel,
            ward_monitor,
            zeno_projector,
            application_count: 0,
            correction_count: 0,
        }
    }

    pub fn convolve(&self, t: f64, history: &Array2<f64>) -> Array1<f64> {
        self.memory_kernel.convolve(t, history)
    }

    pub fn ward_residual(&mut self, rho: &Array1<f64>, rho0: &Array1<f64>) -> f64 {
        if self.ward_monitor.reference_state.is_none() {
            self.ward_monitor.reference_state = Some(rho0.clone());
        }
        self.ward_monitor.compute_residual(rho)
    }

    pub fn zeno_project(&mut self, rho: &Array1<f64>) -> Array1<f64> {
        self.application_count += 1;
        let residual_before = self.ward_monitor.compute_residual(rho);

        let projected = self.zeno_projector.project_state(rho);

        let residual_after = self.ward_monitor.compute_residual(&projected);

        if residual_after < residual_before * 0.9 {
            self.correction_count += 1;
        }

        projected
    }

    /// Evaluate spectral state against sigma Thresholds.
    pub fn evaluate_spectral_state(
        &mut self,
        thresholds: &Thresholds,
        transition: StateTransition,
    ) -> Result<SpectralState, String> {
        let _ = self.ward_residual(&Array1::zeros(2), &Array1::zeros(2));
        let state = SpectralState {
            resonance_functional: transition.r_sc,
            drift: transition.r_sc - thresholds.r_sc_reference,
            effective_lipschitz: transition.l_eff,
        };
        sigma_check(&state, thresholds.tau_r).map_err(|e| match e {
            sigma::SigmaViolation::InvariantBreach { l_eff, drift } => {
                if l_eff >= 1.0 {
                    "LipschitzContraction".to_string()
                } else {
                    format!("ResonanceDelta: drift={}", drift)
                }
            }
        })?;
        Ok(state)
    }
}
