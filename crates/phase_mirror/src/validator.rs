use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use chrono::Utc;
use sha2::{Sha256, Digest};
use regex::Regex;
use std::time::Instant;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct L0ValidatorConfig {
    pub drift_threshold: f64,
    pub nonce_max_age_seconds: i64,
    pub contraction_witness_min_events: usize,
}

impl Default for L0ValidatorConfig {
    fn default() -> Self {
        L0ValidatorConfig {
            drift_threshold: 0.5,
            nonce_max_age_seconds: 3600,
            contraction_witness_min_events: 10,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct L0ValidationResult {
    pub invariant_id: String,
    pub invariant_name: String,
    pub passed: bool,
    pub message: String,
    pub evidence: Option<HashMap<String, serde_json::Value>>,
    pub latency_ns: u128,
}

pub struct L0Validator {
    pub config: L0ValidatorConfig,
}

impl L0Validator {
    pub fn new(config: L0ValidatorConfig) -> Self {
        L0Validator { config }
    }

    pub fn validate_schema_hash(&self, schema_content: &str, expected_hash: &str) -> L0ValidationResult {
        let start = Instant::now();
        let mut hasher = Sha256::new();
        hasher.update(schema_content);
        let result = hasher.finalize();
        
        let mut actual_hash = String::new();
        for byte in result.iter().take(4) {
            actual_hash.push_str(&format!("{:02x}", byte));
        }
        
        let passed = actual_hash == expected_hash;
        let latency = start.elapsed().as_nanos();
        
        let mut evidence = HashMap::new();
        evidence.insert("expected".to_string(), serde_json::json!(expected_hash));
        evidence.insert("actual".to_string(), serde_json::json!(actual_hash));
        evidence.insert("schemaLength".to_string(), serde_json::json!(schema_content.len()));

        L0ValidationResult {
            invariant_id: "L0-001".to_string(),
            invariant_name: "schema_hash".to_string(),
            passed,
            message: if passed { "Schema hash valid".to_string() } else { format!("Schema hash mismatch: expected {}, got {}", expected_hash, actual_hash) },
            evidence: Some(evidence),
            latency_ns: latency,
        }
    }

    pub fn validate_permission_bits(&self, workflow_path: &str, workflow_content: &str) -> L0ValidationResult {
        let start = Instant::now();
        
        let excessive_patterns = [
            r"permissions:\s*write-all",
            r"permissions:\s*\{\s*\w+:\s*write-all",
            r"contents:\s*write(?!-)",
        ];
        
        let mut violations = Vec::new();
        for pattern in &excessive_patterns {
            let re = Regex::new(&format!(r"(?i){}", pattern)).unwrap();
            if let Some(m) = re.find(workflow_content) {
                violations.push(m.as_str().to_string());
            }
        }
        
        let passed = violations.is_empty();
        let latency = start.elapsed().as_nanos();
        
        let mut evidence = HashMap::new();
        evidence.insert("workflow".to_string(), serde_json::json!(workflow_path));
        if !violations.is_empty() {
            evidence.insert("violations".to_string(), serde_json::json!(violations));
        }

        L0ValidationResult {
            invariant_id: "L0-002".to_string(),
            invariant_name: "permission_bits".to_string(),
            passed,
            message: if passed { 
                format!("Workflow {} follows least privilege", workflow_path) 
            } else { 
                format!("Workflow {} has excessive permissions: {}", workflow_path, violations.join(", ")) 
            },
            evidence: Some(evidence),
            latency_ns: latency,
        }
    }

    pub fn validate_drift_magnitude(&self, current: f64, baseline: f64) -> L0ValidationResult {
        let start = Instant::now();
        
        let drift = if baseline == 0.0 {
            if current == 0.0 { 0.0 } else { 1.0 }
        } else {
            (current - baseline).abs() / baseline
        };
        
        let passed = drift <= self.config.drift_threshold;
        let latency = start.elapsed().as_nanos();
        
        let mut evidence = HashMap::new();
        evidence.insert("drift".to_string(), serde_json::json!(drift));
        evidence.insert("threshold".to_string(), serde_json::json!(self.config.drift_threshold));
        evidence.insert("current".to_string(), serde_json::json!(current));
        evidence.insert("baseline".to_string(), serde_json::json!(baseline));

        L0ValidationResult {
            invariant_id: "L0-003".to_string(),
            invariant_name: "drift_magnitude".to_string(),
            passed,
            message: if passed {
                format!("Drift {:.1}% within acceptable range", drift * 100.0)
            } else {
                format!("Drift {:.1}% exceeds threshold {:.1}%", drift * 100.0, self.config.drift_threshold * 100.0)
            },
            evidence: Some(evidence),
            latency_ns: latency,
        }
    }

    pub fn validate_nonce_freshness(&self, nonce: &str, timestamp_ms: i64, now_ms: Option<i64>) -> L0ValidationResult {
        let start = Instant::now();
        let now = now_ms.unwrap_or_else(|| Utc::now().timestamp_millis());
        let age_seconds = (now - timestamp_ms) / 1000;
        
        let passed = age_seconds >= 0 && age_seconds < self.config.nonce_max_age_seconds;
        let latency = start.elapsed().as_nanos();
        
        let mut evidence = HashMap::new();
        evidence.insert("age".to_string(), serde_json::json!(age_seconds));
        evidence.insert("maxAge".to_string(), serde_json::json!(self.config.nonce_max_age_seconds));
        evidence.insert("nonce".to_string(), serde_json::json!(nonce));
        evidence.insert("timestamp".to_string(), serde_json::json!(timestamp_ms));

        L0ValidationResult {
            invariant_id: "L0-004".to_string(),
            invariant_name: "nonce_freshness".to_string(),
            passed,
            message: if passed {
                format!("Nonce fresh (age: {}s)", age_seconds)
            } else if age_seconds < 0 {
                "Nonce timestamp is in the future".to_string()
            } else {
                format!("Nonce expired (age: {}s, max: {}s)", age_seconds, self.config.nonce_max_age_seconds)
            },
            evidence: Some(evidence),
            latency_ns: latency,
        }
    }
}
