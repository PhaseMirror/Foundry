use serde::{Deserialize, Serialize};

/// The fundamental governance thresholds for the Tether Policy
pub const TAU_SAFE: f64 = 0.30;
pub const TAU_CRIT: f64 = 0.85;

/// Defines the operational state of the Citizen Gardens Node
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum NodeState {
    /// Node is actively contributing to coherence; Stablecoin minting authorized.
    Execution,
    /// Node is in dissonance; minting throttled, reinforcement learning (PSMC) adjusting parameters.
    Calibration,
    /// Critical dissonance detected. Autonomous revocation initiated via SIG_GOV_KILL.
    SigGovKill,
}

/// The Governance Tether Policy evaluates the instantaneous drift and network coverage
/// to autonomously modulate system expansion.
pub struct TetherPolicy {
    pub req_coverage: f64,
    pub tau_safe: f64,
    pub tau_crit: f64,
}

impl Default for TetherPolicy {
    fn default() -> Self {
        Self {
            req_coverage: 1.0,
            tau_safe: TAU_SAFE,
            tau_crit: TAU_CRIT,
        }
    }
}

impl TetherPolicy {
    pub fn new(req_coverage: f64) -> Self {
        Self { 
            req_coverage,
            tau_safe: TAU_SAFE,
            tau_crit: TAU_CRIT,
        }
    }

    /// Computes the tether tension τ based on the Lane A development formula:
    /// τ = (coverage / req_coverage) * (1 - ||Δ_drift||)
    pub fn compute_tau(&self, current_coverage: f64, drift_norm: f64) -> f64 {
        let coverage_ratio = current_coverage / self.req_coverage;
        let stability_factor = 1.0 - drift_norm.clamp(0.0, 1.0);
        
        coverage_ratio * stability_factor
    }

    /// Determines the autonomous governance state based on the current tether tension τ.
    pub fn evaluate_state(&self, tau: f64) -> NodeState {
        if tau > TAU_CRIT {
            NodeState::Execution
        } else if tau > TAU_SAFE && tau <= TAU_CRIT {
            NodeState::Calibration
        } else {
            NodeState::SigGovKill
        }
    }

    /// Master control loop iteration: Ingests the latest operational metrics and 
    /// returns the required governance action (the NodeState).
    pub fn process_telemetry(&self, current_coverage: f64, drift_norm: f64) -> (f64, NodeState) {
        let tau = self.compute_tau(current_coverage, drift_norm);
        let state = self.evaluate_state(tau);
        (tau, state)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_tether_policy_execution() {
        let policy = TetherPolicy::new(100.0);
        // High coverage (120), low drift (0.05)
        let (tau, state) = policy.process_telemetry(120.0, 0.05);
        assert!(tau > TAU_CRIT, "Tau should be above critical threshold");
        assert_eq!(state, NodeState::Execution);
    }

    #[test]
    fn test_tether_policy_calibration() {
        let policy = TetherPolicy::new(100.0);
        // Adequate coverage (90), moderate drift (0.4)
        let (tau, state) = policy.process_telemetry(90.0, 0.4);
        assert!(tau > TAU_SAFE && tau <= TAU_CRIT);
        assert_eq!(state, NodeState::Calibration);
    }

    #[test]
    fn test_tether_policy_sig_gov_kill() {
        let policy = TetherPolicy::new(100.0);
        // Low coverage (50), high drift (0.8)
        let (tau, state) = policy.process_telemetry(50.0, 0.8);
        assert!(tau <= TAU_SAFE, "Tau should be below safe threshold");
        assert_eq!(state, NodeState::SigGovKill);
    }
}
