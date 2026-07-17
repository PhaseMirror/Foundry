pub mod petc;
pub mod contractor;
pub mod dae;
pub mod zeta_ros;
pub mod pipeline;
pub mod lawfulness;

pub use petc::*;
pub use contractor::*;
pub use dae::*;
pub use zeta_ros::*;
pub use lawfulness::*;

#[cfg(feature = "triple-lock")]
pub mod triple_lock;

#[cfg(test)]
mod tests;

#[cfg(kani)]
mod prms_verification;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[cfg(feature = "archivum")]
use archivum::{WitnessLedger, PrmsTelemetryProof};

/// Canonical scale factor: 10000 represents 1.0 in fixed-point arithmetic.
pub const SCALE: u64 = 10000;

/// Lineage metrics for state-transition tracking.
///
/// All fields use the canonical `scale = 10000` fixed-point convention
/// where 10000 represents 1.0.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LineageMetrics {
    pub data_age: u64,
    pub max_allowed_age: u64,
    pub non_zero_channels: u64,
    pub total_channels: u64,
    pub measurement_variance: u64,
}

impl LineageMetrics {
    /// Validate lineage metrics.
    ///
    /// Returns `Ok(())` if:
    /// - `non_zero_channels <= total_channels`
    /// - `total_channels <= scale` (10000)
    /// - `data_age <= max_allowed_age`
    pub fn validate(&self) -> Result<(), PrmsViolation> {
        if self.non_zero_channels > self.total_channels {
            return Err(PrmsViolation::LineageViolation {
                reason: format!(
                    "nonZeroChannels {} > totalChannels {}",
                    self.non_zero_channels, self.total_channels
                ),
            });
        }
        if self.total_channels > 10000 {
            return Err(PrmsViolation::LineageViolation {
                reason: format!(
                    "totalChannels {} exceeds scale 10000",
                    self.total_channels
                ),
            });
        }
        if self.data_age > self.max_allowed_age {
            return Err(PrmsViolation::LineageViolation {
                reason: format!(
                    "dataAge {} exceeds maxAllowedAge {}",
                    self.data_age, self.max_allowed_age
                ),
            });
        }
        Ok(())
    }

    /// Compute a deterministic hash of this lineage record.
    pub fn hash(&self) -> u64 {
        let mut hasher = Sha256::new();
        hasher.update(self.data_age.to_le_bytes());
        hasher.update(self.max_allowed_age.to_le_bytes());
        hasher.update(self.non_zero_channels.to_le_bytes());
        hasher.update(self.total_channels.to_le_bytes());
        hasher.update(self.measurement_variance.to_le_bytes());
        let hash = hasher.finalize();
        u64::from_le_bytes(hash[..8].try_into().unwrap())
    }
}

/// Compliance budget for condition-number enforcement.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplianceBudget {
    pub max_allowed_cond: u64,
    pub p7_admissibility_threshold: u64,
}

impl ComplianceBudget {
    /// Validate compliance budget.
    ///
    /// Returns `Ok(())` if both thresholds are positive and within scale.
    pub fn validate(&self) -> Result<(), PrmsViolation> {
        if self.max_allowed_cond == 0 {
            return Err(PrmsViolation::BudgetViolation {
                reason: "maxAllowedCond must be positive".to_string(),
            });
        }
        if self.max_allowed_cond > 10000 {
            return Err(PrmsViolation::BudgetViolation {
                reason: format!(
                    "maxAllowedCond {} exceeds scale 10000",
                    self.max_allowed_cond
                ),
            });
        }
        if self.p7_admissibility_threshold == 0 {
            return Err(PrmsViolation::BudgetViolation {
                reason: "p7AdmissibilityThreshold must be positive".to_string(),
            });
        }
        if self.p7_admissibility_threshold > 10000 {
            return Err(PrmsViolation::BudgetViolation {
                reason: format!(
                    "p7AdmissibilityThreshold {} exceeds scale 10000",
                    self.p7_admissibility_threshold
                ),
            });
        }
        Ok(())
    }

    /// Compute a deterministic hash of this budget record.
    pub fn hash(&self) -> u64 {
        let mut hasher = Sha256::new();
        hasher.update(self.max_allowed_cond.to_le_bytes());
        hasher.update(self.p7_admissibility_threshold.to_le_bytes());
        let hash = hasher.finalize();
        u64::from_le_bytes(hash[..8].try_into().unwrap())
    }
}

/// Telemetry frame capturing a single monitoring instant.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryFrame {
    pub t: u64,
    pub cond_number: u64,
    pub provenance_valid: bool,
}

impl TelemetryFrame {
    /// Create a new telemetry frame.
    pub fn new(t: u64, cond_number: u64, provenance_valid: bool) -> Self {
        Self {
            t,
            cond_number,
            provenance_valid,
        }
    }

    /// Validate frame against a compliance budget.
    pub fn validate(&self, budget: &ComplianceBudget) -> Result<(), PrmsViolation> {
        if !self.provenance_valid {
            return Err(PrmsViolation::FrameViolation {
                reason: "provenanceValid is false".to_string(),
            });
        }
        if self.cond_number > budget.max_allowed_cond {
            return Err(PrmsViolation::BudgetExceeded {
                actual: self.cond_number,
                budget: budget.max_allowed_cond,
            });
        }
        Ok(())
    }
}

