// crates/mcp/src/archivum.rs
use async_trait::async_trait;
use sigma::{TransitionBlock, DissonanceError};
use std::collections::HashMap;
use std::sync::Mutex;
use uuid::Uuid;

/// The ledger interface for stamping transitions and logging conflicts.
#[async_trait]
pub trait Archivum: Send + Sync {
    /// Permanently record a ratified block; returns a unique witness ID.
    async fn stamp(&self, block: &TransitionBlock) -> Result<String, String>;

    /// Record a dissonance trap; returns an optional conflict log ID.
    async fn log_conflict(&self, err: &DissonanceError, agent_request_id: &str) -> Result<String, String>;
}

/// Simple in-memory store for testing/development.
pub struct InMemoryArchivum {
    witnesses: Mutex<HashMap<String, TransitionBlock>>,
    conflicts: Mutex<Vec<String>>,
}

impl InMemoryArchivum {
    pub fn new() -> Self {
        Self {
            witnesses: Mutex::new(HashMap::new()),
            conflicts: Mutex::new(Vec::new()),
        }
    }
}

#[async_trait]
impl Archivum for InMemoryArchivum {
    async fn stamp(&self, block: &TransitionBlock) -> Result<String, String> {
        let id = Uuid::new_v4().to_string();
        let mut map = self.witnesses.lock().map_err(|e| e.to_string())?;
        map.insert(id.clone(), block.clone());
        Ok(id)
    }

    async fn log_conflict(&self, err: &DissonanceError, agent_request_id: &str) -> Result<String, String> {
        let id = Uuid::new_v4().to_string();
        let mut vec = self.conflicts.lock().map_err(|e| e.to_string())?;
        vec.push(format!(
            "conflict_id={}, agent={}, error={}",
            id, agent_request_id, err
        ));
        Ok(id)
    }
}
