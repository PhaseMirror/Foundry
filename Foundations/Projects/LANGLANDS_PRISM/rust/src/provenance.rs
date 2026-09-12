use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use crate::tensor::PrismTensorState;
use crate::firewall::{firewall_gate, compute_ethical_metric};

/// Immutable Provenance Ledger Block.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProvenanceBlock {
    pub time: u64,
    pub state_hash: String,
    pub previous_hash: String,
    pub ethical_metric: f64,
    pub was_collapsed: bool,
    pub timestamp_epoch: u64,
}

/// Cryptographic Provenance Ledger chain.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ProvenanceLedger {
    pub blocks: Vec<ProvenanceBlock>,
}

impl ProvenanceLedger {
    pub fn new() -> Self {
        Self { blocks: Vec::new() }
    }

    /// Compute cryptographic state signature SHA-256 hash.
    pub fn hash_state(st: &PrismTensorState, prev_hash: &str) -> String {
        let mut hasher = Sha256::new();
        hasher.update(st.time.to_be_bytes());
        hasher.update(st.lambda_m.to_be_bytes());
        hasher.update(prev_hash.as_bytes());

        for node in &st.nodes {
            hasher.update(node.prime.to_be_bytes());
            hasher.update(node.weight.to_be_bytes());
            hasher.update(node.phase.to_be_bytes());
            hasher.update(node.energy.to_be_bytes());
        }

        hex::encode(hasher.finalize())
    }

    /// Record a verified state transition into the ledger.
    pub fn record_state(&mut self, st: &PrismTensorState) -> ProvenanceBlock {
        let (safe_st, was_collapsed) = firewall_gate(st);
        let metric = compute_ethical_metric(&safe_st);
        let prev_hash = self.blocks.last()
            .map(|b| b.state_hash.clone())
            .unwrap_or_else(|| "0000000000000000000000000000000000000000000000000000000000000000".to_string());

        let state_hash = Self::hash_state(&safe_st, &prev_hash);
        let block = ProvenanceBlock {
            time: safe_st.time,
            state_hash,
            previous_hash: prev_hash,
            ethical_metric: metric,
            was_collapsed,
            timestamp_epoch: 1724774400 + safe_st.time * 60,
        };

        self.blocks.push(block.clone());
        block
    }

    /// Validate the integrity of the cryptographic ledger chain.
    pub fn verify_chain_integrity(&self) -> bool {
        if self.blocks.is_empty() {
            return true;
        }
        for i in 1..self.blocks.len() {
            if self.blocks[i].previous_hash != self.blocks[i - 1].state_hash {
                return false;
            }
        }
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::LAMBDA_M;

    #[test]
    fn test_provenance_ledger_chaining() {
        let mut ledger = ProvenanceLedger::new();
        let primes = [2, 3, 5, 7, 11];
        let mut st = PrismTensorState::new_with_primes(&primes, LAMBDA_M);

        ledger.record_state(&st);
        st = st.step();
        ledger.record_state(&st);
        st = st.step();
        ledger.record_state(&st);

        assert_eq!(ledger.blocks.len(), 3);
        assert!(ledger.verify_chain_integrity());
        assert_eq!(ledger.blocks[0].previous_hash, "0000000000000000000000000000000000000000000000000000000000000000");
        assert_eq!(ledger.blocks[1].previous_hash, ledger.blocks[0].state_hash);
    }
}
