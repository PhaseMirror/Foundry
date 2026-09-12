//! Longitudinal Multi-Session Neuroplastic Simulation Engine

use crate::csl::CslAuditor;
use crate::echo_braid::EchoBraidCoordinator;
use crate::eeg_interface::EegInterface;
use crate::operator::RecursiveOperator;
use crate::tensor::PirtmEngine;
use crate::types::{CognitiveState, NeuroConfig, SessionMetrics};

/// Simulation engine running longitudinal cognitive adaptation sessions.
pub struct NeuroplasticitySimulator {
    pub config: NeuroConfig,
    pub operator: RecursiveOperator,
    pub csl_auditor: CslAuditor,
    pub echo_braid: EchoBraidCoordinator,
    pub current_state: CognitiveState,
}

impl NeuroplasticitySimulator {
    pub fn new(config: NeuroConfig) -> Self {
        let initial_state = PirtmEngine::initialize_default_state(7);
        Self {
            operator: RecursiveOperator::new(config.clone()),
            csl_auditor: CslAuditor::new(config.clone()),
            echo_braid: EchoBraidCoordinator::new(),
            current_state: initial_state,
            config,
        }
    }

    /// Execute a single learning session of N time steps under task stimuli and EEG state.
    pub fn run_session(
        &mut self,
        session_id: usize,
        steps: usize,
        stimuli: &[f64],
        eeg_state_type: &str,
    ) -> SessionMetrics {
        let eeg_bands = EegInterface::simulate_eeg_bands(eeg_state_type);
        let readiness = EegInterface::compute_subjective_readiness(&eeg_bands);

        let initial_power = self.current_state.total_power();
        let mut total_delta_s = 0.0;
        let mut all_csl_satisfied = true;

        for _ in 0..steps {
            let next_raw = self.operator.step(&self.current_state, stimuli, readiness);
            let (satisfied, delta_s) = self.csl_auditor.audit_transition(&self.current_state, &next_raw);

            total_delta_s += delta_s;
            if !satisfied {
                all_csl_satisfied = false;
                // Homeostatic damping applied on CSL breach
                self.current_state = self.csl_auditor.enforce_homeostasis(&next_raw);
            } else {
                self.current_state = next_raw;
            }
        }

        let final_power = self.current_state.total_power();
        let echo_coherence = self.echo_braid.compute_identity_coherence(&self.current_state);

        SessionMetrics {
            session_id,
            initial_power,
            final_power,
            delta_s: total_delta_s / (steps as f64),
            csl_satisfied: all_csl_satisfied,
            echo_braid_coherence: echo_coherence,
            subjective_readiness: readiness,
        }
    }
}
