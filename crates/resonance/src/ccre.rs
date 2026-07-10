use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PilotConfig {
    pub drift_threshold: f64,
    pub resonance_min: f64,
    pub resonance_max: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DriftTracker {
    pub history: Vec<f64>,
    pub threshold: f64,
}

impl DriftTracker {
    pub fn new(threshold: f64) -> Self {
        Self {
            history: Vec::new(),
            threshold,
        }
    }

    pub fn update(&mut self, drift: f64) -> bool {
        self.history.push(drift);
        drift <= self.threshold
    }
}

pub fn check_resonance_guard(resonance: f64, config: &PilotConfig) -> bool {
    resonance >= config.resonance_min && resonance <= config.resonance_max
}
