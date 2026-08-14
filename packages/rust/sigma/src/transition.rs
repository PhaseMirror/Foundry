use serde::{Deserialize, Serialize};

#[derive(Debug, Default, Serialize, Deserialize, schemars::JsonSchema)]
pub struct State {
    pub version: u32,
    pub data: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct TransitionRecord {
    pub id: String,
    pub workflow_name: String,
    pub status: String,
}
