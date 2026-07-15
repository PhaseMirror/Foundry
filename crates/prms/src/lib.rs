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

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LineageMetrics {
    pub data_age: u64,
    pub max_allowed_age: u64,
    pub non_zero_channels: u64,
    pub total_channels: u64,
    pub measurement_variance: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ComplianceBudget {
    pub max_allowed_cond: u64,
    pub p7_admissibility_threshold: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TelemetryFrame {
    pub t: u64,
    pub cond_number: u64,
    pub provenance_valid: bool,
}

#[derive(Debug, thiserror::Error)]
pub enum PrmsViolation {
    #[error("condition number {actual} exceeds budget {budget}")]
    BudgetExceeded { actual: u64, budget: u64 },
}

pub struct PrmsEngine;

impl PrmsEngine {
    pub fn check_compliance(
        &self,
        budget: &ComplianceBudget,
        cond: u64,
    ) -> Result<TelemetryFrame, PrmsViolation> {
        if cond > budget.max_allowed_cond {
            return Err(PrmsViolation::BudgetExceeded { actual: cond, budget: budget.max_allowed_cond });
        }
        Ok(TelemetryFrame { t: 0, cond_number: cond, provenance_valid: true })
    }
}

#[cfg(kani)]
mod prms_verification {
    use super::*;

    #[kani::proof]
    fn proof_budget_respected() {
        let engine = PrmsEngine;
        let cond: u64 = kani::any();
        let max_allowed_cond: u64 = kani::any();
        
        let budget = ComplianceBudget {
            max_allowed_cond,
            p7_admissibility_threshold: 0,
        };
        
        let res = engine.check_compliance(&budget, cond);
        if cond > max_allowed_cond {
            kani::assert(res.is_err(), "Exceeded budget rejected");
        } else {
            kani::assert(res.is_ok(), "Valid budget accepted");
        }
    }
}
