//! CRMF cryptographic seals with dual anchors (SHA-256 + Ed25519)
//! and Poseidon2 sponge commitments.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use ed25519_dalek::{Verifier, Signature, VerifyingKey};
use crate::poseidon2::Poseidon2Commitment;
use crate::{CrmfError, CrmfKeypair};
use hex;

/// Dual cryptographic anchors binding a CRMF record.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DualAnchor {
    /// SHA-256 hash of the BCS-serialized payload.
    pub sha256_hex: String,
    /// Ed25519 signature over the SHA-256 hash.
    pub ed25519_sig: Vec<u8>,
    /// Ed25519 public key (compressed, 32 bytes).
    pub ed25519_pk: Vec<u8>,
}

impl DualAnchor {
    /// Create a new dual anchor by signing the SHA-256 hash with Ed25519.
    pub fn sign(payload: &[u8], keypair: &CrmfKeypair) -> Self {
        let sha256_hash = Sha256::digest(payload);
        let sha256_hex = hex::encode(sha256_hash);
        let sig = keypair.sign(payload);
        Self {
            sha256_hex,
            ed25519_sig: sig.to_bytes().to_vec(),
            ed25519_pk: keypair.public.to_bytes().to_vec(),
        }
    }

    /// Verify the dual anchor against the payload.
    pub fn verify(&self, payload: &[u8]) -> Result<(), CrmfError> {
        let sha256_hash = Sha256::digest(payload);
        let computed_hex = hex::encode(sha256_hash);

        if computed_hex != self.sha256_hex {
            return Err(CrmfError::SealViolation);
        }

        let pk = VerifyingKey::try_from(self.ed25519_pk.as_slice())
            .map_err(|_| CrmfError::InvalidKey)?;
        let sig = Signature::try_from(self.ed25519_sig.as_slice())
            .map_err(|_| CrmfError::InvalidKey)?;

        pk.verify(payload, &sig)
            .map_err(|_| CrmfError::SignatureVerificationFailed)?;

        Ok(())
    }
}

/// A CRMF validity seal.
///
/// Binds together:
/// - Dual cryptographic anchors (SHA-256 + Ed25519)
/// - Poseidon2 sponge commitment
/// - BCS-serialized payload hash
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CrmfSeal {
    pub dual_anchor: DualAnchor,
    pub poseidon2: Poseidon2Commitment,
    pub bcs_hash: String,
    pub crmf_version: String,
}

impl CrmfSeal {
    pub fn new(
        payload: &[u8],
        domain_tag: &str,
        keypair: &CrmfKeypair,
    ) -> Self {
        let bcs_hash = hex::encode(Sha256::digest(payload));
        let dual_anchor = DualAnchor::sign(payload, keypair);
        let poseidon2 = Poseidon2Commitment::new(payload, domain_tag);

        Self {
            dual_anchor,
            poseidon2,
            bcs_hash,
            crmf_version: "0.1.0".to_string(),
        }
    }

    /// Verify the complete seal chain.
    pub fn verify(&self, payload: &[u8]) -> Result<(), CrmfError> {
        self.dual_anchor.verify(payload)?;
        if !self.poseidon2.verify(payload) {
            return Err(CrmfError::SealViolation);
        }
        Ok(())
    }
}
