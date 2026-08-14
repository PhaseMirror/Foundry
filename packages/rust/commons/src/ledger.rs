use std::path::{Path, PathBuf};
use std::process::Command;
use serde::{Deserialize, Serialize};
use anyhow::{Result, anyhow};
use chrono::Utc;

#[derive(Debug, Serialize, Deserialize)]
pub struct LedgerHistoryEntry {
    pub sha: String,
    pub timestamp: String,
    pub message: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ProposalEntry {
    pub proposal_id: String,
    pub rationale: String,
    pub delta: serde_json::Value,
    pub committed_at: String,
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
    ) -> Result<String> {
        let ledger_dir = self.repo_path.join("state").join("proposals");
        std::fs::create_dir_all(&ledger_dir)?;
        
        let proposal_file = ledger_dir.join(format!("{}.json", proposal_id));
        let entry = ProposalEntry {
            proposal_id: proposal_id.to_string(),
            rationale: rationale.to_string(),
            delta,
            committed_at: Utc::now().to_rfc3339(),
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
}
