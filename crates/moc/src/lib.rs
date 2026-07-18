use serde::{Deserialize, Serialize};
use blake3::Hasher;

#[cfg(feature = "archivum")]
use archivum::{WitnessLedger, MocSchemaProof};

#[cfg(feature = "triple-lock")]
pub mod triple_lock;

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
    #[error("archivum write failed: {0}")]
    ArchivumError(String),
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MocSchemaWitness {
    pub schema_hash: [u8; 32],
    pub seq: u64,
    pub timestamp: i64,
}

impl MocSchemaWitness {
    pub fn new(verified: &VerifiedSchema) -> Self {
        let mut hasher = Hasher::new();
        hasher.update(&verified.schema.seq.to_le_bytes());
        for p in &verified.schema.primes {
            hasher.update(&p.to_le_bytes());
        }
        let hash = hasher.finalize();
        Self {
            schema_hash: hash.into(),
            seq: verified.schema.seq,
            timestamp: chrono::Utc::now().timestamp(),
        }
    }
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

    pub fn verify_operator(&self, op: &MocOperator, schema: &VerifiedSchema) -> Result<(), MocError> {
        if let Some(p) = op.prime_grading() {
            if !schema.schema.primes.contains(&p) {
                return Err(MocError::InvalidPrime(p));
            }
        }
        Ok(())
    }

    pub fn verify_operator_word(&self, word: &OperatorWord, schema: &VerifiedSchema) -> Result<(), MocError> {
        for op in &word.operators {
            self.verify_operator(op, schema)?;
        }
        Ok(())
    }

    #[cfg(feature = "archivum")]
    pub fn monitor_and_archive_schema(
        &self,
        schema: &Schema,
        last_seq: u64,
        ledger: &mut WitnessLedger,
    ) -> Result<(VerifiedSchema, MocSchemaWitness), MocError> {
        let verified = self.verify_schema(schema, last_seq)?;
        let witness = MocSchemaWitness::new(&verified);
        let proof = MocSchemaProof::new(witness.schema_hash, schema.seq);
        ledger
            .stamp_moc_schema_proof(&proof)
            .map_err(|e| MocError::ArchivumError(e.to_string()))?;
        Ok((verified, witness))
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
    fn proof_schema_validation() {
        let engine = MocEngine;
        let p: u64 = kani::any();
        let schema = Schema {
            primes: vec![2, 3],
            seq: 2,
            attestation: "AUTHORIZED_SCHEMA_SIG".to_string(),
        };
        let verified = engine.verify_schema(&schema, 1).unwrap();
        
        let op = MocOperator::Sp(p);
        let res = engine.verify_operator(&op, &verified);
        
        if p == 2 || p == 3 {
            kani::assert(res.is_ok(), "Permitted primes are accepted");
        } else {
            kani::assert(res.is_err(), "Unpermitted primes are rejected");
        }
    }

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
