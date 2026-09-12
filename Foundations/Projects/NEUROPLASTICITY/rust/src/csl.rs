//! Consciousness Stability Law (CSL) Auditor & Ethical Guardrail
//! Enforces: ΔS < ln(φ) ≈ 0.4812 to prevent cognitive overload and preserve dignity.

use crate::tensor::PirtmEngine;
use crate::types::{CognitiveState, NeuroConfig};

/// Consciousness Stability Law Auditor.
pub struct CslAuditor {
    pub config: NeuroConfig,
}

impl CslAuditor {
    pub fn new(config: NeuroConfig) -> Self {
        Self { config }
    }

    /// Golden ratio entropy threshold: ln(φ) = ln((1 + √5)/2) ≈ 0.4812118
    pub fn golden_ratio_entropy_bound() -> f64 {
        ((1.0 + 5.0_f64.sqrt()) / 2.0).ln()
    }

    /// Evaluates entropy differential ΔS between two consecutive cognitive states:
    /// ΔS = |S(t+1) - S(t)| / max(S(t), 1e-6)
    pub fn compute_entropy_delta(prev_state: &CognitiveState, next_state: &CognitiveState) -> f64 {
        let s_prev = PirtmEngine::spectral_entropy(prev_state);
        let s_next = PirtmEngine::spectral_entropy(next_state);
        (s_next - s_prev).abs()
    }

    /// Checks if a transition satisfies the Consciousness Stability Law: ΔS < ln(φ).
    pub fn audit_transition(
        &self,
        prev_state: &CognitiveState,
        next_state: &CognitiveState,
    ) -> (bool, f64) {
        let delta_s = Self::compute_entropy_delta(prev_state, next_state);
        let satisfied = delta_s < self.config.csl_entropy_bound;
        (satisfied, delta_s)
    }

    /// Apply homeostatic damping if CSL is breached to prevent cognitive dysregulation.
    pub fn enforce_homeostasis(&self, runaway_state: &CognitiveState) -> CognitiveState {
        let max_allowed_scale = (self.config.csl_entropy_bound * 2.0).min(1.0);
        let damped_components = runaway_state
            .components
            .iter()
            .map(|c| {
                crate::types::PrimeComponent::new(
                    c.prime_p,
                    c.amplitude * max_allowed_scale,
                    c.phase,
                )
            })
            .collect();

        CognitiveState::new(damped_components, runaway_state.timestamp)
    }
}
