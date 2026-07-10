use anyhow::Result;
use chrono::Utc;
use serde_json::Value;
use std::path::PathBuf;

use crate::snapshot_manager::SnapshotManager;

pub struct DigitalTwin {
    pub live_state_path: PathBuf,
    pub epoch_index_path: PathBuf,
    pub snapshot_store: PathBuf,
    pub latest_snapshot_path: PathBuf,
    pub manager: SnapshotManager,
}

impl DigitalTwin {
    pub fn new(base_dir: PathBuf) -> Self {
        let state_dir = base_dir.join("state");
        let twin_dir = base_dir.join("digital_twin");

        Self {
            live_state_path: state_dir.join("live_state.yaml"),
            epoch_index_path: state_dir.join("epoch_index.yaml"),
            snapshot_store: twin_dir.join("snapshot_store"),
            latest_snapshot_path: twin_dir.join("latest_snapshot.yaml"),
            manager: SnapshotManager::new(),
        }
    }

    pub fn ensure_state_surfaces(&self) -> Result<()> {
        if !self.live_state_path.exists() {
            if let Some(p) = self.live_state_path.parent() {
                std::fs::create_dir_all(p)?;
            }
            let default_state = serde_json::json!({
                "governance_version": "phase-mirror-stub-v0",
                "system": "tooling-pmd",
                "status": "bootstrap",
                "updated_at": Utc::now().to_rfc3339(),
                "roots": {
                    "mcp_server": "mcp_server/",
                    "daemon": "daemon/",
                    "digital_twin": "digital_twin/",
                    "rollback": "rollback/",
                    "ensemble": "ensemble/"
                }
            });
            let f = std::fs::File::create(&self.live_state_path)?;
            serde_yaml::to_writer(f, &default_state)?;
        }

        if !self.epoch_index_path.exists() {
            if let Some(p) = self.epoch_index_path.parent() {
                std::fs::create_dir_all(p)?;
            }
            let default_epoch = serde_json::json!({
                "governance_version": "phase-mirror-stub-v0",
                "active_snapshot": null,
                "history": []
            });
            let f = std::fs::File::create(&self.epoch_index_path)?;
            serde_yaml::to_writer(f, &default_epoch)?;
        }

        std::fs::create_dir_all(&self.snapshot_store)?;

        Ok(())
    }

    fn load_live_state(&self) -> Result<Value> {
        let f = std::fs::File::open(&self.live_state_path)?;
        let val: Value = serde_yaml::from_reader(f)?;
        Ok(val)
    }

    pub fn snapshot(&mut self) -> Result<Value> {
        self.ensure_state_surfaces()?;
        let live_state = self.load_live_state()?;

        let record = self.manager.snapshot(&live_state, "phase-mirror-stub-v0")?;

        let snapshot_file = self.snapshot_store.join(format!("{}.json", record.tx_id));
        std::fs::write(&snapshot_file, serde_json::to_string_pretty(&record)?)?;

        let f = std::fs::File::create(&self.latest_snapshot_path)?;
        serde_yaml::to_writer(f, &record)?;

        Ok(serde_json::to_value(record)?)
    }
}
