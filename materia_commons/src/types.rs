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

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema, PartialEq, Eq)]
pub enum SpoliationRiskLevel {
    Critical,
    High,
    Medium,
    Low,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct CompilationResult {
    pub pirtm_version: String,
    pub axioms_clean: bool,
    pub lean_proof_hash: Option<String>,
    pub required_retention_days: Option<u32>,
    pub spoliation_risk_level: SpoliationRiskLevel,
    pub compilation_timestamp: String,
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

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum VetoStatus {
    Approved,
    Vetoed(String),
    Pending,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct UnifiedWitness {
    pub witness_id: String,
    pub action_id: String,
    pub timestamp: String,
    pub compliance_evidence: String,
    pub execution_receipt: serde_json::Value,
    pub contractivity_score: f64,
    pub veto_status: VetoStatus,
    #[serde(default)]
    pub witness_hash: Option<String>,
    #[serde(default)]
    pub p_lineage: Option<String>,
}

impl UnifiedWitness {
    pub fn compute_hash(&self) -> String {
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(&self.witness_id);
        hasher.update(&self.action_id);
        hasher.update(&self.timestamp);
        hasher.update(&self.compliance_evidence);
        hasher.update(self.contractivity_score.to_string());
        let digest = hasher.finalize();
        format!("{:x}", digest)
    }

    pub fn new(
        witness_id: String,
        action_id: String,
        timestamp: String,
        compliance_evidence: String,
        execution_receipt: serde_json::Value,
        contractivity_score: f64,
        veto_status: VetoStatus,
    ) -> Result<Self, anyhow::Error> {
        if witness_id.trim().is_empty() {
            return Err(anyhow::anyhow!("L0-1 Violation: witness_id cannot be empty"));
        }
        if action_id.trim().is_empty() {
            return Err(anyhow::anyhow!("L0-1 Violation: action_id cannot be empty"));
        }
        if timestamp.trim().is_empty() {
            return Err(anyhow::anyhow!("L0-1 Violation: timestamp cannot be empty"));
        }
        Ok(Self {
            witness_id,
            action_id,
            timestamp,
            compliance_evidence,
            execution_receipt,
            contractivity_score,
            veto_status,
            witness_hash: None,
            p_lineage: None,
        })
    }
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

impl SignedAdmissionToken {
    pub fn compute_payload_hash(&self) -> String {
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(&self.token_id);
        if let Some(ref tid) = self.task_id {
            hasher.update(tid);
        }
        hasher.update(self.issued_at.to_string());
        hasher.update(self.expires_at.to_string());
        hasher.update(&self.caller_identity);
        hasher.update(&self.server_binding);
        hasher.update(&self.tool_name);
        for cap in &self.capabilities_granted {
            hasher.update(cap);
        }
        hasher.update(&self.constitution_version);
        let digest = hasher.finalize();
        format!("{:x}", digest)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct McpRegistry {
    pub servers: Vec<McpServerDescriptor>,
}
