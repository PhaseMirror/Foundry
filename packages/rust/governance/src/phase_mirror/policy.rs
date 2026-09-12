use std::collections::HashMap;
use crate::phase_mirror::report::{DissonanceReport, DissonanceSignal};
use crate::phase_mirror::semantic_parom::{SemanticParom, lift_float_to_gfp};

pub const RHO_STAR: f64 = 0.7;
pub const KAPPA_MIN: f64 = 0.3;
pub const KILL_SWITCH_THRESHOLD: f64 = 1.0;

pub static STATE_WEIGHTS: [(&str, f64); 16] = [
    ("bad_precedent", 0.5),
    ("twin_desynced", 0.4),
    ("governance_version_mismatch", 0.2),
    ("stale_base_disabled", 0.3),
    ("boundary_absent", 0.3),
    ("rollback_trigger_active", 0.5),
    ("lambda_m_instability", 0.5),
    ("fractal_trace_absent", 0.8),
    ("high_harm_low_confidence", 0.8),
    ("structural_instability", 0.6),
    ("foundry_proof_failure", 1.0),
    ("foundry_commutator_divergence", 0.5),
    ("gate_1_lipschitz_violation", 0.5),
    ("gate_2_contraction_violation", 0.8),
    ("gate_3_witness_mismatch", 0.6),
    ("gate_4_velocity_excess", 0.4),
];

pub fn get_state_weight(id: &str) -> f64 {
    STATE_WEIGHTS.iter()
        .find(|(name, _)| *name == id)
        .map(|(_, w)| *w)
        .unwrap_or(0.0)
}

pub static EXPR_WEIGHTS: [(&str, f64); 6] = [
    ("semantic_drift", 0.3),
    ("contractivity_assertion_absent", 0.4),
    ("governance_version_mismatch", 0.2),
    ("unauthorized_prime_index", 0.3),
    ("verbatim_echo", 0.1),
    ("empty_expression", 1.0),
];

pub fn get_expr_weight(id: &str) -> f64 {
    EXPR_WEIGHTS.iter()
        .find(|(name, _)| *name == id)
        .map(|(_, w)| *w)
        .unwrap_or(0.0)
}

pub fn normalize_trigger(trigger: &str) -> String {
    let normalized = trigger.trim();
    if normalized.is_empty() || normalized.to_lowercase() == "none" {
        return "none".to_string();
    }
    let lowered = normalized.to_lowercase();
    if lowered.starts_with("emergency") {
        return "emergency_rollback".to_string();
    }
    if lowered == "l_phi_breach" {
        return "L_Phi_breach".to_string();
    }
    if lowered == "kill_switch" {
        return "kill_switch".to_string();
    }
    normalized.to_string()
}

pub fn evaluate(
    payload: crate::phase_mirror::types::PhaseMirrorPayload,
) -> DissonanceReport {
    match payload {
        crate::phase_mirror::types::PhaseMirrorPayload::Expression(p) => score_expression(p),
        crate::phase_mirror::types::PhaseMirrorPayload::StateTransition(p) => score_state_transition(p),
    }
}

pub fn evaluate_state_transition(
    input_text: &str,
    snapshot_json: &str,
    rollback_trigger: &str,
) -> DissonanceReport {
    let snapshot = match crate::phase_mirror::types::StateSnapshot::new(
        snapshot_json.as_bytes().to_vec(),
        "legacy-snapshot".to_string()
    ) {
        Ok(s) => s,
        Err(e) => {
             return DissonanceReport {
                execute: false,
                rho: 2.0,
                rho_star: RHO_STAR,
                kappa_min: KAPPA_MIN,
                rho_threshold: KILL_SWITCH_THRESHOLD,
                tensions: vec![DissonanceSignal {
                    signal_id: "snapshot_decode_error".to_string(),
                    severity: "high".to_string(),
                    summary: e,
                }],
                suppressed_tensions: vec![],
                metadata: HashMap::new(),
            };
        }
    };

    let payload = crate::phase_mirror::types::StateTransitionPayload::from_snapshot(
        input_text.to_string(),
        snapshot,
        rollback_trigger.to_string()
    );

    score_state_transition(payload)
}

