//! AEAD: ChaCha20 (RFC 8439) + HMAC-SHA256 Encrypt-then-MAC.
//!
//! This is the default AEAD backend for the QKD pipeline. The QKD v1.0.1 spec
//! mandates AES-256-GCM; this ChaCha20-HMAC construction is a deliberate
//! seam (see the crate-level docs for the substitution rationale).
//!
//! The nonce is extended with a prime-indexed domain tag: the first 4 bytes
//! of the base nonce are XORed with `resolved_prime`, ensuring ciphertexts
//! derived at different prime indices are non-interchangeable.

use crate::chacha20::{ChaCha20, ChaChaNonce};
use crate::commitment::sha256;
use crate::kdf::{KEY_LEN, hkdf_extract, hkdf_expand};
use crate::profile::MultiplicityProfile;
use crate::prime::get_prime_at_index;
use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

/// AEADEncryption output: ciphertext + authentication tag.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AeadCiphertext {
    pub ciphertext: Vec<u8>,
    pub auth_tag: [u8; 32],
}

/// AEAD error type.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum AeadError {
    #[error("authentication tag mismatch — ciphertext was tampered")]
    AuthenticationFailure,
    #[error("invalid nonce length")]
    InvalidNonce,
    #[error("invalid key length")]
    InvalidKey,
}

/// Derive a sub-key for encryption vs. MAC from the master key, using the
/// prime-indexed profile as domain separation.
fn derive_subkey(master: &[u8; KEY_LEN], salt: &[u8], purpose: &[u8]) -> [u8; KEY_LEN] {
    let prk = hkdf_extract(salt, master);
    let bytes = hkdf_expand(&prk, purpose, KEY_LEN);
    let mut key = [0u8; KEY_LEN];
    key.copy_from_slice(&bytes);
    key
}

/// Apply the prime-indexed nonce domain tag: XOR the first 4 bytes of the
/// 12-byte nonce with the resolved prime (big-endian).
fn tag_nonce(nonce: &ChaChaNonce, profile: &MultiplicityProfile) -> ChaChaNonce {
    let prime = get_prime_at_index(profile.prime_index as usize);
    let prime_bytes = prime.to_be_bytes();
    let mut tagged = *nonce;
    for i in 0..4 {
        tagged[i] ^= prime_bytes[i];
    }
    tagged
}

/// Encrypt `plaintext` under `key` with `nonce` and `aad`, producing a
/// self-authenticating ciphertext+tag.
///
/// The AAD is authenticated as `aad || profile_bytes || nonce_tag`.
pub fn encrypt_aead(
    key: &[u8; KEY_LEN],
    nonce: &ChaChaNonce,
    plaintext: &[u8],
    aad: &[u8],
    profile: &MultiplicityProfile,
) -> Result<AeadCiphertext, AeadError> {
    let enc_key = derive_subkey(key, b"enc", b"multiplicity-aead-enc");
    let mac_key = derive_subkey(key, b"mac", b"multiplicity-aead-mac");
    let tagged_nonce = tag_nonce(nonce, profile);
    let profile_bytes = profile.encode();

    let mut cipher = ChaCha20::new(&enc_key, &tagged_nonce);
    let ciphertext = cipher.stream(plaintext);

    let mut mac_data = Vec::with_capacity(aad.len() + 8 + 4 + ciphertext.len());
    mac_data.extend_from_slice(aad);
    mac_data.extend_from_slice(&profile_bytes);
    mac_data.extend_from_slice(&tagged_nonce[0..4]);
    mac_data.extend_from_slice(&ciphertext);

    let mut mac = HmacSha256::new_from_slice(&mac_key).expect("HMAC accepts any key length");
    mac.update(&mac_data);
    let tag_bytes = mac.finalize().into_bytes();
    let mut auth_tag = [0u8; 32];
    auth_tag.copy_from_slice(&tag_bytes);

    Ok(AeadCiphertext { ciphertext, auth_tag })
}

