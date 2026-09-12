// crates/engine/src/crmf_binding.rs
//! Telemetry framing and lawful‑recursion‑hash integration.
//! Provides a deterministic BCS‑serialized payload that is fed into the
//! hashing backend (SHA‑256 or Poseidon2 depending on the `poseidon2` feature).

use serde::{Serialize, Deserialize};
use bcs; // BCS uses little‑endian fixed‑int encoding.
use sha2::{Digest, Sha256};



#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
#[repr(C)]
pub struct FPGATelemetryFrame {
    pub tdata: u32,
    pub timestamp: u64,
    pub flags: u8,
}

impl FPGATelemetryFrame {
    pub fn new(tdata: u32, timestamp: u64, flags: u8) -> Self {
        Self { tdata, timestamp, flags }
    }

    /// Packs the telemetry frame into a deterministic byte array via BCS.
    pub fn to_canonical_bytes(&self) -> Vec<u8> {
        bcs::to_bytes(self).expect("Deterministic BCS serialization of telemetry failed")
    }
}

/// Example `SecurityState` – replace with the real struct from the codebase.
#[derive(Debug, Serialize, Deserialize)]
pub struct SecurityState {
    pub mode: u8,
    // Add other fields as required.
}

impl SecurityState {
    pub fn new(mode: u8) -> Self { Self { mode } }
}

/// Compute the lawful recursion hash.
/// When the `poseidon2` Cargo feature is enabled the Poseidon2 sponge is used;
/// otherwise SHA‑256 is the default fallback.
pub fn compute_lawful_recursion_hash(
    prev_hash: &[u8; 32],
    frame: &FPGATelemetryFrame,
    security_state: &SecurityState,
) -> [u8; 32] {
    // Serialize components.
    let mut data = Vec::new();
    data.extend_from_slice(prev_hash);
    data.extend_from_slice(&frame.to_canonical_bytes());
    data.extend_from_slice(&bcs::to_bytes(security_state).expect("SecurityState serialization failed"));

    #[cfg(feature = "poseidon2")]
    {
        // Convert the concatenated data to a deterministic field element via SHA‑256.
        let mut sha_hasher = Sha256::new();
        sha_hasher.update(&data);
        let digest = sha_hasher.finalize();
        let mut bytes = [0u8; 32];
        bytes.copy_from_slice(&digest);
        // Interpret the digest as a BN254 field element (big‑endian order).
        let fe = ark_bn254::Fr::from_be_bytes_mod_order(&bytes);
        // Apply the Poseidon2 sponge (currently the placeholder sum implementation).
        let result = sponge(&[fe]);
        // Export the result as a 32‑byte little‑endian array.
        let mut out = [0u8; 32];
        out.copy_from_slice(&result.into_repr().to_bytes_le());
        out
    }
    #[cfg(not(feature = "poseidon2"))]
    {
        let mut hasher = Sha256::new();
        hasher.update(&data);
        let result = hasher.finalize();
        let mut out = [0u8; 32];
        out.copy_from_slice(&result);
        out
    }
}
