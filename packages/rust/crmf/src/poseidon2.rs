//! Poseidon2 Sponge Commitment for CRMF.
//!
//! Note: A production Poseidon2 implementation requires field arithmetic over
//! the BN254 scalar field (or similar). This module provides the commitment
//! interface using SHA-256 as the underlying permutation; substitute with a
//! circuit-native Poseidon2 when the ZK backend (Arkworks/BN254) is available.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Poseidon2Commitment {
    pub commitment: [u8; 32],
    pub domain_tag: String,
}

impl Poseidon2Commitment {
    /// Create a new Poseidon2 commitment over the given payload.
    ///
    /// The domain_tag acts as a sponge domain separator, ensuring commitments
    /// from different contexts (e.g., state transitions vs policy decisions)
    /// cannot be combined adversarially.
    pub fn new(payload: &[u8], domain_tag: &str) -> Self {
        let mut hasher = Sha256::new();
        hasher.update(domain_tag.as_bytes());
        hasher.update(b"POSEIDON2-DOMAIN-SEPARATOR");
        hasher.update(payload);
        let commitment: [u8; 32] = hasher.finalize().into();
        Self {
            commitment,
            domain_tag: domain_tag.to_string(),
        }
    }

    /// Verify a commitment against a payload.
    pub fn verify(&self, payload: &[u8]) -> bool {
        let recomputed = Self::new(payload, &self.domain_tag);
        self.commitment == recomputed.commitment
    }
}
