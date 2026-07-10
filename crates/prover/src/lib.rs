/// FRI (Fast Reed-Solomon Interactive Oracle Proof) Prover
/// 
/// Implements the FRI protocol for STARK proofs with:
/// - Domain size: 2^21
/// - Fold factor: 4
/// - Query count: 56
/// - DEEP sampling enabled
/// - Keccak256 transcript

pub mod fri;
pub mod transcript;
pub mod merkle;

pub use fri::FriProver;
pub use transcript::Keccak256Transcript;

use goldilocks::GoldilocksField;
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ProverError {
    #[error("Invalid trace length: {0}")]
    InvalidTraceLength(usize),
    
    #[error("FRI commit failed: {0}")]
    FriCommitFailed(String),
    
    #[error("Merkle tree error: {0}")]
    MerkleError(String),
    
    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StarkProof {
    /// Trace commitments (Merkle roots)
    pub trace_commitment: [u8; 32],
    
    /// FRI commitments for each folding round
    pub fri_commitments: Vec<[u8; 32]>,
    
    /// Query openings (evaluations + authentication paths)
    pub query_openings: Vec<QueryOpening>,
    
    /// Final FRI polynomial (constant after all folding)
    pub fri_final_poly: Vec<GoldilocksField>,
}

impl StarkProof {
    /// Encode proof to binary format for Solidity verifier
    pub fn to_binary(&self) -> Result<Vec<u8>, ProverError> {
        use std::io::Write;
        
        let mut buf = Vec::new();
        
        // Write trace commitment (32 bytes)
        buf.write_all(&self.trace_commitment)?;
        
        // Write FRI commitments count and data
        buf.write_all(&(self.fri_commitments.len() as u32).to_le_bytes())?;
        for commitment in &self.fri_commitments {
            buf.write_all(commitment)?;
        }
        
        // Write queries count
        buf.write_all(&(self.query_openings.len() as u32).to_le_bytes())?;
        
        for query in &self.query_openings {
            // Write index
            buf.write_all(&(query.index as u64).to_le_bytes())?;
            
            // Write trace values
            buf.write_all(&(query.trace_values.len() as u32).to_le_bytes())?;
            for value in &query.trace_values {
                buf.write_all(&value.to_canonical().to_le_bytes())?;
            }
            
            // Write auth path
            buf.write_all(&(query.auth_path.len() as u32).to_le_bytes())?;
            for hash in &query.auth_path {
                buf.write_all(hash)?;
            }
            
            // Write FRI layers
            buf.write_all(&(query.fri_layers.len() as u32).to_le_bytes())?;
            for value in &query.fri_layers {
                buf.write_all(&value.to_canonical().to_le_bytes())?;
            }
        }
        
        // Write final polynomial
        buf.write_all(&(self.fri_final_poly.len() as u32).to_le_bytes())?;
        for value in &self.fri_final_poly {
            buf.write_all(&value.to_canonical().to_le_bytes())?;
        }
        
        Ok(buf)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueryOpening {
    /// Index in the domain
    pub index: usize,
    
    /// Trace evaluations at this index
    pub trace_values: Vec<GoldilocksField>,
    
    /// Merkle authentication path
    pub auth_path: Vec<[u8; 32]>,
    
    /// FRI layer evaluations
    pub fri_layers: Vec<GoldilocksField>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublicInputs {
    pub values: Vec<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Manifest {
    pub system: String,
    pub circuit: String,
    pub field: String,
    pub transcript: String,
    pub fri: FriConfig,
    pub air_commit: String,
    pub verifier_bytecode_hash: String,
    pub build: BuildInfo,
    pub recursive: Option<RecursiveManifest>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecursiveManifest {
    pub ec_field: String,
    pub ec_curve: String,
    pub rpo_v: u32,
    pub outer_verification_key: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FriConfig {
    pub domain_pow: u32,
    pub fold: u32,
    pub queries: u32,
    pub deep: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BuildInfo {
    pub rustc: String,
    pub toolchain: String,
}

impl Manifest {
    pub fn hash(&self) -> Vec<u8> {
        use sha3::{Digest, Keccak256};
        let json = serde_json::to_string(self).expect("manifest serialization");
        Keccak256::digest(json.as_bytes()).to_vec()
    }
}
