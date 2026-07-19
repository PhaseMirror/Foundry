use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum TwinBindingError {
    #[error("Inadmissible Contraction: q {q} exceeds maximum threshold {max_threshold}")]
    InadmissibleContraction { q: f64, max_threshold: f64 },

    #[error("Trajectory Dissonance: Educational trajectory {edu_trajectory} does not match Health trajectory {health_trajectory}")]
    TrajectoryDissonance { edu_trajectory: String, health_trajectory: String },

    #[error("Provenance Gap: TEE quote is missing or invalid for twin binding")]
    ProvenanceGap,

    #[error("Cross-Domain Misalignment: Educational state and Health state diverge beyond acceptable ACE bounds")]
    CrossDomainMisalignment,
}

/// Atomized deep provenance payload originating from the agiOS ingress spine / EchoMirror.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LambdaTraceAtom {
    pub proof_digest: String,
    pub state_root_hash: String,
    pub timestamp: u64,
    pub q: f64,
    pub tee_quote: Option<String>,
    pub trajectory_id: String,
    pub protocol_v: u32,
    pub signer_id: Option<String>,
}

/// Health Twin State within Ataraxia.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthTwinState {
    pub twin_id: String,
    pub active_trajectory: String,
    pub biometrics_hash: String,
    pub eeg_coherence_score: f64,
    pub last_updated: u64,
}

/// Cross-Domain Contractivity Bridge enforcing resonance between EchoMirror (Educational) and Ataraxia (Health).
pub struct TwinBindingContract {
    pub max_q_threshold: f64,
    pub min_eeg_coherence: f64,
}

impl TwinBindingContract {
    pub fn new(max_q_threshold: f64, min_eeg_coherence: f64) -> Self {
        Self { max_q_threshold, min_eeg_coherence }
    }

    /// Evaluates cross-domain resonance between the incoming educational state and the current health twin state.
    pub fn evaluate_resonance(
        &self,
        educational_atom: &LambdaTraceAtom,
        health_twin: &HealthTwinState,
    ) -> Result<(), TwinBindingError> {
        if educational_atom.trajectory_id != health_twin.active_trajectory {
            return Err(TwinBindingError::TrajectoryDissonance {
                edu_trajectory: educational_atom.trajectory_id.clone(),
                health_trajectory: health_twin.active_trajectory.clone(),
            });
        }

        if educational_atom.tee_quote.is_none() {
            return Err(TwinBindingError::ProvenanceGap);
        }

        if educational_atom.q >= self.max_q_threshold {
            return Err(TwinBindingError::InadmissibleContraction {
                q: educational_atom.q,
                max_threshold: self.max_q_threshold,
            });
        }

        if health_twin.eeg_coherence_score < self.min_eeg_coherence {
            return Err(TwinBindingError::CrossDomainMisalignment);
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_atom(q: f64, trajectory: &str, tee: bool) -> LambdaTraceAtom {
        LambdaTraceAtom {
            proof_digest: "digest".to_string(),
            state_root_hash: "state_hash".to_string(),
            timestamp: 123456789,
            q,
            tee_quote: if tee { Some("TEE_QUOTE".to_string()) } else { None },
            trajectory_id: trajectory.to_string(),
            protocol_v: 1,
            signer_id: Some("signer".to_string()),
        }
    }

    fn make_health(trajectory: &str, eeg: f64) -> HealthTwinState {
        HealthTwinState {
            twin_id: "twin-001".to_string(),
            active_trajectory: trajectory.to_string(),
            biometrics_hash: "bio_hash".to_string(),
            eeg_coherence_score: eeg,
            last_updated: 123456780,
        }
    }

    #[test]
    fn test_successful_twin_binding() {
        let contract = TwinBindingContract::new(0.995, 0.70);
        let atom = make_atom(0.95, "Ataraxia-EchoMirror-Twin-Binding", true);
        let health = make_health("Ataraxia-EchoMirror-Twin-Binding", 0.85);
        assert!(contract.evaluate_resonance(&atom, &health).is_ok());
    }

    #[test]
    fn test_dissonance_trajectory_mismatch() {
        let contract = TwinBindingContract::new(0.995, 0.70);
        let atom = make_atom(0.95, "EchoMirror-Only", true);
        let health = make_health("Ataraxia-Only", 0.85);
        assert!(matches!(
            contract.evaluate_resonance(&atom, &health),
            Err(TwinBindingError::TrajectoryDissonance { .. })
        ));
    }

    #[test]
    fn test_cross_domain_misalignment() {
        let contract = TwinBindingContract::new(0.995, 0.70);
        let atom = make_atom(0.95, "Ataraxia-EchoMirror-Twin-Binding", true);
        let health = make_health("Ataraxia-EchoMirror-Twin-Binding", 0.50);
        assert!(matches!(
            contract.evaluate_resonance(&atom, &health),
            Err(TwinBindingError::CrossDomainMisalignment)
        ));
    }
}
