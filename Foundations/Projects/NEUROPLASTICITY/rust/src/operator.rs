//! Recursive Operator Ξ(t) State Evolution & Hebbian Synaptic Dynamics

use crate::types::{CognitiveState, NeuroConfig, PrimeComponent};

/// Recursive Operator Ξ(t) that steps cognitive states under input stimuli.
pub struct RecursiveOperator {
    pub config: NeuroConfig,
}

impl RecursiveOperator {
    pub fn new(config: NeuroConfig) -> Self {
        Self { config }
    }

    /// Step the cognitive state forward: Ψ(t+1) = Ξ(Ψ(t), Stimulus, Readiness).
    pub fn step(
        &self,
        current_state: &CognitiveState,
        stimuli: &[f64], // stimulus intensity per prime component
        readiness: f64,  // subjective readiness scalar [0, 1]
    ) -> CognitiveState {
        let eta = self.config.learning_rate * readiness.clamp(0.1, 1.0);
        let gamma = self.config.synaptic_decay;
        let k_coupling = self.config.phase_coupling_k;

        let num_components = current_state.components.len();
        let mut next_components = Vec::with_capacity(num_components);

        // Compute mean phase for Kuramoto inter-harmonic coupling
        let mut sin_sum = 0.0;
        let mut cos_sum = 0.0;
        for c in &current_state.components {
            sin_sum += c.phase.sin();
            cos_sum += c.phase.cos();
        }
        let mean_phase = sin_sum.atan2(cos_sum);

        for (i, c) in current_state.components.iter().enumerate() {
            let stimulus = stimuli.get(i).cloned().unwrap_or(0.0);

            // Hebbian growth with homeostatic exponential decay
            // θ_next = θ * (1 - γ) + η * stimulus
            let next_amp = (c.amplitude * (1.0 - gamma) + eta * stimulus).max(0.0);

            // Phase evolution with Kuramoto sync toward mean phase
            // ϕ_next = ϕ + ω_p + K * sin(mean_phase - ϕ)
            let intrinsic_freq = 0.05 * (c.prime_p as f64).ln();
            let phase_pull = k_coupling * (mean_phase - c.phase).sin();
            let next_phase = (c.phase + intrinsic_freq + phase_pull).rem_euclid(2.0 * std::f64::consts::PI);

            next_components.push(PrimeComponent::new(c.prime_p, next_amp, next_phase));
        }

        CognitiveState::new(next_components, current_state.timestamp + 1)
    }
}
