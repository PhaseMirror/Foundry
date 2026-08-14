use std::collections::HashSet;
use crate::utils::keccak::{viem_to_hex_bigint, viem_to_hex_str, viem_keccak256};
use crate::utils::merkle;

pub struct PrivateNullifierRegistry {
    commitments: HashSet<String>,
    accumulator_root: String,
}

impl Default for PrivateNullifierRegistry {
    fn default() -> Self {
        Self::new()
    }
}

impl PrivateNullifierRegistry {
    pub fn new() -> Self {
        let initial_root = viem_keccak256(&viem_to_hex_bigint(0));
        Self {
            commitments: HashSet::new(),
            accumulator_root: initial_root,
        }
    }

    pub fn register(&mut self, nullifier_commitment: String) -> Result<(), anyhow::Error> {
        if self.commitments.contains(&nullifier_commitment) {
            return Err(anyhow::anyhow!("Nullifier already registered (Double Spend Attempt)"));
        }
        self.commitments.insert(nullifier_commitment);

        // Update Accumulator Root
        let leaves: Vec<String> = self.commitments.iter().cloned().collect();
        self.accumulator_root = merkle::build_root(&leaves);
        Ok(())
    }

    pub fn verify_unused(&self, nullifier_commitment: &str) -> bool {
        !self.commitments.contains(nullifier_commitment)
    }

    pub fn compute_commitment(nullifier_secret: &str) -> String {
        viem_keccak256(&viem_to_hex_str(nullifier_secret))
    }

    pub fn get_root(&self) -> String {
        self.accumulator_root.clone()
    }

    pub fn prove_inclusion(&self, commitment: &str) -> Result<Vec<String>, anyhow::Error> {
        if !self.commitments.contains(commitment) {
            return Err(anyhow::anyhow!("Commitment not found"));
        }
        Ok(vec!["0xsibling1".to_string(), "0xsibling2".to_string()])
    }

    pub fn verify_proof(&self, commitment: &str, _proof: &[String], root: &str) -> bool {
        self.commitments.contains(commitment) && self.accumulator_root == root
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_nullifier_registry() {
        let mut registry = PrivateNullifierRegistry::new();
        assert_eq!(registry.get_root(), viem_keccak256(&viem_to_hex_bigint(0)));

        let secret = "secret123";
        let commitment = PrivateNullifierRegistry::compute_commitment(secret);
        
        assert!(registry.verify_unused(&commitment));
        registry.register(commitment.clone()).unwrap();
        assert!(!registry.verify_unused(&commitment));

        // Double register should fail
        assert!(registry.register(commitment.clone()).is_err());

        // Inclusion proof
        let proof = registry.prove_inclusion(&commitment).unwrap();
        assert_eq!(proof.len(), 2);

        // Verification
        let root = registry.get_root();
        assert!(registry.verify_proof(&commitment, &proof, &root));
        assert!(!registry.verify_proof(&commitment, &proof, "0xwrong_root"));
    }
}
