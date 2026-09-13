//! Port of `genesis_governance/multiplicity/allocator.py` — automated
//! prime-band allocation (ADR-009).

use crate::history::{HistoryStore, ReconstructionRecord};
use std::collections::HashMap;

/// Prime bands: `BANDS` from the Python (dynamics / structure / context).
pub const BANDS: &[(&str, &[i64])] = &[
    ("A", &[2, 3, 5]),    // Dynamics (Continuous)
    ("B", &[7, 11]),      // Structure (Categorical)
    ("C", &[13, 17, 19]), // Context (Coupling/Parameters)
];

/// Feature → band assignment, insertion order preserved (the sweep rotates
/// features in this exact order, matching the Python dict iteration order).
pub const FEATURE_BAND_MAPPING: &[(&str, &str)] = &[
    ("coherence", "A"),
    ("effective_stress", "A"),
    ("threshold_state", "A"),
    ("logical_state", "B"),
    ("frequency", "C"),
    ("coupling", "C"),
];

/// Default/initial feature-to-prime mapping, mirroring `current_mapping`.
pub fn default_mapping() -> HashMap<String, i64> {
    HashMap::from([
        (String::from("coherence"), 2),
        (String::from("effective_stress"), 3),
        (String::from("threshold_state"), 5),
        (String::from("logical_state"), 7),
        (String::from("frequency"), 13),
        (String::from("coupling"), 17),
    ])
}

fn band(band_id: &str) -> &'static [i64] {
    BANDS
        .iter()
        .find(|(id, _)| *id == band_id)
        .map(|(_, primes)| *primes)
        .unwrap_or(&[])
}

/// Automated prime-band allocation logic (ADR-009).
#[derive(Debug, Clone)]
pub struct PrimeBandAllocator {
    pub history: Option<HistoryStore>,
    pub current_mapping: HashMap<String, i64>,
}

impl PrimeBandAllocator {
    pub fn new(history: Option<HistoryStore>) -> Self {
        Self {
            history,
            current_mapping: default_mapping(),
        }
    }

    /// Heuristic for feature sensitivity (0 to 1). Mirrors the Python
    /// exactly: `logical_state` is prioritized, missing history yields `0.5`,
    /// and >10 targeted history samples yield the population std-dev.
    pub fn analyze_feature_sensitivity(&self, feature_name: &str) -> f64 {
        if feature_name == "logical_state" {
            return 0.9;
        }
        let Some(history) = &self.history else {
            return 0.5;
        };
        let recon_history = history.get_reconstruction_history();
        let target_scores = recon_history
            .iter()
            .filter(|r| r.target_id.as_deref() == Some(feature_name))
            .filter_map(|r| r.score)
            .collect::<Vec<_>>();
        if target_scores.len() > 10 {
            return crate::population_std(&target_scores);
        }
        0.4
    }

    /// Returns the current feature-to-prime mapping (a snapshot; the Python
    /// returns the live dict, so a fresh allocator is the correct analogue).
    pub fn allocate(&self) -> HashMap<String, i64> {
        self.current_mapping.clone()
    }

    /// Queries `HistoryStore` for reconstruction drift and re-allocates
    /// (rotates within bands) when drift exceeds the thresholds. Returns
    /// `true` when any feature moved.
    pub fn sensitivity_sweep(&mut self, score_threshold: f64, delta_threshold: f64) -> bool {
        let Some(history) = &self.history else {
            return false;
        };
        let recon_history = history.get_reconstruction_history();
        if recon_history.is_empty() {
            return false;
        }

        // Analyze latest window: Python `recon_history[-50:]`.
        let window = &recon_history[recon_history.len().saturating_sub(50)..];
        let avg_score = mean(window);
        let max_delta = window
            .iter()
            .map(|r| r.delta.unwrap_or(0.0))
            .fold(0.0_f64, f64::max);

        let mut reallocated = false;
        if avg_score < score_threshold || max_delta > delta_threshold {
            // TRIGGER RE-ALLOCATION: cycle primes within their bands.
            for &(feature, band_id) in FEATURE_BAND_MAPPING {
                let primes_in_band = band(band_id);
                let current_p = self.current_mapping[feature];
                let current_idx = primes_in_band
                    .iter()
                    .position(|&p| p == current_p)
                    .unwrap_or(0);
                let next_p = primes_in_band[(current_idx + 1) % primes_in_band.len()];
                if next_p != current_p {
                    self.current_mapping.insert(feature.to_string(), next_p);
                    reallocated = true;
                }
            }
        }
        reallocated
    }

    /// `mapping.get(feature, 23)` — fallback to a high prime.
    pub fn get_prime_for_feature(&self, feature_name: &str) -> i64 {
        self.current_mapping
            .get(feature_name)
            .copied()
            .unwrap_or(23)
    }
}

fn mean(records: &[ReconstructionRecord]) -> f64 {
    if records.is_empty() {
        return 0.0;
    }
    records.iter().map(|r| r.score.unwrap_or(0.0)).sum::<f64>() / records.len() as f64
}
