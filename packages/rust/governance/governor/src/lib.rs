use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum GovernorError {
    #[error("Agent not found: {0}")]
    AgentNotFound(String),
    #[error("Lever not found: {0}")]
    LeverNotFound(String),
    #[error("Access denied: missing prime support for gate {gate}")]
    MissingPrimeSupport { gate: u64 },
    #[error("Access denied: ethical drift {drift} exceeds threshold {threshold}")]
    EthicalDriftExceeded { drift: f64, threshold: f64 },
    #[error("Gate violation: {0} is not prime")]
    InvalidGate(u64),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    pub id: String,
    pub prime_support: HashSet<u64>,
    pub identity_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Lever {
    pub id: String,
    pub prime_gate: u64,
}

pub struct PolicyEngine {
    pub drift_threshold: f64,
}

impl PolicyEngine {
    pub fn new(drift_threshold: f64) -> Self {
        Self { drift_threshold }
    }

    pub fn authorize(
        &self,
        agent: &Agent,
        lever: &Lever,
        current_drift: f64,
    ) -> Result<(), GovernorError> {
        // 1. Primality Invariant
        if !is_prime(lever.prime_gate) {
            return Err(GovernorError::InvalidGate(lever.prime_gate));
        }

        // 2. Ethical Drift Circuit-Breaker
        if current_drift >= self.drift_threshold {
            return Err(GovernorError::EthicalDriftExceeded {
                drift: current_drift,
                threshold: self.drift_threshold,
            });
        }

        // 3. Support Check
        if !agent.prime_support.contains(&lever.prime_gate) {
            return Err(GovernorError::MissingPrimeSupport {
                gate: lever.prime_gate,
            });
        }

        Ok(())
    }
}

fn is_prime(n: u64) -> bool {
    if n < 2 { return false; }
    let mut i = 2;
    while i * i <= n {
        if n % i == 0 { return false; }
        i += 1;
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_authorization_pass() {
        let engine = PolicyEngine::new(0.05);
        let mut support = HashSet::new();
        support.insert(17);
        let agent = Agent {
            id: "agent-1".to_string(),
            prime_support: support,
            identity_hash: "hash".to_string(),
        };
        let lever = Lever {
            id: "lever-1".to_string(),
            prime_gate: 17,
        };
        assert!(engine.authorize(&agent, &lever, 0.01).is_ok());
    }

    #[test]
    fn test_authorization_fail_drift() {
        let engine = PolicyEngine::new(0.05);
        let mut support = HashSet::new();
        support.insert(17);
        let agent = Agent {
            id: "agent-1".to_string(),
            prime_support: support,
            identity_hash: "hash".to_string(),
        };
        let lever = Lever {
            id: "lever-1".to_string(),
            prime_gate: 17,
        };
        let result = engine.authorize(&agent, &lever, 0.06);
        assert!(matches!(result, Err(GovernorError::EthicalDriftExceeded { .. })));
    }

    #[test]
    fn test_authorization_fail_support() {
        let engine = PolicyEngine::new(0.05);
        let mut support = HashSet::new();
        support.insert(2);
        let agent = Agent {
            id: "agent-1".to_string(),
            prime_support: support,
            identity_hash: "hash".to_string(),
        };
        let lever = Lever {
            id: "lever-1".to_string(),
            prime_gate: 17,
        };
        let result = engine.authorize(&agent, &lever, 0.01);
        assert!(matches!(result, Err(GovernorError::MissingPrimeSupport { gate: 17 })));
    }
}
