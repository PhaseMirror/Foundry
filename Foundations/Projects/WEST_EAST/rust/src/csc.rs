//! Conscious Symbol Calculus (CSC) Engine

use num_complex::Complex64;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Conscious Symbol tuple σ = (token, π, ρ, a, κ).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConsciousSymbol {
    pub token: String,
    pub prime_anchor: u64,
    /// Resonance profile ρ(π^k) for k = 1, 2, ...
    pub resonance_profile: Vec<(u32, f64, f64)>, // (k, re, im)
    pub amplitude: (f64, f64),                   // (re, im)
    pub lawfulness: f64,                         // κ ∈ [0, 1]
}

impl ConsciousSymbol {
    pub fn new(
        token: &str,
        prime_anchor: u64,
        resonance_profile: Vec<(u32, f64, f64)>,
        amplitude: (f64, f64),
        lawfulness: f64,
    ) -> Self {
        Self {
            token: token.to_string(),
            prime_anchor,
            resonance_profile,
            amplitude,
            lawfulness: lawfulness.clamp(0.0, 1.0),
        }
    }

    /// Compute Coherence Norm: ||σ||_coh^2 = ∑_{k≥1} κ * (k / log π) * |ρ(π^k)|^2.
    pub fn compute_coherence_norm_sq(&self) -> f64 {
        let log_p = (self.prime_anchor as f64).ln().max(1e-6);
        let mut sum = 0.0;
        for &(k, re, im) in &self.resonance_profile {
            let mag_sq = re * re + im * im;
            let weight = self.lawfulness * (k as f64) / log_p;
            sum += weight * mag_sq;
        }
        sum
    }

    /// Evaluate Bohr-prime driver term: m_σ(ω) = a * ∑_{k≥1} ρ(π^k) * e^{i ω k log π}.
    pub fn evaluate_driver(&self, omega: f64) -> Complex64 {
        let a = Complex64::new(self.amplitude.0, self.amplitude.1);
        let log_p = (self.prime_anchor as f64).ln();
        let mut sum = Complex64::new(0.0, 0.0);

        for &(k, re, im) in &self.resonance_profile {
            let rho_k = Complex64::new(re, im);
            let phase = omega * (k as f64) * log_p;
            let exp_term = Complex64::from_polar(1.0, phase);
            sum += rho_k * exp_term;
        }

        a * sum
    }
}

/// Aggregates symbols into composite driver C(ω; w) with budget clamping.
pub struct SymbolRegistry {
    pub symbols: HashMap<String, ConsciousSymbol>,
    pub max_budget: f64,
}

impl SymbolRegistry {
    pub fn new(max_budget: f64) -> Self {
        Self {
            symbols: HashMap::new(),
            max_budget,
        }
    }

    pub fn register(&mut self, symbol: ConsciousSymbol) {
        self.symbols.insert(symbol.token.clone(), symbol);
    }

    /// Compute composite driver C(ω; w) = clamp(∑_σ m_σ(ω), B).
    pub fn evaluate_composite_driver(&self, omega: f64) -> Complex64 {
        let mut total = Complex64::new(0.0, 0.0);
        for symbol in self.symbols.values() {
            total += symbol.evaluate_driver(omega);
        }

        let norm = total.norm();
        if norm > self.max_budget && norm > 1e-12 {
            total * (self.max_budget / norm)
        } else {
            total
        }
    }
}
