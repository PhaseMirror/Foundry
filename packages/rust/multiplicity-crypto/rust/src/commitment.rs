//! Domain-separated commitment primitives.
//!
//! Mirrors `ts/src/commitment.ts` and the ADR-0066 CRMF seal semantics.
//! Two backends are provided:
//!
//! - **HMAC-SHA256** (default): deterministic, domain-separated, and
//!   suitable for audit logs and non-ZK contexts.
//! - **Poseidon2 sponge** (ZK-compatible): the 256-bit `crmf_validity_seal`
//!   used by zero-knowledge verifiers.
//!
//! The domain tag `PM-COMMIT-p{prime}` ensures commitments at different
//! prime indices are non-interchangeable (matching the TypeScript comment
//! in `commitment.ts`).

use crate::poseidon2::Poseidon2Sponge;
use crate::profile::MultiplicityProfile;
use crate::prime::get_prime_at_index;
use hmac::{Hmac, Mac};
use sha2::{Digest, Sha256};

type HmacSha256 = Hmac<Sha256>;

/// A 32-byte commitment digest.
pub type Digest32 = [u8; 32];

/// Domain-separator for HMAC-SHA256 commitments: `PM-COMMIT-p{prime}`.
fn domain_tag(profile: &MultiplicityProfile) -> Vec<u8> {
    let prime = get_prime_at_index(profile.prime_index as usize);
    let mut tag = b"PM-COMMIT-p".to_vec();
    tag.extend_from_slice(&prime.to_be_bytes());
    tag
}

/// Compute a domain-separated commitment over `message || randomness`.
///
/// Uses HMAC-SHA256 keyed by the domain tag, so commitments derived at
/// different prime indices are cryptographically non-interchangeable.
#[must_use]
pub fn compute_commitment(
    message: &[u8],
    randomness: &[u8],
    profile: &MultiplicityProfile,
) -> CommitmentOutput {
    let tag = domain_tag(profile);
    let mut mac = HmacSha256::new_from_slice(&tag).expect("domain tag is non-empty");
    mac.update(message);
    mac.update(randomness);
    let bytes = mac.finalize().into_bytes();
    let mut commitment = [0u8; 32];
    commitment.copy_from_slice(&bytes);
    CommitmentOutput {
        commitment,
        domain_tag: tag,
    }
}

/// Verify a commitment matches `message || randomness` at the given profile.
#[must_use]
pub fn verify_commitment(
    commitment: &CommitmentOutput,
    message: &[u8],
    randomness: &[u8],
    profile: &MultiplicityProfile,
) -> bool {
    let expected = compute_commitment(message, randomness, profile);
    expected.commitment == commitment.commitment
}

/// Output of [`compute_commitment`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommitmentOutput {
    pub commitment: Digest32,
    pub domain_tag: Vec<u8>,
}

/// Poseidon2-based commitment (ZK-compatible seal).
///
/// Absorbs `message || randomness || domain_tag` into the Poseidon2 sponge
/// (`t=9, r=8`, M61 field) and squeezes a 256-bit commitment.
#[must_use]
pub fn poseidon_commitment(message: &[u8], randomness: &[u8], profile: &MultiplicityProfile) -> Digest32 {
    let tag = domain_tag(profile);
    let mut sponge = Poseidon2Sponge::new();
    sponge.absorb(message);
    sponge.absorb(randomness);
    sponge.absorb(&tag);
    sponge.squeeze_bytes32()
}

/// Raw SHA-256 digest of a byte stream.
#[must_use]
pub fn sha256(bytes: &[u8]) -> Digest32 {
    let digest = Sha256::digest(bytes);
    let mut out = [0u8; 32];
    out.copy_from_slice(&digest);
    out
}

/// Commitment error type.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum CommitmentError {
    #[error("commitment mismatch")]
    Mismatch,
}

/// A domain-separated commitment value.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Commitment {
    pub bytes: Digest32,
    pub profile: MultiplicityProfile,
    pub backend: CommitmentBackend,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CommitmentBackend {
    HmacSha256,
    Poseidon2,
}

impl Commitment {
    #[must_use]
    pub fn new(message: &[u8], randomness: &[u8], profile: MultiplicityProfile, backend: CommitmentBackend) -> Self {
        let bytes = match backend {
            CommitmentBackend::HmacSha256 => compute_commitment(message, randomness, &profile).commitment,
            CommitmentBackend::Poseidon2 => poseidon_commitment(message, randomness, &profile),
        };
        Self { bytes, profile, backend }
    }

    #[must_use]
    pub fn verify(&self, message: &[u8], randomness: &[u8]) -> bool {
        let recomputed = Self::new(message, randomness, self.profile, self.backend);
        recomputed.bytes == self.bytes
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::profile::{default_profile, MultiplicityProfile};

    #[test]
    fn commitment_is_deterministic() {
        let profile = default_profile();
        let c1 = compute_commitment(b"msg", b"rand", &profile);
        let c2 = compute_commitment(b"msg", b"rand", &profile);
        assert_eq!(c1.commitment, c2.commitment);
    }

    #[test]
    fn different_primes_yield_different_commitments() {
        let pa = MultiplicityProfile::new(0, 1, 0, 0); // prime 2
        let pb = MultiplicityProfile::new(0, 1, 0, 1); // prime 3
        let ca = compute_commitment(b"msg", b"rand", &pa);
        let cb = compute_commitment(b"msg", b"rand", &pb);
        assert_ne!(ca.commitment, cb.commitment);
    }

    #[test]
    fn domain_tag_encodes_resolved_prime() {
        let p = MultiplicityProfile::new(0, 1, 0, 3); // prime 7
        let tag = domain_tag(&p);
        assert!(tag.starts_with(b"PM-COMMIT-p"));
        // The last 4 bytes are the prime (7) in big-endian.
        assert_eq!(&tag[tag.len() - 4..], &7u32.to_be_bytes());
    }

    #[test]
    fn commitment_verifies() {
        let profile = default_profile();
        let c = compute_commitment(b"message", b"randomness", &profile);
        assert!(verify_commitment(&c, b"message", b"randomness", &profile));
        assert!(!verify_commitment(&c, b"tampered", b"randomness", &profile));
    }

    #[test]
    fn sha256_matches_std() {
        let expected = sha2::Sha256::digest(b"hello");
        let got = sha256(b"hello");
        assert_eq!(&got[..], expected.as_slice());
    }
}
