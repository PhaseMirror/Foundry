use thiserror::Error;
use serde::{Deserialize, Serialize};

#[derive(Error, Debug)]
pub enum ContractivityError {
    #[error("Non-recoverable drift: delta {delta} >= epsilon {epsilon}")]
    DriftExceeded { delta: f64, epsilon: f64 },
    
    #[error("Sovereign Binding Failed: TEE quote missing")]
    ProvenanceGap,
    
    #[error("Trajectory Dissonance: Atom trajectory {atom} does not match active {active}")]
    TrajectoryDissonance { active: String, atom: String },
}

/// Deep Provenance payload from the agiOS ingress spine
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

/// A trait for states that can measure their own divergence.
pub trait MetricSpace {
    fn distance(&self, other: &Self) -> f64;
}

/// Enforces Invariant II: |Xi(t+1) - Xi*(t)| < epsilon
pub fn enforce_contractivity<S: MetricSpace>(
    current: &S,
    next: &S,
    epsilon: f64,
) -> Result<(), ContractivityError> {
    let delta = current.distance(next);
    if delta >= epsilon {
        Err(ContractivityError::DriftExceeded { delta, epsilon })
    } else {
        Ok(())
    }
}

/// Enforces Sovereign Contractivity by binding the LambdaTraceAtom to the EchoMirror-HQ kernel
pub fn enforce_sovereign_contractivity(
    atom: &LambdaTraceAtom,
    active_trajectory: &str,
    max_q_threshold: f64,
) -> Result<(), ContractivityError> {
    if atom.trajectory_id != active_trajectory {
        return Err(ContractivityError::TrajectoryDissonance {
            active: active_trajectory.to_string(),
            atom: atom.trajectory_id.clone(),
        });
    }

    if atom.tee_quote.is_none() {
        return Err(ContractivityError::ProvenanceGap);
    }

    // Since q measures contractivity directly, it acts as our delta vs a fixed 1.0 threshold
    // Here we use max_q_threshold as the boundary (e.g., 0.995)
    if atom.q >= max_q_threshold {
        return Err(ContractivityError::DriftExceeded {
            delta: atom.q,
            epsilon: max_q_threshold,
        });
    }

    Ok(())
}

#[cfg(kani)]
mod verification {
    use super::*;

    struct MockMetric(f64);
    impl MetricSpace for MockMetric {
        fn distance(&self, other: &Self) -> f64 {
            if self.0 >= other.0 { self.0 - other.0 } else { other.0 - self.0 }
        }
    }

    #[kani::proof]
    fn verify_enforce_contractivity_bound() {
        let x: f64 = kani::any();
        let y: f64 = kani::any();
        let epsilon: f64 = kani::any();
        
        kani::assume(x.is_finite() && y.is_finite() && epsilon.is_finite());
        kani::assume(epsilon > 0.0);
        
        let s1 = MockMetric(x);
        let s2 = MockMetric(y);
        
        if enforce_contractivity(&s1, &s2, epsilon).is_ok() {
            let dist = s1.distance(&s2);
            kani::assert(dist < epsilon, "Distance must be strictly bounded by epsilon");
        }
    }

    #[kani::proof]
    fn verify_sovereign_contractivity() {
        let q: f64 = kani::any();
        let max_q: f64 = kani::any();
        
        kani::assume(q.is_finite() && max_q.is_finite());
        kani::assume(max_q > 0.0);
        
        let atom = LambdaTraceAtom {
            proof_digest: String::new(),
            state_root_hash: String::new(),
            timestamp: 0,
            q,
            tee_quote: Some(String::new()),
            trajectory_id: "ACTIVE".to_string(),
            protocol_v: 1,
            signer_id: None,
        };
        
        if enforce_sovereign_contractivity(&atom, "ACTIVE", max_q).is_ok() {
            kani::assert(q < max_q, "Sovereign q must be bounded by max_q");
        }
    }
}
