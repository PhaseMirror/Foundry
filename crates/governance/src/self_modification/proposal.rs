use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use chrono::Utc;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ModificationTarget {
    GainMatrix,
    ContractivityEpsilon,
    DcgfThreshold,
    ConstraintStatus,
    LegitimacyDocument,
    BoundaryAssessment,
    PlaybookStage,
    SourceCode,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum Reversibility {
    Reversible,
    PartiallyReversible,
    Irreversible,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ModificationProposal {
    pub proposal_id: String,
    pub target: ModificationTarget,
    pub current_snapshot_hash: String,
    pub proposed_delta: serde_json::Value,
    pub rationale: String,
    #[serde(default)]
    pub pmd_roots_triggered: Vec<String>,
    #[serde(default = "default_true")]
    pub simulation_required: bool,
    #[serde(default = "default_reversible")]
    pub reversibility: Reversibility,
    pub timestamp: f64,
}

fn default_true() -> bool { true }
fn default_reversible() -> Reversibility { Reversibility::Reversible }

impl ModificationProposal {
    pub fn new(
        proposal_id: String,
        target: ModificationTarget,
        current_snapshot_hash: String,
        proposed_delta: serde_json::Value,
        rationale: String,
    ) -> Self {
        Self {
            proposal_id,
            target,
            current_snapshot_hash,
            proposed_delta,
            rationale,
            pmd_roots_triggered: Vec::new(),
            simulation_required: true,
            reversibility: Reversibility::Reversible,
            timestamp: Utc::now().timestamp() as f64,
        }
    }

    pub fn proposal_hash(&self) -> String {
        let payload = serde_json::json!({
            "proposal_id": self.proposal_id,
            "target": self.target,
            "current_snapshot_hash": self.current_snapshot_hash,
            "proposed_delta": self.proposed_delta,
            "rationale": self.rationale,
            "reversibility": self.reversibility,
        });
        let payload_json = serde_json::to_string(&payload).unwrap();
        hex::encode(Sha256::digest(payload_json.as_bytes()))
    }

    pub fn requires_human_approval(&self) -> bool {
        if self.reversibility == Reversibility::Irreversible {
            return true;
        }
        matches!(self.target, ModificationTarget::LegitimacyDocument | ModificationTarget::PlaybookStage)
    }

    pub fn is_stale(&self, current_hash: &str) -> bool {
        self.current_snapshot_hash != current_hash
    }
}
