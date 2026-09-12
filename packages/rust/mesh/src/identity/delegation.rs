use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct DelegationLink {
    pub parent_did: String,
    pub child_did: String,
    pub capabilities: Vec<String>,
    pub depth: u32,
}

impl DelegationLink {
    pub fn new(parent_did: String, child_did: String, capabilities: Vec<String>, depth: u32) -> Self {
        Self {
            parent_did,
            child_did,
            capabilities,
            depth,
        }
    }
}
