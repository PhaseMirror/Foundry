use std::collections::{HashMap, HashSet};
use crate::witness::{UnifiedWitness, WitnessError, DualSignatureProtocol};

/// Grow-Only Set (G-Set) CRDT for distributed Archivum synchronization.
/// Ensures eventual consistency for immutable UnifiedWitness receipts.
#[derive(Debug, Clone, Default)]
pub struct ArchivumCrdt {
    /// Maps transition_id to the UnifiedWitness
    pub witnesses: HashMap<String, UnifiedWitness>,
}

impl ArchivumCrdt {
    pub fn new() -> Self {
        Self {
            witnesses: HashMap::new(),
        }
    }

    /// Appends a new witness locally. Fails if the signature is invalid.
    pub fn append(&mut self, witness: UnifiedWitness, operator_key: &str, kernel_key: &str) -> Result<(), WitnessError> {
        // Enforce Phase D signature traps before admitting to local CRDT
        DualSignatureProtocol::verify(&witness, operator_key, kernel_key)?;
        
        self.witnesses.insert(witness.transition_id.clone(), witness);
        Ok(())
    }

    /// Merges an incoming CRDT state into the local state.
    /// Only adds missing witnesses that pass strict signature verification.
    pub fn merge(&mut self, incoming: &ArchivumCrdt, operator_key: &str, kernel_key: &str) -> Result<usize, WitnessError> {
        let mut added_count = 0;
        
        for (id, witness) in &incoming.witnesses {
            if !self.witnesses.contains_key(id) {
                // Strict verification on inbound sync
                DualSignatureProtocol::verify(witness, operator_key, kernel_key)?;
                self.witnesses.insert(id.clone(), witness.clone());
                added_count += 1;
            }
        }
        
        Ok(added_count)
    }

    /// Returns the total size of the synchronized ledger
    pub fn len(&self) -> usize {
        self.witnesses.len()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_crdt_merge_sync() {
        let op_key = "op-secret";
        let kernel_key = "kernel-secret";

        // Agent A creates a witness
        let mut agent_a = ArchivumCrdt::new();
        let mut w1 = UnifiedWitness::new("tx-1", "time1", "hash1");
        DualSignatureProtocol::sign_primary(&mut w1, op_key);
        DualSignatureProtocol::sign_secondary(&mut w1, kernel_key);
        agent_a.append(w1, op_key, kernel_key).unwrap();

        // Agent B creates a different witness
        let mut agent_b = ArchivumCrdt::new();
        let mut w2 = UnifiedWitness::new("tx-2", "time2", "hash2");
        DualSignatureProtocol::sign_primary(&mut w2, op_key);
        DualSignatureProtocol::sign_secondary(&mut w2, kernel_key);
        agent_b.append(w2.clone(), op_key, kernel_key).unwrap();

        // Sync A -> B
        let added = agent_b.merge(&agent_a, op_key, kernel_key).unwrap();
        assert_eq!(added, 1);
        assert_eq!(agent_b.len(), 2);

        // Sync B -> A
        let added = agent_a.merge(&agent_b, op_key, kernel_key).unwrap();
        assert_eq!(added, 1);
        assert_eq!(agent_a.len(), 2);
        
        // Both agents are now consistent
        assert!(agent_a.witnesses.contains_key("tx-1"));
        assert!(agent_a.witnesses.contains_key("tx-2"));
    }

    #[test]
    fn test_crdt_rejects_invalid_sync() {
        let op_key = "op-secret";
        let kernel_key = "kernel-secret";

        let mut agent_a = ArchivumCrdt::new();
        let mut agent_b = ArchivumCrdt::new();

        // Agent A creates a corrupted witness
        let mut w1 = UnifiedWitness::new("tx-1", "time1", "hash1");
        DualSignatureProtocol::sign_primary(&mut w1, op_key);
        DualSignatureProtocol::sign_secondary(&mut w1, kernel_key);
        
        // Manual corruption (bypasses Agent A's append validation for the sake of the test)
        w1.metrics_hash = "corrupted".to_string();
        agent_a.witnesses.insert("tx-1".to_string(), w1);

        // Sync A -> B should trap and fail
        let result = agent_b.merge(&agent_a, op_key, kernel_key);
        assert!(result.is_err());
        assert_eq!(agent_b.len(), 0);
    }
}
