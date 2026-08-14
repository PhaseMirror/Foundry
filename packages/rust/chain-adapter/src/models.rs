use alloy::primitives::{Address, B256, U256};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Proof {
    pub pi_a: [String; 3],
    pub pi_b: [[String; 2]; 3],
    pub pi_c: [String; 3],
    pub protocol: String,
    pub curve: String,
}

#[derive(Debug, Clone)]
pub struct ProofSubmission {
    pub proof: Proof,
    pub public_signals: Vec<String>,
    pub proof_hash: B256,
    pub nullifier: Option<B256>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionResult {
    pub hash: B256,
    pub status: String, // "submitted", "confirmed", "failed"
    pub block_number: Option<u64>,
    pub gas_used: Option<u128>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChainState {
    pub current_state: B256,
    pub prime_gates: Vec<U256>,
    pub commit_count: U256,
    pub last_transition: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContractAddresses {
    pub core: Address,
    pub root_verifier: Address,
    pub miller_rabin_verifier: Address,
    pub recovery_verifier: Address,
    pub receipt_registry: Option<Address>,
    pub finality_tracker: Option<Address>,
}
