use std::collections::HashMap;

pub const DELTA_E_DEFAULT_THRESHOLD: f64 = 1e-6;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub enum Tier {
    Spectral = 1,
    Structural = 2,
    Predictive = 3,
    Theoretical = 4,
    Safety = 5,
}

impl Tier {
    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "spectral" => Some(Tier::Spectral),
            "structural" => Some(Tier::Structural),
            "predictive" => Some(Tier::Predictive),
            "theoretical" => Some(Tier::Theoretical),
            "safety" => Some(Tier::Safety),
            _ => None,
        }
    }

    pub fn to_str(&self) -> &'static str {
        match self {
            Tier::Spectral => "spectral",
            Tier::Structural => "structural",
            Tier::Predictive => "predictive",
            Tier::Theoretical => "theoretical",
            Tier::Safety => "safety",
        }
    }
}

pub fn tier_precedence(tier_a: Tier, tier_b: Tier) -> Tier {
    // Lower tier number wins
    if (tier_a as u8) <= (tier_b as u8) {
        tier_a
    } else {
        tier_b
    }
}

pub fn check_safety_veto(meta: &HashMap<String, serde_json::Value>) -> bool {
    if meta.get("semantic_class").and_then(|v| v.as_str()) != Some("safety") {
        return false;
    }
    meta.get("safety_veto").and_then(|v| v.as_bool()).unwrap_or(false)
}

pub fn check_theoretical_conflict(
    energy_a: f64,
    energy_b: f64,
    threshold: Option<f64>,
) -> bool {
    let t = threshold.unwrap_or(DELTA_E_DEFAULT_THRESHOLD);
    (energy_a - energy_b).abs() > t
}

pub fn validate_theoretical_regime(meta: &HashMap<String, serde_json::Value>) -> Result<(), String> {
    if meta.get("semantic_class").and_then(|v| v.as_str()) != Some("theoretical") {
        return Ok(());
    }
    let regime = meta.get("theoretical_regime").and_then(|v| v.as_str());
    match regime {
        Some("perturbative") | Some("non_perturbative") | Some("topological") => Ok(()),
        Some(r) => Err(format!("Invalid theoretical_regime: {}", r)),
        None => Err("Missing theoretical_regime".to_string()),
    }
}
