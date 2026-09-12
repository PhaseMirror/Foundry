use serde::{Deserialize, Serialize};
use thiserror::Error;
use crate::types::TrustLevel;

/// Role of this Commander node in the replication topology.
#[derive(Debug, Clone, Deserialize, Serialize, PartialEq, schemars::JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ReplicationRole {
    Primary,
    Replica { primary_addr: String },
}

/// Runtime configuration for LAN Archivum replication.
/// Stored in state/sync/replication_config.yaml — not in env.sh.
#[derive(Debug, Clone, Deserialize, Serialize, schemars::JsonSchema)]
pub struct ReplicationConfig {
    pub role: ReplicationRole,
    pub node_id: String,
    /// Trust levels eligible for cross-node replication.
    /// Default: [Internal] only. Changing this requires an ALP policy update.
    pub replicate_trust_levels: Vec<TrustLevel>,
    /// Maximum retry attempts for Transport failures before quarantine.
    pub max_transport_retries: u32,
}

impl Default for ReplicationConfig {
    fn default() -> Self {
        Self {
            role: ReplicationRole::Primary,
            node_id: String::from("node-local"),
            replicate_trust_levels: vec![TrustLevel::Internal],
            max_transport_retries: 3,
        }
    }
}

/// Errors produced by the replica push loop.
/// The caller MUST match on these variants — no wildcard handling permitted.
#[derive(Debug, Error)]
pub enum ReplicationError {
    /// Transient network failure. Eligible for exponential backoff retry.
    #[error("transport failure: {0}")]
    Transport(String),

    /// Primary ALP gate rejected the witness. Do NOT retry.
    /// Write to state/sync/quarantine/ and emit a structured log entry.
    #[error("policy rejection: {reason} (witness_id: {witness_id})")]
    PolicyRejection {
        witness_id: String,
        reason: String,
    },

    /// SAT expired or invalid. Attempt exactly one rotation, then quarantine.
    #[error("authentication failure: SAT invalid or expired")]
    AuthFailure,

    /// Serialization or schema mismatch. Indicates a version skew.
    /// Quarantine immediately. Do not retry without operator intervention.
    #[error("schema error: {0}")]
    SchemaError(String),
}

impl ReplicationError {
    /// Returns true if the error class permits automatic retry.
    pub fn is_retryable(&self) -> bool {
        matches!(self, ReplicationError::Transport(_))
    }

    /// Returns true if the witness should be written to quarantine.
    pub fn requires_quarantine(&self) -> bool {
        matches!(
            self,
            ReplicationError::PolicyRejection { .. }
                | ReplicationError::SchemaError(_)
        )
    }
}
