//! Canonical BCS packing of the ADR-0066 CRMF `UnsignedCrmfEnvelope`.
//!
//! Implements the **Universal BCS Packing Rules** mandated by ADR-0066
//! §"1. Universal BCS Packing Rules" (and its parent ADR-0013):
//!
//! * **Fixed field order** — fields are packed consecutively in declaration
//!   order, labels stripped;
//! * **Deterministic integer types** — floating point is structurally
//!   excluded; integers are packed as unsigned, big-endian values;
//! * **Length-prefixed sequences** — `metadata: Vec<u8>` is prefixed by its
//!   `u32` big-endian element count.
//!
//! Two serialization surfaces are exposed:
//!
//! 1. [`UnsignedCrmfEnvelope::to_canonical_bytes`] / [`from_canonical_bytes`]
//!    — the byte-exact ADR wire format used for Poseidon2 absorption.
//! 2. `serde` + the `bcs` crate — the same struct derives
//!    `Serialize`/`Deserialize`, so the ADR's Kani harness can prove
//!    `(bcs::to_bytes(a) == bcs::to_bytes(b)) == (a == b)`.
//!
//! Field order, widths, and the 184-byte fixed header are compile-time
//! constant-checked (`FIXED_FIELD_WIDTH == 184`).

use serde::{Deserialize, Serialize};
use serde_big_array::BigArray;

use crate::poseidon2::Poseidon2Sponge;

/// Width of the fixed header: id[32] + ts[8] + poseidon[32] + sha[32] +
/// sig[64] + lambda_m[8] + drift[8] = 184.
pub const FIXED_FIELD_WIDTH: usize = 32 + 8 + 32 + 32 + 64 + 8 + 8;

/// Width of the metadata length prefix (`u32` big-endian).
pub const LENGTH_PREFIX_WIDTH: usize = 4;

/// Minimum encoded length of an envelope with empty metadata.
pub const MIN_ENVELOPE_LEN: usize = FIXED_FIELD_WIDTH + LENGTH_PREFIX_WIDTH;

const _: () = assert!(FIXED_FIELD_WIDTH == 184);

/// Error type for canonical en/decode failures.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum CanonicalError {
    #[error("truncated UnsignedCrmfEnvelope byte stream")]
    Truncated,
    #[error("metadata length prefix does not match the remaining bytes")]
    LengthMismatch,
    #[error("BCS serialization failed: {0}")]
    Bcs(String),
}

/// Scalars carried by the envelope's metrics block. Both are scaled unsigned
/// integers; the contractivity invariant is `lambda_m < CONTRACTIVITY_SCALE`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct MetricBounds {
    /// Fixed-point representation of the contractivity invariant `Λ_m`.
    pub lambda_m: u64,
    /// Bounded execution drift limit.
    pub drift: u64,
}

/// The canonical `UnsignedCrmfEnvelope` of ADR-0066, packed per the BCS rules.
///
/// Field order mirrors the ADR byte sequence exactly:
///
/// | # | Field | Width |
/// | --- | --- | --- |
/// | 1 | `envelope_id` (SHA-256 digest) | 32 |
/// | 2 | `timestamp` (`u64` big-endian) | 8 |
/// | 3 | `poseidon_commitment` (BN254-scalar mapping) | 32 |
/// | 4 | `sha256_anchor` (canonical payload digest) | 32 |
/// | 5 | `ed25519_signature` (enterprise attestation) | 64 |
/// | 6 | `metrics.lambda_m` | 8 |
/// | 7 | `metrics.drift` | 8 |
/// | 8 | `metadata` (ULEB128/`u32`-prefixed) | ≤ 4 + len |
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct UnsignedCrmfEnvelope {
    /// Fixed 256-bit SHA-256 digest of the sealed event fields.
    pub envelope_id: [u8; 32],
    /// Epoch integer (`u64`).
    pub timestamp: u64,
    /// Poseidon2 sponge commitment mapped to the BN254 scalar field output.
    pub poseidon_commitment: [u8; 32],
    /// Canonical payload digest (SHA-256 anchor).
    pub sha256_anchor: [u8; 32],
    /// Ed25519 local-enterprise attestation.
    #[serde(with = "BigArray")]
    pub ed25519_signature: [u8; 64],
    /// Fixed-point contractivity + drift bounds.
    pub metrics: MetricBounds,
    /// Arbitrary telemetry fingerprints (length-prefixed).
    pub metadata: Vec<u8>,
}

