use crate::{IChainAdapter, ContractAddresses, ProofSubmission, TransactionResult, AdapterError};
use async_trait::async_trait;

pub struct ArbitrumAdapter {}

impl ArbitrumAdapter {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl IChainAdapter for ArbitrumAdapter {
    async fn submit_proof(&self, _submission: ProofSubmission) -> Result<TransactionResult, AdapterError> {
        Ok(TransactionResult {
            tx_hash: "0xarb_mock_hash".to_string(),
            block_number: 1,
            status: 1,
        })
    }

    async fn get_network_id(&self) -> Result<u64, AdapterError> {
        Ok(42161) // Arbitrum One chain ID
    }

    fn get_contract_addresses(&self) -> ContractAddresses {
        ContractAddresses {
            core: "0x0".to_string(),
            root_verifier: "0x0".to_string(),
            miller_rabin_verifier: "0x0".to_string(),
            recovery_verifier: "0x0".to_string(),
        }
    }
}
