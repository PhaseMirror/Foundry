use serde::{Deserialize, Serialize};
use thiserror::Error;
use std::fmt;

// --- Constants ---
pub const LAMBDA_M_THRESHOLD: f64 = 0.3; // MTPI bound delta(t) <= 0.3
pub const CONTRACTIVITY_UPPER: f64 = 1.0;
pub const CONTRACTIVITY_LOWER: f64 = 0.0;
pub const CIRCUIT_BREAKER_THRESHOLD: u32 = 3;
pub const CIVIC_STATE_MINIMUM: f64 = 1.0;

#[derive(Debug, Clone, Serialize, Deserialize, schemars::JsonSchema, PartialEq, Eq)]
pub enum L0Invariant {
    #[serde(rename = "L0-1")] L0_1,
    #[serde(rename = "L0-2")] L0_2,
    #[serde(rename = "L0-3")] L0_3,
    #[serde(rename = "L0-4")] L0_4,
    #[serde(rename = "L0-5")] L0_5,
    #[serde(rename = "L0-6")] L0_6,
    #[serde(rename = "L0-7")] L0_7,
    #[serde(rename = "L0-8")] L0_8,
    #[serde(rename = "L0-9")] L0_9,
    #[serde(rename = "L0-10")] L0_10,
}

impl fmt::Display for L0Invariant {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s = match self {
            L0Invariant::L0_1 => "L0-1",
            L0Invariant::L0_2 => "L0-2",
            L0Invariant::L0_3 => "L0-3",
            L0Invariant::L0_4 => "L0-4",
            L0Invariant::L0_5 => "L0-5",
            L0Invariant::L0_6 => "L0-6",
            L0Invariant::L0_7 => "L0-7",
            L0Invariant::L0_8 => "L0-8",
            L0Invariant::L0_9 => "L0-9",
            L0Invariant::L0_10 => "L0-10",
        };
        write!(f, "{}", s)
    }
}

