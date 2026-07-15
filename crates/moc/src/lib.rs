use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum MocOperator {
    Sp(u64), // S_p
    A,
    R,
    W,
    Q,
    Pi(u64),
    Delta(u64),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OperatorWord {
    pub operators: Vec<MocOperator>,
    pub prime_grade: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommutatorResult {
    pub value: i64,
    pub prime_p: u64,
    pub prime_q: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResonanceResult {
    pub value: f64,
    pub hamiltonian_hash: [u8; 32],
    pub domain_hash: [u8; 32],
}

#[derive(Debug, thiserror::Error)]
pub enum MocError {
    #[error("resonance exceeded bound: {actual} > 1.0")]
    ResonanceExceeded { actual: f64 },
    #[error("invalid prime {0}: not in schema")]
    InvalidPrime(u64),
    #[error("sequence violation: {current} <= {last}")]
    SequenceViolation { current: u64, last: u64 },
    #[error("invalid attestation")]
    InvalidAttestation,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Schema {
    pub primes: Vec<u64>,
    pub seq: u64,
    pub attestation: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerifiedSchema {
    pub schema: Schema,
    pub last_seq: u64,
}

pub struct MocEngine;

impl MocEngine {
    pub fn verify_schema(&self, schema: &Schema, last_seq: u64) -> Result<VerifiedSchema, MocError> {
        if schema.attestation != "AUTHORIZED_SCHEMA_SIG" {
            return Err(MocError::InvalidAttestation);
        }
        if schema.seq <= last_seq {
            return Err(MocError::SequenceViolation { current: schema.seq, last: last_seq });
        }
        Ok(VerifiedSchema { schema: schema.clone(), last_seq })
    }
}

impl MocOperator {
    pub fn prime_grading(&self) -> Option<u64> {
        match self {
            MocOperator::Sp(p) | MocOperator::Pi(p) | MocOperator::Delta(p) => Some(*p),
            _ => None,
        }
    }

    pub fn commute(&self, other: &MocOperator) -> CommutatorResult {
        match (self, other) {
            (MocOperator::Sp(p1), MocOperator::Sp(p2)) => {
                CommutatorResult { value: if p1 == p2 { 0 } else { 1 }, prime_p: *p1, prime_q: *p2 }
            }
            _ => CommutatorResult { value: 0, prime_p: 0, prime_q: 0 },
        }
    }
}

pub fn resonance(value: f64, hamiltonian_hash: [u8; 32], domain_hash: [u8; 32]) -> Result<ResonanceResult, MocError> {
    if value > 1.0 {
        return Err(MocError::ResonanceExceeded { actual: value });
    }
    
    Ok(ResonanceResult {
        value,
        hamiltonian_hash,
        domain_hash,
    })
}

pub fn braid(word: &OperatorWord) -> OperatorWord {
    // Dummy braid reduction that just returns the word unchanged
    word.clone()
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_commutation_sound() {
        let op1 = MocOperator::Sp(kani::any());
        let op2 = MocOperator::Sp(kani::any());

        let res = op1.commute(&op2);
        let p1 = match op1 { MocOperator::Sp(p) => p, _ => unreachable!() };
        let p2 = match op2 { MocOperator::Sp(p) => p, _ => unreachable!() };

        if p1 == p2 {
            kani::assert(res.value == 0, "Commutator [S_p, S_p] must be 0");
        } else {
            kani::assert(res.value == 1, "Commutator [S_p, S_q] must be 1 for p != q");
        }
    }

    #[kani::proof]
    fn proof_braid_terminates() {
        let word = OperatorWord {
            operators: vec![],
            prime_grade: 2,
        };
        let _ = braid(&word);
        // If it returns, it terminates.
    }

    #[kani::proof]
    fn proof_resonance_bounded() {
        let value: f64 = kani::any();
        kani::assume(value >= 0.0);
        let hash = [0u8; 32];
        
        let res = resonance(value, hash, hash);
        if let Ok(r) = res {
            kani::assert(r.value <= 1.0, "Resonance must be <= 1.0");
        }
    }

    #[kani::proof]
    fn proof_sequence_monotone() {
        let engine = MocEngine;
        let schema = Schema {
            primes: vec![2, 3],
            seq: kani::any(),
            attestation: "AUTHORIZED_SCHEMA_SIG".to_string(),
        };
        let last_seq: u64 = kani::any();
        
        let res = engine.verify_schema(&schema, last_seq);
        if schema.seq <= last_seq {
            kani::assert(res.is_err(), "Monotone seq check");
        } else {
            kani::assert(res.is_ok(), "Valid seq accepted");
        }
    }
}
