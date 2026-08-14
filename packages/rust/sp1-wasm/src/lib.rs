use serde::{Deserialize, Serialize};
use thiserror::Error;
use sp1_verifier::{Groth16Verifier, PlonkVerifier, GROTH16_VK_BYTES, PLONK_VK_BYTES};
use wasm_bindgen::prelude::*;

#[derive(Error, Debug)]
pub enum VerifierError {
    #[error("Groth16 verification failed")]
    Groth16Failed,
    #[error("Plonk verification failed")]
    PlonkFailed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationRequest {
    pub proof: Vec<u8>,
    pub vk_hash: String,
    pub public_values: Vec<u8>,
}

/// Pure Rust API for proof verification
pub fn verify_proof(req: &VerificationRequest) -> Result<bool, VerifierError> {
    if Groth16Verifier::verify(&req.proof, &req.public_values, &req.vk_hash, *GROTH16_VK_BYTES).is_ok() {
        return Ok(true);
    }
    if PlonkVerifier::verify(&req.proof, &req.public_values, &req.vk_hash, *PLONK_VK_BYTES).is_ok() {
        return Ok(true);
    }
    Ok(false)
}

/// WASM-compatible API (retained for compatibility)
#[wasm_bindgen]
pub fn verify(proof: &[u8], sp1_vk_hash: &str, public_values: &[u8]) -> bool {
    let req = VerificationRequest {
        proof: proof.to_vec(),
        vk_hash: sp1_vk_hash.to_string(),
        public_values: public_values.to_vec(),
    };
    verify_proof(&req).unwrap_or(false)
}

#[wasm_bindgen]
pub fn verify_groth16(proof: &[u8], sp1_vk_hash: &str, public_values: &[u8]) -> bool {
    Groth16Verifier::verify(proof, public_values, sp1_vk_hash, *GROTH16_VK_BYTES).is_ok()
}

#[wasm_bindgen]
pub fn verify_plonk(proof: &[u8], sp1_vk_hash: &str, public_values: &[u8]) -> bool {
    PlonkVerifier::verify(proof, public_values, sp1_vk_hash, *PLONK_VK_BYTES).is_ok()
}
