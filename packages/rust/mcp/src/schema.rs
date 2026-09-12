use serde::{Deserialize, Serialize};
use sigma::{StateTransition, TransitionBlock};

/// The operational mode for the agent's request.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum EvaluationMode {
    /// Validate against the policy engine without recording a witness (dry-run).
    Simulate,
    /// Validate and irrevocably stamp the action into the Archivum ledger.
    Commit,
}

/// The MCP Tool input parameters for `evaluate_transition`.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvaluateTransitionRequest {
    /// The agent's unique request/correlation ID for end-to-end tracing.
    pub agent_request_id: String,
    /// The raw transition parameters proposed by the agent.
    pub transition_data: StateTransition,
    /// Whether this is a dry-run or a binding execution.
    pub mode: EvaluationMode,
}

/// The MCP Tool result payload. 
/// Agents must gracefully handle both ratification and dissonance traps.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum EvaluateTransitionResponse {
    Ratified {
        witness_id: String,
        ratified_block: TransitionBlock,
    },
    Simulated {
        ratified_block: TransitionBlock,
    },
    DissonanceTrap {
        breach_type: String,
        details: String,
        /// Reference to the ConflictLog stored in Archivum (if in Commit mode)
        conflict_log_id: Option<String>,
    },
}
