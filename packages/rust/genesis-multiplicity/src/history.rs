//! Port of `genesis_governance/shared/history.py` — persistent run history
//! and reconstruction-metric extraction (ADR-006).
//!
//! The store keeps the entire history in memory (`self.history`) and saves to
//! a JSON file on every `add_run`, exactly like the Python. `json.dump(...,`
//! `indent=2, default=str)` is mirrored with `serde_json::to_string_pretty`.

use crate::shrapnel::ShrapnelMap;
use serde_json::Value;
use std::collections::{BTreeSet, HashMap};
use std::io::Write;
use std::path::{Path, PathBuf};

/// One reconstruction record extracted from fragment metadata, mirroring the
/// dicts produced by `get_reconstruction_history`.
#[derive(Debug, Clone, PartialEq)]
pub struct ReconstructionRecord {
    /// `frag.get("target_id")`
    pub target_id: Option<String>,
    /// `m_meta.get("reconstruction_score")`
    pub score: Option<f64>,
    /// `m_meta.get("locality_delta")`
    pub delta: Option<f64>,
    /// `m_meta.get("exponent_vector")` — used to trace primes
    pub mapping: Option<Value>,
}

/// Persistent store for run history and fragility classes (ADR-006).
#[derive(Debug, Clone)]
pub struct HistoryStore {
    pub file_path: PathBuf,
    pub history: Vec<ShrapnelMap>,
}

impl HistoryStore {
    /// Loads existing history from `file_path`; a missing or unparseable file
    /// yields an empty store (the Python catches `json.JSONDecodeError`).
    pub fn new(file_path: impl Into<PathBuf>) -> Self {
        let file_path = file_path.into();
        let history = Self::load(&file_path);
        Self { file_path, history }
    }

    fn load(path: &Path) -> Vec<ShrapnelMap> {
        match std::fs::read_to_string(path) {
            Ok(text) => serde_json::from_str(&text).unwrap_or_else(|_| Vec::new()),
            Err(_) => Vec::new(),
        }
    }

    fn save(&self) {
        let parent = self
            .file_path
            .parent()
            .filter(|p| !p.as_os_str().is_empty());
        if let Some(parent) = parent {
            let _ = std::fs::create_dir_all(parent);
        }
        // mirror `json.dump(self.history, indent=2, default=str)`
        if let Ok(serialized) = serde_json::to_string_pretty(&self.history) {
            if let Ok(mut file) = std::fs::File::create(&self.file_path) {
                let _ = file.write_all(serialized.as_bytes());
            }
        }
    }

    /// Mirror of `add_run` / `_save`.
    pub fn add_run(&mut self, shrapnel_map: ShrapnelMap) {
        self.history.push(shrapnel_map);
        self.save();
    }

    /// Mirror of `get_known_fragility_classes`.
    pub fn get_known_fragility_classes(&self) -> BTreeSet<String> {
        let mut known = BTreeSet::new();
        for run in &self.history {
            for frag in &run.fragments {
                known.insert(frag.fragility_class.clone());
            }
        }
        known
    }

    /// Mirror of `get_fragility_class_counts`.
    pub fn get_fragility_class_counts(&self) -> HashMap<String, usize> {
        let mut counts = HashMap::new();
        for run in &self.history {
            for frag in &run.fragments {
                *counts.entry(frag.fragility_class.clone()).or_insert(0) += 1;
            }
        }
        counts
    }

    /// Mirror of `get_reconstruction_history`: extracts all reconstruction
    /// metrics from history for sensitivity analysis. Records are only
    /// emitted when the fragment's `metadata.multiplicity` carries a
    /// `reconstruction_score` key.
    pub fn get_reconstruction_history(&self) -> Vec<ReconstructionRecord> {
        let mut records = Vec::new();
        for run in &self.history {
            for frag in &run.fragments {
                let multiplicity = frag.metadata.get("multiplicity").and_then(Value::as_object);
                let Some(m_meta) = multiplicity else {
                    continue;
                };
                if !m_meta.contains_key("reconstruction_score") {
                    continue;
                }
                records.push(ReconstructionRecord {
                    target_id: Some(frag.target_id.clone()),
                    score: m_meta.get("reconstruction_score").and_then(Value::as_f64),
                    delta: m_meta.get("locality_delta").and_then(Value::as_f64),
                    mapping: m_meta.get("exponent_vector").cloned(),
                });
            }
        }
        records
    }
}