fn score_expression(payload: crate::phase_mirror::types::ExpressionPayload) -> DissonanceReport {
    let mut tensions = Vec::new();
    let suppressed = Vec::new();
    let mut rho = 0.0;
    let resolved_trigger = normalize_trigger(&payload.rollback_trigger);

    let decoded_output = String::from_utf8_lossy(&payload.output_expr.data);
    let expression_body = decoded_output.split("MAGIC").last().unwrap_or("").trim_matches(|c: char| c == '\0' || c.is_whitespace());
    let input_clean = payload.input_text.trim();

    if input_clean.is_empty() || expression_body.is_empty() {
        tensions.push(DissonanceSignal {
            signal_id: "empty_expression".to_string(),
            severity: "auto_fail".to_string(),
            summary: "Expression payload is empty or input expression is blank.".to_string(),
        });
        rho += get_expr_weight("empty_expression");
        return DissonanceReport {
            execute: false,
            rho: rho.min(2.0),
            rho_star: RHO_STAR,
            kappa_min: KAPPA_MIN,
            rho_threshold: KILL_SWITCH_THRESHOLD,
            tensions,
            suppressed_tensions: suppressed,
            metadata: HashMap::new(),
        };
    }

    if input_clean == expression_body {
        tensions.push(DissonanceSignal {
            signal_id: "verbatim_echo".to_string(),
            severity: "medium".to_string(),
            summary: "Expression output matches input exactly.".to_string(),
        });
        rho += get_expr_weight("verbatim_echo");
    }

    // Simplified semantic drift check
    let input_tokens: std::collections::HashSet<_> = input_clean.split_whitespace().collect();
    let output_tokens: std::collections::HashSet<_> = expression_body.split_whitespace().collect();
    if !input_tokens.is_empty() && !output_tokens.is_empty() && input_tokens.is_disjoint(&output_tokens) {
        tensions.push(DissonanceSignal {
            signal_id: "semantic_drift".to_string(),
            severity: "high".to_string(),
            summary: "Expression output is semantically disconnected from input tokens.".to_string(),
        });
        rho += get_expr_weight("semantic_drift");
    }

    let contractivity_markers = ["contractive", "contractivity", "epsilon", "op_norm_t"];
    let body_lower = expression_body.to_lowercase();
    if !contractivity_markers.iter().any(|m| body_lower.contains(m)) {
        tensions.push(DissonanceSignal {
            signal_id: "contractivity_assertion_absent".to_string(),
            severity: "high".to_string(),
            summary: "Expression lacks explicit contractivity markers (epsilon/op_norm_T).".to_string(),
        });
        rho += get_expr_weight("contractivity_assertion_absent");
    }

    let execute = rho < KILL_SWITCH_THRESHOLD;

    let mut metadata = HashMap::new();
    metadata.insert("rollback_trigger".to_string(), serde_json::json!(resolved_trigger));
    metadata.insert("mode".to_string(), serde_json::json!("expression"));

    DissonanceReport {
        execute,
        rho: rho.min(2.0),
        rho_star: RHO_STAR,
        kappa_min: KAPPA_MIN,
        rho_threshold: KILL_SWITCH_THRESHOLD,
        tensions,
        suppressed_tensions: suppressed,
        metadata,
    }
}

