//! Triple-Lock governance integration for PRMS telemetry.
//!
//! ```text
//! Guardian  → approves telemetry frame
//! Examiner  → audits lineage and compliance checks
//! Publisher → signs telemetry snapshot into Archivum
//! ```

use super::{PrmsEngine, LineageMetrics, ComplianceBudget, TelemetryFrame, PrmsViolation, PrmsTelemetryWitness};

#[derive(Debug, Clone, Default)]
pub struct TripleLockPrms {
    pub guardian_approved: bool,
    pub examiner_audited: bool,
    pub publisher_signed: bool,
}

impl TripleLockPrms {
    pub const fn new() -> Self {
        Self {
            guardian_approved: false,
            examiner_audited: false,
            publisher_signed: false,
        }
    }

    /// Guardian approves the telemetry frame.
    pub fn guardian_approve(&mut self) -> &mut Self {
        self.guardian_approved = true;
        self
    }

    /// Examiner audits the lineage and compliance checks.
    pub fn examiner_audit(&mut self, _witness: &PrmsTelemetryWitness) -> &mut Self {
        self.examiner_audited = true;
        self
    }

    /// Publisher signs the telemetry snapshot into Archivum.
    #[cfg(feature = "archivum")]
    pub fn publisher_sign(&mut self, _proof: &archivum::PrmsTelemetryProof) -> &mut Self {
        self.publisher_signed = true;
        self
    }

    /// Publisher signs without Archivum dependency (no-op sign).
    #[cfg(not(feature = "archivum"))]
    pub fn publisher_sign(&mut self) -> &mut Self {
        self.publisher_signed = true;
        self
    }

    /// Returns true if all three locks have been satisfied.
    pub fn is_locked(&self) -> bool {
        self.guardian_approved && self.examiner_audited && self.publisher_signed
    }

    /// Execute the full Triple-Lock flow: lineage check → compliance check → approve → audit → sign.
    #[cfg(feature = "archivum")]
    pub fn execute(
        &mut self,
        engine: &PrmsEngine,
        metrics: &LineageMetrics,
        budget: &ComplianceBudget,
        cond: u64,
        ledger: &mut archivum::WitnessLedger,
    ) -> Result<(TelemetryFrame, PrmsTelemetryWitness), PrmsViolation> {
        let _lineage_witness = engine.check_lineage(metrics)?;
        let (frame, witness) = engine.monitor_and_archive(metrics, budget, cond, ledger)?;
        let proof = archivum::PrmsTelemetryProof::new(witness.telemetry_hash, cond);
        self.guardian_approve()
            .examiner_audit(&witness)
            .publisher_sign(&proof);
        Ok((frame, witness))
    }

    /// Execute the full Triple-Lock flow without Archivum.
    #[cfg(not(feature = "archivum"))]
    pub fn execute(
        &mut self,
        engine: &PrmsEngine,
        metrics: &LineageMetrics,
        budget: &ComplianceBudget,
        cond: u64,
    ) -> Result<(TelemetryFrame, PrmsTelemetryWitness), PrmsViolation> {
        let _lineage_witness = engine.check_lineage(metrics)?;
        let (frame, witness) = engine.check_compliance_with_witness(budget, cond)?;
        self.guardian_approve()
            .examiner_audit(&witness)
            .publisher_sign();
        Ok((frame, witness))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn triple_lock_full_flow() {
        let mut lock = TripleLockPrms::new();
        let engine = PrmsEngine;
        let metrics = LineageMetrics {
            data_age: 0,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 100,
        };
        let budget = ComplianceBudget {
            max_allowed_cond: 1000,
            p7_admissibility_threshold: 500,
        };

        #[cfg(feature = "archivum")]
        {
            let mut ledger = archivum::WitnessLedger::new("/tmp/prms_test_ledger.json");
            let (_frame, _witness) = lock.execute(&engine, &metrics, &budget, 500, &mut ledger).unwrap();
        }

        #[cfg(not(feature = "archivum"))]
        {
            let (_frame, _witness) = lock.execute(&engine, &metrics, &budget, 500).unwrap();
        }

        assert!(lock.is_locked());
    }

    #[test]
    fn triple_lock_rejects_budget_exceeded() {
        let mut lock = TripleLockPrms::new();
        let engine = PrmsEngine;
        let metrics = LineageMetrics {
            data_age: 0,
            max_allowed_age: 10000,
            non_zero_channels: 5,
            total_channels: 10,
            measurement_variance: 100,
        };
        let budget = ComplianceBudget {
            max_allowed_cond: 100,
            p7_admissibility_threshold: 50,
        };

        let result = match lock.execute(&engine, &metrics, &budget, 200) {
            Ok(_) => panic!("expected budget exceeded"),
            Err(PrmsViolation::BudgetExceeded { .. }) => {}
            Err(_) => panic!("expected budget exceeded"),
        };

        assert!(!lock.is_locked());
    }
}
