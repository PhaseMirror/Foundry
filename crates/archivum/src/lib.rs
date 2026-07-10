use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs::{OpenOptions, File};
use std::io::{BufRead, BufReader, Write};
use std::path::{Path, PathBuf};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ArchivumError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Validation error: {0}")]
    Validation(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictLogSchema {
    pub receipt_hash: String,
    pub r_sc: f64,
    pub l_eff: f64,
    pub tau_r: f64,
    pub breach_type: String,
    pub timestamp: String,
    pub pweh_hash: String,
}

impl ConflictLogSchema {
    pub fn new(transition_id: &str, r_sc: f64, l_eff: f64, tau_r: f64, breach_type: String) -> Self {
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs()
            .to_string();
        
        let receipt_hash = format!("PWEH-TRAP-{}", timestamp);
        let pweh_hash = PwehHash::compute(transition_id, &receipt_hash);
        
        Self {
            receipt_hash,
            r_sc,
            l_eff,
            tau_r,
            breach_type,
            timestamp,
            pweh_hash,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransitionBlock {
    pub transition_id: String,
    pub ratified: bool,
}

impl TransitionBlock {
    pub fn new_ratified(transition_id: String) -> Self {
        Self {
            transition_id,
            ratified: true,
        }
    }
}

#[derive(Debug, Clone)]
pub struct PwehHash(String);

impl PwehHash {
    pub fn compute(transition_id: &str, receipt_hash: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(transition_id.as_bytes());
        hasher.update(receipt_hash.as_bytes());
        format!("{:x}", hasher.finalize())
    }
}

pub struct WitnessLedger {
    path: PathBuf,
}

impl WitnessLedger {
    pub fn new<P: AsRef<Path>>(path: P) -> Self {
        Self { path: path.as_ref().to_path_buf() }
    }

    pub fn stamp_pweh(&self, log: &ConflictLogSchema) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(log)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn append_block(&self, block: &TransitionBlock) -> Result<(), ArchivumError> {
        self.ensure_dir()?;
        let mut file = OpenOptions::new().create(true).append(true).open(&self.path)?;
        let json = serde_json::to_string(block)?;
        writeln!(file, "{}", json)?;
        Ok(())
    }

    pub fn has_conflict_log(&self) -> bool {
        if let Ok(file) = File::open(&self.path) {
            let reader = BufReader::new(file);
            reader.lines().any(|line| {
                if let Ok(l) = line {
                    if let Ok(obj) = serde_json::from_str::<serde_json::Value>(&l) {
                        return obj.get("breach_type").is_some() && obj.get("pweh_hash").is_some();
                    }
                }
                false
            })
        } else {
            false
        }
    }

    pub fn contains_pweh_for(&self, block: &TransitionBlock) -> bool {
        if let Ok(file) = File::open(&self.path) {
            let reader = BufReader::new(file);
            reader.lines().any(|line| {
                if let Ok(l) = line {
                    if let Ok(obj) = serde_json::from_str::<serde_json::Value>(&l) {
                        return obj.get("transition_id")
                            .and_then(|v| v.as_str())
                            .map(|s| s == block.transition_id)
                            .unwrap_or(false);
                    }
                }
                false
            })
        } else {
            false
        }
    }

    fn ensure_dir(&self) -> Result<(), ArchivumError> {
        if let Some(parent) = self.path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        Ok(())
    }
}
