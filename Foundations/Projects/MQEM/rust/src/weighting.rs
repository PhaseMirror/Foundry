//! Multi-Scale Trophic Weighting and Seasonal Basis (M³EM Eq. 2)

/// Computes time-varying multi-scale normalized weights:
/// w_i(t) = s_i^{-beta(t)} / sum_j s_j^{-beta(t)}
pub struct MultiScaleWeighter {
    pub scales: Vec<f64>,       // e.g. trophic body sizes [1.0, 10.0, 100.0]
    pub beta_0: f64,
    pub seasonal_amplitude: f64,
    pub seasonal_period: f64,
}

impl MultiScaleWeighter {
    pub fn new(scales: Vec<f64>, beta_0: f64) -> Self {
        Self {
            scales,
            beta_0,
            seasonal_amplitude: 0.2,
            seasonal_period: 365.0,
        }
    }

    /// Time-varying beta(t) = beta_0 + amplitude * sin(2 * pi * t / period).
    pub fn compute_beta(&self, t: f64) -> f64 {
        self.beta_0 + self.seasonal_amplitude * (2.0 * std::f64::consts::PI * t / self.seasonal_period).sin()
    }

    /// Compute normalized multi-scale weights at time t.
    pub fn compute_normalized_weights(&self, t: f64) -> Vec<f64> {
        let beta = self.compute_beta(t);
        let mut raw_weights = Vec::with_capacity(self.scales.len());
        let mut sum = 0.0;

        for &scale in &self.scales {
            let w = scale.powf(-beta).max(1e-9);
            raw_weights.push(w);
            sum += w;
        }

        if sum <= 0.0 {
            return vec![1.0 / self.scales.len() as f64; self.scales.len()];
        }

        raw_weights.into_iter().map(|w| w / sum).collect()
    }
}
