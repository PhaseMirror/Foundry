use serde::{Deserialize, Serialize};
use serde_json::Value;
use crate::self_modification::proposal::{ModificationProposal, ModificationTarget, Reversibility};
use std::collections::HashMap;
use sha2::{Sha256, Digest};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParameterSnapshot {
    pub snapshot_id: String,
    pub timestamp: f64,
    pub parameters: HashMap<String, Value>,
    pub snapshot_hash: String,
    pub proposal_id: Option<String>,
}

impl ParameterSnapshot {
    pub fn capture(snapshot_id: &str, parameters: &HashMap<String, Value>, proposal_id: Option<String>) -> Self {
        let mut sorted_params: Vec<_> = parameters.iter().collect();
        sorted_params.sort_by_key(|k| k.0);
        let canonical = serde_json::to_string(&sorted_params).unwrap();
        
        let mut hasher = Sha256::new();
        hasher.update(canonical.as_bytes());
        let hash = hex::encode(hasher.finalize());

        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs_f64();

        Self {
            snapshot_id: snapshot_id.to_string(),
            timestamp: now,
            parameters: parameters.clone(),
            snapshot_hash: hash,
            proposal_id,
        }
    }

    pub fn verify_integrity(&self) -> bool {
        let mut sorted_params: Vec<_> = self.parameters.iter().collect();
        sorted_params.sort_by_key(|k| k.0);
        let canonical = serde_json::to_string(&sorted_params).unwrap();
        
        let mut hasher = Sha256::new();
        hasher.update(canonical.as_bytes());
        let expected = hex::encode(hasher.finalize());
        self.snapshot_hash == expected
    }
}

pub struct LedgerEntry {
    pub snapshot: ParameterSnapshot,
    pub proposal: Option<ModificationProposal>,
    pub parent_snapshot_id: Option<String>,
}

pub struct ModificationLedger {
    entries: Vec<LedgerEntry>,
    by_id: HashMap<String, usize>,
    head_id: Option<String>,
}

impl ModificationLedger {
    pub fn new() -> Self {
        Self {
            entries: Vec::new(),
            by_id: HashMap::new(),
            head_id: None,
        }
    }

    pub fn head_hash(&self) -> Option<String> {
        self.head_id.as_ref().map(|id| {
            let idx = self.by_id.get(id).unwrap();
            self.entries[*idx].snapshot.snapshot_hash.clone()
        })
    }

    pub fn append(&mut self, snapshot: ParameterSnapshot, proposal: Option<ModificationProposal>) {
        let parent_id = self.head_id.clone();
        let snapshot_id = snapshot.snapshot_id.clone();
        let entry = LedgerEntry {
            snapshot,
            proposal,
            parent_snapshot_id: parent_id,
        };
        let idx = self.entries.len();
        self.entries.push(entry);
        self.by_id.insert(snapshot_id.clone(), idx);
        self.head_id = Some(snapshot_id);
    }

    pub fn get_snapshot(&self, snapshot_id: &str) -> Option<&ParameterSnapshot> {
        self.by_id.get(snapshot_id).map(|&idx| &self.entries[idx].snapshot)
    }
}

pub fn check_boundary_gate(
    proposal: &ModificationProposal,
    boundary_doc: &Value,
) -> (bool, Vec<String>) {
    let mut blockers = Vec::new();

    if boundary_doc.is_null() || !boundary_doc.is_object() {
        blockers.push("boundary_doc is empty or missing".to_string());
        return (false, blockers);
    }

    let safe_to_transfer = boundary_doc.get("safe_to_transfer_pattern")
        .and_then(|v| v.as_bool())
        .unwrap_or(true);

    if proposal.reversibility == Reversibility::Irreversible {
        if !safe_to_transfer {
            blockers.push(format!(
                "Irreversible proposal {} requires safe_to_transfer_pattern=true",
                proposal.proposal_id
            ));
            return (false, blockers);
        }
    }

    if proposal.reversibility == Reversibility::PartiallyReversible {
        if !safe_to_transfer {
            blockers.push(format!(
                "Warning: proposal {} crosses partial boundary — human review recommended",
                proposal.proposal_id
            ));
            return (true, blockers);
        }
    }

    (true, blockers)
}

pub const REQUIRED_LEGITIMACY_SECTIONS: [&str; 4] = [
    "input_legitimacy",
    "procedural_legitimacy",
    "output_legitimacy",
    "tradeoff_declaration",
];

pub fn check_legitimacy_gate(
    proposal: &ModificationProposal,
    legitimacy_doc: &Value,
    human_approved: bool,
) -> (bool, Vec<String>) {
    let mut blockers = Vec::new();

    if legitimacy_doc.is_null() || !legitimacy_doc.is_object() {
        blockers.push("legitimacy_doc is empty or missing".to_string());
        return (false, blockers);
    }

    for &section in &REQUIRED_LEGITIMACY_SECTIONS {
        if legitimacy_doc.get(section).map_or(true, |v| v.is_null() || (v.is_string() && v.as_str().unwrap().is_empty())) {
            blockers.push(format!("Missing or empty legitimacy section: {}", section));
        }
    }

    if !blockers.is_empty() {
        return (false, blockers);
    }

    let td = legitimacy_doc.get("tradeoff_declaration");
    if let Some(td_obj) = td.and_then(|v| v.as_object()) {
        if td_obj.get("approver").map_or(true, |v| v.is_null() || (v.is_string() && v.as_str().unwrap().is_empty())) {
            blockers.push("tradeoff_declaration.approver is required".to_string());
            return (false, blockers);
        }
    } else {
        blockers.push("tradeoff_declaration is missing or not an object".to_string());
        return (false, blockers);
    }

    if proposal.requires_human_approval() && !human_approved {
        blockers.push(format!(
            "Proposal {} targets {:?} — human approval is mandatory",
            proposal.proposal_id, proposal.target
        ));
        return (false, blockers);
    }

    (true, blockers)
}

pub fn check_playbook_gate(
    proposal: &ModificationProposal,
    playbook_stage: &Value,
    completed_artifacts: &[String],
) -> (bool, Vec<String>) {
    if proposal.target != ModificationTarget::PlaybookStage {
        return (true, Vec::new());
    }

    let mut blockers = Vec::new();

    if playbook_stage.is_null() || !playbook_stage.is_object() {
        blockers.push("playbook_stage is empty or missing".to_string());
        return (false, blockers);
    }

    let required = playbook_stage.get("required_artifacts").and_then(|v| v.as_array());
    if let Some(req_arr) = required {
        let missing: Vec<_> = req_arr.iter()
            .filter_map(|v| v.as_str())
            .filter(|&a| !completed_artifacts.contains(&a.to_string()))
            .collect();
        if !missing.is_empty() {
            let stage_id = playbook_stage.get("current").and_then(|v| v.as_str()).unwrap_or("unknown");
            blockers.push(format!("Cannot advance from stage {}: missing artifacts: {:?}", stage_id, missing));
        }
    }

    let stage_blockers = playbook_stage.get("blockers").and_then(|v| v.as_array());
    if let Some(sb_arr) = stage_blockers {
        if !sb_arr.is_empty() {
            blockers.push(format!("Stage has blockers: {:?}", sb_arr));
        }
    }

    let can_advance = playbook_stage.get("can_advance").and_then(|v| v.as_bool()).unwrap_or(false);
    if !can_advance {
        blockers.push("can_advance is false".to_string());
    }

    (blockers.is_empty(), blockers)
}
