//! Cryptographic Safety Receipts and Complexity Ceilings (ADR-0038 §8.1 & §8.2)

use serde::{Deserialize, Serialize};

/// Safety Receipt record certifying compliance across BURST, CAPTURE, and GROUND.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ReceiptRecord {
    pub burst_id: u64,
    pub snapshot_id: u64,
    pub t_pred_used: f64,
    pub lambda_hat_final: f64,
    pub v_score_final: f64,
    pub c3_pass: bool,
    pub post_use_pass: bool,
    pub state_hash: String,
    pub c_ext_signature: String,
    pub issue_time: u64,
    pub expiry_time: u64,
}

impl ReceiptRecord {
    /// Validates receipt integrity: pass flags set, signature non-empty, unexpired.
    pub fn is_valid(&self, current_time: u64) -> bool {
        self.c3_pass
            && self.post_use_pass
            && !self.c_ext_signature.is_empty()
            && self.c_ext_signature != "PENDING"
            && current_time <= self.expiry_time
    }
}

/// Complexity Ceiling record defining maximum allowed operational thresholds.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CeilingRecord {
    pub max_coordinates: usize,
    pub max_lambda_hat: f64,
    pub max_theta_norm: f64,
    pub max_v_change_per_burst: f64,
    pub max_bursts_unreviewed: u64,
}

impl CeilingRecord {
    /// Evaluates if current system metrics sit strictly within declared ceiling bounds.
    pub fn is_within_ceiling(
        &self,
        coordinates: usize,
        lambda_hat: f64,
        theta_norm: f64,
        v_change: f64,
        bursts_count: u64,
    ) -> bool {
        coordinates <= self.max_coordinates
            && lambda_hat <= self.max_lambda_hat
            && theta_norm <= self.max_theta_norm
            && v_change <= self.max_v_change_per_burst
            && bursts_count <= self.max_bursts_unreviewed
    }
}
