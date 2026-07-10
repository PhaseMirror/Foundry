use std::collections::HashMap;

use chrono::{Duration, Utc};

use crate::types::internal::LoadedModelProcess;
use crate::types::ollama::{PsResponse, RunningModel};
use crate::{Error, Result};

/// Manages running model processes
pub struct ProcessManager {
    processes: HashMap<String, LoadedModelProcess>,
    default_keep_alive: Duration,
}

impl ProcessManager {
    pub fn new() -> Self {
        Self {
            processes: HashMap::new(),
            default_keep_alive: Duration::minutes(5),
        }
    }

    /// List all running models
    pub fn list(&self) -> PsResponse {
        let models: Vec<RunningModel> = self
            .processes
            .values()
            .map(|p| RunningModel {
                name: p.model_name.clone(),
                model: p.model_name.clone(),
                size: p.memory_usage,
                digest: format!("sha256:{}", &p.id[..12]),
                expires_at: p.expires_at.to_rfc3339(),
                size_vram: 0, // Not tracking VRAM separately for now
            })
            .collect();

        PsResponse { models }
    }

    /// Register a new running model
    pub fn register(&mut self, model_name: &str, memory_usage: u64) -> String {
        let id = uuid::Uuid::new_v4().to_string();
        let now = Utc::now();

        let process = LoadedModelProcess {
            id: id.clone(),
            model_name: model_name.to_string(),
            loaded_at: now,
            expires_at: now + self.default_keep_alive,
            memory_usage,
        };

        self.processes.insert(id.clone(), process);
        id
    }

    /// Update the expiration time for a model (keep alive)
    pub fn keep_alive(&mut self, model_name: &str, duration: Option<Duration>) -> Result<()> {
        let process = self
            .processes
            .values_mut()
            .find(|p| p.model_name == model_name)
            .ok_or_else(|| Error::ModelNotRunning(model_name.to_string()))?;

        let keep_alive = duration.unwrap_or(self.default_keep_alive);
        process.expires_at = Utc::now() + keep_alive;

        Ok(())
    }

    /// Stop a running model
    pub fn stop(&mut self, model_name: &str) -> Result<()> {
        let id = self
            .processes
            .iter()
            .find(|(_, p)| p.model_name == model_name)
            .map(|(id, _)| id.clone())
            .ok_or_else(|| Error::ModelNotRunning(model_name.to_string()))?;

        self.processes.remove(&id);
        tracing::info!("Stopped model: {}", model_name);

        Ok(())
    }

    /// Check if a model is running
    pub fn is_running(&self, model_name: &str) -> bool {
        self.processes.values().any(|p| p.model_name == model_name)
    }

    /// Get a running model process
    pub fn get(&self, model_name: &str) -> Option<&LoadedModelProcess> {
        self.processes.values().find(|p| p.model_name == model_name)
    }

    /// Clean up expired processes
    pub fn cleanup_expired(&mut self) -> Vec<String> {
        let now = Utc::now();
        let expired: Vec<String> = self
            .processes
            .iter()
            .filter(|(_, p)| p.expires_at < now)
            .map(|(id, _)| id.clone())
            .collect();

        for id in &expired {
            if let Some(process) = self.processes.remove(id) {
                tracing::info!("Expired model unloaded: {}", process.model_name);
            }
        }

        expired
    }
}

impl Default for ProcessManager {
    fn default() -> Self {
        Self::new()
    }
}
