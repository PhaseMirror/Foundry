use serde::{Deserialize, Serialize};
use std::collections::HashMap;

pub type PhaseMirrorDecision = String; // PASS, FAIL, REVIEW

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DissonanceSignal {
    pub signal_id: String,
    pub severity: String, // low, medium, high, auto_fail
    pub summary: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DissonanceReport {
    pub execute: bool,
    pub rho: f64,
    pub rho_star: f64,
    pub kappa_min: f64,
    pub rho_threshold: f64,
    pub tensions: Vec<DissonanceSignal>,
    pub suppressed_tensions: Vec<DissonanceSignal>,
    pub metadata: HashMap<String, serde_json::Value>,
}

impl DissonanceReport {
    pub fn decision(&self) -> &str {
        if self.execute { "PASS" } else { "FAIL" }
    }

    pub fn tension_count(&self) -> usize {
        self.tensions.len() + self.suppressed_tensions.len()
    }

    pub fn get_all_tensions(&self) -> Vec<DissonanceSignal> {
        let mut all = self.tensions.clone();
        all.extend(self.suppressed_tensions.clone());
        all
    }

    pub fn margin_to_fail(&self) -> f64 {
        self.rho_threshold - self.rho
    }
}
