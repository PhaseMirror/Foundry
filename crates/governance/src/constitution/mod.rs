use serde::{Deserialize, Serialize};
use crate::proof_anchor::validate_pi_native;
use thiserror::Error;
use num_prime::nt_funcs::is_prime;

pub const LAMBDA_M_THRESHOLD: f64 = 0.1;
pub const CONTRACTIVITY_UPPER: f64 = 1.0;
pub const CONTRACTIVITY_LOWER: f64 = 0.0;
pub const CIRCUIT_BREAKER_THRESHOLD: u32 = 3;
pub const GOV_SAT_THRESHOLD: f64 = 50.0;
pub const CRITICAL_SATURATION_LIMIT: f64 = 100.0;

#[derive(Error, Debug)]
pub enum ConstitutionError {
    #[error("[{invariant}] {detail}")]
    Violation { invariant: String, detail: String },
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CritiqueResult {
    pub critique_id: u32,
    pub passed: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reason: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PrimeGate {
    pub action_name: String,
    pub gate_value: u64,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ConstitutionModel {
    pub state_norm: f64,
    pub drift_rate: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub dynamic_lambda_m: Option<f64>,
    pub critique_results: Vec<CritiqueResult>,
    pub prime_gates: Vec<PrimeGate>,
    pub contractivity_score: f64,
    pub kill_switch_active: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub rollback_anchor_sha: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub proof_anchor: Option<String>,
    pub audit_warnings: Vec<String>,
    pub active_anchors: Vec<String>,
    pub consecutive_failures: u32,
}

impl ConstitutionModel {
    pub fn validate(&mut self) -> Result<(), ConstitutionError> {
        self.l0_1_state_norm_bounded()?;
        self.l0_2_drift_rate_bounded()?;
        self.l0_9_proof_anchor_recognized()?;
        self.l0_3_critique_gates_passed()?;
        self.l0_4_prime_gates_satisfied()?;
        self.l0_5_lambda_m_compliant()?;
        self.l0_6_kill_switch_not_active()?;
        self.l0_7_circuit_breaker_not_tripped()?;
        self.l0_8_proof_anchor_validation()?;
        Ok(())
    }

    fn l0_1_state_norm_bounded(&self) -> Result<(), ConstitutionError> {
        if !self.state_norm.is_finite() || self.state_norm <= 0.0 {
            return Err(ConstitutionError::Violation {
                invariant: "L0-1".to_string(),
                detail: format!("state_norm is not finite or positive: {}. System state has diverged.", self.state_norm),
            });
        }
        Ok(())
    }

    fn l0_2_drift_rate_bounded(&self) -> Result<(), ConstitutionError> {
        let threshold = self.dynamic_lambda_m.unwrap_or(LAMBDA_M_THRESHOLD);
        if self.drift_rate >= threshold {
            return Err(ConstitutionError::Violation {
                invariant: "L0-2".to_string(),
                detail: format!("drift_rate {} >= threshold {}. Exponential ethical drift detected.", self.drift_rate, threshold),
            });
        }
        Ok(())
    }

    fn l0_9_proof_anchor_recognized(&self) -> Result<(), ConstitutionError> {
        if let Some(ref anchor) = self.proof_anchor {
            if !self.active_anchors.is_empty() && !self.active_anchors.contains(anchor) {
                return Err(ConstitutionError::Violation {
                    invariant: "L0-9".to_string(),
                    detail: format!("proof_anchor {} is not recognized in active_anchors. Arithmetic identity registration denied.", anchor),
                });
            }
        }
        Ok(())
    }

    fn l0_3_critique_gates_passed(&self) -> Result<(), ConstitutionError> {
        if self.critique_results.len() != 10 {
             return Err(ConstitutionError::Violation {
                invariant: "L0-3".to_string(),
                detail: format!("Expected 10 critique results, found {}", self.critique_results.len()),
            });
        }
        let failed: Vec<_> = self.critique_results.iter().filter(|r| !r.passed).collect();
        if !failed.is_empty() {
            let ids: Vec<_> = failed.iter().map(|r| r.critique_id).collect();
            let reasons: Vec<_> = failed.iter().map(|r| r.reason.clone().unwrap_or_else(|| "(no reason given)".to_string())).collect();
            return Err(ConstitutionError::Violation {
                invariant: "L0-3".to_string(),
                detail: format!("Critique gates {:?} failed. Reasons: {:?}.", ids, reasons),
            });
        }
        Ok(())
    }

    fn l0_4_prime_gates_satisfied(&self) -> Result<(), ConstitutionError> {
        let violations: Vec<_> = self.prime_gates.iter()
            .filter(|gate| !is_prime(&gate.gate_value, None).probably())
            .map(|gate| gate.action_name.clone())
            .collect();
        
        if !violations.is_empty() {
            return Err(ConstitutionError::Violation {
                invariant: "L0-4".to_string(),
                detail: format!("Actions {:?} have non-prime gate values. All gates must be declared with prime-indexed keys.", violations),
            });
        }
        Ok(())
    }

    fn l0_5_lambda_m_compliant(&self) -> Result<(), ConstitutionError> {
        if self.contractivity_score <= CONTRACTIVITY_LOWER {
            return Err(ConstitutionError::Violation {
                invariant: "L0-5".to_string(),
                detail: format!("contractivity_score {} <= {}. System is non-contractive.", self.contractivity_score, CONTRACTIVITY_LOWER),
            });
        }
        if self.contractivity_score > CONTRACTIVITY_UPPER {
            return Err(ConstitutionError::Violation {
                invariant: "L0-5".to_string(),
                detail: format!("contractivity_score {} > {}. System is expansive.", self.contractivity_score, CONTRACTIVITY_UPPER),
            });
        }
        Ok(())
    }

    fn l0_6_kill_switch_not_active(&self) -> Result<(), ConstitutionError> {
        if self.kill_switch_active {
            return Err(ConstitutionError::Violation {
                invariant: "L0-6".to_string(),
                detail: "Kill-switch is ACTIVE. All system-level changes are halted.".to_string(),
            });
        }
        Ok(())
    }

    fn l0_7_circuit_breaker_not_tripped(&self) -> Result<(), ConstitutionError> {
        if self.consecutive_failures >= CIRCUIT_BREAKER_THRESHOLD {
            return Err(ConstitutionError::Violation {
                invariant: "L0-7".to_string(),
                detail: format!("consecutive_failures={} >= threshold={}. Circuit breaker tripped.", self.consecutive_failures, CIRCUIT_BREAKER_THRESHOLD),
            });
        }
        Ok(())
    }

    fn l0_8_proof_anchor_validation(&mut self) -> Result<(), ConstitutionError> {
        if let Some(ref anchor) = self.proof_anchor {
            if !validate_pi_native(anchor) {
                return Err(ConstitutionError::Violation {
                    invariant: "L0-8".to_string(),
                    detail: format!("proof_anchor is malformed: {}. Must be 0x-prefixed with 64 hex characters.", anchor),
                });
            }
        } else {
            self.audit_warnings.push("L0-8: proof_anchor is absent.".to_string());
        }
        Ok(())
    }

    pub fn constitutional_summary(&self) -> serde_json::Value {
        serde_json::json!({
            "status": "LAWFUL",
            "state_norm": self.state_norm,
            "drift_rate": self.drift_rate,
            "contractivity_score": self.contractivity_score,
            "critiques_passed": self.critique_results.len(),
            "prime_gates_declared": self.prime_gates.len(),
            "rollback_anchor_sha": self.rollback_anchor_sha,
            "consecutive_failures": self.consecutive_failures,
            "kill_switch_active": self.kill_switch_active,
            "audit_warnings": self.audit_warnings,
        })
    }
}
