use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::collections::HashMap;
use once_cell::sync::Lazy;
use serde_yaml;

#[derive(Debug, Deserialize)]
struct PreservationEvent {
    // Example fields; actual schema defined in policy YAML
    esi_type: String,
    size_bytes: u64,
    deadline_days: u32,
}

#[derive(Debug, Serialize)]
struct RiskOutcome {
    risk_level: String, // "Critical", "High", "Medium"
    retention_days: u32,
}

/// Core function that computes preservation risk based on the Sedona Spine engine.
/// This is the single source of truth for all ESI retention logic.

#[derive(Debug, Deserialize)]
struct PolicyEntry {
    risk_level: String,
    retention_days: u32,
}

static POLICY: Lazy<HashMap<String, PolicyEntry>> = Lazy::new(|| {
    let yaml_str = include_str!("policy.yaml");
    serde_yaml::from_str(yaml_str).expect("Invalid policy yaml")
});

#[wasm_bindgen]
pub fn compute_risk(event_json: &str) -> String {
    // Parse input event JSON
    let event: PreservationEvent = match serde_json::from_str(event_json) {
        Ok(e) => e,
        Err(e) => {
            return json!({"error": format!("Invalid input: {}", e)}).to_string();
        }
    };

    // Policy‑driven risk mapping loaded from policy.yaml at compile time
    let entry = POLICY.get(&event.esi_type).unwrap_or(&PolicyEntry {
        risk_level: "Medium".to_string(),
        retention_days: 180,
    });

    let outcome = RiskOutcome {
        risk_level: entry.risk_level.clone(),
        retention_days: entry.retention_days,
    };
    serde_json::to_string(&outcome).unwrap_or_else(|e| json!({"error": e.to_string()}).to_string())
}
pub fn compute_risk(event_json: &str) -> String {
    // Parse input event JSON
    let event: PreservationEvent = match serde_json::from_str(event_json) {
        Ok(e) => e,
        Err(e) => {
            return json!({"error": format!("Invalid input: {}", e)}).to_string();
        }
    };

    // Simple placeholder policy: map esi_type to risk level
    let risk = match event.esi_type.as_str() {
        "email" => ("High", 365),
        "document" => ("Medium", 180),
        "image" => ("Low", 90),
        _ => ("Medium", 180),
    };

    let outcome = RiskOutcome {
        risk_level: risk.0.to_string(),
        retention_days: risk.1,
    };
    serde_json::to_string(&outcome).unwrap_or_else(|e| json!({"error": e.to_string()}).to_string())
}

// Exported version info for contracts
#[wasm_bindgen]
pub fn version() -> String {
    "sedona_spine v0.1.0".to_string()
}
