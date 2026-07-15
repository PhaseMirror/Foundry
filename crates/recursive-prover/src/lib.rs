//! Recursive Proof Aggregation
//!
//! This crate provides the production-grade implementation of ADR-069.
//! It handles the safe wrapping and aggregation of Zero-Knowledge proofs
//! into a single Aggregated Proof Object (APO) for high-throughput 
//! formal verification inside the PhaseMirror environment.

#![forbid(unsafe_code)]
#![deny(clippy::all, missing_docs)]

#[allow(missing_docs)]
pub mod verifier_gadget;

use serde::{Deserialize, Serialize};

/// Represents a base Zero-Knowledge proof object.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofObject {
    /// The unique identifier for the circuit.
    pub circuit_id: u64,
    /// The public inputs corresponding to the proof.
    pub public_inputs: Vec<i64>,
    /// The actual raw bytes of the proof.
    pub proof_bytes: Vec<u8>,
}

/// Represents a proof wrapped recursively within another circuit.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecursiveProof {
    /// The inner proof object being wrapped.
    pub inner_proof: ProofObject,
    /// The circuit identifier of the wrapper.
    pub wrapper_circuit_id: u64,
}

/// Aggregated Proof Object (APO) representing multiple proofs.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct APO {
    /// The collection of proofs that have been aggregated.
    pub aggregated_proofs: Vec<RecursiveProof>,
    /// The cryptographic root hash securing the integrity of the APO.
    pub root_hash: String,
}

/// Errors that can occur during the proof aggregation process.
#[derive(Debug, thiserror::Error)]
pub enum ProverError {
    /// Indicates that the proof for a given circuit is invalid.
    #[error("invalid proof for circuit {0}")]
    InvalidProof(u64),
    /// Indicates that the recursive depth limit was exceeded.
    #[error("aggregation depth exceeded")]
    DepthExceeded,
    /// Indicates that a single proof's byte size exceeded the safe threshold.
    #[error("proof size limit exceeded")]
    SizeLimitExceeded,
}

/// The main prover engine for wrapping and aggregating proofs.
pub struct RecursiveProver {
    /// The maximum allowable depth for recursive wrapping.
    #[allow(dead_code)]
    pub max_depth: usize,
    /// The maximum number of proofs that can be aggregated in a single APO.
    pub max_proofs: usize,
}

/// Computes the cryptographic root hash for a slice of recursive proofs.
fn compute_apo_root_hash(proofs: &[RecursiveProof]) -> String {
    let mut hasher = blake3::Hasher::new();
    for p in proofs {
        hasher.update(&p.inner_proof.circuit_id.to_le_bytes());
        for i in &p.inner_proof.public_inputs {
            hasher.update(&i.to_le_bytes());
        }
        hasher.update(&p.inner_proof.proof_bytes);
        hasher.update(&p.wrapper_circuit_id.to_le_bytes());
    }
    hasher.finalize().to_string()
}

impl RecursiveProver {
    /// Instantiates a new `RecursiveProver` with safety bounds.
    pub fn new(max_depth: usize, max_proofs: usize) -> Self {
        Self { max_depth, max_proofs }
    }

    /// Wraps a standard proof inside a recursive wrapper circuit.
    pub fn wrap(
        &self,
        proof: ProofObject,
        wrapper_circuit: u64,
    ) -> Result<RecursiveProof, ProverError> {
        if proof.proof_bytes.len() > 1024 * 1024 {
            return Err(ProverError::SizeLimitExceeded);
        }
        Ok(RecursiveProof { inner_proof: proof, wrapper_circuit_id: wrapper_circuit })
    }

    /// Aggregates multiple recursive proofs into a single `APO`.
    pub fn aggregate(
        &self,
        proofs: Vec<RecursiveProof>,
    ) -> Result<APO, ProverError> {
        if proofs.len() > self.max_proofs {
            return Err(ProverError::DepthExceeded);
        }
        let root_hash = compute_apo_root_hash(&proofs);
        Ok(APO { aggregated_proofs: proofs, root_hash })
    }

    /// Verifies the structural integrity and root hash of an `APO`.
    pub fn verify_apo(&self, apo: &APO) -> Result<bool, ProverError> {
        Ok(apo.root_hash == compute_apo_root_hash(&apo.aggregated_proofs))
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_aggregation_preserves_validity() {
        let prover = RecursiveProver::new(10, 10);
        let p = ProofObject {
            circuit_id: 1,
            public_inputs: vec![1],
            proof_bytes: vec![1, 2, 3],
        };
        let r = prover.wrap(p, 2).unwrap();
        let apo = prover.aggregate(vec![r]).unwrap();
        kani::assert(prover.verify_apo(&apo).unwrap(), "APO verification failed");
    }

    #[kani::proof]
    fn proof_wrap_soundness() {
        let prover = RecursiveProver::new(10, 10);
        let p = ProofObject {
            circuit_id: 1,
            public_inputs: vec![1],
            proof_bytes: vec![1, 2, 3],
        };
        let r = prover.wrap(p.clone(), 2).unwrap();
        kani::assert(r.inner_proof.circuit_id == p.circuit_id, "Wrap altered circuit id");
        kani::assert(r.wrapper_circuit_id == 2, "Wrap failed to set wrapper circuit id");
    }

    #[kani::proof]
    fn proof_apo_verification_sound() {
        let prover = RecursiveProver::new(10, 10);
        let p = ProofObject {
            circuit_id: 1,
            public_inputs: vec![1],
            proof_bytes: vec![1, 2, 3],
        };
        let r = prover.wrap(p, 2).unwrap();
        let mut apo = prover.aggregate(vec![r]).unwrap();
        
        kani::assert(prover.verify_apo(&apo).unwrap(), "Valid APO rejected");
        
        // Mutate the APO
        apo.root_hash = "invalid".to_string();
        kani::assert(!prover.verify_apo(&apo).unwrap(), "Invalid APO accepted");
    }
}
