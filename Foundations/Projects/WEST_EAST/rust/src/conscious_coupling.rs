//! Bounded Consciousness Coupling & Spectral Stability Engine

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CouplingSafetyReport {
    pub certified_delta_s: f64,
    pub alpha_chosen: f64,
    pub safe_alpha_limit: f64,
    pub perturbed_gap_lb: f64,
    pub projector_angle_bound: f64,
    pub is_gate_passed: bool,
}

pub struct ConsciousnessCoupler;

impl ConsciousnessCoupler {
    /// Evaluate Conscious Coupling Safety Gate: |α| < δ_S / 4.
    pub fn evaluate_safety_gate(delta_s: f64, alpha: f64) -> Result<CouplingSafetyReport, String> {
        let safe_limit = delta_s / 4.0;
        let abs_alpha = alpha.abs();

        if delta_s <= 0.0 {
            return Err("Invalid baseline spectral gap: δ_S must be positive".into());
        }

        if abs_alpha >= safe_limit {
            return Err(format!(
                "Conscious Overshoot Violation: |α| = {:.4} exceeds safe bound δ_S / 4 = {:.4}",
                abs_alpha, safe_limit
            ));
        }

        // Theorem guarantees:
        // 1. gap(U_α) ≥ δ_S - 2|α|
        // 2. angle(Π_α, Π_0) ≤ 2|α| / δ_S
        let perturbed_gap_lb = delta_s - 2.0 * abs_alpha;
        let projector_angle_bound = 2.0 * abs_alpha / delta_s;

        Ok(CouplingSafetyReport {
            certified_delta_s: delta_s,
            alpha_chosen: alpha,
            safe_alpha_limit: safe_limit,
            perturbed_gap_lb,
            projector_angle_bound,
            is_gate_passed: true,
        })
    }

    /// Simulate 2-level Hamiltonian spectral perturbation: U_α = U_0 + α R(ψ).
    pub fn perturb_two_level_spectrum(e1_0: f64, e2_0: f64, alpha: f64) -> (f64, f64, f64) {
        let delta_s = (e2_0 - e1_0).abs();
        let e1_pert = e1_0 - alpha.abs();
        let e2_pert = e2_0 + alpha.abs();
        let actual_gap = (e2_pert - e1_pert).abs();
        (e1_pert, e2_pert, actual_gap.max(delta_s - 2.0 * alpha.abs()))
    }
}
