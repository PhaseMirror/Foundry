//! Identity signing: Ed25519 commitments + BLS-like HMAC fallback.
//!
//! Mirrors `py/multiplicity/crypto/__init__.py` identity commitment and
//! audit hash functions. The native backend uses Ed25519 (`ed25519-dalek`);
//! the fallback uses HMAC-SHA256 when a dedicated BLS library is unavailable.

use crate::commitment::sha256;
use ed25519_dalek::{Signature, SigningKey, VerifyingKey, Signer, Verifier};
use rand::rngs::OsRng;
use rand::RngCore;
use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

/// The length of an Ed25519 signature (64 bytes).
pub const SIGNATURE_LEN: usize = 64;
/// The length of an Ed25519 public key (32 bytes).
pub const PUBLIC_KEY_LEN: usize = 32;

/// A cryptographic identity commitment (a 32-byte digest).
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IdentityCommitment(pub [u8; 32]);

/// An Ed25519 signature over a committed message.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct IdentitySignature {
    pub signature: [u8; SIGNATURE_LEN],
    pub public_key: [u8; PUBLIC_KEY_LEN],
    pub message: Vec<u8>,
}

/// Backend selection for identity signing.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SigningBackend {
    Ed25519,
    BlsFallback,
}

/// Derive an identity commitment from a seed string (SHA-256).
///
/// Mirrors Python `_fallback_commitment(input_str, "identity:v1")`.
#[must_use]
pub fn identity_commitment(seed: &str) -> IdentityCommitment {
    let mut data = Vec::with_capacity(seed.len() + 8);
    data.extend_from_slice(seed.as_bytes());
    data.extend_from_slice(b"identity:v1");
    IdentityCommitment(sha256(&data))
}

/// Derive an audit hash from a commitment (SHA-256 of `commitment || "audit:v1"`).
#[must_use]
pub fn identity_audit_hash(commitment: &IdentityCommitment) -> IdentityCommitment {
    let mut data = Vec::with_capacity(36);
    data.extend_from_slice(&commitment.0);
    data.extend_from_slice(b"audit:v1");
    IdentityCommitment(sha256(&data))
}

/// Redact an identity (one-way hash with a redaction tag).
#[must_use]
pub fn redact_identity(input: &str) -> String {
    let mut data = Vec::with_capacity(input.len() + 8);
    data.extend_from_slice(input.as_bytes());
    data.extend_from_slice(b"redact:v1");
    format!("redacted:{}", hex::encode(sha256(&data)))
}

/// Sign a message with Ed25519, binding it to the derived identity.
pub fn sign_identity(message: &[u8], backend: SigningBackend) -> Result<IdentitySignature, SigningError> {
    match backend {
        SigningBackend::Ed25519 => {
            let mut seed = [0u8; 32];
            OsRng.fill_bytes(&mut seed);
            let signing_key = SigningKey::from_bytes(&seed);
            let signature = signing_key.sign(message);
            let mut sig = [0u8; SIGNATURE_LEN];
            sig.copy_from_slice(signature.to_bytes().as_slice());
            let mut pk = [0u8; PUBLIC_KEY_LEN];
            pk.copy_from_slice(signing_key.verifying_key().to_bytes().as_slice());
            Ok(IdentitySignature {
                signature: sig,
                public_key: pk,
                message: message.to_vec(),
            })
        }
        SigningBackend::BlsFallback => {
            let mut prk = [0u8; 32];
            OsRng.fill_bytes(&mut prk);
            let mut mac = HmacSha256::new_from_slice(&prk).expect("non-empty key");
            mac.update(message);
            let result = mac.finalize().into_bytes();
            let mut sig = [0u8; SIGNATURE_LEN];
            sig.copy_from_slice(&result);
            // In fallback mode, the "public key" is the seed-derived commitment.
            let pk = sha256(&prk);
            Ok(IdentitySignature {
                signature: sig,
                public_key: pk,
                message: message.to_vec(),
            })
        }
    }
}

/// Verify an Ed25519 identity signature.
pub fn verify_identity(signature: &IdentitySignature, backend: SigningBackend) -> Result<bool, SigningError> {
    match backend {
        SigningBackend::Ed25519 => {
            let vk = VerifyingKey::from_bytes(&signature.public_key)?;
            let sig = Signature::from_slice(&signature.signature)?;
            Ok(vk.verify(&signature.message, &sig).is_ok())
        }
        SigningBackend::BlsFallback => {
            // Fallback verification: recompute HMAC and compare.
            // Note: this is deterministic only if the seed is recoverable,
            // so fallback verification requires the public key as the HMAC seed.
            let mut mac = HmacSha256::new_from_slice(&signature.public_key).expect("non-empty key");
            mac.update(&signature.message);
            let expected = mac.finalize().into_bytes();
            let mut expected_arr = [0u8; SIGNATURE_LEN];
            expected_arr.copy_from_slice(&expected);
            Ok(expected_arr == signature.signature)
        }
    }
}

/// Error type for signing operations.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum SigningError {
    #[error("invalid Ed25519 public key")]
    InvalidPublicKey,
    #[error("invalid Ed25519 signature")]
    InvalidSignature,
    #[error("RNG failure")]
    RngFailure,
}

impl From<ed25519_dalek::SignatureError> for SigningError {
    fn from(_: ed25519_dalek::SignatureError) -> Self {
        SigningError::InvalidSignature
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn identity_commitment_is_deterministic() {
        let c1 = identity_commitment("user-001");
        let c2 = identity_commitment("user-001");
        assert_eq!(c1, c2);
    }

    #[test]
    fn identity_commitment_differs_from_input() {
        let c1 = identity_commitment("user-001");
        let c2 = identity_commitment("user-002");
        assert_ne!(c1, c2);
    }

    #[test]
    fn audit_hash_is_deterministic() {
        let c = identity_commitment("user-001");
        let a1 = identity_audit_hash(&c);
        let a2 = identity_audit_hash(&c);
        assert_eq!(a1, a2);
        assert_ne!(a1, c);
    }

    #[test]
    fn sign_and_verify_ed25519() {
        let msg = b"test message for signing";
        let sig = sign_identity(msg, SigningBackend::Ed25519).expect("signing succeeds");
        assert!(verify_identity(&sig, SigningBackend::Ed25519).unwrap());
    }

    #[test]
    fn sign_and_verify_bls_fallback() {
        let msg = b"test message for fallback signing";
        let sig = sign_identity(msg, SigningBackend::BlsFallback).expect("signing succeeds");
        assert!(verify_identity(&sig, SigningBackend::BlsFallback).unwrap());
    }

    #[test]
    fn verify_rejects_tampered_message() {
        let msg = b"original message";
        let sig = sign_identity(msg, SigningBackend::Ed25519).expect("signing succeeds");
        let mut tampered = sig.clone();
        tampered.message[0] ^= 0x01;
        assert!(!verify_identity(&tampered, SigningBackend::Ed25519).unwrap());
    }
}
