use serde::{Deserialize, Serialize};
use thiserror::Error;
use std::fmt;

// --- Constants ---
pub const LAMBDA_M_THRESHOLD: f64 = 0.1;
pub const CONTRACTIVITY_UPPER: f64 = 1.0;
pub const CONTRACTIVITY_LOWER: f64 = 0.0;
pub const CIRCUIT_BREAKER_THRESHOLD: u32 = 3;

#[derive(Error, Debug, Serialize, Deserialize, schemars::JsonSchema)]
pub struct ConstitutionViolation {
    pub invariant: String,
    pub detail: String,
}

impl fmt::Display for ConstitutionViolation {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "[{}] {}", self.invariant, self.detail)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct CritiqueResult {
    pub critique_id: u32, // 0..9
    pub passed: bool,
    pub reason: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct PrimeGate {
    pub action_name: String,
    pub gate_value: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema)]
pub struct ConstitutionModel {
    pub state_norm: f64,
    pub drift_rate: f64,
    pub dynamic_lambda_m: Option<f64>,
    pub critique_results: Vec<CritiqueResult>,
    pub prime_gates: Vec<PrimeGate>,
    pub contractivity_score: f64,
    pub kill_switch_active: bool,
    pub rollback_anchor_sha: Option<String>,
    pub proof_anchor: Option<String>,
    pub audit_warnings: Vec<String>,
    pub active_anchors: Vec<String>,
    pub consecutive_failures: u32,
}

impl ConstitutionModel {
    pub fn validate(&self) -> Result<(), ConstitutionViolation> {
        self.l0_1_state_norm_bounded()?;
        self.l0_2_drift_rate_bounded()?;
        self.l0_3_critique_gates_passed()?;
        self.l0_4_prime_gates_satisfied()?;
        self.l0_5_lambda_m_compliant()?;
        self.l0_6_kill_switch_not_active()?;
        self.l0_7_circuit_breaker_not_tripped()?;
        self.l0_9_proof_anchor_recognized()?;
        Ok(())
    }

    fn l0_1_state_norm_bounded(&self) -> Result<(), ConstitutionViolation> {
        if !self.state_norm.is_finite() || self.state_norm <= 0.0 {
            return Err(ConstitutionViolation {
                invariant: "L0-1".to_string(),
                detail: format!("state_norm is not finite or non-positive: {}", self.state_norm),
            });
        }
        Ok(())
    }

    fn l0_2_drift_rate_bounded(&self) -> Result<(), ConstitutionViolation> {
        let threshold = self.dynamic_lambda_m.unwrap_or(LAMBDA_M_THRESHOLD);
        if self.drift_rate >= threshold {
            return Err(ConstitutionViolation {
                invariant: "L0-2".to_string(),
                detail: format!("drift_rate {} >= threshold {}", self.drift_rate, threshold),
            });
        }
        Ok(())
    }

    fn l0_3_critique_gates_passed(&self) -> Result<(), ConstitutionViolation> {
        if self.critique_results.len() != 10 {
            return Err(ConstitutionViolation {
                invariant: "L0-3".to_string(),
                detail: format!("Expected 10 critique results, found {}", self.critique_results.len()),
            });
        }
        let failed: Vec<_> = self.critique_results.iter().filter(|r| !r.passed).collect();
        if !failed.is_empty() {
            let ids: Vec<_> = failed.iter().map(|r| r.critique_id).collect();
            return Err(ConstitutionViolation {
                invariant: "L0-3".to_string(),
                detail: format!("Critique gates {:?} failed.", ids),
            });
        }
        Ok(())
    }

    fn l0_4_prime_gates_satisfied(&self) -> Result<(), ConstitutionViolation> {
        fn is_prime(n: u64) -> bool {
            if n < 2 { return false; }
            if n == 2 || n == 3 { return true; }
            if n % 2 == 0 || n % 3 == 0 { return false; }
            let mut i = 5;
            while i * i <= n {
                if n % i == 0 || n % (i + 2) == 0 { return false; }
                i += 6;
            }
            true
        }

        let violations: Vec<_> = self.prime_gates.iter()
            .filter(|g| !is_prime(g.gate_value))
            .map(|g| g.action_name.clone())
            .collect();

        if !violations.is_empty() {
            return Err(ConstitutionViolation {
                invariant: "L0-4".to_string(),
                detail: format!("Actions {:?} have non-prime gate values.", violations),
            });
        }
        Ok(())
    }

    fn l0_5_lambda_m_compliant(&self) -> Result<(), ConstitutionViolation> {
        if self.contractivity_score <= CONTRACTIVITY_LOWER {
            return Err(ConstitutionViolation {
                invariant: "L0-5".to_string(),
                detail: format!("contractivity_score {} <= 0", self.contractivity_score),
            });
        }
        if self.contractivity_score > CONTRACTIVITY_UPPER {
            return Err(ConstitutionViolation {
                invariant: "L0-5".to_string(),
                detail: format!("contractivity_score {} > {}", self.contractivity_score, CONTRACTIVITY_UPPER),
            });
        }
        Ok(())
    }

    fn l0_6_kill_switch_not_active(&self) -> Result<(), ConstitutionViolation> {
        if self.kill_switch_active {
            return Err(ConstitutionViolation {
                invariant: "L0-6".to_string(),
                detail: "Kill-switch is ACTIVE.".to_string(),
            });
        }
        Ok(())
    }

    fn l0_7_circuit_breaker_not_tripped(&self) -> Result<(), ConstitutionViolation> {
        if self.consecutive_failures >= CIRCUIT_BREAKER_THRESHOLD {
            return Err(ConstitutionViolation {
                invariant: "L0-7".to_string(),
                detail: format!("consecutive_failures={} >= threshold", self.consecutive_failures),
            });
        }
        Ok(())
    }

    fn l0_9_proof_anchor_recognized(&self) -> Result<(), ConstitutionViolation> {
        if let Some(ref anchor) = self.proof_anchor {
            if !self.active_anchors.is_empty() && !self.active_anchors.contains(anchor) {
                return Err(ConstitutionViolation {
                    invariant: "L0-9".to_string(),
                    detail: format!("proof_anchor {} is not recognized", anchor),
                });
            }
        }
        Ok(())
    }
}
