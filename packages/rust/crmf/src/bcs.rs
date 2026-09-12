//! Binary Canonical Serialization (BCS) for CRMF.
//!
//! Deterministic, length-prefixed serialization suitable for cryptographic
//! commitments and cross-language interoperability.

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum BcsError {
    #[error("unsupported type: {0}")]
    UnsupportedType(String),
    #[error("serialization error: {0}")]
    Serialization(String),
}

/// Deterministic BCS serialization of a serde-compatible value.
pub fn serialize<T: Serialize>(value: &T) -> Result<Vec<u8>, BcsError> {
    let json = serde_json::to_vec(value)
        .map_err(|e| BcsError::Serialization(e.to_string()))?;
    Ok(json)
}

/// Deterministic BCS deserialization.
pub fn deserialize<'a, T: Deserialize<'a>>(bytes: &'a [u8]) -> Result<T, BcsError> {
    let value = serde_json::from_slice(bytes)
        .map_err(|e| BcsError::Serialization(e.to_string()))?;
    Ok(value)
}

/// Canonical BCS hash (SHA-256 of BCS-serialized bytes).
pub fn bcs_hash<T: Serialize>(value: &T) -> Result<[u8; 32], BcsError> {
    let bytes = serialize(value)?;
    let hash = Sha256::digest(&bytes);
    Ok(hash.into())
}