impl UnsignedCrmfEnvelope {
    /// Deterministic canonical byte length for a given metadata length.
    #[inline]
    #[must_use]
    pub const fn canonical_len(metadata_len: usize) -> usize {
        FIXED_FIELD_WIDTH + LENGTH_PREFIX_WIDTH + metadata_len
    }

    /// Serialize to the canonical ADR byte sequence (fixed order, big-endian).
    #[must_use]
    pub fn to_canonical_bytes(&self) -> Vec<u8> {
        let mlen = u32::try_from(self.metadata.len())
            .expect("metadata length exceeds u32, violating the BCS length ceiling");
        let mut out = Vec::with_capacity(Self::canonical_len(self.metadata.len()));
        out.extend_from_slice(&self.envelope_id);
        out.extend_from_slice(&self.timestamp.to_be_bytes());
        out.extend_from_slice(&self.poseidon_commitment);
        out.extend_from_slice(&self.sha256_anchor);
        out.extend_from_slice(&self.ed25519_signature);
        out.extend_from_slice(&self.metrics.lambda_m.to_be_bytes());
        out.extend_from_slice(&self.metrics.drift.to_be_bytes());
        out.extend_from_slice(&mlen.to_be_bytes());
        out.extend_from_slice(&self.metadata);
        debug_assert_eq!(out.len(), Self::canonical_len(self.metadata.len()));
        out
    }

    /// Parse a canonical ADR byte stream, rejecting truncated or
    /// length-mismatched inputs and any trailing garbage.
    pub fn from_canonical_bytes(bytes: &[u8]) -> Result<Self, CanonicalError> {
        if bytes.len() < MIN_ENVELOPE_LEN {
            return Err(CanonicalError::Truncated);
        }
        let mlen = u32::from_be_bytes(
            bytes[FIXED_FIELD_WIDTH..MIN_ENVELOPE_LEN]
                .try_into()
                .expect("8-byte window under length guard"),
        ) as usize;
        if bytes.len() != MIN_ENVELOPE_LEN + mlen {
            return Err(CanonicalError::LengthMismatch);
        }
        Ok(Self {
            envelope_id: bytes[0..32]
                .try_into()
                .expect("32-byte slice under length guard"),
            timestamp: u64::from_be_bytes(
                bytes[32..40].try_into().expect("8-byte slice under guard"),
            ),
            poseidon_commitment: bytes[40..72]
                .try_into()
                .expect("32-byte slice under length guard"),
            sha256_anchor: bytes[72..104]
                .try_into()
                .expect("32-byte slice under length guard"),
            ed25519_signature: bytes[104..168]
                .try_into()
                .expect("64-byte slice under length guard"),
            metrics: MetricBounds {
                lambda_m: u64::from_be_bytes(
                    bytes[168..176].try_into().expect("8-byte slice under guard"),
                ),
                drift: u64::from_be_bytes(
                    bytes[176..184].try_into().expect("8-byte slice under guard"),
                ),
            },
            metadata: bytes[MIN_ENVELOPE_LEN..].to_vec(),
        })
    }

    /// The 256-bit `crmf_validity_seal` produced by the Poseidon2 sponge
    /// (`t=9, r=8`) over the canonical byte stream. This is the value that
    /// zero-knowledge verifiers must reproduce from the BCS-packed payload.
    #[must_use]
    pub fn seal(&self) -> [u8; 32] {
        Poseidon2Sponge::seal(&self.to_canonical_bytes())
    }

    /// The SHA-256 anchor of the canonical byte stream (`sha256_anchor`).
    #[must_use]
    pub fn sha256(&self) -> [u8; 32] {
        sha256_canonical(&self.to_canonical_bytes())
    }
}

/// SHA-256 digest of a byte stream (used for `envelope_id`, `sha256_anchor`).
#[must_use]
pub fn sha256_canonical(bytes: &[u8]) -> [u8; 32] {
    use sha2::{Digest, Sha256};
    let digest = Sha256::digest(bytes);
    digest.into()
}

