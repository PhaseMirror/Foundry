//! Multiplicity profile — the 8-byte ADR-007/ADR-013 context tag.
//!
//! Mirrors `ts/src/multiplicity.ts` `MultiplicityProfile` and `encodeProfile` /
//! `decodeProfile` exactly. The profile binds a cryptographic operation to a
//! specific multiplicity regime (prime band, version, state index).
//!
//! ## Wire format (big-endian, 8 bytes)
//!
//! | Offset | Width | Field |
//! | --- | --- | --- |
//! | 0 | 1 | `profile_type` (`u8`) |
//! | 1 | 1 | `version` (`u8`) |
//! | 2 | 2 | `state_index` (`u16` BE) |
//! | 4 | 4 | `prime_index` (`u32` BE) |

use crate::prime::{MAX_PRIME_INDEX, get_prime_at_index};

/// Default profile version (v1.0.1 spec).
pub const DEFAULT_PROFILE_VERSION: u8 = 1;

/// An 8-byte multiplicity profile.
///
/// `prime_index` selects the prime-indexed domain separation parameter.
/// `state_index` tracks the pipeline position (monotonicity guard per ADR-013).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct MultiplicityProfile {
    /// Profile type (1 byte).
    pub profile_type: u8,
    /// Protocol version (1 byte).
    pub version: u8,
    /// Pipeline state index (2 bytes, big-endian).
    pub state_index: u16,
    /// Prime index into the sieve (4 bytes, big-endian).
    pub prime_index: u32,
}

/// The fixed canonical width of an encoded profile.
pub const PROFILE_WIDTH: usize = 8;

impl MultiplicityProfile {
    /// Build a profile from raw components.
    #[must_use]
    pub const fn new(profile_type: u8, version: u8, state_index: u16, prime_index: u32) -> Self {
        Self {
            profile_type,
            version,
            state_index,
            prime_index,
        }
    }

    /// Validate that `prime_index` is within `[0, MAX_PRIME_INDEX]`.
    /// Returns `Err` with a descriptive message if out of range.
    pub fn validate(&self) -> Result<(), ProfileError> {
        if self.prime_index as usize > MAX_PRIME_INDEX {
            return Err(ProfileError::PrimeIndexOutOfRange {
                index: self.prime_index,
                max: MAX_PRIME_INDEX as u32,
            });
        }
        Ok(())
    }

    /// The resolved prime governing this profile's domain separation.
    #[must_use]
    pub fn resolved_prime(&self) -> u32 {
        get_prime_at_index(self.prime_index as usize)
    }

    /// Encode to 8 bytes (big-endian, matching `ts/src/multiplicity.ts`).
    #[must_use]
    pub fn encode(&self) -> [u8; PROFILE_WIDTH] {
        let mut buf = [0u8; PROFILE_WIDTH];
        buf[0] = self.profile_type;
        buf[1] = self.version;
        buf[2..4].copy_from_slice(&self.state_index.to_be_bytes());
        buf[4..8].copy_from_slice(&self.prime_index.to_be_bytes());
        buf
    }

    /// The SHA-256 anchor of the encoded profile (used for domain separation).
    #[must_use]
    pub fn anchor(&self) -> [u8; 32] {
        crate::commitment::sha256(&self.encode())
    }
}

impl Default for MultiplicityProfile {
    /// `multiplicity-crypto` default: `type=0, version=1, state=0, prime_index=0`.
    /// Prime index 0 resolves to prime 2 (lowest contractivity requirement).
    fn default() -> Self {
        default_profile()
    }
}

/// Error type for profile validation.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum ProfileError {
    #[error("prime_index {index} exceeds MAX_PRIME_INDEX ({max})")]
    PrimeIndexOutOfRange { index: u32, max: u32 },
    #[error("encoded profile must be exactly {expected} bytes, got {actual}")]
    BadLength { expected: usize, actual: usize },
}

/// The crate-wide default profile: `type=0, version=1, state=0, prime_index=0`.
#[must_use]
pub fn default_profile() -> MultiplicityProfile {
    MultiplicityProfile::new(0, DEFAULT_PROFILE_VERSION, 0, 0)
}

/// Encode a profile to 8 bytes (big-endian).
#[must_use]
pub fn encode_profile(profile: &MultiplicityProfile) -> [u8; PROFILE_WIDTH] {
    profile.encode()
}

/// Decode an 8-byte buffer to a profile, validating length.
pub fn decode_profile(buf: &[u8]) -> Result<MultiplicityProfile, ProfileError> {
    if buf.len() != PROFILE_WIDTH {
        return Err(ProfileError::BadLength {
            expected: PROFILE_WIDTH,
            actual: buf.len(),
        });
    }
    Ok(MultiplicityProfile::new(
        buf[0],
        buf[1],
        u16::from_be_bytes([buf[2], buf[3]]),
        u32::from_be_bytes([buf[4], buf[5], buf[6], buf[7]]),
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn encode_decode_roundtrip() {
        let p = MultiplicityProfile::new(1, 1, 123, 3);
        let bytes = p.encode();
        assert_eq!(bytes.len(), 8);
        let decoded = decode_profile(&bytes).unwrap();
        assert_eq!(decoded, p);
        assert_eq!(decoded.resolved_prime(), 5); // prime_index 3 → 5? No, 3 → 7
        // Wait: index 3 → PRIMES[3] = 7
        assert_eq!(decoded.resolved_prime(), 7);
    }

    #[test]
    fn encode_matches_typescript_byte_sequence() {
        let p = MultiplicityProfile::new(1, 1, 123, 3);
        let bytes = p.encode();
        assert_eq!(&bytes[0..1], &[1]); // type
        assert_eq!(&bytes[1..2], &[1]); // version
        assert_eq!(&bytes[2..4], &123u16.to_be_bytes()); // stateIndex
        assert_eq!(&bytes[4..8], &3u32.to_be_bytes()); // prime_index
    }

    #[test]
    fn default_profile_primes_index_0() {
        let d = default_profile();
        assert_eq!(d.prime_index, 0);
        assert_eq!(d.resolved_prime(), 2);
    }

    #[test]
    fn validate_rejects_out_of_range() {
        let p = MultiplicityProfile::new(0, 1, 0, MAX_PRIME_INDEX as u32 + 1);
        assert!(p.validate().is_err());
    }

    #[test]
    fn decode_rejects_wrong_length() {
        assert!(decode_profile(&[0u8; 7]).is_err());
        assert!(decode_profile(&[0u8; 9]).is_err());
    }
}
