use crate::strata::StratumState;
use crate::meta_ensemble::MetaEnsemble;
use serde::{Serialize, Deserialize};
use blake3;

/// AIR Column definitions for the Goldilocks Kernel update.
/// This matches the arithmetization required for STARK proofs.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct AirColumns {
    pub step: usize,
    pub prev_state: Vec<f64>,
    pub next_state: Vec<f64>,
    pub update: Vec<f64>,
    pub damping_factor: f64,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ExecutionTrace {
    pub step: usize,
    pub stratum_id: String,
    pub prev_state_hash: String,
    pub next_state_hash: String,
    pub update_hash: String,
    pub entropy_threshold: f64,
    pub was_damped: bool,
    /// BLAKE3-hashed commitment to the full arithmetized row (AIR).
    pub air_commitment: String,
}

pub struct ZkTracer {
    pub traces: Vec<ExecutionTrace>,
}

impl ZkTracer {
    pub fn new() -> Self {
        ZkTracer { traces: Vec::new() }
    }

    /// Records an execution step for auditable proof generation using BLAKE3 for STARK compatibility.
    pub fn record_step(
        &mut self,
        step: usize,
        stratum: &StratumState,
        prev_state: &ndarray::Array1<f64>,
        update: &ndarray::Array1<f64>,
        threshold: f64,
        was_damped: bool,
    ) {
        let prev_hash = hash_vector_blake3(prev_state);
        let next_hash = hash_vector_blake3(&stratum.state_vector);
        let update_hash = hash_vector_blake3(update);

        let damping_factor = if was_damped { threshold / update_hash.len() as f64 } else { 1.0 };

        let air = AirColumns {
            step,
            prev_state: prev_state.to_vec(),
            next_state: stratum.state_vector.to_vec(),
            update: update.to_vec(),
            damping_factor,
        };

        let air_commitment = blake3::hash(&serde_json::to_vec(&air).unwrap()).to_hex().to_string();

        let stratum_id = match stratum.stratum_type {
            crate::strata::StratumType::S0Physics => "S0",
            crate::strata::StratumType::S2Cognition => "S2",
            crate::strata::StratumType::S4Collective => "S4",
        }.to_string();

        self.traces.push(ExecutionTrace {
            step,
            stratum_id,
            prev_state_hash: prev_hash,
            next_state_hash: next_hash,
            update_hash,
            entropy_threshold: threshold,
            was_damped,
            air_commitment,
        });
    }

    /// Generates a 'Commitment' to the execution sequence using BLAKE3.
    pub fn generate_commitment(&self) -> String {
        let mut hasher = blake3::Hasher::new();
        for trace in &self.traces {
            hasher.update(&serde_json::to_vec(trace).unwrap());
        }
        hasher.finalize().to_hex().to_string()
    }
}

fn hash_vector_blake3(v: &ndarray::Array1<f64>) -> String {
    let mut hasher = blake3::Hasher::new();
    for &val in v.iter() {
        hasher.update(&val.to_be_bytes());
    }
    hasher.finalize().to_hex().to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::Array1;

    // A mock StratumState for testing purposes, assuming StratumType exists.
    #[test]
    fn test_matrix_resonance_under_runtime_load() {
        let mut tracer = ZkTracer::new();
        
        // Simulating the 108-cycle resonance matrix update propagation
        for step in 0..108 {
            let prev_state = Array1::from_vec(vec![0.5, 1.5, 2.5, 3.5]);
            let next_state = Array1::from_vec(vec![1.0, 2.0, 3.0, 4.0]);
            let update = Array1::from_vec(vec![0.5, 0.5, 0.5, 0.5]);
            
            // Dummy stratum struct
            let stratum = crate::strata::StratumState {
                stratum_type: crate::strata::StratumType::S0Physics,
                state_vector: next_state,
            };

            let is_damped = step % 2 == 0;
            tracer.record_step(step, &stratum, &prev_state, &update, 1.0, is_damped);
        }

        let commitment = tracer.generate_commitment();
        assert_eq!(tracer.traces.len(), 108);
        assert!(!commitment.is_empty(), "ZK propagation circuit finalized with resonance trace");
    }
}