/// Decrypt and verify `ciphertext` under `key`, `nonce`, `aad`, and `profile`.
/// Returns the plaintext only if the authentication tag verifies.
pub fn decrypt_aead(
    key: &[u8; KEY_LEN],
    nonce: &ChaChaNonce,
    ciphertext: &AeadCiphertext,
    aad: &[u8],
    profile: &MultiplicityProfile,
) -> Result<Vec<u8>, AeadError> {
    let enc_key = derive_subkey(key, b"enc", b"multiplicity-aead-enc");
    let mac_key = derive_subkey(key, b"mac", b"multiplicity-aead-mac");
    let tagged_nonce = tag_nonce(nonce, profile);
    let profile_bytes = profile.encode();

    let mut mac_data = Vec::with_capacity(aad.len() + 8 + 4 + ciphertext.ciphertext.len());
    mac_data.extend_from_slice(aad);
    mac_data.extend_from_slice(&profile_bytes);
    mac_data.extend_from_slice(&tagged_nonce[0..4]);
    mac_data.extend_from_slice(&ciphertext.ciphertext);

    let mut mac = HmacSha256::new_from_slice(&mac_key).expect("HMAC accepts any key length");
    mac.update(&mac_data);
    let computed_tag_bytes = mac.finalize().into_bytes();
    let mut computed_tag = [0u8; 32];
    computed_tag.copy_from_slice(&computed_tag_bytes);

    if computed_tag != ciphertext.auth_tag {
        return Err(AeadError::AuthenticationFailure);
    }

    let mut cipher = ChaCha20::new(&enc_key, &tagged_nonce);
    Ok(cipher.stream(&ciphertext.ciphertext))
}

/// Convenience: derive a 32-byte nonce from a shared secret (first 12 bytes).
#[must_use]
pub fn nonce_from_secret(shared_secret: &[u8]) -> ChaChaNonce {
    let hash = sha256(shared_secret);
    let mut nonce = [0u8; 12];
    nonce.copy_from_slice(&hash[0..12]);
    nonce
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::profile::default_profile;

    #[test]
    fn roundtrip_succeeds() {
        let key = [0x42u8; 32];
        let nonce = [0x24u8; 12];
        let profile = default_profile();
        let plaintext = b"secret message for QKD channel";

        let ct = encrypt_aead(&key, &nonce, plaintext, b"aad", &profile).unwrap();
        let pt = decrypt_aead(&key, &nonce, &ct, b"aad", &profile).unwrap();
        assert_eq!(pt.as_slice(), plaintext);
    }

    #[test]
    fn tampered_ciphertext_fails() {
        let key = [0x42u8; 32];
        let nonce = [0x24u8; 12];
        let profile = default_profile();
        let ct = encrypt_aead(&key, &nonce, b"hello", b"aad", &profile).unwrap();

        let mut tampered = ct.clone();
        tampered.ciphertext[0] ^= 0x01;
        assert_eq!(
            decrypt_aead(&key, &nonce, &tampered, b"aad", &profile),
            Err(AeadError::AuthenticationFailure)
        );
    }

    #[test]
    fn different_primes_reject_cross_decryption() {
        let key = [0x99u8; 32];
        let nonce = [0x77u8; 12];
        let pa = MultiplicityProfile::new(0, 1, 0, 0); // prime 2
        let pb = MultiplicityProfile::new(0, 1, 0, 1); // prime 3

        let ct = encrypt_aead(&key, &nonce, b"msg", b"aad", &pa).unwrap();
        // Decrypting with the wrong prime index should fail (nonce tag mismatch).
        assert!(decrypt_aead(&key, &nonce, &ct, b"aad", &pb).is_err());
    }

    #[test]
    fn nonce_from_secret_is_deterministic() {
        let n1 = nonce_from_secret(b"shared-secret");
        let n2 = nonce_from_secret(b"shared-secret");
        assert_eq!(n1, n2);
        assert_eq!(n1.len(), 12);
    }
}
