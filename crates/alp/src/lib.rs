use unicode_segmentation::UnicodeSegmentation;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};

pub mod admission {
    use serde::{Deserialize, Serialize};
    use schemars::JsonSchema;
    #[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
    pub struct AdmissibilityReport {
        pub allowed: bool,
        pub reason: String,
    }
}
pub struct PolicyEngine;
impl PolicyEngine {
    pub fn new<T, U, V>(_constitution: T, _config: Option<U>, _tier: V) -> Self { PolicyEngine }
    
    pub fn validate_action(
        &self, 
        action: &Action, 
        trust: &multiplicity_common::types::TrustLevel
    ) -> Result<admission::AdmissibilityReport, anyhow::Error> {
        let mut violations = Vec::new();
        let payload_str = action.payload.to_string();

        if action.mutating {
            if action.payload.is_null() || payload_str.len() == 0 {
                violations.push("L0-STRUCTURAL: mutating action has empty payload");
            }
            if payload_str.len() > 1_048_576 {
                violations.push("L0-RESOURCE: payload exceeds 1 MiB limit");
            }
        }

        if let Some(ref binding) = action.server_binding {
            if binding.contains("external") && matches!(trust, multiplicity_common::types::TrustLevel::External) {
                violations.push("L0-PRIVACY: external trust requires prime-gated server binding");
            }
        }

        if violations.is_empty() {
            Ok(admission::AdmissibilityReport { allowed: true, reason: "Admitted".to_string() })
        } else {
            Ok(admission::AdmissibilityReport { allowed: false, reason: violations.join("; ") })
        }
    }
}
pub mod policy {
    pub use multiplicity_common::types::TrustLevel;
}
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Action {
    pub id: String,
    pub payload: serde_json::Value,
    pub mutating: bool,
    pub server_binding: Option<String>,
}
/// UnitIdentity represents a mapped grapheme to its prime modulus.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct UnitIdentity {
    pub grapheme: String,
    pub mod_val: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PETCVector {
    pub components: HashMap<String, f64>,
}

pub struct GraphemeDecomposer {
    grapheme_map: HashMap<String, u64>,
    next_prime_idx: usize,
    primes: Vec<u64>,
}

impl GraphemeDecomposer {
    pub fn new() -> Self {
        GraphemeDecomposer {
            grapheme_map: HashMap::new(),
            next_prime_idx: 0,
            primes: generate_primes(10000), // Pre-generate some primes
        }
    }

    pub fn decompose(&mut self, text: &str) -> (Vec<UnitIdentity>, PETCVector) {
        let clusters: Vec<&str> = text.graphemes(true).collect();
        let mut all_units = Vec::new();
        let mut total_components = HashMap::new();

        for &g in &clusters {
            let mod_val = self.ensure_grapheme(g);
            all_units.push(UnitIdentity {
                grapheme: g.to_string(),
                mod_val,
            });
            let dim = format!("g_{}", mod_val);
            *total_components.entry(dim).or_insert(0.0) += 1.0;
        }

        (all_units, PETCVector { components: total_components })
    }

    pub fn reassemble(&self, units: &[UnitIdentity]) -> String {
        units.iter().map(|u| u.grapheme.as_str()).collect()
    }

    fn ensure_grapheme(&mut self, g: &str) -> u64 {
        if let Some(&m) = self.grapheme_map.get(g) {
            m
        } else {
            let m = self.primes[self.next_prime_idx];
            self.next_prime_idx += 1;
            self.grapheme_map.insert(g.to_string(), m);
            m
        }
    }
}

fn generate_primes(n: usize) -> Vec<u64> {
    let mut primes = Vec::with_capacity(n);
    let mut candidate = 2;
    while primes.len() < n {
        let mut is_prime = true;
        for &p in &primes {
            if candidate % p == 0 {
                is_prime = false;
                break;
            }
            if p * p > candidate { break; }
        }
        if is_prime { primes.push(candidate); }
        candidate += 1;
    }
    primes
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_decompose_reassemble() {
        let mut decomposer = GraphemeDecomposer::new();
        let text = "Hello 👋 Multiplicity";
        let (units, _) = decomposer.decompose(text);
        let reassembled = decomposer.reassemble(&units);
        assert_eq!(reassembled, text);
    }

    #[test]
    fn test_deterministic_mapping() {
        let mut decomposer = GraphemeDecomposer::new();
        let (units1, _) = decomposer.decompose("a");
        let (units2, _) = decomposer.decompose("a");
        assert_eq!(units1[0].mod_val, units2[0].mod_val);
    }
}

// --- Policy evaluation wrapper for WASM and CLI ---
use serde_json;
use anyhow::Result;

#[derive(Debug, Deserialize, Serialize)]
pub struct PolicyInput {
    pub id: String,
    pub payload: serde_json::Value,
    pub mutating: bool,
    pub server_binding: Option<String>,
}

/// Convert a JSON string describing a `PolicyInput` into a risk level string.
/// Currently this uses the dummy `PolicyEngine::validate_action` which always approves.
/// In a real system this would invoke the full policy engine.
pub fn evaluate_preservation(json_input: &str) -> Result<String, anyhow::Error> {
    // Deserialize the JSON into PolicyInput
    let input: PolicyInput = serde_json::from_str(json_input)?;
    // Build an Action that the PolicyEngine expects
    let action = Action {
        id: input.id,
        payload: input.payload,
        mutating: input.mutating,
        server_binding: input.server_binding,
    };
    // For now we use a placeholder TrustLevel (e.g., High). In the actual engine this
    // would be derived from the constitution and policy configuration.
    let trust = multiplicity_common::types::TrustLevel::High;
    // Call the engine (currently always allowed)
    let report = PolicyEngine::new(() , None).validate_action(&action, &trust)?;
    // Map the allowed flag to a simple risk level string.
    let risk = if report.allowed { "Low" } else { "High" };
    Ok(risk.to_string())
}
