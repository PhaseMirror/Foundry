//! Serialization and deserialization with verified round-trips.

use crate::error::{Error, Result};

/// Encode a u64 as big-endian bytes.
pub fn encode_u64(value: u64) -> [u8; 8] {
    value.to_be_bytes()
}

/// Decode a u64 from big-endian bytes.
pub fn decode_u64(bytes: [u8; 8]) -> u64 {
    u64::from_be_bytes(bytes)
}

/// Encode an ensemble ID and element count.
pub fn encode_ensemble_header(id: u64, count: usize) -> Vec<u8> {
    let mut buf = Vec::new();
    buf.extend_from_slice(&id.to_be_bytes());
    buf.extend_from_slice(&(count as u64).to_be_bytes());
    buf
}

/// Decode an ensemble header.
pub fn decode_ensemble_header(data: &[u8]) -> Result<(u64, usize)> {
    if data.len() < 16 {
        return Err(Error::serialization_round_trip("Ensemble"));
    }
    let id = u64::from_be_bytes([data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7]]);
    let count = u64::from_be_bytes([data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]]) as usize;
    Ok((id, count))
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
    fn test_ensemble_header_round_trip() {
        let header = encode_ensemble_header(42, 10);
        let (id, count) = decode_ensemble_header(&header).unwrap();
        assert_eq!(id, 42);
        assert_eq!(count, 10);
    }
}