#[derive(Error, Debug, Serialize, Deserialize, schemars::JsonSchema)]
pub struct ConstitutionViolation {
    pub invariant: L0Invariant,
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
    pub civic_state: Option<f64>,
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
        self.l0_10_civic_state_preserved()?;
        Ok(())
    }

    fn l0_1_state_norm_bounded(&self) -> Result<(), ConstitutionViolation> {
        if !self.state_norm.is_finite() || self.state_norm <= 0.0 {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_1,
                detail: format!("state_norm is not finite or non-positive: {}", self.state_norm),
            });
        }
        Ok(())
    }

    fn l0_2_drift_rate_bounded(&self) -> Result<(), ConstitutionViolation> {
        let threshold = self.dynamic_lambda_m.unwrap_or(LAMBDA_M_THRESHOLD);
        if self.drift_rate >= threshold {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_2,
                detail: format!("drift_rate {} >= threshold {}", self.drift_rate, threshold),
            });
        }
        Ok(())
    }

    fn l0_3_critique_gates_passed(&self) -> Result<(), ConstitutionViolation> {
        if self.critique_results.len() != 10 {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_3,
                detail: format!("Expected 10 critique results, found {}", self.critique_results.len()),
            });
        }
        let failed: Vec<_> = self.critique_results.iter().filter(|r| !r.passed).collect();
        if !failed.is_empty() {
            let ids: Vec<_> = failed.iter().map(|r| r.critique_id).collect();
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_3,
                detail: format!("Critique gates {:?} failed.", ids),
            });
        }
        Ok(())
    }

    fn l0_4_prime_gates_satisfied(&self) -> Result<(), ConstitutionViolation> {
        fn mod_pow(mut base: u128, mut exp: u128, modulus: u128) -> u128 {
            if modulus == 1 { return 0; }
            let mut result = 1;
            base %= modulus;
            while exp > 0 {
                if exp % 2 == 1 {
                    result = (result * base) % modulus;
                }
                exp >>= 1;
                base = (base * base) % modulus;
            }
            result
        }

        fn is_prime(n: u64) -> bool {
            if n < 2 { return false; }
            if n == 2 || n == 3 { return true; }
            if n % 2 == 0 { return false; }

            let mut d = n - 1;
            let mut s = 0;
            while d % 2 == 0 {
                d /= 2;
                s += 1;
            }

            let bases: [u64; 7] = [2, 3, 5, 7, 11, 13, 17];
            let n_u128 = n as u128;

            for &a in bases.iter() {
                if a >= n { continue; }
                let mut x = mod_pow(a as u128, d as u128, n_u128);
                if x == 1 || x == n_u128 - 1 {
                    continue;
                }
                let mut composite = true;
                for _ in 1..s {
                    x = (x * x) % n_u128;
                    if x == n_u128 - 1 {
                        composite = false;
                        break;
                    }
                }
                if composite {
                    return false;
                }
            }
            true
        }

        let violations: Vec<_> = self.prime_gates.iter()
            .filter(|g| !is_prime(g.gate_value))
            .map(|g| g.action_name.clone())
            .collect();

        if !violations.is_empty() {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_4,
                detail: format!("Actions {:?} failed MTPI Miller-Rabin primality test.", violations),
            });
        }
        Ok(())
    }

    fn l0_5_lambda_m_compliant(&self) -> Result<(), ConstitutionViolation> {
        if self.contractivity_score <= CONTRACTIVITY_LOWER {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_5,
                detail: format!("contractivity_score {} <= 0", self.contractivity_score),
            });
        }
        if self.contractivity_score > CONTRACTIVITY_UPPER {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_5,
                detail: format!("contractivity_score {} > {}", self.contractivity_score, CONTRACTIVITY_UPPER),
            });
        }
        Ok(())
    }

    fn l0_6_kill_switch_not_active(&self) -> Result<(), ConstitutionViolation> {
        if self.kill_switch_active {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_6,
                detail: "Kill-switch is ACTIVE.".to_string(),
            });
        }
        Ok(())
    }

    fn l0_7_circuit_breaker_not_tripped(&self) -> Result<(), ConstitutionViolation> {
        if self.consecutive_failures >= CIRCUIT_BREAKER_THRESHOLD {
            return Err(ConstitutionViolation {
                invariant: L0Invariant::L0_7,
                detail: format!("consecutive_failures={} >= threshold", self.consecutive_failures),
            });
        }
        Ok(())
    }

    fn l0_9_proof_anchor_recognized(&self) -> Result<(), ConstitutionViolation> {
        if let Some(ref anchor) = self.proof_anchor {
            if !self.active_anchors.is_empty() && !self.active_anchors.contains(anchor) {
                return Err(ConstitutionViolation {
                    invariant: L0Invariant::L0_9,
                    detail: format!("proof_anchor {} is not recognized", anchor),
                });
            }
        }
        Ok(())
    }

    fn l0_10_civic_state_preserved(&self) -> Result<(), ConstitutionViolation> {
        if let Some(state) = self.civic_state {
            if state < CIVIC_STATE_MINIMUM {
                return Err(ConstitutionViolation {
                    invariant: L0Invariant::L0_10,
                    detail: format!("Civic State {} is below the critical threshold of {}", state, CIVIC_STATE_MINIMUM),
                });
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // Helper to create a valid baseline model
    fn create_valid_model(civic_state: Option<f64>) -> ConstitutionModel {
        ConstitutionModel {
            state_norm: 1.0,
            drift_rate: 0.05,
            dynamic_lambda_m: Some(0.1),
            critique_results: (0..10).map(|i| CritiqueResult { critique_id: i, passed: true, reason: None }).collect(),
            prime_gates: vec![],
            contractivity_score: 0.5,
            kill_switch_active: false,
            rollback_anchor_sha: None,
            proof_anchor: None,
            audit_warnings: vec![],
            active_anchors: vec![],
            consecutive_failures: 0,
            civic_state,
        }
    }

    #[test]
    fn test_s1_nominal_operation() {
        let model = create_valid_model(Some(1.1));
        assert!(model.validate().is_ok());
    }

    #[test]
    fn test_s2_boundary_proximity() {
        let model = create_valid_model(Some(1.0));
        assert!(model.validate().is_ok());
    }

    #[test]
    fn test_s3_immediate_dissonance() {
        let model = create_valid_model(Some(0.99));
        let result = model.validate();
        assert!(result.is_err());
        if let Err(e) = result {
            assert_eq!(e.invariant, L0Invariant::L0_10);
        }
    }

    #[test]
    fn test_s4_recovery_phase() {
        let model = create_valid_model(Some(1.01));
        assert!(model.validate().is_ok());
    }

    #[test]
    fn test_s5_volatility_spike() {
        let states = vec![1.2, 0.8, 1.1];
        let mut results = vec![];
        for state in states {
            let model = create_valid_model(Some(state));
            results.push(model.validate().is_ok());
        }
        assert_eq!(results, vec![true, false, true]);
    }
}
