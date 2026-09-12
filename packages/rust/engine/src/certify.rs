use crate::types::{Certificate, StepInfo};
use serde::{Deserialize, Serialize};
use serde_json::json;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum CertLevel {
    L0Heuristic,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AceCertificate {
    pub level: CertLevel,
    pub certified: bool,
    pub lipschitz_upper: f64,
    pub gap_lb: f64,
    pub contraction_rate: f64,
    pub budget_used: f64,
    pub tau: f64,
    pub delta: f64,
    pub margin: f64,
    pub tail_bound: f64,
    pub details: serde_json::Value,
}

pub fn certify_l0(
    records: &[StepInfo],
    tau: f64,
    tail_norm: f64,
    delta: f64,
) -> AceCertificate {
    if records.is_empty() {
        panic!("L0: no telemetry provided");
    }

    let min_epsilon = records.iter().map(|r| r.epsilon).fold(f64::INFINITY, f64::min);
    let target = 1.0 - min_epsilon;
    let max_q = records.iter().map(|r| r.q).fold(f64::NEG_INFINITY, f64::max);
    let margin = target - max_q;
    let certified = margin >= delta;
    let tail_bound = if max_q >= 1.0 {
        f64::INFINITY
    } else {
        tail_norm / (1.0 - max_q).max(1e-12)
    };

    AceCertificate {
        level: CertLevel::L0Heuristic,
        certified,
        lipschitz_upper: max_q,
        gap_lb: (1.0 - max_q).max(0.0),
        contraction_rate: max_q,
        budget_used: max_q,
        tau,
        delta,
        margin,
        tail_bound,
        details: json!({
            "max_q": max_q,
            "target": target,
            "steps": records.len(),
        }),
    }
}

pub fn ace_certificate(
    records: &[StepInfo],
    tail_norm: f64,
) -> AceCertificate {
    certify_l0(records, 1.0, tail_norm, 0.0)
}

pub fn to_legacy_certificate(ace: &AceCertificate) -> Certificate {
    Certificate {
        certified: ace.certified,
        margin: ace.margin,
        tail_bound: ace.tail_bound,
        details: ace.details.clone(),
    }
}

pub fn iss_bound(records: &[StepInfo], disturbance_norm: f64) -> f64 {
    if records.is_empty() {
        panic!("no telemetry provided");
    }
    let max_q = records.iter().map(|r| r.q).fold(f64::NEG_INFINITY, f64::max);
    if max_q >= 1.0 {
        f64::INFINITY
    } else {
        disturbance_norm / (1.0 - max_q)
    }
}
