use serde::{Deserialize, Serialize};
use async_trait::async_trait;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum SidechainError {
    #[error("Submission failed: {0}")]
    SubmissionError(String),
    #[error("Protocol error: {0}")]
    ProtocolError(String),
}

pub type Proof = Vec<u8>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HyperscalingConfig {
    pub sequencer_count: usize,
    pub shard_count: usize,
    pub target_tps: u64,
    pub target_finality: u64,
    pub sequencer_redundancy: usize,
    pub consensus_type: String,
    pub consensus_threshold: usize,
    pub sharding_strategy: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShardInfo {
    pub shard_id: usize,
    pub shard_index: usize,
    pub primary_sequencer: String,
    pub backup_sequencers: Vec<String>,
    pub proof_count: u64,
    pub state_root: Vec<u8>,
    pub current_tps: f64,
    pub utilization_percent: f64,
    pub is_healthy: bool,
    pub uptime: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShardSubmissionReceipt {
    pub proof_id: String,
    pub shard_id: usize,
    pub assigned_sequencer: String,
    pub estimated_shard_time: f64,
    pub batch_id: String,
    pub proof_index_in_batch: usize,
    pub submitted_at: u64,
    pub estimated_finality: f64,
    pub status: String,
}

#[async_trait]
pub trait IHyperscalingProtocol: Send + Sync {
    async fn initialize_hyperscaling(&self, config: HyperscalingConfig) -> Result<(), SidechainError>;
    async fn submit_proof_to_shard(&self, proof: Proof, public_signals: Vec<String>) -> Result<ShardSubmissionReceipt, SidechainError>;
    async fn create_new_shard(&self, sequencer_id: String, shard_index: usize) -> Result<ShardInfo, SidechainError>;
    async fn rebalance_shards(&self) -> Result<Vec<String>, SidechainError>; // Simplified return
}

#[async_trait]
pub trait IStateAggregationEngine: Send + Sync {
    async fn create_batch_merkle_tree(&self, nullifiers: Vec<Vec<u8>>, commitments: Vec<Vec<u8>>) -> Result<Vec<u8>, SidechainError>;
    // Other methods would go here...
}

pub mod lib_impl;
pub use lib_impl::*;
