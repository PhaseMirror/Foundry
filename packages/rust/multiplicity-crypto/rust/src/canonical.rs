//! BCS canonical serialization for the multiplicity envelope wire format.
//!
//! Ported from `pirtm-engine/src/canonical.rs` (ADR-0066 §"Universal BCS
//! Packing Rules"). The envelope carries CRMF event telemetry with fixed field
//! order, big-endian integers, and a ULEB128/u32 length-prefixed metadata
//! vector.
//!
//! Two serialization surfaces:
//! 1. [`CanonicalEnvelope::to_canonical_bytes`] / [`from_canonical_bytes`] —
//!    the byte-exact ADR wire format used for Poseidon2 absorption.
//! 2. `serde` + `bcs` — the same struct derives `Serialize`/`Deserialize`.

use crate::commitment::Digest32;
use crate::poseidon2::Poseidon2Sponge;
use serde::{Deserialize, Serialize};

/// Width of the fixed envelope header.
pub const FIXED_FIELD_WIDTH: usize = 32 /* envelope_id */ + 8 /* timestamp */ + 32 /* poseidon_commitment */ + 32 /* sha256_anchor */ + 64 /* signature */ + 8 /* lambda_m */ + 8 /* drift */;

/// Minimum encoded length (fixed fields + 4-byte length prefix + empty metadata).
pub const MIN_ENVELOPE_LEN: usize = FIXED_FIELD_WIDTH + 4;

const _: () = assert!(FIXED_FIELD_WIDTH == 184);

/// Scaled contractivity invariant: `Λ_m < CONTRACTIVITY_SCALE`.
pub const CONTRACTIVITY_SCALE: u64 = 1_000_000_000;
/// Scaled drift limit.
pub const DRIFT_LIMIT_SCALED: u64 = 30_000_000;

/// Error type for canonical en/decode failures.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum CanonicalError {
    #[error("truncated envelope byte stream")]
    Truncated,
    #[error("metadata length prefix does not match remaining bytes")]
    LengthMismatch,
    #[error("lambda_m >= CONTRACTIVITY_SCALE (non-contractive manifold)")]
    NonContractiveLambda,
    #[error("drift exceeds DRIFT_LIMIT_SCALED")]
    DriftBreach,
}

/// Fixed-point metrics block carried by the envelope.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct EnvelopeMetrics {
    /// Fixed-point contractivity invariant `Λ_m` (`Λ_m < 1` ⇔ `lambda_m < SCALE`).
    pub lambda_m: u64,
    /// Bounded execution drift limit.
    pub drift: u64,
}

impl EnvelopeMetrics {
    #[must_use]
    pub const fn new(lambda_m: u64, drift: u64) -> Self {
        Self { lambda_m, drift }
    }

    /// The envelope is contractive iff `Λ_m < 1.0` (scaled `lambda_m < SCALE`).
    #[must_use]
    pub const fn is_contractive(&self) -> bool {
        self.lambda_m < CONTRACTIVITY_SCALE
    }

    /// The envelope's drift is within bounds iff `drift ≤ DRIFT_LIMIT_SCALED`.
    #[must_use]
    pub const fn drift_within_bounds(&self) -> bool {
        self.drift <= DRIFT_LIMIT_SCALED
    }
}

/// The canonical envelope: a tamper-evident CRMF event payload.
///
/// Field order mirrors the ADR byte sequence exactly (fixed order,
/// big-endian integers, length-prefixed metadata).
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CanonicalEnvelope {
    /// Fixed 256-bit SHA-256 digest of the sealed event fields.
    pub envelope_id: Digest32,
    /// Epoch integer (`u64` BE).
    pub timestamp: u64,
    /// Poseidon2 sponge commitment mapped to the BN254 scalar field output.
    pub poseidon_commitment: Digest32,
    /// Canonical payload digest (SHA-256 anchor).
    pub sha256_anchor: Digest32,
    /// Ed25519 local-enterprise attestation (64 bytes).
    #[serde(with = "serde_big_array::BigArray")]
    pub ed25519_signature: [u8; 64],
    /// Fixed-point contractivity + drift bounds.
    pub metrics: EnvelopeMetrics,
    /// Arbitrary telemetry fingerprints (big-endian length-prefixed).
    pub metadata: Vec<u8>,
}

impl CanonicalEnvelope {
    /// Deterministic canonical byte length for a given metadata length.
    #[inline]
    #[must_use]
    pub const fn canonical_len(metadata_len: usize) -> usize {
        FIXED_FIELD_WIDTH + 4 + metadata_len
    }

