//! Prime-Indexed Recursive Tensor Mathematics (PIRTM)
//! Implements orthogonal prime coordinate bases: Ψ(t) = ∑_p θ_p(t) ⊗ e^{i ϕ_p(t)}

use crate::types::{CognitiveState, PrimeComponent, PrimeIndex};

/// PIRTM mathematical operations and tensor decompositions.
pub struct PirtmEngine;

impl PirtmEngine {
    /// Canonical first N primes for cognitive channel mapping.
    pub const PRIMES: [usize; 16] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53];

    /// Construct a default initial cognitive state over the first N prime modes.
    pub fn initialize_default_state(num_primes: usize) -> CognitiveState {
        let count = num_primes.min(Self::PRIMES.len());
        let mut components = Vec::with_capacity(count);

        for (i, &p) in Self::PRIMES[..count].iter().enumerate() {
            // Baseline 1/p power-law distribution for stable baseline
            let amp = 1.0 / (p as f64).sqrt();
            let phase = (i as f64) * 0.5;
            components.push(PrimeComponent::new(p, amp, phase));
        }

        CognitiveState::new(components, 0)
    }

    /// Compute complex inner product ⟨Ψ_a | Ψ_b⟩ under prime orthogonality.
    /// Since distinct primes are strictly orthogonal: ⟨p|q⟩ = δ_{pq}.
    pub fn inner_product(state_a: &CognitiveState, state_b: &CognitiveState) -> (f64, f64) {
        let mut real_sum = 0.0;
        let mut imag_sum = 0.0;

        for ca in &state_a.components {
            for cb in &state_b.components {
                if ca.prime_p == cb.prime_p {
                    let phase_diff = ca.phase - cb.phase;
                    let amp_prod = ca.amplitude * cb.amplitude;
                    real_sum += amp_prod * phase_diff.cos();
                    imag_sum += amp_prod * phase_diff.sin();
                }
            }
        }

        (real_sum, imag_sum)
    }

    /// Retrieve component amplitude for a specific prime index.
    pub fn get_amplitude(state: &CognitiveState, prime: PrimeIndex) -> f64 {
        state
            .components
            .iter()
            .find(|c| c.prime_p == prime)
            .map(|c| c.amplitude)
            .unwrap_or(0.0)
    }

    /// Compute spectral entropy of cognitive power distribution: S = -∑ (p_i ln p_i).
    pub fn spectral_entropy(state: &CognitiveState) -> f64 {
        let total_power = state.total_power();
        if total_power <= 1e-9 {
            return 0.0;
        }

        let mut entropy = 0.0;
        for c in &state.components {
            let prob = (c.amplitude * c.amplitude) / total_power;
            if prob > 1e-9 {
                entropy -= prob * prob.ln();
            }
        }

        entropy
    }
}
