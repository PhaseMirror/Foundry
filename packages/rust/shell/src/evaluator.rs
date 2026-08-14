use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShellArtifact {
    pub module_id: String,
    pub domain_class: String,
    pub rank: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvaluationResult {
    pub module_id: String,
    pub domain_class: String,
    pub rank: i32,
    pub evaluation_order: usize,
    pub verdict: String,
    pub outputs: HashMap<String, serde_json::Value>,
    pub inputs_hash: String,
    pub outputs_hash: String,
    pub duration_us: u64,
}

pub fn build_evaluation_order(artifacts: &[ShellArtifact]) -> Vec<ShellArtifact> {
    let mut ordered = artifacts.to_vec();
    ordered.sort_by(|a, b| {
        a.rank.cmp(&b.rank)
            .then(a.module_id.cmp(&b.module_id))
    });
    ordered
}
