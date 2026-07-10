//! # Embodied Protocols Engine
//! Tracks nervous system metrics and computes systemic viability.

pub struct EmbodiedMetrics {
    pub stress: f64,
    pub capacity: f64,
}

impl EmbodiedMetrics {
    pub fn new(stress: f64, capacity: f64) -> Self {
        Self { stress, capacity }
    }
}

pub struct EmbodiedEngine {
    aggregate_metrics: EmbodiedMetrics,
}

impl EmbodiedEngine {
    pub fn new() -> Self {
        Self {
            aggregate_metrics: EmbodiedMetrics::new(0.0, 0.0),
        }
    }

    /// Update the network's aggregate metrics
    pub fn update_metrics(&mut self, stress: f64, capacity: f64) {
        self.aggregate_metrics.stress = stress;
        self.aggregate_metrics.capacity = capacity;
    }

    /// Calculate the Embodied Viability score (Capacity - Stress)
    pub fn calculate_viability(&self) -> f64 {
        self.aggregate_metrics.capacity - self.aggregate_metrics.stress
    }

    /// Calculates a modifier for the Sovereignty Index based on Viability
    pub fn sovereignty_modifier(&self) -> f64 {
        let v = self.calculate_viability();
        if v > 0.0 {
            1.0 + (v * 0.1) // Boosts sovereignty
        } else {
            1.0 - (v.abs() * 0.1) // Degrades sovereignty
        }
    }
}
