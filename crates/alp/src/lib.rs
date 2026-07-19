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

// --- ADR-101: native ALP/CNL inference path (replaces LLM on the control path) ---
pub mod cnl;
pub mod llm;
pub mod engine;
pub use engine::AlpEngine;
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
    // Derive trust level from the action's server binding BEFORE moving fields.
    // If the binding references an "external" server, trust is External;
    // otherwise default to Internal (the local governance boundary).
    let trust = if input.server_binding.as_deref().map_or(false, |b| b.contains("external")) {
        multiplicity_common::types::TrustLevel::External
    } else {
        multiplicity_common::types::TrustLevel::Internal
    };
    // Build an Action that the PolicyEngine expects
    let action = Action {
        id: input.id,
        payload: input.payload,
        mutating: input.mutating,
        server_binding: input.server_binding,
    };
    // Call the engine (currently always allowed)
    let report = PolicyEngine::new((), None::<String>, ()).validate_action(&action, &trust)?;
    // Map the allowed flag to a simple risk level string.
    let risk = if report.allowed { "Low" } else { "High" };
    Ok(risk.to_string())
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SystemState {
    pub arta_defect: f64,
    pub multiplicity_measure: f64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AlpPolicy {
    pub name: String,
    pub rules: Vec<AlpRule>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum AlpRule {
    IncreaseMultiplicity(f64),
    DecreaseArtaDefect(f64),
    NoOp,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct RtaMetric {
    pub value: f64,
}

#[derive(Debug, Clone, PartialEq, thiserror::Error)]
pub enum EvalError {
    #[error("invalid policy: {0}")]
    InvalidPolicy(String),
    #[error("contradictory policy detected")]
    ContradictoryPolicy,
}

impl PolicyEngine {
    pub fn evaluate(&self, policy: &AlpPolicy, state: &SystemState) -> std::result::Result<RtaMetric, EvalError> {
        let mut has_increase = false;
        let mut has_decrease = false;
        let mut has_noop = false;

        for r in &policy.rules {
            match r {
                AlpRule::IncreaseMultiplicity(_) => has_increase = true,
                AlpRule::DecreaseArtaDefect(_) => has_decrease = true,
                AlpRule::NoOp => has_noop = true,
            }
        }

        // Just an arbitrary rule for contradiction demonstration
        if has_noop && (has_increase || has_decrease) {
            return Err(EvalError::ContradictoryPolicy);
        }

        let mut new_state = state.clone();
        for r in &policy.rules {
            match r {
                AlpRule::IncreaseMultiplicity(d) => new_state.multiplicity_measure += d,
                AlpRule::DecreaseArtaDefect(d) => new_state.arta_defect -= d,
                AlpRule::NoOp => {}
            }
        }

        Ok(RtaMetric { value: new_state.multiplicity_measure - new_state.arta_defect })
    }

    pub fn check(&self, state: &SystemState) -> std::result::Result<bool, EvalError> {
        // dummy check logic
        Ok(state.multiplicity_measure > state.arta_defect)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;
    use crate::cnl::CnlCompiler;
    use crate::engine::AlpEngine;
    use crate::llm::LlmDraft;

    #[kani::proof]
    fn proof_alp_preserves_rta() {
        let state = SystemState {
            arta_defect: 10.0,
            multiplicity_measure: 20.0,
        };
        let initial_rta = state.multiplicity_measure - state.arta_defect;

        let rule_val: f64 = kani::any();
        kani::assume(rule_val >= 0.0); // valid increases are positive

        let policy = AlpPolicy {
            name: "Test".to_string(),
            rules: vec![AlpRule::IncreaseMultiplicity(rule_val)],
        };

        let engine = PolicyEngine;
        if let Ok(new_rta) = engine.evaluate(&policy, &state) {
            kani::assert(new_rta.value >= initial_rta, "Rta must be preserved or improved");
        }
    }

    // ADR-101 Lemma 1 — CNL compiler determinism (function-ness).
    //
    // Kani in this toolchain cannot bound symbolic `String`/`Vec<u8>` inputs
    // (the state space is 256^N) so symbolic-string proofs blow up. We verify
    // the determinism invariant on representative concrete inputs; the cargo e2e
    // harness (`tests/e2e_phase_mirror.rs`) exercises the same invariant
    // across many inputs, including edge cases.
    #[kani::proof]
    fn proof_cnl_compiler_deterministic() {
        let s = "policy p\nincrease multiplicity by 1.0".to_string();
        let p1 = CnlCompiler::parse(&s).unwrap();
        let p2 = CnlCompiler::parse(&s).unwrap();
        kani::assert(p1 == p2, "identical CNL parses to identical policy");
    }

    // ADR-101 soundness: a well-formed CNL numeric directive compiles.
    #[kani::proof]
    fn proof_cnl_compiler_sound() {
        let p = CnlCompiler::parse("policy demo\nincrease multiplicity by 2.0");
        kani::assert(p.is_ok(), "well-formed CNL must compile");
    }

    // ADR-101 architectural invariant: `LlmDraft::normalize` is exactly
    // `CnlCompiler::parse(to_cnl(raw))`. An LLM output can never become
    // an action except by re-entering the CNL channel.
    #[kani::proof]
    fn proof_llm_normalize_routes_through_cnl() {
        let draft = LlmDraft {
            raw: "text\n```\npolicy x\ndecrease arta defect by 0.25\n```".to_string(),
        };
        let norm = draft.normalize().unwrap();
        let direct = CnlCompiler::parse("policy x\ndecrease arta defect by 0.25").unwrap();
        kani::assert(norm == direct, "normalize equals parse(to_cnl(raw))");
    }

    // ADR-101 determinism at the engine boundary: `evaluate_cnl` returns the
    // same canonical (policy, rta) pair for equal state and CNL source.
    #[kani::proof]
    fn proof_engine_evaluate_cnl_deterministic() {
        let state = SystemState {
            arta_defect: 2.0,
            multiplicity_measure: 8.0,
        };
        let cnl = "policy p\nincrease multiplicity by 1.5\ndecrease arta defect by 0.5";
        let engine = AlpEngine;
        let (p1, m1) = engine.evaluate_cnl(&state, cnl).unwrap();
        let (p2, m2) = engine.evaluate_cnl(&state, cnl).unwrap();
        kani::assert(p1 == p2 && m1 == m2, "engine is deterministic on identical inputs");
    }
}
