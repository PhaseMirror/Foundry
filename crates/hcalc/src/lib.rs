use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum TerminalState {
    CONVERGED,
    INCONCLUSIVE,
    FREEZE,
    FREEZE_CYTOKINE_STORM,
    DECOUPLED,
}

impl std::fmt::Display for TerminalState {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernanceScore {
    pub code: String,
    pub probability: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HCalcInput {
    pub modality_count: usize,
    pub contraction_tau: f64,
    pub contraction_mass: f64,
    pub lipschitz_bound: f64,
    pub drift: f64,
    pub resonance: f64,
    pub classifier_confidence: f64,
    pub ranked_differential: Vec<GovernanceScore>,
    #[serde(default = "default_true")]
    pub physio_bounds_ok: bool,
    #[serde(default = "default_true")]
    pub epistemic_verified: bool,
    pub prior_witness_q: Option<f64>,
}

fn default_true() -> bool {
    true
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HCalcResult {
    pub state: TerminalState,
    pub contraction_witness_q: f64,
    pub top_k_concentration: f64,
    pub reason: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DomainProfile {
    pub domain_id: String,
    pub compliance_regime: String,
    pub r_max_runtime: usize,
    pub drift_bound_max: f64,
    pub resonance_r_min: f64,
    pub resonance_r_safe: f64,
    pub top_k_k: usize,
    pub top_k_concentration_threshold: f64,
    pub convergence_epsilon: f64,
    pub classifier_confidence_min: f64,
    pub requires_audit_trail: bool,
    pub phi_fields: Vec<String>,
    pub output_refusal_reason: String,
}

pub mod config {
    pub const TOP_K_CONCENTRATION_THRESHOLD: f64 = 0.60;
    pub const CONVERGENCE_EPSILON: f64 = 0.01;
    pub const CLASSIFIER_CONFIDENCE_MIN: f64 = 0.90;
    pub const R_MAX_RUNTIME: usize = 16;
    pub const DRIFT_BOUND_MAX: f64 = 0.30;
    pub const RESONANCE_R_MIN: f64 = 0.10;
    pub const RESONANCE_R_SAFE: f64 = 0.90;
}

pub mod brain_aging;

pub fn compute_contraction_witness(
    tau: f64,
    mass: f64,
    lipschitz_term: f64,
    _prior_q: Option<f64>,
) -> f64 {
    let denom = lipschitz_term.max(1e-12);
    tau * mass / denom
}

pub fn top_k_concentration(scores: &[GovernanceScore], k: usize) -> f64 {
    let mut probabilities: Vec<f64> = scores.iter().map(|s| s.probability).collect();
    probabilities.sort_by(|a, b| b.partial_cmp(a).unwrap_or(std::cmp::Ordering::Equal));
    
    if probabilities.is_empty() {
        return 0.0;
    }
    
    let take_k = k.max(1).min(probabilities.len());
    probabilities.iter().take(take_k).sum()
}

pub fn classify_terminal_state(
    payload: &HCalcInput,
    profile: Option<&DomainProfile>,
) -> HCalcResult {
    let q = compute_contraction_witness(
        payload.contraction_tau,
        payload.contraction_mass,
        payload.lipschitz_bound,
        payload.prior_witness_q,
    );

    let r_max = profile.map(|p| p.r_max_runtime).unwrap_or(config::R_MAX_RUNTIME);
    let drift_max = profile.map(|p| p.drift_bound_max).unwrap_or(config::DRIFT_BOUND_MAX);
    let r_min = profile.map(|p| p.resonance_r_min).unwrap_or(config::RESONANCE_R_MIN);
    let r_safe = profile.map(|p| p.resonance_r_safe).unwrap_or(config::RESONANCE_R_SAFE);
    let conf_min = profile.map(|p| p.classifier_confidence_min).unwrap_or(config::CLASSIFIER_CONFIDENCE_MIN);
    let top_k = profile.map(|p| p.top_k_k).unwrap_or(3);
    let conc_threshold = profile.map(|p| p.top_k_concentration_threshold).unwrap_or(config::TOP_K_CONCENTRATION_THRESHOLD);
    let conv_epsilon = profile.map(|p| p.convergence_epsilon).unwrap_or(config::CONVERGENCE_EPSILON);

    let concentration = top_k_concentration(&payload.ranked_differential, top_k);

    // Gate 4: Velocity / Runtime Cap
    if payload.modality_count > r_max {
        return HCalcResult {
            state: TerminalState::DECOUPLED,
            contraction_witness_q: q,
            top_k_concentration: concentration,
            reason: "runtime_cap_exceeded".to_string(),
        };
    }

    // Gate 2: CRMF Contraction Witness
    let is_contractive = q < (1.0 - conv_epsilon);

    // Cytokine Storm Detection (Gate 1 PASS, Gate 2 FAIL)
    if payload.physio_bounds_ok && !is_contractive {
        return HCalcResult {
            state: TerminalState::FREEZE_CYTOKINE_STORM,
            contraction_witness_q: q,
            top_k_concentration: concentration,
            reason: "cytokine_storm_detected_gate_mismatch".to_string(),
        };
    }

    // Gate 1 & Stability bounds
    if !payload.physio_bounds_ok
        || payload.lipschitz_bound >= 1.0
        || payload.drift > drift_max
        || payload.resonance < r_min
        || payload.resonance > r_safe
    {
        return HCalcResult {
            state: TerminalState::FREEZE,
            contraction_witness_q: q,
            top_k_concentration: concentration,
            reason: "stability_violation".to_string(),
        };
    }

    // Gate 3: Epistemic / Self vs Non-self
    if !payload.epistemic_verified {
        return HCalcResult {
            state: TerminalState::INCONCLUSIVE,
            contraction_witness_q: q,
            top_k_concentration: concentration,
            reason: "epistemic_provenance_failed".to_string(),
        };
    }

    if payload.classifier_confidence < conf_min || payload.ranked_differential.is_empty() {
        return HCalcResult {
            state: TerminalState::INCONCLUSIVE,
            contraction_witness_q: q,
            top_k_concentration: concentration,
            reason: "insufficient_confidence".to_string(),
        };
    }

    // All 4 Gates Passed (physio_bounds_ok, is_contractive, epistemic_verified, r_max_ok)
    if concentration >= conc_threshold && is_contractive {
        return HCalcResult {
            state: TerminalState::CONVERGED,
            contraction_witness_q: q,
            top_k_concentration: concentration,
            reason: "convergence_verified".to_string(),
        };
    }

    HCalcResult {
        state: TerminalState::INCONCLUSIVE,
        contraction_witness_q: q,
        top_k_concentration: concentration,
        reason: "convergence_not_reached".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_contraction_witness() {
        let q = compute_contraction_witness(0.5, 1.0, 0.8, None);
        assert!((q - 0.625).abs() < 1e-10);
    }

    #[test]
    fn test_top_k_concentration() {
        let scores = vec![
            GovernanceScore { code: "A".to_string(), probability: 0.5 },
            GovernanceScore { code: "B".to_string(), probability: 0.3 },
            GovernanceScore { code: "C".to_string(), probability: 0.1 },
            GovernanceScore { code: "D".to_string(), probability: 0.05 },
        ];
        let conc = top_k_concentration(&scores, 2);
        assert!((conc - 0.8).abs() < 1e-10);
    }

    #[test]
    fn test_classify_terminal_state_converged() {
        let input = HCalcInput {
            modality_count: 5,
            contraction_tau: 0.1,
            contraction_mass: 1.0,
            lipschitz_bound: 0.5,
            drift: 0.1,
            resonance: 0.5,
            classifier_confidence: 0.95,
            ranked_differential: vec![
                GovernanceScore { code: "A".to_string(), probability: 0.7 },
            ],
            physio_bounds_ok: true,
            epistemic_verified: true,
            prior_witness_q: None,
        };
        let result = classify_terminal_state(&input, None);
        assert_eq!(result.state, TerminalState::CONVERGED);
        assert_eq!(result.reason, "convergence_verified");
    }

    #[test]
    fn test_brain_aging_step() {
        use crate::brain_aging::{BrainAgingState, BrainAgingInput, BrainAgingParams, step_state};
        let state = BrainAgingState { w: 0.8, s: 0.2, i: 0.2, c: 0.1, m: 0.5, a: 20.0 };
        let inputs = BrainAgingInput::default();
        let params = BrainAgingParams::default();
        let next_state = step_state(&state, &inputs, &params, 1.0);
        assert!(next_state.a > state.a);
    }
}
