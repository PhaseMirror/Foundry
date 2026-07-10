use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;
use sha2::{Sha256, Digest};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AuditEntry {
    pub trace_id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub action: String,
    pub actor: String,
    pub result: String,
    pub severity: String,
}

pub struct AuditLogger {
    pub log_path: std::path::PathBuf,
}

impl AuditLogger {
    pub fn new(log_path: std::path::PathBuf) -> Self {
        Self { log_path }
    }

    pub fn log(&self, action: &str, actor: &str, result: &str, severity: &str) -> anyhow::Result<()> {
        let entry = AuditEntry {
            trace_id: Uuid::new_v4(),
            timestamp: Utc::now(),
            action: action.to_string(),
            actor: actor.to_string(),
            result: result.to_string(),
            severity: severity.to_string(),
        };
        
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.log_path)?;
            
        let json = serde_json::to_string(&entry)?;
        use std::io::Write;
        writeln!(file, "{}", json)?;
        Ok(())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CasRecord {
    pub id: String,
    pub commitment: String,
    pub timestamp: DateTime<Utc>,
}

pub struct CasRegistry {
    pub records: std::collections::HashMap<String, CasRecord>,
}

impl CasRegistry {
    pub fn new() -> Self {
        Self { records: std::collections::HashMap::new() }
    }

    pub fn register(&mut self, id: &str, commitment: &str) {
        let record = CasRecord {
            id: id.to_string(),
            commitment: commitment.to_string(),
            timestamp: Utc::now(),
        };
        self.records.insert(id.to_string(), record);
    }

    pub fn get_commitment(&self, id: &str) -> Option<&String> {
        self.records.get(id).map(|r| &r.commitment)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;

    #[test]
    fn test_audit_logger() {
        let temp = NamedTempFile::new().unwrap();
        let logger = AuditLogger::new(temp.path().to_path_buf());
        logger.log("test_action", "actor_1", "success", "info").unwrap();
        
        let content = std::fs::read_to_string(temp.path()).unwrap();
        assert!(content.contains("test_action"));
    }

    #[test]
    fn test_cas_registry() {
        let mut registry = CasRegistry::new();
        registry.register("id1", "commitment1");
        assert_eq!(registry.get_commitment("id1"), Some(&"commitment1".to_string()));
    }
}
