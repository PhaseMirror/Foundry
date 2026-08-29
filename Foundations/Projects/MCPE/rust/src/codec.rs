//! Serialization and deserialization with verified round-trips for MCPE.
//!
//! All codec implementations guarantee that `decode(encode(x)) == x`
//! for all valid inputs.

use crate::error::{Error, Result};

/// Encode a u32 as big-endian bytes.
pub fn encode_u32(value: u32) -> [u8; 4] {
    value.to_be_bytes()
}

/// Decode a u32 from big-endian bytes.
pub fn decode_u32(bytes: [u8; 4]) -> u32 {
    u32::from_be_bytes(bytes)
}

/// Encode a usize as variable-length big-endian bytes.
///
/// Format: [start_index:1][bytes...]
/// where `start_index` is the index of the first non-zero byte in the
/// 8-byte big-endian representation.
pub fn encode_usize(value: usize) -> Vec<u8> {
    let bytes = value.to_be_bytes();
    let start = bytes.iter().position(|&b| b != 0).unwrap_or(7);
    let mut buf = Vec::with_capacity(1 + (8 - start));
    buf.push(start as u8);
    buf.extend_from_slice(&bytes[start..]);
    buf
}

/// Decode a usize from variable-length big-endian bytes.
pub fn decode_usize(data: &[u8]) -> Result<usize> {
    if data.is_empty() {
        return Err(Error::serialization_round_trip("usize"));
    }
    let start = data[0] as usize;
    if start >= 8 || data.len() < 2 {
        return Err(Error::serialization_round_trip("usize"));
    }
    let mut bytes = [0u8; 8];
    let payload_len = data.len() - 1;
    bytes[8 - payload_len..].copy_from_slice(&data[1..]);
    Ok(usize::from_be_bytes(bytes))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_u32_round_trip() {
        let values = [0u32, 1, 255, 256, 0xFFFF, 0xFFFF_FFFF];
        for &val in &values {
            let encoded = encode_u32(val);
            let decoded = decode_u32(encoded);
            assert_eq!(val, decoded);
        }
    }

    #[test]
    fn test_usize_round_trip() {
        let values = [0usize, 1, 255, 256, 0xFFFF, 0xFFFF_FFFF_FFFF_FFFF];
        for &val in &values {
            let encoded = encode_usize(val);
            let decoded = decode_usize(&encoded).unwrap();
            assert_eq!(val, decoded);
        }
    }
}
