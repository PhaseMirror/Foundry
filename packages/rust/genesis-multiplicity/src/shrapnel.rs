//! Port of `genesis_governance/schemas/shrapnel.py` — the run-history records
//! consumed by `HistoryStore`. Only the fields `HistoryStore` reads are
//! ported; the pydantic base-model fields are intentionally omitted (nothing
//! in the multiplicity pipeline reads them).

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use std::collections::HashMap;

/// Mirrors `ShrapnelFragment` (pydantic). `metadata` is a free-form map whose
/// `multiplicity` key feeds `HistoryStore::get_reconstruction_history`.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShrapnelFragment {
    pub target_id: String,
    pub baseline_intent: String,
    pub test_suite: Vec<String>,
    pub observed_drift: HashMap<String, f64>,
    pub fragility_class: String,
    pub tether_tension: f64,
    #[serde(default)]
    pub tier: String,
    #[serde(default)]
    pub metadata: Map<String, Value>,
}

/// Mirrors `ShrapnelMap` (pydantic).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ShrapnelMap {
    #[serde(default)]
    pub fragments: Vec<ShrapnelFragment>,
    pub overall_tau: f64,
    pub coverage: f64,
    #[serde(default)]
    pub tier: String,
}
