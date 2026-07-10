// prms/src/zeta_ros.rs  
use crate::dae::TelemetryFrame;

#[derive(Debug, Clone)]
pub struct LineageMetrics {
    pub data_age_seconds: f64,
    pub maximum_allowed_age: f64,
    pub non_zero_channels: usize,
    pub total_channels: usize,
    pub measurement_variance: f64,
}

#[derive(Debug, Clone, Copy)]
pub struct ComplianceBudget {
    pub max_allowed_cond: f64,
    pub p7_admissibility_threshold: f64,
}

pub struct AuditEngine;

impl AuditEngine {
    pub fn calculate_lineage_score(metrics: &LineageMetrics) -> (f64, f64, f64, f64) {
        let s_f = (-metrics.data_age_seconds / metrics.maximum_allowed_age).exp().min(1.0).max(0.0);
        let s_c = if metrics.total_channels == 0 { 0.0 } else {
            (metrics.non_zero_channels as f64 / metrics.total_channels as f64).min(1.0).max(0.0)
        };
        let s_a = 1.0 / (1.0 + metrics.measurement_variance);
        let composite = (s_f * s_c * s_a).powf(1.0 / 3.0);
        (s_f, s_c, s_a, composite)
    }

    pub fn verify_step_lawfulness(
        frame: &TelemetryFrame,
        lineage: &LineageMetrics,
        budget: &ComplianceBudget,
        provenance_valid: bool,
    ) -> Result<f64, &'static str> {
        if !provenance_valid {
            return Err("FAIL-CLOSED: Cryptographic token mismatch on Path B audit.");
        }
        let (_, _, _, score) = Self::calculate_lineage_score(lineage);
        if score < budget.p7_admissibility_threshold {
            return Err("FAIL-CLOSED: Lineage score falls below p=7 admissibility envelope.");
        }
        if frame.cond_number > budget.max_allowed_cond {
            return Err("FAIL-CLOSED: Numerical conditioning exceeds metric tolerance limits.");
        }
        Ok(score)
    }
}
