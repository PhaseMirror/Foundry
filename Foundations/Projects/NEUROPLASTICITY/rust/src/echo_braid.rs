//! EchoBraid: ASD-Centric Multi-Frequency Braided Neuroplasticity
//! Preserves core identity phase-locking while allowing flexible cognitive adaptation.

use crate::types::CognitiveState;

/// EchoBraid Phase Coherence and Multi-Frequency Coordinator.
pub struct EchoBraidCoordinator {
    pub identity_primes: Vec<usize>, // core anchor primes, e.g. [2, 3, 5]
    pub plasticity_primes: Vec<usize>, // adaptive task primes, e.g. [7, 11, 13, 17]
}

impl EchoBraidCoordinator {
    pub fn new() -> Self {
        Self {
            identity_primes: vec![2, 3, 5],
            plasticity_primes: vec![7, 11, 13, 17],
        }
    }

    /// Evaluates Kuramoto order parameter (phase coherence) R ∈ [0, 1] across identity primes:
    /// R e^{i Ψ} = (1/N) ∑_{p ∈ Identity} e^{i ϕ_p}
    pub fn compute_identity_coherence(&self, state: &CognitiveState) -> f64 {
        let mut cos_sum = 0.0;
        let mut sin_sum = 0.0;
        let mut count = 0;

        for c in &state.components {
            if self.identity_primes.contains(&c.prime_p) {
                cos_sum += c.phase.cos();
                sin_sum += c.phase.sin();
                count += 1;
            }
        }

        if count == 0 {
            return 1.0;
        }

        let mean_cos = cos_sum / (count as f64);
        let mean_sin = sin_sum / (count as f64);
        (mean_cos * mean_cos + mean_sin * mean_sin).sqrt()
    }

    /// Checks if identity braid remains phase-stable (coherence R ≥ 0.70).
    pub fn is_identity_stable(&self, state: &CognitiveState) -> bool {
        self.compute_identity_coherence(state) >= 0.70
    }
}
