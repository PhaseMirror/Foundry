//! Levers: one `[owner] — action — metric — horizon` per named defect.

use serde::{Deserialize, Serialize};

/// A single actionable lever bound to one named defect.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Lever {
    /// The owner a node can act on — the affected identity (or 0 for system).
    pub owner: u64,
    /// The English action that clears the defect.
    pub action: String,
    /// The fixed-point metric the action must bring under tolerance.
    pub metric: u64,
    /// The horizon in which the action must land.
    pub horizon: String,
}

impl Lever {
    pub fn new(owner: u64, action: &'static str, metric: u64, horizon: &'static str) -> Self {
        Lever {
            owner,
            action: action.to_string(),
            metric,
            horizon: horizon.to_string(),
        }
    }
}
