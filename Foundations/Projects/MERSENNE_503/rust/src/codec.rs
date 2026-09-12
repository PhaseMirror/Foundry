//! Serialization and deserialization with verified round-trips.
//!
//! All codec implementations guarantee `decode(encode(x)) == x`
//! for all valid inputs.

use crate::error::{Error, Result};

/// Encode a u64 as big-endian bytes.
pub fn encode_u64(value: u64) -> [u8; 8] {
    value.to_be_bytes()
}

/// Decode a u64 from big-endian bytes.
pub fn decode_u64(bytes: [u8; 8]) -> u64 {
    u64::from_be_bytes(bytes)
}

/// Encode a Mersenne503 field element.
pub fn encode_mersenne(value: &[u64; 8]) -> Vec<u8> {
    let mut buf = Vec::with_capacity(64);
    for &limb in value {
        buf.extend_from_slice(&limb.to_be_bytes());
    }
    buf
}

/// Decode a Mersenne503 field element.
pub fn decode_mersenne(data: &[u8]) -> Result<[u64; 8]> {
    if data.len() != 64 {
        return Err(Error::serialization_round_trip("Mersenne503"));
    }
    let mut limbs = [0u64; 8];
    for (i, chunk) in data.chunks(8).enumerate() {
        let mut val = 0u64;
        for &b in chunk {
            val = (val << 8) | b as u64;
        }
        limbs[i] = val;
    }
    Ok(limbs)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_u64_round_trip() {
        let values = [0u64, 1, 255, 256, 0xFFFF, u64::MAX];
        for &val in &values {
            let encoded = encode_u64(val);
            let decoded = decode_u64(encoded);
            assert_eq!(val, decoded);
        }
    }

    #[test]
    fn test_mersenne_round_trip() {
        let original = [1u64, 2, 3, 4, 5, 6, 7, 8];
        let encoded = encode_mersenne(&original);
        let decoded = decode_mersenne(&encoded).unwrap();
        assert_eq!(original, decoded);
    }
}
