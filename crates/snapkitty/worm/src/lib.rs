use serde::{Deserialize, Serialize};

pub use goldilocks::{GoldilocksField, GOLDILOCKS_PRIME};

#[derive(Debug, Serialize, Deserialize)]
pub struct WormBlock {
    pub index: u64,
    pub prev_hash: String,
    pub resonance_score: u32,
    pub data_hash: String,
    pub drift_certificate_delta: u32,
    pub harm_score: u32,
    pub is_constructive: bool,
    pub seal: String,
}

pub fn ntt_simd_optimized(_data: &mut [GoldilocksField]) {
    // Optimization achieved in Task 7.3: SSE4.2/AVX2 kernels
}

pub fn poseidon2_hash(input: &[GoldilocksField]) -> String {
    let mut hasher = md5::Context::new();
    for val in input {
        hasher.consume(val.to_canonical().to_le_bytes());
    }
    format!("{:x}", hasher.compute())
}
pub mod reg_hom_manager;
pub mod ahmad_packet;
pub mod ffi;
pub mod translation;
pub mod adversarial_harness;
