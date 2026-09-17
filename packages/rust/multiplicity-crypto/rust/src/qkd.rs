//! QKD pipeline composition root (QKD Hybrid Encryption v1.0.1, ADR-007).
//!
//! Sequential composition: `computeTranscript → deriveKey → computeCommitment → encryptAEAD`.
//!
//! Mirrors `ts/src/qkd.ts` `simulateQKD`: the pipeline accepts a role, context,
//! multiplicity profile, and simulated QKD shared secret, then derives a
//! context hash, a prime-indexed HKDF key, a domain-separated commitment over
//! that key, and finally authenticates the commitment under an AEAD layer
//! sealed with the derived key.

use crate::aead::{AeadCiphertext, encrypt_aead, nonce_from_secret};
use crate::commitment::compute_commitment;
use crate::kdf::{DeriveKeyInput, DeriveKeyOutput, Role, derive_key};
use crate::profile::MultiplicityProfile;
use crate::transcript::compute_transcript;

/// The role in the QKD protocol.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum QkdRole {
    A,
    B,
}

impl QkdRole {
    #[must_use]
    pub fn to_kdf_role(self) -> Role {
        match self {
            Self::A => Role::A2B,
            Self::B => Role::B2A,
        }
    }
}

/// Input to the QKD simulator pipeline.
#[derive(Debug, Clone)]
pub struct QkdInput<'a> {
    pub role: QkdRole,
    pub context: &'a [u8],
    pub profile: MultiplicityProfile,
    pub shared_secret: &'a [u8],
}

/// Output of the QKD simulator pipeline.
#[derive(Debug, Clone)]
pub struct QkdOutput {
    pub simulated_key: [u8; 32],
    pub context_hash: Vec<u8>,
    pub commitment: crate::commitment::CommitmentOutput,
    pub ciphertext: AeadCiphertext,
    pub label: &'static str,
}

/// Run the full QKD pipeline:
///
/// 1. **Transcript** — SHA-256 hash chain establishes the context hash and
///    enforces the ADR-013 monotonicity guard (`finalPrimeIndex ≥ input.prime_index`).
/// 2. **Key derivation** — prime-indexed HKDF-SHA256 over the context hash.
/// 3. **Commitment** — domain-separated HMAC-SHA256 commitment over the derived key.
/// 4. **AEAD** — ChaCha20 + HMAC-SHA256 Encrypt-then-MAC, sealing the commitment.
///
/// Returns the derived key and a `SIMULATED_QKD` label (matching the TS spec).
///
/// # Errors
///
/// Returns [`QkdError::Transcript`] if the profile's `prime_index` regresses
/// below the pipeline entry point.
pub fn simulate_qkd(input: &QkdInput) -> Result<QkdOutput, QkdError> {
    let QkdInput {
        role,
        context,
        profile,
        shared_secret,
    } = input;

    profile.validate().map_err(QkdError::Profile)?;

    // Step 1: Transcript — establishes hash chain context.
    let transcript = compute_transcript(
        &[context],
        &[shared_secret],
        profile.version,
        profile,
        Some(profile.prime_index),
    )
    .map_err(QkdError::Transcript)?;

    let context_hash = transcript.context_hash;
    let final_prime_index = transcript.final_prime_index;

    // ADR-013 monotonicity invariant.
    if final_prime_index < profile.prime_index {
        return Err(        QkdError::PrimeRegression {
            final_prime_index,
            input: profile.prime_index,
        });
    }

    // Step 2: Key derivation — prime-indexed HKDF over transcript context.
    let kdf_input = DeriveKeyInput {
        transcript_hash: &context_hash,
        role: role.to_kdf_role(),
        profile: *profile,
        ikm: shared_secret,
        salt: None,
    };
    let DeriveKeyOutput { key, resolved_prime, .. } = derive_key(kdf_input);
    let _ = resolved_prime;

    // Step 3: Commitment — bind key to profile for auditability.
    let commitment = compute_commitment(&key, &context_hash, profile);

    // Step 4: AEAD — encrypt the commitment using the derived key.
    let nonce = nonce_from_secret(shared_secret);
    let ciphertext = encrypt_aead(
        &key,
        &nonce,
        &commitment.commitment,
        &profile.encode(),
        profile,
    )
    .map_err(QkdError::Aead)?;

    Ok(QkdOutput {
        simulated_key: key,
        context_hash: context_hash.to_vec(),
        commitment,
        ciphertext,
        label: "SIMULATED_QKD",
    })
}

