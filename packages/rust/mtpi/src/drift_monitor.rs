use serde::{Serialize, Deserialize};
use std::collections::HashSet;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum LambdaBand {
    Quiet,
    Amber,
    Red,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum Mode {
    Suspended,
    Advisory,
    Constrained,
    Full,
}

#[derive(Debug, Clone)]
pub struct DriftCheckResult {
    pub within_bounds: bool,
    pub drift_value: f64,
    pub max: f64,
    pub band: LambdaBand,
    pub required_mode: Option<Mode>,
    pub blocked_actions: HashSet<String>,
}

pub struct DriftMonitor {
    max_drift: f64,
    quiet_max: f64,
    amber_max: f64,
}

impl DriftMonitor {
    pub fn new(max_drift: f64) -> Self {
        Self { 
            max_drift,
            quiet_max: 0.33,
            amber_max: 0.66,
        }
    }

    pub fn set_bands(&mut self, quiet: f64, amber: f64) {
        self.quiet_max = quiet;
        self.amber_max = amber;
    }

    pub fn classify_band(&self, drift_value: f64) -> LambdaBand {
        if drift_value <= self.quiet_max {
            LambdaBand::Quiet
        } else if drift_value <= self.amber_max {
            LambdaBand::Amber
        } else {
            LambdaBand::Red
        }
    }

    pub fn evaluate(
        &self, 
        drift_value: f64, 
        rights_material: bool, 
        domain_matches: bool,
        amber_blocked_actions: Option<HashSet<String>>
    ) -> DriftCheckResult {
        let within_bounds = drift_value.is_finite() && drift_value < self.max_drift;
        let band = self.classify_band(drift_value);

        let mut required_mode = None;
        let mut blocked_actions = HashSet::new();

        match band {
            LambdaBand::Quiet => {},
            LambdaBand::Amber => {
                if let Some(blocked) = amber_blocked_actions {
                    blocked_actions = blocked;
                }
            },
            LambdaBand::Red => {
                required_mode = Some(Mode::Advisory);
                if rights_material && domain_matches {
                    blocked_actions.insert("appeal_denial".to_string());
                }
            }
        }

        DriftCheckResult {
            within_bounds,
            drift_value,
            max: self.max_drift,
            band,
            required_mode,
            blocked_actions,
        }
    }
}
