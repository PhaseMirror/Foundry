//! # Phase Mirror Governance Roadmap
//! Implements the strictly monotonic phase transition logic.

#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum DeploymentPhase {
    Foundation,
    Validation,
    EmbodiedLayer,
    AtomicLayer,
    CryptoEconomic,
    OperationalDeployment,
    Scaling,
}

pub struct PhaseMirrorEngine {
    pub current_phase: DeploymentPhase,
}

#[derive(Debug, PartialEq)]
pub enum PhaseError {
    CriteriaNotMet,
    InvalidProgression,
    AlreadyAtMaxPhase,
}

impl PhaseMirrorEngine {
    pub fn new() -> Self {
        Self {
            current_phase: DeploymentPhase::Foundation,
        }
    }

    /// Progress to the next phase, enforcing strict monotonicity
    pub fn try_advance(&mut self, criteria_met: bool) -> Result<(), PhaseError> {
        if !criteria_met {
            return Err(PhaseError::CriteriaNotMet);
        }

        let next_phase = match self.current_phase {
            DeploymentPhase::Foundation => DeploymentPhase::Validation,
            DeploymentPhase::Validation => DeploymentPhase::EmbodiedLayer,
            DeploymentPhase::EmbodiedLayer => DeploymentPhase::AtomicLayer,
            DeploymentPhase::AtomicLayer => DeploymentPhase::CryptoEconomic,
            DeploymentPhase::CryptoEconomic => DeploymentPhase::OperationalDeployment,
            DeploymentPhase::OperationalDeployment => DeploymentPhase::Scaling,
            DeploymentPhase::Scaling => return Err(PhaseError::AlreadyAtMaxPhase),
        };

        self.current_phase = next_phase;
        Ok(())
    }
}
