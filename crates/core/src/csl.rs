use crate::types::StepInfo;
use nalgebra::DVector;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SilenceEvent {
    pub step: usize,
    pub reason: String,
    pub operator_failed: Vec<String>,
    pub detail: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CSLVerdict {
    pub neutrality: bool,
    pub beneficence: bool,
    pub silence_triggered: bool,
    pub commutes: bool,
    pub violations: Vec<String>,
    pub detail: serde_json::Value,
}

pub fn neutrality_check(
    t_op: fn(&DVector<f64>) -> DVector<f64>,
    subjects: &[DVector<f64>],
    epsilon_n: f64,
) -> (bool, serde_json::Value) {
    if subjects.len() < 2 {
        return (
            true,
            serde_json::json!({"pairs_checked": 0, "max_deviation": 0.0, "violations": []}),
        );
    }

    let outputs: Vec<DVector<f64>> = subjects.iter().map(t_op).collect();
    let mut max_dev: f64 = 0.0;
    let mut violations = Vec::new();

    for i in 0..outputs.len() {
        for j in i + 1..outputs.len() {
            let deviation = (&outputs[i] - &outputs[j]).norm();
            max_dev = max_dev.max(deviation);
            if deviation >= epsilon_n {
                violations.push((i, j, deviation));
            }
        }
    }

    (
        violations.is_empty(),
        serde_json::json!({
            "pairs_checked": outputs.len() * (outputs.len() - 1) / 2,
            "max_deviation": max_dev,
            "violations": violations,
        }),
    )
}

pub fn beneficence_check(
    x_t: &DVector<f64>,
    x_next: &DVector<f64>,
    info: &StepInfo,
    norm_growth_limit: f64,
    residual_limit: f64,
) -> (bool, serde_json::Value) {
    let mut violations = Vec::new();
    let norm_t = x_t.norm();
    let norm_next = x_next.norm();
    let growth = if norm_t > 0.0 {
        norm_next / norm_t
    } else {
        norm_next
    };

    if growth > norm_growth_limit {
        violations.push(format!("norm_growth={:.4}>{norm_growth_limit}", growth));
    }
    if info.residual > residual_limit {
        violations.push(format!("residual={:.4}>{residual_limit}", info.residual));
    }

    (
        violations.is_empty(),
        serde_json::json!({
            "norm_growth": growth,
            "residual": info.residual,
            "violations": violations,
        }),
    )
}

pub fn silence_clause(
    neutrality_ok: bool,
    beneficence_ok: bool,
    step_index: usize,
    detail: serde_json::Value,
) -> (bool, Option<SilenceEvent>) {
    if neutrality_ok && beneficence_ok {
        return (false, None);
    }

    let mut failed = Vec::new();
    if !neutrality_ok {
        failed.push("neutrality".to_string());
    }
    if !beneficence_ok {
        failed.push("beneficence".to_string());
    }

    let event = SilenceEvent {
        step: step_index,
        reason: format!("CSL operator(s) failed: {}", failed.join(", ")),
        operator_failed: failed,
        detail,
    };
    (true, Some(event))
}

pub fn commutation_check(
    t_op: fn(&DVector<f64>) -> DVector<f64>,
    csl_filter: fn(&DVector<f64>) -> DVector<f64>,
    x: &DVector<f64>,
    epsilon_c: f64,
) -> (bool, serde_json::Value) {
    let path1 = csl_filter(&t_op(x));
    let path2 = t_op(&csl_filter(x));
    let deviation = (path1 - path2).norm();
    let commutes = deviation < epsilon_c;
    (
        commutes,
        serde_json::json!({
            "deviation": deviation,
            "epsilon_c": epsilon_c,
            "commutes": commutes,
        }),
    )
}

pub fn evaluate_csl(
    t_op: fn(&DVector<f64>) -> DVector<f64>,
    x_t: &DVector<f64>,
    x_next: &DVector<f64>,
    info: &StepInfo,
    step_index: usize,
    subjects: Option<&[DVector<f64>]>,
    csl_filter: Option<fn(&DVector<f64>) -> DVector<f64>>,
    epsilon_n: f64,
    epsilon_c: f64,
    norm_growth_limit: f64,
    residual_limit: f64,
) -> CSLVerdict {
    let (neutrality_ok, neutrality_detail) = if let Some(subs) = subjects {
        neutrality_check(t_op, subs, epsilon_n)
    } else {
        (true, serde_json::json!({"skipped": true}))
    };

    let (beneficence_ok, beneficence_detail) =
        beneficence_check(x_t, x_next, info, norm_growth_limit, residual_limit);

    let (silence_triggered, silence_event) = silence_clause(
        neutrality_ok,
        beneficence_ok,
        step_index,
        serde_json::json!({"neutrality": neutrality_detail, "beneficence": beneficence_detail}),
    );

    let (commutes, commutation_detail) = if let Some(filter) = csl_filter {
        commutation_check(t_op, filter, x_t, epsilon_c)
    } else {
        (true, serde_json::json!({"skipped": true}))
    };

    let mut violations = Vec::new();
    if !neutrality_ok {
        violations.push("neutrality".to_string());
    }
    if !beneficence_ok {
        violations.push("beneficence".to_string());
    }
    if silence_triggered {
        violations.push("silence_triggered".to_string());
    }
    if !commutes {
        violations.push("commutation".to_string());
    }

    CSLVerdict {
        neutrality: neutrality_ok,
        beneficence: beneficence_ok,
        silence_triggered,
        commutes,
        violations,
        detail: serde_json::json!({
            "neutrality": neutrality_detail,
            "beneficence": beneficence_detail,
            "commutation": commutation_detail,
            "silence_event": silence_event,
        }),
    }
}
