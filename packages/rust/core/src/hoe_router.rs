use crate::spectral::SpectralMetrics;

/// HoE escalation router using SpectralMetrics for governance decisions
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum EscalationDecision {
    /// Autonomous: Gershgorin stable AND convergence within bounds
    Autonomous,
    /// Escalate: Spectral violation detected
    Escalate(String),
    /// Review: Convergence uncertainty (needs human review)
    Review(String),
}

impl EscalationDecision {
    pub fn is_autonomous(&self) -> bool {
        matches!(self, EscalationDecision::Autonomous)
    }
}

/// HoE Router determines escalation based on spectral metrics
#[derive(Debug, Clone)]
pub struct HoERouter {
    pub tier: usize,
}

impl HoERouter {
    pub fn new(tier: usize) -> Self {
        Self { tier }
    }

    /// Determine escalation decision from spectral metrics
    ///
    /// # Policy
    /// - Gershgorin fast-path: If used_power_iteration=false, use disk-based check
    /// - HoE trigger: ρ ≥ 1-ε_tier OR convergence_rate ≥ (1-ε) → Escalate
    /// - Convergence uncertainty: rate ≥ (1-ε) → Review
    /// - Otherwise: Autonomous
    pub fn route(&self, metrics: &SpectralMetrics) -> EscalationDecision {
        let epsilon = match self.tier {
            1 => 0.10,
            2 => 0.05,
            3 => 0.02,
            4 => 0.01,
            _ => 0.05,
        };

        // Check spectral radius violation (HoE escalation trigger)
        if metrics.spectral_radius >= 1.0 - epsilon {
            return EscalationDecision::Escalate(format!(
                "SPECTRAL_VIOLATION: ρ={:.4} >= 1-ε={:.2}",
                metrics.spectral_radius, epsilon
            ));
        }

        // Check convergence rate (review trigger)
        if metrics.convergence_rate >= 1.0 - epsilon && metrics.used_power_iteration {
            return EscalationDecision::Review(format!(
                "CONVERGENCE_UNCERTAINTY: rate={:.4} >= 1-ε={:.2}",
                metrics.convergence_rate, epsilon
            ));
        }

        // Gershgorin fast-path: no power iteration needed = stable
        if !metrics.used_power_iteration {
            return EscalationDecision::Autonomous;
        }

        EscalationDecision::Autonomous
    }

    /// Get tier epsilon margin
    pub fn epsilon(&self) -> f64 {
        match self.tier {
            1 => 0.10,
            2 => 0.05,
            3 => 0.02,
            4 => 0.01,
            _ => 0.05,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hoe_router_autonomous_stable() {
        let metrics = SpectralMetrics {
            spectral_radius: 0.5,
            gershgorin_radius: 0.3,
            contraction_margin: 0.5,
            drift_score: 0.2,
            iteration_count: 0,
            used_power_iteration: false,
            convergence_rate: 0.0,
            effective_iterations: 0,
        };
        let router = HoERouter::new(2);
        assert!(router.route(&metrics).is_autonomous());
    }

    #[test]
    fn test_hoe_router_escalate_violation() {
        let metrics = SpectralMetrics {
            spectral_radius: 0.96,
            gershgorin_radius: 0.9,
            contraction_margin: 0.04,
            drift_score: 0.06,
            iteration_count: 50,
            used_power_iteration: true,
            convergence_rate: 0.01,
            effective_iterations: 50,
        };
        let router = HoERouter::new(2); // ε = 0.05, 1-ε = 0.95
        match router.route(&metrics) {
            EscalationDecision::Escalate(msg) => assert!(msg.contains("SPECTRAL_VIOLATION")),
            _ => panic!("Expected Escalate"),
        }
    }

    #[test]
    fn test_hoe_router_tier_epsilon() {
        let router1 = HoERouter::new(1);
        assert!((router1.epsilon() - 0.10).abs() < 1e-10);

        let router4 = HoERouter::new(4);
        assert!((router4.epsilon() - 0.01).abs() < 1e-10);
    }
}
