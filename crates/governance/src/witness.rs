use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum WitnessError {
    #[error("Dual-signature mismatch. Expected {expected}, got {actual}")]
    SignatureMismatch { expected: String, actual: String },
    #[error("Witness schema validation failed: {0}")]
    ValidationFailed(String),
}

/// The core UnifiedWitness for Phase D recovery
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct UnifiedWitness {
    pub transition_id: String,
    pub timestamp: String,
    pub metrics_hash: String,
    pub primary_signature: String,
    pub secondary_signature: Option<String>,
}

impl UnifiedWitness {
    pub fn new(transition_id: &str, timestamp: &str, metrics_hash: &str) -> Self {
        Self {
            transition_id: transition_id.to_string(),
            timestamp: timestamp.to_string(),
            metrics_hash: metrics_hash.to_string(),
            primary_signature: String::new(),
            secondary_signature: None,
        }
    }

    /// Generates the deterministic core hash over the invariant metrics
    pub fn compute_core_hash(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.transition_id.as_bytes());
        hasher.update(self.timestamp.as_bytes());
        hasher.update(self.metrics_hash.as_bytes());
        hex::encode(hasher.finalize())
    }
}

/// The Dual-Signature Protocol wrapper for strict re-certification
pub struct DualSignatureProtocol;

impl DualSignatureProtocol {
    /// Applies the primary governance signature
    pub fn sign_primary(witness: &mut UnifiedWitness, operator_key: &str) {
        let core = witness.compute_core_hash();
        let mut hasher = Sha256::new();
        hasher.update(core.as_bytes());
        hasher.update(operator_key.as_bytes());
        witness.primary_signature = hex::encode(hasher.finalize());
    }

    /// Applies the secondary sigma-kernel signature for ratification
    pub fn sign_secondary(witness: &mut UnifiedWitness, kernel_key: &str) {
        let core = witness.compute_core_hash();
        let mut hasher = Sha256::new();
        hasher.update(core.as_bytes());
        hasher.update(kernel_key.as_bytes());
        witness.secondary_signature = Some(hex::encode(hasher.finalize()));
    }

    /// Verifies both signatures hold cleanly against the core parameters
    pub fn verify(witness: &UnifiedWitness, operator_key: &str, kernel_key: &str) -> Result<(), WitnessError> {
        if witness.primary_signature.is_empty() || witness.secondary_signature.is_none() {
            return Err(WitnessError::ValidationFailed("Missing signatures".to_string()));
        }

        let core = witness.compute_core_hash();
        
        let mut p_hasher = Sha256::new();
        p_hasher.update(core.as_bytes());
        p_hasher.update(operator_key.as_bytes());
        let expected_primary = hex::encode(p_hasher.finalize());
        
        if expected_primary != witness.primary_signature {
            return Err(WitnessError::SignatureMismatch { 
                expected: expected_primary, 
                actual: witness.primary_signature.clone() 
            });
        }

        let mut s_hasher = Sha256::new();
        s_hasher.update(core.as_bytes());
        s_hasher.update(kernel_key.as_bytes());
        let expected_secondary = hex::encode(s_hasher.finalize());
        
        if expected_secondary != witness.secondary_signature.as_ref().unwrap().clone() {
            return Err(WitnessError::SignatureMismatch { 
                expected: expected_secondary, 
                actual: witness.secondary_signature.as_ref().unwrap().clone() 
            });
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dual_signature_protocol() {
        let mut witness = UnifiedWitness::new("tx-108", "1783015009", "abc123metrics");
        
        let op_key = "op-secret";
        let kernel_key = "kernel-secret";

        DualSignatureProtocol::sign_primary(&mut witness, op_key);
        DualSignatureProtocol::sign_secondary(&mut witness, kernel_key);

        assert!(DualSignatureProtocol::verify(&witness, op_key, kernel_key).is_ok());
    }

    #[test]
    fn test_signature_mismatch() {
        let mut witness = UnifiedWitness::new("tx-108", "1783015009", "abc123metrics");
        let op_key = "op-secret";
        let kernel_key = "kernel-secret";

        DualSignatureProtocol::sign_primary(&mut witness, op_key);
        DualSignatureProtocol::sign_secondary(&mut witness, kernel_key);
        
        // Corrupt metrics hash
        witness.metrics_hash = "corrupted".to_string();

        assert!(DualSignatureProtocol::verify(&witness, op_key, kernel_key).is_err());
    }

    use proptest::prelude::*;

    proptest! {
        #[test]
        fn fuzz_dual_signature_protocol(
            transition_id in ".*",
            timestamp in ".*",
            metrics_hash in ".*",
            op_key in ".*",
            kernel_key in ".*"
        ) {
            let mut witness = UnifiedWitness::new(&transition_id, &timestamp, &metrics_hash);
            
            DualSignatureProtocol::sign_primary(&mut witness, &op_key);
            DualSignatureProtocol::sign_secondary(&mut witness, &kernel_key);

            prop_assert!(DualSignatureProtocol::verify(&witness, &op_key, &kernel_key).is_ok());
        }

        #[test]
        fn fuzz_dual_signature_corruption(
            transition_id in ".*",
            timestamp in ".*",
            metrics_hash in ".*",
            op_key in ".*",
            kernel_key in ".*",
            corrupt_id in ".*"
        ) {
            let mut witness = UnifiedWitness::new(&transition_id, &timestamp, &metrics_hash);
            
            DualSignatureProtocol::sign_primary(&mut witness, &op_key);
            DualSignatureProtocol::sign_secondary(&mut witness, &kernel_key);
            
            prop_assume!(corrupt_id != transition_id);
            witness.transition_id = corrupt_id;

            prop_assert!(DualSignatureProtocol::verify(&witness, &op_key, &kernel_key).is_err());
        }
    }
}
