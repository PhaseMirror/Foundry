use std::path::PathBuf;
use std::fs::{OpenOptions, File};
use std::io::{Write, BufReader, BufRead};
use serde_json::Value;
use crate::witnesses::humoe::operator_auth::{HOXRole, OperatorRegistry};

pub struct HOXAuditLog {
    log_path: PathBuf,
}

impl HOXAuditLog {
    pub fn new(log_path: PathBuf) -> Self {
        let mut log = Self { log_path };
        log.ensure_log();
        log
    }

    fn ensure_log(&mut self) {
        if let Some(parent) = self.log_path.parent() {
            let _ = std::fs::create_dir_all(parent);
        }
        if !self.log_path.exists() {
            let _ = File::create(&self.log_path);
        }
    }

    pub fn append(&self, record: &Value) -> Result<(), String> {
        let mut file = OpenOptions::new()
            .append(true)
            .open(&self.log_path)
            .map_err(|e| format!("Failed to open log: {}", e))?;
        
        let json = serde_json::to_string(record).unwrap();
        writeln!(file, "{}", json).map_err(|e| format!("Failed to write to log: {}", e))?;
        Ok(())
    }

    pub fn export(&self) -> Result<Vec<Value>, String> {
        let file = File::open(&self.log_path).map_err(|e| format!("Failed to open log: {}", e))?;
        let reader = BufReader::new(file);
        let mut records = Vec::new();
        for line in reader.lines() {
            let line = line.map_err(|e| format!("Failed to read line: {}", e))?;
            if !line.trim().is_empty() {
                let rec: Value = serde_json::from_str(&line).map_err(|e| format!("Failed to parse JSON: {}", e))?;
                records.push(rec);
            }
        }
        Ok(records)
    }

    pub fn search(&self, query: &std::collections::HashMap<String, Value>) -> Result<Vec<Value>, String> {
        let records = self.export()?;
        let results = records.into_iter()
            .filter(|rec| {
                query.iter().all(|(k, v)| rec.get(k) == Some(v))
            })
            .collect();
        Ok(results)
    }

    pub fn export_by_case(&self, event_id: &str) -> Result<Vec<Value>, String> {
        let records = self.export()?;
        let results = records.into_iter()
            .filter(|rec| rec.get("event_id").and_then(|v| v.as_str()) == Some(event_id))
            .collect();
        Ok(results)
    }

    pub fn export_redacted(&self, operator_id: &str, registry: &OperatorRegistry) -> Result<Vec<Value>, String> {
        let operator = registry.get_operator(operator_id).ok_or_else(|| format!("Unknown operator: {}", operator_id))?;
        let role = operator.role;
        let records = self.export()?;
        
        if role == HOXRole::ComplianceOfficer || role == HOXRole::Supervisor {
            return Ok(records);
        }
        
        let mut redacted = Vec::new();
        for mut rec in records {
            if let Some(obj) = rec.as_object_mut() {
                if role != HOXRole::SystemAdmin {
                    obj.remove("provenance");
                }
                if role == HOXRole::Reviewer {
                    obj.insert("rationale".to_string(), Value::String("REDACTED".to_string()));
                }
                redacted.push(Value::Object(obj.clone()));
            }
        }
        Ok(redacted)
    }

    pub fn enforce_retention(&self, keep_event_ids: Option<Vec<String>>) -> Result<(), String> {
        let event_ids = match keep_event_ids {
            Some(ids) => ids,
            None => return Ok(()),
        };
        
        let records = self.export()?;
        let retained: Vec<Value> = records.into_iter()
            .filter(|rec| {
                if let Some(eid) = rec.get("event_id").and_then(|v| v.as_str()) {
                    event_ids.contains(&eid.to_string())
                } else {
                    false
                }
            })
            .collect();
        
        let mut file = File::create(&self.log_path).map_err(|e| format!("Failed to clear log for retention: {}", e))?;
        for rec in retained {
            let json = serde_json::to_string(&rec).unwrap();
            writeln!(file, "{}", json).map_err(|e| format!("Failed to write retained record: {}", e))?;
        }
        Ok(())
    }
}
