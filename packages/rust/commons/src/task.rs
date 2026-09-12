use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct Workflow {
    pub name: String,
    pub tasks: Vec<Task>,
    pub trust: Option<crate::types::TrustLevel>,
    pub consensus_proof: Option<String>,
    pub threshold_met: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct Task {
    pub id: String,
    pub action: String,
    pub server_binding: Option<String>,
    pub tool_name: Option<String>,
}
