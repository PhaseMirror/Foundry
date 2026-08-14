pub mod merkle;

use serde::{Deserialize, Serialize};
use crate::proof_anchor::{normalize_pi_native, ProofAnchorError};
use thiserror::Error;
use chrono::Utc;
use sha2::{Sha256, Digest};
use std::collections::HashMap;
use std::path::PathBuf;
use std::fs;
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq, Eq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum LedgerEntryType {
    GovernanceRootCommit,
    GovernanceAction,
    AuditLog,
    ProofAnchor,
    CouncilDecision,
    GovernanceDecision,
}

#[derive(Error, Debug)]
pub enum LedgerError {
    #[error("Governance violation: {0}")]
    Violation(String),
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Serde error: {0}")]
    Serde(#[from] serde_json::Error),
    #[error("Proof anchor error: {0}")]
    ProofAnchor(#[from] ProofAnchorError),
    #[error("Runtime error: {0}")]
    Runtime(String),
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub struct EpistemicWarrant {
    pub justification: String,
    pub evidence: String,
    pub confidence: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub re_evaluation_date: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct ImmutableFileRecord {
    pub path: String,
    pub hash: String,
    #[serde(default)]
    pub raw_hash: String,
    #[serde(default)]
    pub root_input_hash: String,
    #[serde(default = "default_hash_semantics")]
    pub hash_semantics: String,
    #[serde(default)]
    pub size_bytes: u64,
}

fn default_hash_semantics() -> String {
    "raw_bytes".to_string()
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
#[serde(rename_all = "camelCase")]
pub struct GovernanceRootCommit {
    #[serde(rename = "type")]
    pub entry_type: LedgerEntryType,
    pub governance_version: String,
    pub merkle_root: String,
    pub immutable_files: Vec<ImmutableFileRecord>,
    pub signers: Vec<String>,
    pub signed_by: String,
    pub timestamp: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub previous_root_tx_id: Option<u64>,
    pub governance_notes: String,
    pub quorum_threshold: u32,
    pub rollback_ref: String,
    pub review_cadence_days: u32,
    pub audit_trigger: String,
    pub bls_aggregate_signature: String,
    pub bls_pubkey_set_hash: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub epistemic_warrant: Option<EpistemicWarrant>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub re_evaluation_date: Option<String>,
}

impl Default for GovernanceRootCommit {
    fn default() -> Self {
        Self {
            entry_type: LedgerEntryType::GovernanceRootCommit,
            governance_version: "v0.0.0".to_string(),
            merkle_root: String::new(),
            immutable_files: Vec::new(),
            signers: Vec::new(),
            signed_by: String::new(),
            timestamp: String::new(),
            previous_root_tx_id: None,
            governance_notes: String::new(),
            quorum_threshold: 1,
            rollback_ref: "main".to_string(),
            review_cadence_days: 30,
            audit_trigger: "governance_action".to_string(),
            bls_aggregate_signature: String::new(),
            bls_pubkey_set_hash: String::new(),
            epistemic_warrant: None,
            re_evaluation_date: None,
        }
    }
}

pub struct LedgerStore {
    storage_path: Option<PathBuf>,
    entries: HashMap<u64, GovernanceRootCommit>,
    next_id: u64,
}

impl LedgerStore {
    pub fn new(storage_path: Option<PathBuf>) -> Result<Self, LedgerError> {
        let mut store = Self {
            storage_path,
            entries: HashMap::new(),
            next_id: 1,
        };

        if let Some(ref path) = store.storage_path {
            if path.exists() {
                store.load_from_disk()?;
            }
        }

        Ok(store)
    }

    fn load_from_disk(&mut self) -> Result<(), LedgerError> {
        let path = self.storage_path.as_ref().unwrap();
        let content = fs::read_to_string(path)?;
        let data: HashMap<String, GovernanceRootCommit> = serde_json::from_str(&content)?;
        
        for (id_str, entry) in data {
            let id = id_str.parse::<u64>().map_err(|_| LedgerError::Runtime("Invalid TX ID in ledger".to_string()))?;
            self.entries.insert(id, entry);
            if id >= self.next_id {
                self.next_id = id + 1;
            }
        }
        Ok(())
    }

    fn save_to_disk(&self) -> Result<(), LedgerError> {
        if let Some(ref path) = self.storage_path {
            if let Some(parent) = path.parent() {
                fs::create_dir_all(parent)?;
            }
            let content = serde_json::to_string_pretty(&self.entries)?;
            fs::write(path, content)?;
        }
        Ok(())
    }

    pub fn create_entry(&mut self, mut entry: GovernanceRootCommit) -> Result<u64, LedgerError> {
        let effective_signers: Vec<String> = if entry.signers.is_empty() {
            if entry.signed_by.is_empty() { vec![] } else { vec![entry.signed_by.clone()] }
        } else {
            entry.signers.clone()
        };

        let unique_signers: std::collections::HashSet<_> = effective_signers.iter().collect();
        if (unique_signers.len() as u32) < entry.quorum_threshold {
            return Err(LedgerError::Violation(format!(
                "Quorum not met: {} signer(s) < threshold {}",
                unique_signers.len(),
                entry.quorum_threshold
            )));
        }

        let tx_id = self.next_id;
        self.next_id += 1;

        if entry.timestamp.is_empty() {
            entry.timestamp = Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true);
        }

        self.entries.insert(tx_id, entry);
        self.save_to_disk()?;
        Ok(tx_id)
    }

    pub fn get_entry(&self, tx_id: u64) -> Option<&GovernanceRootCommit> {
        self.entries.get(&tx_id)
    }

    pub fn get_latest_root_commit(&self) -> Option<(u64, &GovernanceRootCommit)> {
        self.entries.iter()
            .filter(|(_, entry)| entry.entry_type == LedgerEntryType::GovernanceRootCommit)
            .max_by_key(|(id, _)| **id)
            .map(|(id, entry)| (*id, entry))
    }

    pub fn list_entries(&self) -> Vec<(u64, &GovernanceRootCommit)> {
        let mut items: Vec<_> = self.entries.iter().map(|(id, entry)| (*id, entry)).collect();
        items.sort_by_key(|(id, _)| *id);
        items
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AuditLedgerEntry {
    pub sequence_num: u64,
    pub evaluation_id: String,
    pub timestamp: String,
    pub report: serde_json::Value,
    pub prev_hash: String,
    pub payload_hash: String,
    pub entry_hash: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub proof_anchor: Option<String>,
    #[serde(rename = "type")]
    pub entry_type: LedgerEntryType,
}

pub struct AuditLedger {
    location: Option<PathBuf>,
    pub entries: Vec<AuditLedgerEntry>,
}

impl AuditLedger {
    pub fn new(location: Option<PathBuf>) -> Result<Self, LedgerError> {
        let mut ledger = Self {
            location,
            entries: Vec::new(),
        };

        if let Some(ref path) = ledger.location {
            if path.exists() {
                ledger.load()?;
            }
        }
        Ok(ledger)
    }

    fn load(&mut self) -> Result<(), LedgerError> {
        let path = self.location.as_ref().unwrap();
        let content = fs::read_to_string(path)?;
        self.entries = serde_json::from_str(&content)?;
        Ok(())
    }

    pub fn save(&self) -> Result<(), LedgerError> {
        if let Some(ref path) = self.location {
            if let Some(parent) = path.parent() {
                fs::create_dir_all(parent)?;
            }
            let content = serde_json::to_string_pretty(&self.entries)?;
            fs::write(path, content)?;
        }
        Ok(())
    }

    pub fn append(
        &mut self,
        report: serde_json::Value,
        evaluation_id: Option<String>,
        timestamp: Option<String>,
        persist: bool,
    ) -> Result<AuditLedgerEntry, LedgerError> {
        let sequence_num = (self.entries.len() as u64) + 1;
        let resolved_timestamp = timestamp.unwrap_or_else(|| Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true));
        
        let metadata = report.get("metadata");
        let resolved_evaluation_id = evaluation_id
            .or_else(|| metadata.and_then(|m| m.get("evaluation_id")).and_then(|v| v.as_str()).map(|s| s.to_string()))
            .unwrap_or_else(|| format!("eval-{}", Uuid::new_v4().simple()));

        let payload_json = serde_json::to_string(&report)?;
        let payload_hash = hex::encode(Sha256::digest(payload_json.as_bytes()));
        
        let prev_hash = self.entries.last().map(|e| e.entry_hash.clone()).unwrap_or_default();
        
        let entry_hash_input = format!("{}:{}:{}:{}", sequence_num, resolved_evaluation_id, prev_hash, payload_hash);
        let entry_hash = hex::encode(Sha256::digest(entry_hash_input.as_bytes()));

        let mut proof_anchor = None;
        if report.get("kind").and_then(|v| v.as_str()) == Some("PROOF_ANCHOR") {
            proof_anchor = report.get("pi_native").and_then(|v| v.as_str()).map(|s| s.to_string());
        }

        let entry = AuditLedgerEntry {
            sequence_num,
            evaluation_id: resolved_evaluation_id,
            timestamp: resolved_timestamp,
            report,
            prev_hash,
            payload_hash,
            entry_hash,
            proof_anchor,
            entry_type: LedgerEntryType::AuditLog,
        };

        self.entries.push(entry.clone());
        if persist {
            self.save()?;
        }
        Ok(entry)
    }

    pub fn append_proof_anchor(
        &mut self,
        pi_native: &str,
        circuit: &str,
        proposal_id: &str,
    ) -> Result<AuditLedgerEntry, LedgerError> {
        let normalized = normalize_pi_native(pi_native)?;
        let report = serde_json::json!({
            "kind": "PROOF_ANCHOR",
            "pi_native": normalized,
            "circuit": circuit,
            "metadata": {
                "proposal_id": proposal_id,
            }
        });
        self.append(report, Some(proposal_id.to_string()), None, true)
    }

    pub fn validate(&self) -> bool {
        let mut prev_hash = String::new();
        for entry in &self.entries {
            if entry.prev_hash != prev_hash {
                return false;
            }

            let payload_json = match serde_json::to_string(&entry.report) {
                Ok(json) => json,
                Err(_) => return false,
            };
            let payload_hash = hex::encode(Sha256::digest(payload_json.as_bytes()));
            if entry.payload_hash != payload_hash {
                return false;
            }

            let entry_hash_input = format!(
                "{}:{}:{}:{}",
                entry.sequence_num, entry.evaluation_id, entry.prev_hash, payload_hash
            );
            let entry_hash = hex::encode(Sha256::digest(entry_hash_input.as_bytes()));
            if entry.entry_hash != entry_hash {
                return false;
            }

            prev_hash = entry.entry_hash.clone();
        }
        true
    }
}

pub struct GitLedger {
    repo_path: PathBuf,
}

impl GitLedger {
    pub fn new(repo_path: PathBuf) -> Self {
        Self { repo_path }
    }

    fn git(&self, args: &[&str]) -> Result<String, LedgerError> {
        let output = std::process::Command::new("git")
            .arg("-C")
            .arg(&self.repo_path)
            .args(args)
            .output()?;

        if !output.status.success() {
            return Err(LedgerError::Runtime(format!(
                "Git command failed: {}",
                String::from_utf8_lossy(&output.stderr)
            )));
        }

        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    }

    pub fn head_sha(&self) -> String {
        self.git(&["rev-parse", "--short", "HEAD"]).unwrap_or_else(|_| "no-commits".to_string())
    }

    pub fn get_ledger_history(&self, limit: usize) -> Vec<serde_json::Value> {
        let log = match self.git(&["log", &format!("-{}", limit), "--pretty=format:%H\t%ai\t%s"]) {
            Ok(l) => l,
            Err(_) => return vec![],
        };

        log.lines()
            .filter_map(|line| {
                let parts: Vec<&str> = line.split('\t').collect();
                if parts.len() == 3 {
                    Some(serde_json::json!({
                        "sha": parts[0],
                        "timestamp": parts[1],
                        "message": parts[2],
                    }))
                } else {
                    None
                }
            })
            .collect()
    }

    pub fn commit_proposal(
        &self,
        proposal_id: &str,
        delta: &serde_json::Value,
        rationale: &str,
    ) -> Result<String, LedgerError> {
        let ledger_dir = self.repo_path.join("state").join("proposals");
        fs::create_dir_all(&ledger_dir)?;
        
        let proposal_file = ledger_dir.join(format!("{}.json", proposal_id));
        let entry = serde_json::json!({
            "proposal_id": proposal_id,
            "rationale": rationale,
            "delta": delta,
            "committed_at": Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true),
        });

        fs::write(&proposal_file, serde_json::to_string_pretty(&entry)?)?;

        self.git(&["add", &proposal_file.to_string_lossy()])?;
        
        let message = format!("proposal({}): {}", proposal_id, &rationale[..std::cmp::min(72, rationale.len())]);
        match self.git(&["commit", "--no-verify", "-m", &message]) {
            Ok(_) => Ok(self.head_sha()),
            Err(_) => Ok(self.head_sha()), // If nothing to commit
        }
    }

    pub fn rollback(&self, target_sha: &str) -> Result<(), LedgerError> {
        if !target_sha.chars().all(|c| c.is_ascii_hexdigit()) {
            return Err(LedgerError::Runtime(format!("Invalid SHA: {}", target_sha)));
        }
        self.git(&["reset", "--hard", target_sha])?;
        Ok(())
    }
}
