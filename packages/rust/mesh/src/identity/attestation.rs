use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use ed25519_dalek::{VerifyingKey, Signature, Verifier};
use base64::{Engine as _, engine::general_purpose};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AttestationError {
    #[error("Invalid signature")]
    InvalidSignature,
    #[error("Attestation expired")]
    Expired,
    #[error("Serialization error: {0}")]
    Serialization(String),
    #[error("Invalid public key: {0}")]
    InvalidPublicKey(String),
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AttestationClaim {
    pub subject_did: String,
    pub public_key_b64: String,
    pub issued_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SignedAttestation {
    pub claim: AttestationClaim,
    pub registry_did: String,
    pub signature_b64: String,
}

impl SignedAttestation {
    pub fn canonical_bytes(claim: &AttestationClaim) -> Vec<u8> {
        serde_json::to_vec(claim).expect("AttestationClaim is always serializable")
    }

    pub fn verify(&self, registry_pubkey_b64: &str) -> Result<(), AttestationError> {
        if self.claim.expires_at < Utc::now() {
            return Err(AttestationError::Expired);
        }

        let pubkey_bytes = general_purpose::STANDARD.decode(registry_pubkey_b64)
            .map_err(|e| AttestationError::InvalidPublicKey(e.to_string()))?;
        
        let pubkey_array: [u8; 32] = pubkey_bytes.as_slice().try_into()
            .map_err(|_| AttestationError::InvalidPublicKey("Wrong length".to_string()))?;
        
        let verifying_key = VerifyingKey::from_bytes(&pubkey_array)
            .map_err(|e| AttestationError::InvalidPublicKey(e.to_string()))?;

        let signature_bytes = general_purpose::STANDARD.decode(&self.signature_b64)
            .map_err(|_| AttestationError::InvalidSignature)?;
        
        let signature = Signature::from_slice(&signature_bytes)
            .map_err(|_| AttestationError::InvalidSignature)?;

        let payload = Self::canonical_bytes(&self.claim);
        verifying_key.verify(&payload, &signature)
            .map_err(|_| AttestationError::InvalidSignature)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ed25519_dalek::{SigningKey, Signer};
    use rand::rngs::OsRng;
    use rand::RngCore;
    use chrono::Duration;

    fn setup() -> (SigningKey, String) {
        let mut rng = OsRng;
        let mut bytes = [0u8; 32];
        rng.fill_bytes(&mut bytes);
        let signing_key = SigningKey::from_bytes(&bytes);
        let pubkey_b64 = general_purpose::STANDARD.encode(signing_key.verifying_key().to_bytes());
        (signing_key, pubkey_b64)
    }

    #[test]
    fn test_attestation_verification_valid() {
        let (registry_key, registry_pubkey) = setup();
        let (_, subject_pubkey) = setup();

        let claim = AttestationClaim {
            subject_did: "did:mesh:agent-1".to_string(),
            public_key_b64: subject_pubkey,
            issued_at: Utc::now(),
            expires_at: Utc::now() + Duration::hours(1),
        };

        let payload = SignedAttestation::canonical_bytes(&claim);
        let signature = registry_key.sign(&payload);
        let signature_b64 = general_purpose::STANDARD.encode(signature.to_bytes());

        let attestation = SignedAttestation {
            claim,
            registry_did: "did:mesh:registry".to_string(),
            signature_b64,
        };

        assert!(attestation.verify(&registry_pubkey).is_ok());
    }

    #[test]
    fn test_attestation_verification_expired() {
        let (registry_key, registry_pubkey) = setup();
        let (_, subject_pubkey) = setup();

        let claim = AttestationClaim {
            subject_did: "did:mesh:agent-1".to_string(),
            public_key_b64: subject_pubkey,
            issued_at: Utc::now() - Duration::hours(2),
            expires_at: Utc::now() - Duration::hours(1),
        };

        let payload = SignedAttestation::canonical_bytes(&claim);
        let signature = registry_key.sign(&payload);
        let signature_b64 = general_purpose::STANDARD.encode(signature.to_bytes());

        let attestation = SignedAttestation {
            claim,
            registry_did: "did:mesh:registry".to_string(),
            signature_b64,
        };

        let result = attestation.verify(&registry_pubkey);
        assert!(matches!(result, Err(AttestationError::Expired)));
    }

    #[test]
    fn test_attestation_verification_wrong_key() {
        let (_, registry_pubkey) = setup();
        let (malicious_key, _) = setup();
        let (_, subject_pubkey) = setup();

        let claim = AttestationClaim {
            subject_did: "did:mesh:agent-1".to_string(),
            public_key_b64: subject_pubkey,
            issued_at: Utc::now(),
            expires_at: Utc::now() + Duration::hours(1),
        };

        let payload = SignedAttestation::canonical_bytes(&claim);
        let signature = malicious_key.sign(&payload);
        let signature_b64 = general_purpose::STANDARD.encode(signature.to_bytes());

        let attestation = SignedAttestation {
            claim,
            registry_did: "did:mesh:registry".to_string(),
            signature_b64,
        };

        let result = attestation.verify(&registry_pubkey);
        assert!(matches!(result, Err(AttestationError::InvalidSignature)));
    }
}
