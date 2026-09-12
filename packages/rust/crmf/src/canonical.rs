//! Canonical BCS wire format for the ADR-0013 `UnsignedCrmfEnvelope`.
//!
//! Implements the byte-level packing rules mandated by
//! [`docs/adr/accepted/0013-UOR Civic Infrastructure.md`]:
//! fixed field order, unsigned big-endian integer encoding, exclusion of all
//! floating-point types, and length-prefixed sequences (u32 big-endian element
//! count). Sequence length is the deterministic `len ==
//! canonical_len(metadata.len())`.
//!
//! ## Guarantees (enforced by construction)
//! - **No floating-point fields:** `UnsignedCrmfEnvelope` is composed only of
//!   `[u8; _]` and unsigned-integer fields; there is no `f32`/`f64` in the wire
//!   type, so rounding non-determinism is structurally impossible.
//! - **Deterministic length:** `to_canonical_bytes` never exceeds
//!   `canonical_len(metadata.len())` and `from_canonical_bytes` rejects any
//!   input whose length does not match the encoded metadata length.
//! - **Fixed field order:** the byte stream is emitted in the exact ADR order.

use crate::bcs::BcsError;

/// Width of the fixed header: id[32] + ts[8] + poseidon[32] + sha[32] +
/// sig[64] + lambda_m[8] + drift[8].
pub const FIXED_FIELD_WIDTH: usize = 32 + 8 + 32 + 32 + 64 + 8 + 8;

/// Width of the metadata length prefix (u32 big-endian).
pub const LENGTH_PREFIX_WIDTH: usize = 4;

/// Minimum encoded length of an envelope with empty metadata.
pub const MIN_ENVELOPE_LEN: usize = FIXED_FIELD_WIDTH + LENGTH_PREFIX_WIDTH;

const _: () = assert!(FIXED_FIELD_WIDTH == 184);

/// Big-endian u64. Integers are packed as unsigned, big-endian values (ADR-0013
/// §"Universal BCS Packing Rules").
#[inline]
pub const fn be_u64(v: u64) -> [u8; 8] {
    v.to_be_bytes()
}

/// Big-endian u32 (used for the metadata length prefix).
#[inline]
pub const fn be_u32(v: u32) -> [u8; 4] {
    v.to_be_bytes()
}

/// Decode the big-endian u64 at `b[0..8]`.
#[inline]
pub fn read_u64_be(b: &[u8]) -> u64 {
    u64::from_be_bytes(b[..8].try_into().expect("slice of length 8"))
}

/// Decode the big-endian u32 at `b[0..4]`.
#[inline]
pub fn read_u32_be(b: &[u8]) -> u32 {
    u32::from_be_bytes(b[..4].try_into().expect("slice of length 4"))
}

/// Encode the metadata length prefix (u32 big-endian).
#[inline]
pub const fn encode_len(len: u32) -> [u8; 4] {
    be_u32(len)
}

/// ULEB128 encoding, available for general length-prefixed sequences where the
/// scheme prefers an element count over a fixed u32 length.
pub fn uleb128(v: u64) -> Vec<u8> {
    let mut out = Vec::new();
    let mut n = v;
    loop {
        let byte = (n & 0x7f) as u8;
        n >>= 7;
        if n == 0 {
            out.push(byte);
            break;
        }
        out.push(byte | 0x80);
    }
    out
}

/// Deterministic canonical byte length for a given metadata length.
#[inline]
pub fn canonical_len(metadata_len: usize) -> usize {
    FIXED_FIELD_WIDTH + LENGTH_PREFIX_WIDTH + metadata_len
}

/// Fixed-point UCC metrics carried by the envelope (ADR-0013 §"The CRMF
/// Envelope Byte Sequence"). Both fields are scaled unsigned integers; the
/// contractivity invariant is `lambda_m < CONTRACTIVITY_SCALE` (see
/// [`crate::failgate`]).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BcsMetrics {
    pub lambda_m: u64,
    pub drift: u64,
}

/// The canonical `UnsignedCrmfEnvelope` of ADR-0013.
///
/// Field order mirrors the ADR byte sequence exactly:
/// 1. `envelope_id`    — `[u8; 32]`
/// 2. `timestamp`      — `u64` (big-endian)
/// 3. `poseidon_commitment` — `[u8; 32]`
/// 4. `sha256_anchor`  — `[u8; 32]`
/// 5. `ed25519_signature` — `[u8; 64]`
/// 6. `metrics.lambda_m` — `u64`
/// 7. `metrics.drift`  — `u64`
/// 8. `metadata`       — `Vec<u8>` prefixed by its u32 length count
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct UnsignedCrmfEnvelope {
    pub envelope_id: [u8; 32],
    pub timestamp: u64,
    pub poseidon_commitment: [u8; 32],
    pub sha256_anchor: [u8; 32],
    pub ed25519_signature: [u8; 64],
    pub metrics: BcsMetrics,
    pub metadata: Vec<u8>,
}

impl UnsignedCrmfEnvelope {
    /// Serialize to the canonical ADR-0013 byte sequence.
    pub fn to_canonical_bytes(&self) -> Vec<u8> {
        let mlen = u32::try_from(self.metadata.len())
            .expect("metadata length exceeds u32, violating the BCS length ceiling");
        let mut out = Vec::with_capacity(canonical_len(self.metadata.len()));

        out.extend_from_slice(&self.envelope_id);
        out.extend_from_slice(&be_u64(self.timestamp));
        out.extend_from_slice(&self.poseidon_commitment);
        out.extend_from_slice(&self.sha256_anchor);
        out.extend_from_slice(&self.ed25519_signature);
        out.extend_from_slice(&be_u64(self.metrics.lambda_m));
        out.extend_from_slice(&be_u64(self.metrics.drift));
        out.extend_from_slice(&be_u32(mlen));
        out.extend_from_slice(&self.metadata);

        debug_assert_eq!(out.len(), canonical_len(self.metadata.len()));
        out
    }

