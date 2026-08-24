pub mod authority;
pub mod federation;
pub mod gicd;
pub mod models;
pub mod sovereign_engine;
pub mod xi_system;

pub use sigma::{
    sigma_check, DissonanceLevel, PolicyEngine, SigmaKernel, SigmaViolation, SpectralState,
    StateTransition, Thresholds,
};

use ndarray::{array, Array2};
use num_complex::Complex64;

// --- Helix Knot Hamiltonian ---
// Maps to the PiKernel spectral attention substrate via sigma's Thresholds.

pub struct KnotHamiltonian {
    pub knot_type: String,
    pub omega_z: f64,
    pub omega_fold: f64,
    pub lambda_topo: f64,
    pub gamma: f64,
}

impl KnotHamiltonian {
    pub fn new(knot_type: String) -> Self {
        Self {
            knot_type,
            omega_z: 1.0,
            omega_fold: 0.5,
            lambda_topo: 0.3,
            gamma: 0.1,
        }
    }

    fn get_knot_invariant(&self) -> f64 {
        match self.knot_type.as_str() {
            "0_1" => 1.0,
            "3_1" => 1.4142,
            "4_1" => 2.6180,
            "5_1" => 1.9890,
            "7_1" => 2.2469,
            "9_1" => 2.4940,
            "hopf" => 1.9021,
            _ => 1.0,
        }
    }

    pub fn get_coherence_protection(&self) -> f64 {
        self.get_knot_invariant()
    }

    pub fn get_decoherence_suppression(&self) -> f64 {
        let j_k = self.get_knot_invariant();
        if j_k != 0.0 {
            1.0 / j_k
        } else {
            0.0
        }
    }

    pub fn get_h_free(&self) -> Array2<Complex64> {
        Complex64::new(self.omega_z / 2.0, 0.0)
            * array![
                [Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)],
                [Complex64::new(0.0, 0.0), Complex64::new(-1.0, 0.0)]
            ]
    }

    pub fn get_h_fold(&self) -> Array2<Complex64> {
        let sx = array![
            [Complex64::new(0.0, 0.0), Complex64::new(1.0, 0.0)],
            [Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)]
        ];
        let sy = array![
            [Complex64::new(0.0, 0.0), Complex64::new(0.0, -1.0)],
            [Complex64::new(0.0, 1.0), Complex64::new(0.0, 0.0)]
        ];
        Complex64::new(self.omega_fold, 0.0) * (sx + Complex64::new(0.0, 1.0) * self.gamma * sy)
    }

    pub fn get_h_topo(&self) -> Array2<Complex64> {
        Complex64::new(self.lambda_topo * self.get_knot_invariant(), 0.0)
            * array![
                [Complex64::new(1.0, 0.0), Complex64::new(0.0, 0.0)],
                [Complex64::new(0.0, 0.0), Complex64::new(-1.0, 0.0)]
            ]
    }

    pub fn construct(&self) -> Array2<Complex64> {
        self.get_h_free() + self.get_h_fold() + self.get_h_topo()
    }

    pub fn get_effective_resistance(&self, t: f64, tau: f64) -> f64 {
        let epsilon = 0.1;
        let wobble = epsilon * (2.0 * std::f64::consts::PI * t / tau).sin();
        1.0 + wobble
    }
}

// --- Invariant Registry (updated with sigma Thresholds) ---

pub struct InvariantRegistry;

impl InvariantRegistry {
    /// Legacy API: hardcoded threshold for backward compatibility.
    pub fn audit_drift(authority: &str, form: &str, current_drift: f64) -> Result<f64, String> {
        let thresholds = Thresholds::default();
        Self::audit_drift_with_thresholds(&thresholds, authority, form, current_drift)
    }

    /// New API: validate drift against sigma Thresholds derived from Lean theorems.
    pub fn audit_drift_with_thresholds(
        thresholds: &Thresholds,
        authority: &str,
        form: &str,
        current_drift: f64,
    ) -> Result<f64, String> {
        let multiplier = match authority {
            "CUSTODIAN_CA_FED" => 1.0,
            "CUSTODIAN_CA_DEFENCE" => 1.2,
            "CUSTODIAN_ITAR" => 1.5,
            "POLICY_QC" => 1.1,
            _ => 1.0,
        };

        let drift_threshold_max = thresholds.tau_r;
        let effective_threshold = drift_threshold_max / multiplier;

        if form == "FACT" {
            let fact_threshold = thresholds.tau_r * 0.5;
            if current_drift > fact_threshold {
                return Err("FACT_PRECISION_VIOLATION".to_string());
            }
        }

        if current_drift > effective_threshold {
            return Err("TOPOLOGICAL_DRIFT_EXCEEDED".to_string());
        }

        Ok(effective_threshold - current_drift)
    }

    /// Evaluate a knot transition against sigma Thresholds and return a SpectralState.
    pub fn evaluate_transition(
        thresholds: &Thresholds,
        transition: &StateTransition,
    ) -> Result<SpectralState, String> {
        let engine = PolicyEngine::new();
        let check = engine.run(transition, thresholds);
        Ok(SpectralState {
            resonance_functional: check.r_sc,
            drift: check.r_sc - thresholds.r_sc_reference,
            effective_lipschitz: check.l_eff,
        })
    }
}
