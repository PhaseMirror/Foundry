use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct ProposalRequest {
    pub proposal_id: String,
    pub payload: serde_json::Value,
    pub rationale: String,
    pub state_norm: f64,
    pub drift_rate: f64,
    pub contractivity_score: f64,
    pub critique_results: Vec<crate::constitution::CritiqueResult>,
    pub prime_gates: Vec<crate::constitution::PrimeGate>,
    pub kill_switch_active: bool,
    pub rollback_anchor_sha: Option<String>,
    pub consecutive_failures: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct ToolResponse {
    pub ok: bool,
    pub tool_name: String,
    pub proposal_id: String,
    pub commit_sha: Option<String>,
    pub result: serde_json::Value,
    pub violation: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct UnifiedWitness {
    pub witness_id: String,
    pub action_id: String,
    pub timestamp: String,
    pub compliance_evidence: String,
    pub execution_receipt: serde_json::Value,
    pub contractivity_score: f64,
    pub veto_status: String,
    pub consensus_proof: Option<String>,
    pub threshold_met: Option<bool>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, schemars::JsonSchema)]
#[serde(rename_all = "lowercase")]
pub enum TrustLevel {
    Internal,
    External,
}

impl TrustLevel {
    pub fn can_call_governed_resource(&self) -> bool {
        matches!(self, TrustLevel::Internal)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct McpServerDescriptor {
    pub id: String,
    pub name: String,
    pub transport: String,
    pub command: String,
    pub args: Vec<String>,
    pub hash: String,
    pub trust: String,
    pub governed: bool,
    pub alp_required: bool,
    pub sat_ttl_seconds: Option<u64>,
    pub capabilities: Option<Vec<String>>,
    pub tags: Option<Vec<String>>,
    pub warning: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct SignedAdmissionToken {
    pub token_id: String,
    pub task_id: Option<String>,
    pub issued_at: i64,
    pub expires_at: i64,
    pub caller_identity: String,
    pub server_binding: String,
    pub tool_name: String,
    pub capabilities_granted: Vec<String>,
    pub constitution_version: String,
    pub signature_scheme: String,
    pub signature: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct McpRegistry {
    pub servers: Vec<McpServerDescriptor>,
}