fn score_state_transition(payload: crate::phase_mirror::types::StateTransitionPayload) -> DissonanceReport {
    let mut tensions = Vec::new();
    let suppressed = Vec::new();
    let mut rho = 0.0;
    let resolved_trigger = normalize_trigger(&payload.rollback_trigger);

    if payload.input_text.trim().is_empty() {
        tensions.push(DissonanceSignal {
            signal_id: "empty_transition_input".to_string(),
            severity: "high".to_string(),
            summary: "Input text is empty for state transition evaluation".to_string(),
        });
        rho += 0.3;
    }

    if !payload.enforcement_bits.legitimacy() {
        tensions.push(DissonanceSignal {
            signal_id: "LEGITIMACY_PREDICATE_FAILED".to_string(),
            severity: "auto_fail".to_string(),
            summary: "Enforcement bits legitimacy check failed".to_string(),
        });
        rho += 2.0;
    }

    if resolved_trigger != "none" {
        tensions.push(DissonanceSignal {
            signal_id: "rollback_trigger_active".to_string(),
            severity: "high".to_string(),
            summary: format!("Rollback trigger detected: {}. Emergency mode active.", resolved_trigger),
        });
        rho += get_state_weight("rollback_trigger_active");
    }

    let snapshot_state: HashMap<String, serde_json::Value> = serde_json::from_slice(&payload.snapshot.data).unwrap_or_default();
    
    if payload.enforcement_bits.p_bad || snapshot_state.get("is_bad_precedent").and_then(|v| v.as_bool()).unwrap_or(false) {
        tensions.push(DissonanceSignal {
            signal_id: "bad_precedent".to_string(),
            severity: "high".to_string(),
            summary: "State transition references a bad precedent in history.".to_string(),
        });
        rho += get_state_weight("bad_precedent");
    }

    if payload.twin_desynced {
        tensions.push(DissonanceSignal {
            signal_id: "twin_desynced".to_string(),
            severity: "medium".to_string(),
            summary: "Digital twin is not synchronized with live state.".to_string(),
        });
        rho += get_state_weight("twin_desynced");
    }

    // Semantic Parom evaluation
    let parom = SemanticParom::new(vec![2, 3, 5, 7, 11, 13]);
    
    // Gate 1: Lipschitz
    let h2_residue = lift_float_to_gfp(rho, 2);
    if h2_residue.value >= 2 {
        tensions.push(DissonanceSignal {
            signal_id: "gate_1_lipschitz_violation".to_string(),
            severity: "high".to_string(),
            summary: "Gate 1: H2 residue exceeds prime bound.".to_string(),
        });
        rho += get_state_weight("gate_1_lipschitz_violation");
    }

    // Gate 2: Contraction
    let (next_rho, omega) = parom.evolve(rho);
    if !(0.0..=1.0).contains(&next_rho) {
        tensions.push(DissonanceSignal {
            signal_id: "gate_2_contraction_violation".to_string(),
            severity: "high".to_string(),
            summary: "Gate 2: CRT reconstruction diverged from stability tube.".to_string(),
        });
        rho += get_state_weight("gate_2_contraction_violation");
    }

    // Gate 3: Witness
    if omega == 0 && rho > 0.01 {
        tensions.push(DissonanceSignal {
            signal_id: "gate_3_witness_mismatch".to_string(),
            severity: "high".to_string(),
            summary: "Gate 3: Prime factorization inconsistent with verified history.".to_string(),
        });
        rho += get_state_weight("gate_3_witness_mismatch");
    }

    // Gate 4: Velocity
    let velocity = (next_rho - rho).abs();
    if velocity > 0.000001 {
        tensions.push(DissonanceSignal {
            signal_id: "gate_4_velocity_excess".to_string(),
            severity: "medium".to_string(),
            summary: format!("Gate 4: Transition velocity ({:.4}) exceeds prime-gap bound.", velocity),
        });
        rho += get_state_weight("gate_4_velocity_excess");
    }

    if payload.stale_base_disabled {
        tensions.push(DissonanceSignal {
            signal_id: "stale_base_disabled".to_string(),
            severity: "medium".to_string(),
            summary: "Strict stale-base enforcement is disabled.".to_string(),
        });
        rho += get_state_weight("stale_base_disabled");
    }

    if payload.boundary_absent {
        tensions.push(DissonanceSignal {
            signal_id: "boundary_absent".to_string(),
            severity: "medium".to_string(),
            summary: "Canonical boundary is absent for this transition.".to_string(),
        });
        rho += get_state_weight("boundary_absent");
    }

    let execute = rho < KILL_SWITCH_THRESHOLD && !tensions.iter().any(|t| t.severity == "auto_fail");
    
    let mut metadata = HashMap::new();
    metadata.insert("rollback_trigger".to_string(), serde_json::json!(resolved_trigger));
    metadata.insert("mode".to_string(), serde_json::json!("state_transition"));

    DissonanceReport {
        execute,
        rho: rho.min(2.0),
        rho_star: RHO_STAR,
        kappa_min: KAPPA_MIN,
        rho_threshold: KILL_SWITCH_THRESHOLD,
        tensions,
        suppressed_tensions: suppressed,
        metadata,
    }
}
