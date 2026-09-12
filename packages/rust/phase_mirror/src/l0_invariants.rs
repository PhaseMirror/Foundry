use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use chrono::Utc;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Nonce {
    pub value: String,
    pub issued_at: i64, // Unix timestamp in milliseconds
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct State {
    pub schema_version: String,
    pub schema_hash: String,
    pub permission_bits: u16,
    pub drift_magnitude: f64,
    pub nonce: Nonce,
    pub contraction_witness_score: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InvariantCheckResult {
    pub passed: bool,
    pub failed_checks: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub violations: Option<HashMap<String, String>>,
}

const EXPECTED_SCHEMA_VERSION: &str = "1.0.0";
const EXPECTED_SCHEMA_HASH: &str = "f7a8b9c0d1e2f3g4";
const RESERVED_PERMISSION_BITS_MASK: u16 = 0b1111000000000000;
const DRIFT_THRESHOLD: f64 = 0.3;
const NONCE_LIFETIME_MS: i64 = 3600000;
const MIN_NONCE_LENGTH: usize = 64;
const CONTRACTION_WITNESS_THRESHOLD: f64 = 1.0;

pub fn check_l0_invariants(state: &State, now_ms: Option<i64>) -> InvariantCheckResult {
    let now = now_ms.unwrap_or_else(|| Utc::now().timestamp_millis());
    
    let schema_valid = !state.schema_hash.is_empty() && 
                      !state.schema_version.is_empty() &&
                      state.schema_version == EXPECTED_SCHEMA_VERSION &&
                      state.schema_hash == EXPECTED_SCHEMA_HASH;
                      
    let permissions_valid = (state.permission_bits & RESERVED_PERMISSION_BITS_MASK) == 0;
    
    let drift_valid = state.drift_magnitude >= 0.0 && state.drift_magnitude <= DRIFT_THRESHOLD;
    
    let age = now - state.nonce.issued_at;
    let nonce_valid = !state.nonce.value.is_empty() &&
                      state.nonce.value.len() >= MIN_NONCE_LENGTH &&
                      age >= 0 && age < NONCE_LIFETIME_MS;
                      
    let witness_valid = state.contraction_witness_score.map_or(true, |s| s == CONTRACTION_WITNESS_THRESHOLD);
    
    if schema_valid && permissions_valid && drift_valid && nonce_valid && witness_valid {
        return InvariantCheckResult {
            passed: true,
            failed_checks: Vec::new(),
            violations: None,
        };
    }
    
    let mut failed_checks = Vec::new();
    let mut violations = HashMap::new();
    
    if !schema_valid {
        failed_checks.push("schema_hash".to_string());
        violations.insert("schema_hash".to_string(), format!("Schema hash mismatch. Expected version: {}, hash: {}", EXPECTED_SCHEMA_VERSION, EXPECTED_SCHEMA_HASH));
    }
    
    if !permissions_valid {
        failed_checks.push("permission_bits".to_string());
        violations.insert("permission_bits".to_string(), format!("Reserved bits are set. Permission bits: {:016b}", state.permission_bits));
    }
    
    if !drift_valid {
        failed_checks.push("drift_magnitude".to_string());
        violations.insert("drift_magnitude".to_string(), format!("Drift magnitude exceeds threshold. Value: {}, threshold: {}", state.drift_magnitude, DRIFT_THRESHOLD));
    }
    
    if !nonce_valid {
        failed_checks.push("nonce_freshness".to_string());
        if state.nonce.value.is_empty() {
            violations.insert("nonce_freshness".to_string(), "Nonce value is missing".to_string());
        } else if state.nonce.value.len() < MIN_NONCE_LENGTH {
            violations.insert("nonce_freshness".to_string(), "Nonce value is too short".to_string());
        } else if age < 0 {
            violations.insert("nonce_freshness".to_string(), "Nonce timestamp is in the future".to_string());
        } else {
            violations.insert("nonce_freshness".to_string(), format!("Nonce is expired or stale. Age: {}ms, lifetime: {}ms", age, NONCE_LIFETIME_MS));
        }
    }
    
    if !witness_valid {
        failed_checks.push("contraction_witness".to_string());
        violations.insert("contraction_witness".to_string(), format!("Contraction witness score is not perfect. Score: {:?}, required: {}", state.contraction_witness_score, CONTRACTION_WITNESS_THRESHOLD));
    }
    
    InvariantCheckResult {
        passed: false,
        failed_checks,
        violations: Some(violations),
    }
}
