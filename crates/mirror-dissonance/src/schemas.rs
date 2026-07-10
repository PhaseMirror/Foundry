use serde::{Serialize, Deserialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum Severity {
    Critical,
    High,
    Medium,
    Low,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Hash)]
pub enum Outcome {
    Allow,
    Warn,
    Block,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RuleViolation {
    pub rule_id: String,
    pub severity: Severity,
    pub message: String,
    pub context: Option<HashMap<String, String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MachineDecision {
    pub outcome: Outcome,
    pub reasons: Vec<String>,
    pub metadata: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OracleInput {
    pub mode: String,
    pub strict: bool,
    pub dry_run: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClinicalWorkflowInput {
    pub patient_id: String,
    pub procedure_code: String,
    pub justification_anchored: bool,
    pub confidence_score: f64,
    pub execution_epoch: u64,
    pub stability_score: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictLogSchema {
    pub receipt_hash: String,
    pub r_sc: f64,
    pub l_eff: f64,
    pub tau_r: f64,
    pub breach_type: String, // e.g., "ResonanceDelta", "LipschitzContraction"
    pub timestamp: String,
}