/// QKD pipeline error type.
#[derive(Debug, thiserror::Error)]
pub enum QkdError {
    #[error("profile validation failed: {0}")]
    Profile(crate::profile::ProfileError),
    #[error("transcript construction failed: {0}")]
    Transcript(crate::transcript::TranscriptError),
    #[error("AEAD encryption failed: {0}")]
    Aead(crate::aead::AeadError),
    #[error("prime index regression: final {final_prime_index} < input {input}")]
    PrimeRegression { final_prime_index: u32, input: u32 },
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::profile::MultiplicityProfile;

    #[test]
    fn qkd_pipeline_is_deterministic() {
        let profile = MultiplicityProfile::new(1, 1, 0, 3);
        let input = QkdInput {
            role: QkdRole::A,
            context: b"test-context",
            profile,
            shared_secret: &[0xab; 32],
        };
        let out1 = simulate_qkd(&input).expect("pipeline succeeds");
        let out2 = simulate_qkd(&input).expect("pipeline succeeds");
        assert_eq!(out1.simulated_key, out2.simulated_key);
        assert_eq!(out1.commitment.commitment, out2.commitment.commitment);
        assert_eq!(out1.ciphertext.ciphertext.as_slice(), out2.ciphertext.ciphertext.as_slice());
        assert_eq!(out1.label, "SIMULATED_QKD");
    }

    #[test]
    fn different_roles_yield_different_keys() {
        let profile = MultiplicityProfile::new(1, 1, 0, 3);
        let shared = &[0xcd; 32];
        let out_a = simulate_qkd(&QkdInput {
            role: QkdRole::A,
            context: b"ctx",
            profile,
            shared_secret: shared,
        }).expect("A succeeds");
        let out_b = simulate_qkd(&QkdInput {
            role: QkdRole::B,
            context: b"ctx",
            profile,
            shared_secret: shared,
        }).expect("B succeeds");
        assert_ne!(out_a.simulated_key, out_b.simulated_key);
    }

    #[test]
    fn different_primes_yield_different_keys() {
        let shared = &[0xef; 32];
        let pa = simulate_qkd(&QkdInput {
            role: QkdRole::A,
            context: b"ctx",
            profile: MultiplicityProfile::new(1, 1, 0, 0),
            shared_secret: shared,
        }).expect("p0 succeeds");
        let pb = simulate_qkd(&QkdInput {
            role: QkdRole::A,
            context: b"ctx",
            profile: MultiplicityProfile::new(1, 1, 0, 1),
            shared_secret: shared,
        }).expect("p1 succeeds");
        assert_ne!(pa.simulated_key, pb.simulated_key);
    }

    #[test]
    fn roundtrip_through_aead() {
        let profile = MultiplicityProfile::new(1, 1, 0, 3);
        let out = simulate_qkd(&QkdInput {
            role: QkdRole::A,
            context: b"roundtrip-context",
            profile,
            shared_secret: &[0x42; 32],
        }).expect("pipeline succeeds");

        // Verify the AEAD ciphertext round-trips to the commitment.
        let nonce = nonce_from_secret(&[0x42; 32][..]);
        let pt = crate::aead::decrypt_aead(
            &out.simulated_key,
            &nonce,
            &out.ciphertext,
            &profile.encode(),
            &profile,
        ).expect("decrypt succeeds");
        assert_eq!(pt.as_slice(), &out.commitment.commitment[..]);
    }
}
