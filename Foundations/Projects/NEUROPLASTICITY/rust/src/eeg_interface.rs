//! EEG Spectral Interface & Subjective Readiness Filtering
//! Implements: EEGLearn(t) = F^{-1}(⟨ψ| H |ϕ⟩)

use crate::types::EegBandPower;

/// EEG neurofeedback processor calculating cognitive readiness.
pub struct EegInterface;

impl EegInterface {
    /// Computes subjective readiness index from EEG spectral power bands:
    /// Readiness = (Alpha + Theta) / (Delta + Beta + Gamma)
    /// Reflects calm, focused neuroplastic receptivity without stress/hyperarousal.
    pub fn compute_subjective_readiness(bands: &EegBandPower) -> f64 {
        let receptive_power = bands.alpha * 1.2 + bands.theta * 0.8;
        let disruptive_power = bands.delta * 0.5 + bands.beta * 0.7 + bands.gamma * 0.9;

        let ratio = receptive_power / (disruptive_power + 1e-6);
        // Sigmoid mapping to [0.1, 1.0]
        (1.0 / (1.0 + (-ratio + 1.0).exp())).clamp(0.1, 1.0)
    }

    /// Synthetic EEG generator simulating calm focus, fatigue, or stress.
    pub fn simulate_eeg_bands(state_type: &str) -> EegBandPower {
        match state_type {
            "calm_focus" => EegBandPower {
                delta: 1.2,
                theta: 2.5,
                alpha: 4.8,
                beta: 1.5,
                gamma: 0.8,
            },
            "stress_overload" => EegBandPower {
                delta: 0.5,
                theta: 0.8,
                alpha: 1.1,
                beta: 5.6,
                gamma: 4.2,
            },
            _ => EegBandPower {
                delta: 2.0,
                theta: 2.0,
                alpha: 2.5,
                beta: 2.0,
                gamma: 1.0,
            },
        }
    }
}
