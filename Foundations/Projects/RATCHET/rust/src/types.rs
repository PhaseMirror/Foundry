//! Operational data structures for ADR-0038: The Intelligence Ratchet (v4.1)

use serde::{Deserialize, Serialize};

/// Operational modes for external controller C_ext.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Mode {
    IDLE,
    BURST,
    CAPTURE,
    GROUND,
    HALT,
}

/// Access permissions for a write path into theta.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum AccessMode {
    Read,
    Write,
    Execute,
}

/// Write path into learner parameters theta.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct WritePath {
    pub handle: String,
    pub access: AccessMode,
}

/// Complete write manifest for learner parameter theta.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct WriteManifest {
    pub paths: Vec<WritePath>,
    pub complete: bool,
}

impl WriteManifest {
    pub fn is_valid(&self) -> bool {
        self.complete
    }
}

/// Plant state record representing the complete physical/internal configuration.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PlantState {
    pub x: Vec<f64>,
    pub u: Vec<f64>,
    pub y: Vec<f64>,
    pub theta: Vec<f64>,
    pub t: u64,
    pub burst_id: u64,
    pub snapshot_id: u64,
}

/// Safety barrier function metadata.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SafetyBarrier {
    pub margin: f64,
    pub horizon: u64,
}

/// Cryptographically signed state snapshot for rollback operations.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Snapshot {
    pub id: u64,
    pub burst_id: u64,
    pub t: u64,
    pub theta_snap: Vec<f64>,
    pub x_snap: Vec<f64>,
    pub y_hist: Vec<Vec<f64>>,
    pub content_hash: String,
    pub signature: String,
}
