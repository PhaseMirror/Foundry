use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use crate::{CheckpointManager, RollbackError};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RollbackTrigger {
    pub name: String,
    pub metric: String,
    pub comparator: String,
    pub threshold: f64,
}

pub struct RollbackManager {
    pub checkpoint_manager: CheckpointManager,
    pub triggers: Vec<RollbackTrigger>,
}

impl RollbackManager {
    pub fn new(store_path: PathBuf, latest_path: PathBuf, triggers: Vec<RollbackTrigger>) -> Self {
        Self {
            checkpoint_manager: CheckpointManager::new(store_path, latest_path),
            triggers,
        }
    }

    pub fn check_triggers(&self, state: &HashMap<String, f64>) -> Option<String> {
        for trigger in &self.triggers {
            if let Some(&value) = state.get(&trigger.metric) {
                let triggered = match trigger.comparator.as_str() {
                    ">=" => value >= trigger.threshold,
                    ">" => value > trigger.threshold,
                    "==" => (value - trigger.threshold).abs() < 1e-10,
                    _ => false,
                };
                if triggered {
                    return Some(trigger.name.clone());
                }
            }
        }
        None
    }
}
use std::collections::HashMap;