/// Witness emitted after a successful lineage check.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LineageWitness {
    pub lineage_hash: u64,
    pub data_age: u64,
    pub non_zero_channels: u64,
    pub total_channels: u64,
}

/// Witness emitted after a successful compliance check.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplianceWitness {
    pub budget_hash: u64,
    pub cond_number: u64,
    pub max_allowed_cond: u64,
}

/// Witness emitted for every telemetry frame, suitable for Archivum.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrmsTelemetryWitness {
    pub telemetry_hash: [u8; 32],
    pub cond_number: u64,
    pub timestamp: i64,
}

impl PrmsTelemetryWitness {
    /// Create a new `PrmsTelemetryWitness` from a telemetry frame.
    pub fn new(frame: &TelemetryFrame) -> Self {
        let mut hasher = Sha256::new();
        hasher.update(frame.t.to_le_bytes());
        hasher.update(frame.cond_number.to_le_bytes());
        hasher.update([if frame.provenance_valid { 1 } else { 0 }]);
        let telemetry_hash = hasher.finalize().into();
        let timestamp = chrono::Utc::now().timestamp();
        Self {
            telemetry_hash,
            cond_number: frame.cond_number,
            timestamp,
        }
    }
}

/// Errors produced by the PRMS monitoring engine.
#[derive(Debug, thiserror::Error)]
pub enum PrmsViolation {
    #[error("condition number {actual} exceeds budget {budget}")]
    BudgetExceeded { actual: u64, budget: u64 },
    #[error("lineage violation: {reason}")]
    LineageViolation { reason: String },
    #[error("budget violation: {reason}")]
    BudgetViolation { reason: String },
    #[error("frame violation: {reason}")]
    FrameViolation { reason: String },
}

// ---------------------------------------------------------------------------
// PRMS Engine
// ---------------------------------------------------------------------------

/// The PRMS monitoring engine.
///
/// This is the **sole semantic authority** for lineage and telemetry
/// computations in the Multiplicity Sovereign Core.
#[derive(Debug, Default, Clone, Copy)]
pub struct PrmsEngine;

impl PrmsEngine {
    /// Check lineage metrics for validity.
    ///
    /// Returns `Ok(LineageWitness)` if all lineage bounds are respected,
    /// or `Err(PrmsViolation)` if any bound is violated.
    pub fn check_lineage(&self, metrics: &LineageMetrics) -> Result<LineageWitness, PrmsViolation> {
        metrics.validate()?;
        Ok(LineageWitness {
            lineage_hash: metrics.hash(),
            data_age: metrics.data_age,
            non_zero_channels: metrics.non_zero_channels,
            total_channels: metrics.total_channels,
        })
    }

    /// Check compliance budget against a condition number.
    ///
    /// Returns `Ok(TelemetryFrame)` if `cond <= max_allowed_cond`,
    /// or `Err(PrmsViolation::BudgetExceeded)` otherwise.
    pub fn check_compliance(
        &self,
        budget: &ComplianceBudget,
        cond: u64,
    ) -> Result<TelemetryFrame, PrmsViolation> {
        budget.validate()?;
        if cond > budget.max_allowed_cond {
            return Err(PrmsViolation::BudgetExceeded {
                actual: cond,
                budget: budget.max_allowed_cond,
            });
        }
        Ok(TelemetryFrame::new(0, cond, true))
    }

    /// Check compliance and emit a `PrmsTelemetryWitness`.
    ///
    /// This is the preferred entry point for production telemetry because it
    /// produces the audit-ready witness in a single call.
    pub fn check_compliance_with_witness(
        &self,
        budget: &ComplianceBudget,
        cond: u64,
    ) -> Result<(TelemetryFrame, PrmsTelemetryWitness), PrmsViolation> {
        let frame = self.check_compliance(budget, cond)?;
        let witness = PrmsTelemetryWitness::new(&frame);
        Ok((frame, witness))
    }

    /// Check lineage, check compliance, and emit a combined witness.
    ///
    /// Requires the `archivum` feature to be enabled for archival.
    #[cfg(feature = "archivum")]
    pub fn monitor_and_archive(
        &self,
        metrics: &LineageMetrics,
        budget: &ComplianceBudget,
        cond: u64,
        ledger: &mut WitnessLedger,
    ) -> Result<(TelemetryFrame, PrmsTelemetryWitness), PrmsViolation> {
        let _lineage_witness = self.check_lineage(metrics)?;
        let (frame, telemetry_witness) = self.check_compliance_with_witness(budget, cond)?;
        let proof = PrmsTelemetryProof::new(telemetry_witness.telemetry_hash, cond);
        ledger
            .stamp_prms_telemetry_proof(&proof)
            .map_err(|_| PrmsViolation::FrameViolation {
                reason: "failed to write to Archivum".to_string(),
            })?;
        Ok((frame, telemetry_witness))
    }
}

// ---------------------------------------------------------------------------
// Triple-Lock re-export
// ---------------------------------------------------------------------------

#[cfg(feature = "triple-lock")]
pub use triple_lock::TripleLockPrms;

// ---------------------------------------------------------------------------
// Archivum extension (feature-gated)
// ---------------------------------------------------------------------------

// Note: We cannot implement inherent methods on `WitnessLedger` here due to
// Rust orphan rules. Consumers should call `ledger.stamp_prms_telemetry_proof`
// directly from the `archivum` crate.
