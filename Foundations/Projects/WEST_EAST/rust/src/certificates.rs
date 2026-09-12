//! Spectral Gap and Slope Certificate Ledger Engine

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct CertificateRecord {
    pub prime_mask: Vec<u64>,
    pub symbol_count: usize,
    pub j_gap_lb: f64,
    pub j_slope_ub: f64,
    pub max_slope_budget: f64,
    pub seasonal_drift: f64,
    pub projector_angle_bound: f64,
    pub is_valid: bool,
    pub record_digest: String,
}

pub struct CertificateEngine;

impl CertificateEngine {
    /// Compute slope upper bound: J_slope(w) = ∑_{p ∈ M} ∑_{k≥1} |w_{p,k}| * k * log p.
    pub fn compute_j_slope(weights: &[(u64, u32, f64)]) -> f64 {
        let mut slope = 0.0;
        for &(p, k, w) in weights {
            let log_p = (p as f64).ln();
            slope += w.abs() * (k as f64) * log_p;
        }
        slope
    }

    /// Construct verifiable certificate record.
    pub fn create_certificate(
        prime_mask: Vec<u64>,
        symbol_count: usize,
        j_gap_lb: f64,
        j_slope_ub: f64,
        max_slope_budget: f64,
        seasonal_drift: f64,
        projector_angle_bound: f64,
    ) -> CertificateRecord {
        let is_valid = j_gap_lb > 0.0 && j_slope_ub <= max_slope_budget && seasonal_drift <= 0.05;

        let mut hasher = Sha256::new();
        for &p in &prime_mask {
            hasher.update(&p.to_le_bytes());
        }
        hasher.update(&j_gap_lb.to_le_bytes());
        hasher.update(&j_slope_ub.to_le_bytes());
        hasher.update(&seasonal_drift.to_le_bytes());
        let record_digest = hex::encode(hasher.finalize());

        CertificateRecord {
            prime_mask,
            symbol_count,
            j_gap_lb,
            j_slope_ub,
            max_slope_budget,
            seasonal_drift,
            projector_angle_bound,
            is_valid,
            record_digest,
        }
    }
}
