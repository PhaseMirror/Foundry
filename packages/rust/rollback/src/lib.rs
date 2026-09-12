use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};
use chrono::{DateTime, Utc};
use thiserror::Error;

pub mod manager;
pub use manager::*;

#[derive(Error, Debug)]
pub enum RollbackError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("Serialization error: {0}")]
    SerdeYaml(#[from] serde_yaml::Error),
    #[error("Checkpoint not found")]
    CheckpointNotFound,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CheckpointPayload {
    pub checkpoint_id: String,
    pub captured_at: DateTime<Utc>,
    pub metadata: serde_json::Value,
    pub live_state: serde_json::Value,
}

pub struct CheckpointManager {
    pub checkpoint_store: PathBuf,
    pub latest_checkpoint_path: PathBuf,
}

impl CheckpointManager {
    pub fn new(store_path: PathBuf, latest_path: PathBuf) -> Self {
        fs::create_dir_all(&store_path).expect("Failed to create checkpoint store");
        Self {
            checkpoint_store: store_path,
            latest_checkpoint_path: latest_path,
        }
    }

    pub fn write_checkpoint(&self, label: &str, live_state: serde_json::Value, metadata: serde_json::Value) -> Result<PathBuf, RollbackError> {
        let checkpoint_id = format!("{}-{}", label, Utc::now().format("%Y%m%dT%H%M%S%fZ"));
        let payload = CheckpointPayload {
            checkpoint_id: checkpoint_id.clone(),
            captured_at: Utc::now(),
            metadata,
            live_state,
        };
        
        let path = self.checkpoint_store.join(format!("{}.yaml", checkpoint_id));
        let file = fs::File::create(&path)?;
        serde_yaml::to_writer(file, &payload)?;
        
        // Update latest
        let latest_file = fs::File::create(&self.latest_checkpoint_path)?;
        serde_yaml::to_writer(latest_file, &payload)?;
        
        Ok(path)
    }

    pub fn load_latest(&self) -> Result<CheckpointPayload, RollbackError> {
        if !self.latest_checkpoint_path.exists() {
            return Err(RollbackError::CheckpointNotFound);
        }
        let file = fs::File::open(&self.latest_checkpoint_path)?;
        Ok(serde_yaml::from_reader(file)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    #[test]
    fn test_checkpoint_roundtrip() {
        let temp = tempfile::tempdir().unwrap();
        let store = temp.path().to_path_buf();
        let latest = temp.path().join("latest.yaml");
        let manager = CheckpointManager::new(store, latest);
        
        let state = serde_json::json!({"val": 1});
        let meta = serde_json::json!({"test": true});
        
        manager.write_checkpoint("test", state, meta).unwrap();
        let loaded = manager.load_latest().unwrap();
        assert!(loaded.checkpoint_id.contains("test"));
    }
}
