use std::path::{Path, PathBuf};
use std::process::Command;
use serde::{Deserialize, Serialize};
use anyhow::{Result, anyhow};
use chrono::Utc;

#[derive(Debug, Serialize, Deserialize, schemars::JsonSchema)]
pub struct LedgerHistoryEntry {
    pub sha: String,
    pub timestamp: String,
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize, schemars::JsonSchema, Clone)]
#[serde(rename_all = "camelCase")]
pub struct MultiplicityEffect {
    pub current_token_value: f64,
    pub projected_token_value: f64,
    pub projected_civic_state: f64,
}

impl MultiplicityEffect {
    /// Checks if the proposed allocation moves the system state toward the Hundian Ground State ($3.00).
    pub fn is_convergent(&self) -> bool {
        let current_dissonance = (self.current_token_value - 3.0).abs();
        let projected_dissonance = (self.projected_token_value - 3.0).abs();
        projected_dissonance <= current_dissonance
    }
}

#[derive(Debug, Serialize, Deserialize, schemars::JsonSchema)]
pub struct ProposalEntry {
    pub proposal_id: String,
    pub rationale: String,
    pub delta: serde_json::Value,
    pub committed_at: String,
    pub multiplicity_effect: MultiplicityEffect,
}

pub struct GitLedger {
    pub repo_path: PathBuf,
}

impl GitLedger {
    pub fn new<P: AsRef<Path>>(repo_path: P) -> Self {
        Self {
            repo_path: repo_path.as_ref().to_path_buf(),
        }
    }

    fn git(&self, args: &[&str]) -> Result<String> {
        let output = Command::new("git")
            .arg("-C")
            .arg(&self.repo_path)
            .args(args)
            .output()?;

        if !output.status.success() {
            let err = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("Git command failed: {}", err));
        }

        Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
    }

    pub fn head_sha(&self) -> String {
        self.git(&["rev-parse", "--short", "HEAD"]).unwrap_or_else(|_| "no-commits".to_string())
    }

    pub fn get_ledger_history(&self, limit: usize) -> Vec<LedgerHistoryEntry> {
        let limit_str = limit.to_string();
        let log = self.git(&["log", &format!("-{}", limit_str), "--pretty=format:%H\t%ai\t%s"]);
        
        match log {
            Ok(log_str) => {
                log_str.lines().filter_map(|line| {
                    let parts: Vec<&str> = line.split('\t').collect();
                    if parts.len() == 3 {
                        Some(LedgerHistoryEntry {
                            sha: parts[0].to_string(),
                            timestamp: parts[1].to_string(),
                            message: parts[2].to_string(),
                        })
                    } else {
                        None
                    }
                }).collect()
            }
            Err(_) => Vec::new(),
        }
    }

    pub fn commit_proposal(
        &self,
        proposal_id: &str,
        delta: serde_json::Value,
        rationale: &str,
        multiplicity_effect: &MultiplicityEffect,
    ) -> Result<String> {
        if !multiplicity_effect.is_convergent() {
            let current_dissonance = (multiplicity_effect.current_token_value - 3.0).abs();
            let projected_dissonance = (multiplicity_effect.projected_token_value - 3.0).abs();
            
            // Log auditability
            tracing::error!(
                "MultiplicityDissonance: Proposal {} moves system away from Hundian Ground State. Current Dissonance: {}, Projected Dissonance: {}",
                proposal_id, current_dissonance, projected_dissonance
            );
            return Err(anyhow!(
                "MultiplicityDissonance: Proposal {} moves system away from Hundian Ground State.",
                proposal_id
            ));
        }
        let ledger_dir = self.repo_path.join("state").join("proposals");
        std::fs::create_dir_all(&ledger_dir)?;
        
        let proposal_file = ledger_dir.join(format!("{}.json", proposal_id));
        let entry = ProposalEntry {
            proposal_id: proposal_id.to_string(),
            rationale: rationale.to_string(),
            delta,
            committed_at: Utc::now().to_rfc3339(),
            multiplicity_effect: multiplicity_effect.clone(),
        };
        
        let content = serde_json::to_string_pretty(&entry)?;
        std::fs::write(&proposal_file, content)?;
        
        self.git(&["add", proposal_file.to_str().unwrap()])?;
        
        let message = format!("proposal({}): {}", proposal_id, &rationale[..std::cmp::min(rationale.len(), 72)]);
        match self.git(&["commit", "--no-verify", "-m", &message]) {
            Ok(_) => Ok(self.head_sha()),
            Err(_) => Ok(self.head_sha()), // If nothing to commit
        }
    }

    pub fn rollback(&self, target_sha: &str) -> Result<()> {
        if !target_sha.chars().all(|c| c.is_ascii_hexdigit()) {
            return Err(anyhow!("Invalid SHA: {}", target_sha));
        }
        self.git(&["reset", "--hard", target_sha])?;
        Ok(())
    }

    pub fn append_witness(&self, witness: &crate::types::UnifiedWitness) -> Result<String> {
        let archivum_dir = self.repo_path.join("state").join("archivum");
        std::fs::create_dir_all(&archivum_dir)?;
        
        let witness_file = archivum_dir.join("witnesses.jsonl");
        let witness_json = serde_json::to_string(witness)?;
        
        use std::io::Write;
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&witness_file)?;
        writeln!(file, "{}", witness_json)?;
        
        let file_str = witness_file.to_str().unwrap();
        self.git(&["add", file_str])?;
        
        let message = format!("archivum: anchor witness {}", witness.witness_id);
        match self.git(&["commit", "--no-verify", "-m", &message]) {
            Ok(_) => Ok(self.head_sha()),
            Err(_) => Ok(self.head_sha()), // If already clean
        }
    }
}
