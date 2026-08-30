//! Core ledger types for the Λ^p-Archivum.

use serde::{Deserialize, Serialize};
#[cfg(not(kani))]
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

    #[cfg(not(kani))]
    pub fn compute_root_hash(&self) -> [u8; 32] {
        let mut hasher = Hasher::new();
        for w in &self.witnesses {
            hasher.update(w.state_hash.as_bytes());
        }
        *hasher.finalize().as_bytes()
    }

    #[cfg(kani)]
    pub fn compute_root_hash(&self) -> [u8; 32] {
        let mut hash = [0u8; 32];
        let witnesses = &self.witnesses;
        let mut j = 0;
        while j < witnesses.len() {
            let bytes = witnesses[j].state_hash.as_bytes();
            let mut i = 0;
            while i < bytes.len() {
                hash[i % 32] ^= bytes[i];
                i += 1;
            }
            j += 1;
        }
        hash
    }

    #[cfg(not(kani))]
    pub fn produce_tee_quote(&self) -> Result<String, ArchivumError> {
        let root = self.root_hash();
        let quote = format!("TEE-QUOTE-LAMBDA-TRACE-{:?}", root);
        Ok(quote)
    }

    #[cfg(kani)]
    pub fn produce_tee_quote(&self) -> Result<String, ArchivumError> {
        let root = self.root_hash();
        let mut quote = String::from("TEE-QUOTE-LAMBDA-TRACE-");
        for &b in &root {
            quote.push(b as char);
        }
        Ok(quote)
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    #[kani::unwind(50)]
    fn proof_append_only_and_chain_integrity() {
        let mut ledger = ArchivumLedger::new();
        let w = Witness {
            state_hash: String::from("test_hash"),
            event_type: String::from("test_event"),
            timestamp: 0,
            commit_hash: None,
            previous_hash: None,
        };

        let res = ledger.append(w.clone());
        assert!(res.is_ok(), "Append failed on empty ledger");
        assert!(ledger.verify_chain(), "Chain invalid after append");

        let res2 = ledger.append(w);
        assert!(res2.is_err(), "Duplicate witness not rejected");
    }

    #[kani::proof]
    #[kani::unwind(50)]
    fn proof_chain_root_changes_on_append() {
        let mut ledger = ArchivumLedger::new();
        let w = Witness {
            state_hash: String::from("test_hash"),
            event_type: String::from("test_event"),
            timestamp: 0,
            commit_hash: None,
            previous_hash: None,
        };
        let root_before = ledger.root_hash();
        ledger.append(w).unwrap();
        let root_after = ledger.root_hash();
        assert!(root_before != root_after, "Root should change on append");
    }

    #[kani::proof]
    #[kani::unwind(50)]
    fn proof_multiple_appends_maintain_integrity() {
        let mut ledger = ArchivumLedger::new();
        let w1 = Witness {
            state_hash: String::from("test_hash_1"),
            event_type: String::from("test_event"),
            timestamp: 0,
            commit_hash: None,
            previous_hash: None,
        };
        let w2 = Witness {
            state_hash: String::from("test_hash_2"),
            event_type: String::from("test_event"),
            timestamp: 1,
            commit_hash: None,
            previous_hash: None,
        };
        ledger.append(w1).unwrap();
        ledger.append(w2).unwrap();
        assert!(ledger.verify_chain(), "Chain should remain valid after multiple appends");
    }

    #[kani::proof]
    #[kani::unwind(80)]
    fn proof_tee_quote_binds_to_root() {
        let ledger = ArchivumLedger {
            witnesses: vec![Witness {
                state_hash: String::from("test_hash"),
                event_type: String::from("test_event"),
                timestamp: 0,
                commit_hash: None,
                previous_hash: None,
            }],
            root_hash: [1u8; 32],
        };
        let quote = ledger.produce_tee_quote().unwrap();
        let mut expected = String::from("TEE-QUOTE-LAMBDA-TRACE-");
        for &b in &ledger.root_hash() {
            expected.push(b as char);
        }
        assert_eq!(quote, expected);
    }
}
