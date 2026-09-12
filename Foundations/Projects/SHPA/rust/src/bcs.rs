//! Binary Canonical Serialization (BCS) & Canonical Encoding Engine

use sha2::{Digest, Sha256};

pub struct BcsSerializer;

impl BcsSerializer {
    /// Encode a positive integer using ULEB128.
    pub fn uleb128_encode(mut n: usize) -> Vec<u8> {
        let mut out = Vec::new();
        loop {
            let mut byte = (n & 0x7f) as u8;
            n >>= 7;
            if n > 0 {
                byte |= 0x80;
                out.push(byte);
            } else {
                out.push(byte);
                break;
            }
        }
        out
    }

    /// Decode ULEB128 bytes into usize.
    pub fn uleb128_decode(bytes: &[u8]) -> Option<(usize, usize)> {
        let mut result = 0usize;
        let mut shift = 0usize;
        let mut bytes_read = 0usize;

        for &byte in bytes {
            bytes_read += 1;
            result |= ((byte & 0x7f) as usize) << shift;
            if (byte & 0x80) == 0 {
                return Some((result, bytes_read));
            }
            shift += 7;
            if shift >= 64 {
                return None;
            }
        }
        None
    }

    /// Canonical BCS serialization of an operator descriptor.
    pub fn serialize_operator(
        schema_ref: &[u8; 32],
        operator_type: u8,
        scale_factor: u64,
        activation_fn: &[u8; 32],
        nesting_depth: u32,
    ) -> Vec<u8> {
        let mut buf = Vec::with_capacity(32 + 1 + 8 + 32 + 4);
        buf.extend_from_slice(schema_ref);
        buf.push(operator_type);
        buf.extend_from_slice(&scale_factor.to_le_bytes());
        buf.extend_from_slice(activation_fn);
        buf.extend_from_slice(&nesting_depth.to_le_bytes());
        buf
    }

    /// Compute SHA-256 hash of BCS-encoded operator.
    pub fn compute_operator_hash(bcs_bytes: &[u8]) -> [u8; 32] {
        let mut hasher = Sha256::new();
        hasher.update(bcs_bytes);
        hasher.finalize().into()
    }
}
