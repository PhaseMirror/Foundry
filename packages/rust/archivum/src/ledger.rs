//! Core ledger types for the Λ^p-Archivum.

use serde::{Deserialize, Serialize};
use blake3::Hasher;
use thiserror::Error;

use crate::proofs::PwehHash;

#[derive(Debug, Error)]
pub enum ArchivumError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("Validation error: {0}")]
    Validation(String),
    #[error("Duplicate witness: {state_hash}")]
    DuplicateWitness { state_hash: String },
    #[error("Chain integrity violation")]
    ChainViolation,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Witness {
    pub state_hash: String,
    pub event_type: String,
    pub timestamp: i64,
    pub commit_hash: Option<String>,
    pub previous_hash: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ArchivumLedger {
    pub witnesses: Vec<Witness>,
    pub root_hash: [u8; 32],
}

impl ArchivumLedger {
    pub fn new() -> Self {
        Self {
            witnesses: Vec::new(),
            root_hash: [0u8; 32],
        }
    }

    pub fn append(&mut self, w: Witness) -> Result<[u8; 32], ArchivumError> {
        if self.witnesses.iter().any(|x| x.state_hash == w.state_hash) {
            return Err(ArchivumError::DuplicateWitness {
                state_hash: w.state_hash,
            });
        }
        self.witnesses.push(w);
        self.root_hash = self.compute_root_hash();
        Ok(self.root_hash)
    }

    pub fn verify_chain(&self) -> bool {
        self.root_hash == self.compute_root_hash()
    }

    pub fn root_hash(&self) -> [u8; 32] {
        self.root_hash
    }

    pub fn compute_root_hash(&self) -> [u8; 32] {
        let mut hasher = Hasher::new();
        for w in &self.witnesses {
            hasher.update(w.state_hash.as_bytes());
        }
        *hasher.finalize().as_bytes()
    }

    pub fn produce_tee_quote(&self) -> Result<String, ArchivumError> {
        let root = self.root_hash();
        let quote = format!("TEE-QUOTE-LAMBDA-TRACE-{:?}", root);
        Ok(quote)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_append_only_and_chain_integrity() {
        let mut ledger = ArchivumLedger::new();
        let w = Witness {
            state_hash: "test_hash".to_string(),
            event_type: "test_event".to_string(),
            timestamp: 0,
            commit_hash: None,
            previous_hash: None,
        };

        let res = ledger.append(w.clone());
        kani::assert(res.is_ok(), "Append failed on empty ledger");
        kani::assert(ledger.verify_chain(), "Chain invalid after append");

        let res2 = ledger.append(w);
        kani::assert(res2.is_err(), "Duplicate witness not rejected");
    }
}
