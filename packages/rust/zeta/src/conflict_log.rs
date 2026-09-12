use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use std::fs::OpenOptions;
use std::io::{Write, BufRead, BufReader};
use std::path::Path;

#[derive(Error, Debug)]
pub enum ConflictLogError {
    #[error("Missing required field: {0}")]
    MissingField(String),
    #[error("Invalid conflict type: {0}")]
    InvalidConflictType(String),
    #[error("Tier must be 1-5, got: {0}")]
    InvalidTier(u8),
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
    #[error("Serialization error: {0}")]
    SerdeError(#[from] serde_json::Error),
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ConflictType {
    SpectralConflict,
    StructuralConflict,
    PredictiveConflict,
    TheoreticalConflict,
    SafetyVeto,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConflictEntry {
    pub trace_id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub conflict_type: ConflictType,
    pub tier: u8,
    pub artifact_ids: Vec<String>,
    pub artifact_versions: Vec<String>,
    pub winning_tier: u8,
    pub resolution: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub replay_seed: Option<String>,
    #[serde(default)]
    pub human_review_required: bool,
    #[serde(default)]
    pub pipeline_halted: bool,
}

impl ConflictEntry {
    pub fn validate(&self) -> Result<(), ConflictLogError> {
        if self.tier < 1 || self.tier > 5 {
            return Err(ConflictLogError::InvalidTier(self.tier));
        }
        if self.winning_tier < 1 || self.winning_tier > 5 {
            return Err(ConflictLogError::InvalidTier(self.winning_tier));
        }

        if self.conflict_type == ConflictType::SafetyVeto && !self.pipeline_halted {
            return Err(ConflictLogError::MissingField("pipeline_halted must be true for SAFETY_VETO".to_string()));
        }

        if self.conflict_type == ConflictType::TheoreticalConflict && !self.human_review_required {
            return Err(ConflictLogError::MissingField("human_review_required must be true for THEORETICAL_CONFLICT".to_string()));
        }

        Ok(())
    }

    pub fn new(
        conflict_type: ConflictType,
        tier: u8,
        artifact_ids: Vec<String>,
        artifact_versions: Vec<String>,
        winning_tier: u8,
        resolution: String,
        replay_seed: Option<String>,
        human_review_required: bool,
        pipeline_halted: bool,
    ) -> Result<Self, ConflictLogError> {
        let entry = ConflictEntry {
            trace_id: Uuid::new_v4(),
            timestamp: Utc::now(),
            conflict_type,
            tier,
            artifact_ids,
            artifact_versions,
            winning_tier,
            resolution,
            replay_seed,
            human_review_required,
            pipeline_halted,
        };
        entry.validate()?;
        Ok(entry)
    }
}

pub fn write_entry(log_path: &Path, entry: &ConflictEntry) -> Result<(), ConflictLogError> {
    entry.validate()?;
    if let Some(parent) = log_path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let mut file = OpenOptions::new()
        .create(true)
        .append(true)
        .open(log_path)?;
    
    let json = serde_json::to_string(entry)?;
    writeln!(file, "{}", json)?;
    Ok(())
}

pub fn read_entries(log_path: &Path) -> Result<Vec<ConflictEntry>, ConflictLogError> {
    if !log_path.exists() {
        return Ok(Vec::new());
    }
    let file = std::fs::File::open(log_path)?;
    let reader = BufReader::new(file);
    let mut entries = Vec::new();
    for line in reader.lines() {
        let line = line?;
        if !line.trim().is_empty() {
            let entry: ConflictEntry = serde_json::from_str(&line)?;
            entries.push(entry);
        }
    }
    Ok(entries)
}
