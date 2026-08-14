use serde::{Deserialize, Serialize};
use async_trait::async_trait;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum AdapterError {
    #[error("Submission failed: {0}")]
    SubmissionError(String),
    #[error("Verification failed: {0}")]
    VerificationError(String),
    #[error("Not implemented")]
    NotImplemented,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofSubmission {
    pub proof: Vec<u8>,
    pub public_inputs: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionResult {
    pub tx_hash: String,
    pub block_number: u64,
    pub status: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChainState {
    pub current_block: u64,
    pub last_verified_root: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractAddresses {
    pub core: String,
    pub root_verifier: String,
    pub miller_rabin_verifier: String,
    pub recovery_verifier: String,
}

#[async_trait]
pub trait IChainAdapter: Send + Sync {
    async fn submit_proof(&self, submission: ProofSubmission) -> Result<TransactionResult, AdapterError>;
    
    async fn get_current_state(&self) -> Result<ChainState, AdapterError> {
        Err(AdapterError::NotImplemented)
    }

    async fn verify_proof_on_chain(&self, proof: &[u8], signals: &[String]) -> Result<bool, AdapterError> {
        Err(AdapterError::NotImplemented)
    }

    async fn get_network_id(&self) -> Result<u64, AdapterError>;

    fn get_contract_addresses(&self) -> ContractAddresses;

    async fn is_nullifier_used(&self, nullifier: &str) -> Result<bool, AdapterError> {
        Ok(false)
    }

    async fn compute_nullifier(&self, proof: &[u8], nonce: u64) -> Result<String, AdapterError> {
        Ok("0x00".to_string())
    }
}

pub mod base;
pub mod arbitrum;

pub use base::*;
pub use arbitrum::*;
