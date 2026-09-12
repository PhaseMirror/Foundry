//! Core Data Types for Multiplicity Neuroplasticity, PIRTM, and CSL

use serde::{Deserialize, Serialize};

/// Prime number index representing an orthogonal cognitive frequency channel.
pub type PrimeIndex = usize;

/// Single prime-indexed tensor component: θ_p ⊗ e^{i ϕ_p}.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PrimeComponent {
    pub prime_p: PrimeIndex,
    pub amplitude: f64, // θ_p (embodied cognitive trace / synaptic strength)
    pub phase: f64,     // ϕ_p in radians [0, 2π) (attention phase)
}

impl PrimeComponent {
    pub fn new(prime_p: PrimeIndex, amplitude: f64, phase: f64) -> Self {
        Self {
            prime_p,
            amplitude: amplitude.max(0.0),
            phase: phase.rem_euclid(2.0 * std::f64::consts::PI),
        }
    }
}

/// Cognitive state Ψ(t) spanning active prime modes.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CognitiveState {
    pub components: Vec<PrimeComponent>,
    pub timestamp: usize,
}

impl CognitiveState {
    pub fn new(components: Vec<PrimeComponent>, timestamp: usize) -> Self {
        Self {
            components,
            timestamp,
        }
    }

    /// Compute total cognitive power / norm: ∑ θ_p^2.
    pub fn total_power(&self) -> f64 {
        self.components.iter().map(|c| c.amplitude * c.amplitude).sum()
    }
}

/// Neuroplasticity learning and Consciousness Stability Law (CSL) configuration.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct NeuroConfig {
    pub learning_rate: f64,     // η (Hebbian adaptation rate)
    pub synaptic_decay: f64,    // γ (homeostatic forgetting / normalization rate)
    pub csl_entropy_bound: f64, // ln(φ) ≈ 0.481211825
    pub phase_coupling_k: f64,  // Kuramoto-style inter-channel phase synchronization strength
}

impl Default for NeuroConfig {
    fn default() -> Self {
        Self {
            learning_rate: 0.08,
            synaptic_decay: 0.02,
            csl_entropy_bound: ( (1.0 + 5.0_f64.sqrt()) / 2.0 ).ln(), // ln(golden ratio)
            phase_coupling_k: 0.15,
        }
    }
}

/// EEG Spectral Band Power measurements.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EegBandPower {
    pub delta: f64, // 0.5 - 4 Hz (deep rest / restoration)
    pub theta: f64, // 4 - 8 Hz (memory consolidation / plasticity)
    pub alpha: f64, // 8 - 12 Hz (relaxed alertness / readiness)
    pub beta: f64,  // 12 - 30 Hz (active task focus)
    pub gamma: f64, // 30 - 80 Hz (cross-frequency phase binding)
}

/// Metrics recorded across a neuroplastic adaptation session.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SessionMetrics {
    pub session_id: usize,
    pub initial_power: f64,
    pub final_power: f64,
    pub delta_s: f64,
    pub csl_satisfied: bool,
    pub echo_braid_coherence: f64,
    pub subjective_readiness: f64,
}
