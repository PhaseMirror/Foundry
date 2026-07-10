// prms/src/petc.rs
use std::collections::HashMap;
use sha2::{Sha256, Digest};
use serde::{Serialize, Deserialize};

pub type Atom = u64;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct AlgebraicSignature {
    pub components: HashMap<Atom, i64>,
}

impl AlgebraicSignature {
    pub fn zero() -> Self {
        Self { components: HashMap::new() }
    }

    pub fn combine(&self, other: &Self) -> Self {
        let mut combined = self.components.clone();
        for (&atom, &exponent) in &other.components {
            *combined.entry(atom).or_insert(0) += exponent;
        }
        combined.retain(|_, &mut exp| exp != 0);
        Self { components: combined }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TensorSpaceType {
    pub boundaries: Vec<AlgebraicSignature>,
}

impl TensorSpaceType {
    pub fn global_invariant(&self) -> AlgebraicSignature {
        let mut invariant = AlgebraicSignature::zero();
        for bound in &self.boundaries {
            invariant = invariant.combine(bound);
        }
        invariant
    }

    pub fn evaluates_weak_equivalence(&self, other: &Self) -> bool {
        self.global_invariant() == other.global_invariant()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BytecodeHeader {
    pub engine_version: u32,
    pub constraint_flags: u8,
    pub source_type: TensorSpaceType,
    pub target_type: TensorSpaceType,
}

pub struct ProofWitnessVerificationSystem;

impl ProofWitnessVerificationSystem {
    pub fn compute_provenance_hash(
        header: &BytecodeHeader, 
        alpha: f64, 
        prime_table: &[u64]
    ) -> [u8; 32] {
        let mut hasher = Sha256::new();
        let header_bytes = bincode::serialize(header).unwrap_or_default();
        hasher.update(&header_bytes);
        hasher.update(&alpha.to_be_bytes());
        for prime in prime_table {
            hasher.update(&prime.to_be_bytes());
        }
        let mut output = [0u8; 32];
        output.copy_from_slice(&hasher.finalize());
        output
    }
}