    /// Parse a canonical ADR-0013 byte stream.
    ///
    /// Rejects truncated input, a metadata length that does not match the
    /// remaining bytes, and any trailing data (length-safe decoding).
    pub fn from_canonical_bytes(bytes: &[u8]) -> Result<Self, BcsError> {
        if bytes.len() < MIN_ENVELOPE_LEN {
            return Err(BcsError::Serialization(
                "truncated UnsignedCrmfEnvelope".to_string(),
            ));
        }
        let mlen = read_u32_be(&bytes[FIXED_FIELD_WIDTH..MIN_ENVELOPE_LEN]) as usize;
        if bytes.len() != MIN_ENVELOPE_LEN + mlen {
            return Err(BcsError::Serialization(
                "metadata length does not match remaining bytes".to_string(),
            ));
        }
        Ok(Self {
            envelope_id: bytes[0..32]
                .try_into()
                .expect("32-byte slice under length guard"),
            timestamp: read_u64_be(&bytes[32..40]),
            poseidon_commitment: bytes[40..72]
                .try_into()
                .expect("32-byte slice under length guard"),
            sha256_anchor: bytes[72..104]
                .try_into()
                .expect("32-byte slice under length guard"),
            ed25519_signature: bytes[104..168]
                .try_into()
                .expect("64-byte slice under length guard"),
            metrics: BcsMetrics {
                lambda_m: read_u64_be(&bytes[168..176]),
                drift: read_u64_be(&bytes[176..184]),
            },
            metadata: bytes[MIN_ENVELOPE_LEN..].to_vec(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_envelope() -> UnsignedCrmfEnvelope {
        UnsignedCrmfEnvelope {
            envelope_id: [0x11; 32],
            timestamp: 0x0102_0304_0506_0708,
            poseidon_commitment: [0x22; 32],
            sha256_anchor: [0x33; 32],
            ed25519_signature: [0x44; 64],
            metrics: BcsMetrics {
                lambda_m: 0x5555_5555_5555_5555,
                drift: 0x6666_6666_6666_6666,
            },
            metadata: vec![0x77, 0x88, 0x99],
        }
    }

    /// Deterministic length formula for empty metadata (ADR-0013: 184 fixed +
    /// 4 length + 0 metadata = 188).
    #[test]
    fn canonical_len_formula_adr_0013() {
        assert_eq!(FIXED_FIELD_WIDTH, 184);
        assert_eq!(canonical_len(0), 188);
        assert_eq!(canonical_len(3), 191);
    }

    /// Deterministic length formula holds for the real encoder.
    #[test]
    fn encoded_len_matches_formula_adr_0013() {
        let empty = sample_envelope();
        let empty_meta = UnsignedCrmfEnvelope {
            metadata: vec![],
            ..empty
        };
        assert_eq!(empty_meta.to_canonical_bytes().len(), 188);

        let some_meta = sample_envelope();
        assert_eq!(some_meta.to_canonical_bytes().len(), 191);
    }

    /// Fixed field order: each region of the emitted stream carries exactly the
    /// declared field, big-endian (ADR-0013 §"The CRMF Envelope Byte Sequence").
    #[test]
    fn fixed_field_order_adr_0013() {
        let bytes = sample_envelope().to_canonical_bytes();
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

    /// Canonical encode/decode roundtrip.
    #[test]
    fn roundtrip_adr_0013() {
        let env = sample_envelope();
        let decoded = UnsignedCrmfEnvelope::from_canonical_bytes(&env.to_canonical_bytes())
            .expect("valid envelope decodes");
        assert_eq!(decoded, env);
    }

    /// Length-safe decoding rejects a truncated stream (intentional failure).
    #[test]
    fn rejects_truncated_adr_0013() {
        let bytes = sample_envelope().to_canonical_bytes();
        let truncated = &bytes[..bytes.len() - 1];
        assert!(UnsignedCrmfEnvelope::from_canonical_bytes(truncated).is_err());
    }

    /// Length-safe decoding rejects a tampered metadata length (intentional
    /// failure the type system catches at runtime).
    #[test]
    fn rejects_tampered_length_adr_0013() {
        let mut bytes = sample_envelope().to_canonical_bytes();
        bytes[185] = 7; // claim 7 metadata bytes while 3 are present
        assert!(UnsignedCrmfEnvelope::from_canonical_bytes(&bytes).is_err());
    }

    /// No floating-point ambiguity anywhere in the wire type: every field is
    /// integral, and the fixed width is compile-time checked.
    #[test]
    fn no_float_fields_adr_0013() {
        assert_eq!(core::mem::size_of::<BcsMetrics>(), 16);
        // The envelope type itself contains no f32/f64; this is structural.
        let env = sample_envelope();
        let _: u64 = env.metrics.lambda_m;
        let _: u64 = env.metrics.drift;
        let _: u64 = env.timestamp;
    }

    /// ULEB128 primitive matches the u32 length prefix value for small counts.
    #[test]
    fn uleb128_basic_adr_0013() {
        assert_eq!(uleb128(0), vec![0x00]);
        assert_eq!(uleb128(3), vec![0x03]);
        assert_eq!(uleb128(128), vec![0x80, 0x01]);
        assert_eq!(uleb128(16_384), vec![0x80, 0x80, 0x01]);
    }
}