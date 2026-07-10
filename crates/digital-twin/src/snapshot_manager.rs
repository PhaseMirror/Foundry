use anyhow::Result;
use chrono::Utc;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum SchemaCompatibility {
    Compatible,
    Incompatible,
    Deprecated,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum RestoreAction {
    None,
    Warn,
    Restore,
    Escalate,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SnapshotRecord {
    pub tx_id: String,
    pub governance_version: String,
    pub snapshot_path: String,
    pub state_hash: String,
    pub created_at: String,
    pub serialized_state: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SnapshotIndex {
    pub governance_version: String,
    pub latest_tx_id: Option<String>,
    pub tx_history: Vec<String>,
    pub hash_manifest: HashMap<String, String>,
}

impl Default for SnapshotIndex {
    fn default() -> Self {
        Self {
            governance_version: "1.0.0".to_string(),
            latest_tx_id: None,
            tx_history: Vec::new(),
            hash_manifest: HashMap::new(),
        }
    }
}

pub struct SnapshotManager {
    pub index: SnapshotIndex,
    pub snapshots: HashMap<String, SnapshotRecord>,
    pub audit_trail: Vec<serde_json::Value>,
}

impl SnapshotManager {
    pub fn new() -> Self {
        Self {
            index: SnapshotIndex::default(),
            snapshots: HashMap::new(),
            audit_trail: Vec::new(),
        }
    }

    pub fn snapshot(
        &mut self,
        source_state: &serde_json::Value,
        governance_version: &str,
    ) -> Result<SnapshotRecord> {
        let timestamp = Utc::now();
        let timestamp_clean = timestamp.format("%Y-%m-%dT%H-%M-%SZ").to_string();
        let tx_id = format!("tx-{}", timestamp_clean);

        let state_hash = Self::compute_state_hash(source_state)?;
        let snapshot_path = format!("/snapshots/{}.json", tx_id);

        let record = SnapshotRecord {
            tx_id: tx_id.clone(),
            governance_version: governance_version.to_string(),
            snapshot_path,
            state_hash: state_hash.clone(),
            created_at: timestamp.to_rfc3339(),
            serialized_state: source_state.clone(),
        };

        self.snapshots.insert(tx_id.clone(), record.clone());
        
        self.index.latest_tx_id = Some(tx_id.clone());
        self.index.tx_history.push(tx_id.clone());
        self.index.hash_manifest.insert(tx_id, state_hash);

        Ok(record)
    }

    pub fn compute_state_hash(state: &serde_json::Value) -> Result<String> {
        // Deterministic JSON serialization
        let serialized = serde_json::to_string_pretty(state)?;
        let mut hasher = Sha256::new();
        hasher.update(serialized.as_bytes());
        Ok(hex::encode(hasher.finalize()))
    }
}