    /// Serialize to the canonical ADR byte sequence (fixed order, big-endian).
    #[must_use]
    pub fn to_canonical_bytes(&self) -> Vec<u8> {
        let mlen = u32::try_from(self.metadata.len())
            .expect("metadata length exceeds u32 ceiling");
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

    /// Parse a canonical ADR byte stream.
    pub fn from_canonical_bytes(bytes: &[u8]) -> Result<Self, CanonicalError> {
        if bytes.len() < MIN_ENVELOPE_LEN {
            return Err(CanonicalError::Truncated);
        }
        let mlen = u32::from_be_bytes(
            bytes[FIXED_FIELD_WIDTH..FIXED_FIELD_WIDTH + 4]
                .try_into()
                .expect("4-byte window under guard"),
        ) as usize;
        if bytes.len() != FIXED_FIELD_WIDTH + 4 + mlen {
            return Err(CanonicalError::LengthMismatch);
        }
        Ok(Self {
            envelope_id: bytes[0..32].try_into().expect("32-byte slice under guard"),
            timestamp: u64::from_be_bytes(bytes[32..40].try_into().expect("8-byte slice under guard")),
            poseidon_commitment: bytes[40..72].try_into().expect("32-byte slice under guard"),
            sha256_anchor: bytes[72..104].try_into().expect("32-byte slice under guard"),
            ed25519_signature: bytes[104..168].try_into().expect("64-byte slice under guard"),
            metrics: EnvelopeMetrics {
                lambda_m: u64::from_be_bytes(bytes[168..176].try_into().expect("8-byte slice under guard")),
                drift: u64::from_be_bytes(bytes[176..184].try_into().expect("8-byte slice under guard")),
            },
            metadata: bytes[MIN_ENVELOPE_LEN..].to_vec(),
        })
    }

    /// The Poseidon2 `crmf_validity_seal` over the canonical byte stream.
    #[must_use]
    pub fn poseidon_seal(&self) -> Digest32 {
        Poseidon2Sponge::seal(&self.to_canonical_bytes())
    }

    /// The SHA-256 anchor of the canonical byte stream.
    #[must_use]
    pub fn sha256_anchor(&self) -> Digest32 {
        crate::commitment::sha256(&self.to_canonical_bytes())
    }

    /// Enforce the fail-closed contractivity + drift gates (ADR-0066 §The Veto Gate).
    pub fn validate_contractivity(&self) -> Result<(), CanonicalError> {
        if !self.metrics.is_contractive() {
            return Err(CanonicalError::NonContractiveLambda);
        }
        if !self.metrics.drift_within_bounds() {
            return Err(CanonicalError::DriftBreach);
        }
        Ok(())
    }
}

/// Compute the 256-bit Poseidon2 seal over a canonical envelope's byte stream.
#[must_use]
pub fn canonical_seal(env: &CanonicalEnvelope) -> Digest32 {
    env.poseidon_seal()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> CanonicalEnvelope {
        CanonicalEnvelope {
            envelope_id: [0x11; 32],
            timestamp: 0x0102_0304_0506_0708,
            poseidon_commitment: [0x22; 32],
            sha256_anchor: [0x33; 32],
            ed25519_signature: [0x44; 64],
            metrics: EnvelopeMetrics::new(0x5555_5555_5555_5555, 0x6666_6666_6666_6666),
            metadata: vec![0x77, 0x88, 0x99],
        }
    }

    #[test]
    fn field_widths_are_exact() {
        assert_eq!(FIXED_FIELD_WIDTH, 184);
        assert_eq!(CanonicalEnvelope::canonical_len(0), 188);
        assert_eq!(CanonicalEnvelope::canonical_len(3), 191);
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
        let decoded = CanonicalEnvelope::from_canonical_bytes(&env.to_canonical_bytes()).unwrap();
        assert_eq!(decoded, env);
    }

    #[test]
    fn rejects_truncated_stream() {
        let bytes = sample().to_canonical_bytes();
        assert!(CanonicalEnvelope::from_canonical_bytes(&bytes[..bytes.len() - 1]).is_err());
    }

    #[test]
    fn rejects_tampered_length_prefix() {
        let mut bytes = sample().to_canonical_bytes();
        bytes[185] = 7;
        assert!(CanonicalEnvelope::from_canonical_bytes(&bytes).is_err());
    }

    #[test]
    fn contractivity_gate_rejects_expansive_lambda() {
        let env = CanonicalEnvelope {
            metrics: EnvelopeMetrics::new(CONTRACTIVITY_SCALE, 0),
            ..sample()
        };
        assert_eq!(env.validate_contractivity(), Err(CanonicalError::NonContractiveLambda));
    }

    #[test]
    fn contractivity_gate_accepts_contractive() {
        let env = CanonicalEnvelope {
            metrics: EnvelopeMetrics::new(CONTRACTIVITY_SCALE - 1, 0),
            ..sample()
        };
        assert!(env.validate_contractivity().is_ok());
    }

    #[test]
    fn poseidon_seal_is_deterministic() {
        let env = sample();
        assert_eq!(env.poseidon_seal(), env.poseidon_seal());
    }
}
