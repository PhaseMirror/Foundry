use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LedgerBlock {
    pub sequence: u64,
    pub timestamp: u64,
    pub prev_hash: String,
    pub root_hash: String, // Root of the 12,288 matrix state or the transition vector
    pub action: String,    // e.g., "matrix-step"
    pub u: u16,            // The XOR permutation used
    pub signature: Option<String>,
}

pub struct Ledger {
    pub chain: Vec<LedgerBlock>,
}

impl Ledger {
    pub const GENESIS: &'static str = "0000000000000000000000000000000000000000000000000000000000000000";

    pub fn new() -> Self {
        Self { chain: Vec::new() }
    }

    pub fn append(&mut self, root_hash: String, action: String, u: u16) -> LedgerBlock {
        let prev_hash = self.chain.last().map(|b| b.compute_hash()).unwrap_or_else(|| Self::GENESIS.to_string());
        let sequence = self.chain.len() as u64;
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();

        let mut block = LedgerBlock {
            sequence,
            timestamp,
            prev_hash,
            root_hash,
            action,
            u,
            signature: None,
        };

        // Sign the block (mock signing for now, could integrate with Ed25519)
        block.signature = Some(format!("SIG-{}", block.compute_hash()));
        
        self.chain.push(block.clone());
        block
    }

    pub fn verify(&self) -> bool {
        let mut prev_hash = Self::GENESIS.to_string();
        for block in &self.chain {
            if block.prev_hash != prev_hash {
                return false;
            }
            prev_hash = block.compute_hash();
        }
        true
    }
}

impl LedgerBlock {
    pub fn compute_hash(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.sequence.to_be_bytes());
        hasher.update(self.timestamp.to_be_bytes());
        hasher.update(self.prev_hash.as_bytes());
        hasher.update(self.root_hash.as_bytes());
        hasher.update(self.action.as_bytes());
        hasher.update(self.u.to_be_bytes());
        hex::encode(hasher.finalize())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ledger_chain_integrity() {
        let mut ledger = Ledger::new();
        ledger.append("hash1".to_string(), "action1".to_string(), 0);
        ledger.append("hash2".to_string(), "action2".to_string(), 1);
        
        assert!(ledger.verify());
        assert_eq!(ledger.chain.len(), 2);
        assert_eq!(ledger.chain[1].prev_hash, ledger.chain[0].compute_hash());
    }

    #[test]
    fn test_ledger_tamper_detection() {
        let mut ledger = Ledger::new();
        ledger.append("hash1".to_string(), "action1".to_string(), 0);
        ledger.append("hash2".to_string(), "action2".to_string(), 1);
        
        assert!(ledger.verify());
        
        // Tamper with a block
        ledger.chain[0].root_hash = "tampered".to_string();
        assert!(!ledger.verify());
    }
}