/// Convenience: build a canonical envelope and compute its BCS-compatible
/// serialization via the `bcs` crate (little-endian integer encoding, ULEB128
/// sequence prefixes). See module docs for the distinction from
/// `to_canonical_bytes`.
#[must_use]
pub fn bcs_to_bytes(env: &UnsignedCrmfEnvelope) -> Vec<u8> {
    bcs::to_bytes(env).expect("BCS serialization of UnsignedCrmfEnvelope is infallible")
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Field-by-field construction used only by unit tests.
    fn sample() -> UnsignedCrmfEnvelope {
        UnsignedCrmfEnvelope {
            envelope_id: [0x11; 32],
            timestamp: 0x0102_0304_0506_0708,
            poseidon_commitment: [0x22; 32],
            sha256_anchor: [0x33; 32],
            ed25519_signature: [0x44; 64],
            metrics: MetricBounds {
                lambda_m: 0x5555_5555_5555_5555,
                drift: 0x6666_6666_6666_6666,
            },
            metadata: vec![0x77, 0x88, 0x99],
        }
    }

    #[test]
    fn field_widths_are_exact() {
        assert_eq!(FIXED_FIELD_WIDTH, 184);
        assert_eq!(UnsignedCrmfEnvelope::canonical_len(0), 188);
        assert_eq!(UnsignedCrmfEnvelope::canonical_len(3), 191);
    }

    #[test]
    fn fixed_field_order_matches_adr_byte_sequence() {
        let bytes = sample().to_canonical_bytes();
        assert_eq!(&bytes[0..32], &[0x11; 32]);
        assert_eq!(&bytes[32..40], &0x0102_0304_0506_0708u64.to_be_bytes());
        assert_eq!(&bytes[40..72], &[0x22; 32]);
        assert_eq!(&bytes[72..104], &[0x33; 32]);
        assert_eq!(&bytes[104..168], &[0x44; 64]);
        assert_eq!(&bytes[168..176], &0x5555_5555_5555_5555u64.to_be_bytes());
        assert_eq!(&bytes[176..184], &0x6666_6666_6666_6666u64.to_be_bytes());
        assert_eq!(&bytes[184..188], &3u32.to_be_bytes());
        assert_eq!(&bytes[188..191], &[0x77, 0x88, 0x99]);
    }

    #[test]
    fn canonical_roundtrip() {
        let env = sample();
        let decoded = UnsignedCrmfEnvelope::from_canonical_bytes(&env.to_canonical_bytes())
            .expect("valid envelope decodes");
        assert_eq!(decoded, env);
    }

    #[test]
    fn rejects_truncated_stream() {
        let bytes = sample().to_canonical_bytes();
        assert!(UnsignedCrmfEnvelope::from_canonical_bytes(&bytes[..bytes.len() - 1]).is_err());
    }

    #[test]
    fn rejects_tampered_length_prefix() {
        let mut bytes = sample().to_canonical_bytes();
        bytes[185] = 7; // claim 7 metadata bytes while 3 are present
        assert!(UnsignedCrmfEnvelope::from_canonical_bytes(&bytes).is_err());
    }

    /// BCS (serde) and the canonical wire format are distinct encodings; both
    /// must round-trip and both must be deterministic.
    #[test]
    fn bcs_roundtrip_and_determinism() {
        let env = sample();
        let bytes = bcs_to_bytes(&env);
        assert_eq!(bytes, bcs_to_bytes(&env));
        let decoded: UnsignedCrmfEnvelope = bcs::from_bytes(&bytes).expect("bcs decodes");
        assert_eq!(decoded, env);
    }

    #[test]
    fn seal_is_deterministic_and_len_invariant() {
        let env = sample();
        assert_eq!(env.seal(), env.seal());
        // A different envelope differentiates the seal with overwhelming
        // probability; the sponge is a deterministic function.
        let mut other = sample();
        other.timestamp += 1;
        assert_ne!(env.seal(), other.seal());
        assert_eq!(env.sha256(), env.sha256());
    }
}