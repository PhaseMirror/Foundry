use alloy::{
    network::EthereumWallet,
    primitives::{Address, B256, U256},
    providers::{Provider, ProviderBuilder},
    signers::local::PrivateKeySigner,
    sol,
    transports::http::{Client, Http},
};
use anyhow::{Context, Result};
use url::Url;

use crate::models::{ChainState, ContractAddresses, Proof, ProofSubmission, TransactionResult};

sol! {
    #[sol(rpc)]
    interface ICore {
        function getCurrentState() external view returns (bytes32);
        function quantumTransition(uint256[2] calldata a, uint256[2][2] calldata b, uint256[2] calldata c, uint256[] calldata input, bytes32 proofHash) external returns (bytes32);
        function getPrimeGates() external view returns (uint256[] memory);
        function checkPrimeAccess(address user, uint256 prime) external view returns (bool);
        
        event XiStateTransition(bytes32 indexed previousState, bytes32 indexed newState, address indexed executor, uint256 timestamp, bytes32 proofHash);
        event ExcessiveDrift(uint256 drift);
    }

    #[sol(rpc)]
    interface IVerifier {
        function verifyProof(uint256[2] calldata a, uint256[2][2] calldata b, uint256[2] calldata c, uint256[5] calldata input) external view returns (bool);
    }
}

#[async_trait::async_trait]
pub trait IChainAdapter: Send + Sync {
    async fn submit_proof(&self, submission: ProofSubmission) -> Result<TransactionResult>;
    async fn get_current_state(&self) -> Result<ChainState>;
    async fn verify_proof_on_chain(&self, proof: Proof, signals: Vec<String>) -> Result<bool>;
    async fn get_network_id(&self) -> Result<u64>;
    fn get_contract_addresses(&self) -> ContractAddresses;
    async fn is_nullifier_used(&self, nullifier: B256) -> Result<bool>;
    async fn compute_nullifier(&self, proof: Proof, nonce: u64) -> Result<B256>;
}

pub struct EVMAdapter {
    rpc_url: Url,
    private_key: Option<String>,
    addresses: ContractAddresses,
}

impl EVMAdapter {
    pub async fn new(
        rpc_url: &str,
        private_key: Option<&str>,
        addresses: Option<ContractAddresses>,
    ) -> Result<Self> {
        let url = Url::parse(rpc_url).context("Invalid RPC URL")?;

        let addresses = addresses.unwrap_or_else(|| ContractAddresses {
            core: Address::ZERO,
            root_verifier: Address::ZERO,
            miller_rabin_verifier: Address::ZERO,
            recovery_verifier: Address::ZERO,
            receipt_registry: None,
            finality_tracker: None,
        });

        Ok(Self {
            rpc_url: url,
            private_key: private_key.map(|s| s.to_string()),
            addresses,
        })
    }

    fn get_provider(&self) -> impl Provider<Http<Client>> {
        ProviderBuilder::new().on_http(self.rpc_url.clone())
    }
}

#[async_trait::async_trait]
impl IChainAdapter for EVMAdapter {
    async fn submit_proof(&self, submission: ProofSubmission) -> Result<TransactionResult> {
        let pk = self.private_key.as_ref().context("Wallet required for submission")?;
        let signer: PrivateKeySigner = pk.parse().context("Invalid private key")?;
        let wallet = EthereumWallet::from(signer);
        
        let provider = ProviderBuilder::new()
            .wallet(wallet)
            .on_http(self.rpc_url.clone());
        
        let core_contract = ICore::new(self.addresses.core, provider);

        let a = [
            U256::from_str_radix(&submission.proof.pi_a[0], 10)?,
            U256::from_str_radix(&submission.proof.pi_a[1], 10)?,
        ];
        
        let b = [
            [
                U256::from_str_radix(&submission.proof.pi_b[0][0], 10)?,
                U256::from_str_radix(&submission.proof.pi_b[0][1], 10)?,
            ],
            [
                U256::from_str_radix(&submission.proof.pi_b[1][0], 10)?,
                U256::from_str_radix(&submission.proof.pi_b[1][1], 10)?,
            ],
        ];

        let c = [
            U256::from_str_radix(&submission.proof.pi_c[0], 10)?,
            U256::from_str_radix(&submission.proof.pi_c[1], 10)?,
        ];

        let input: Vec<U256> = submission.public_signals.iter()
            .map(|s| U256::from_str_radix(s, 10).unwrap_or(U256::ZERO))
            .collect();

        let call = core_contract.quantumTransition(a, b, c, input, submission.proof_hash);
        let receipt = call.send().await?.get_receipt().await?;

        Ok(TransactionResult {
            hash: receipt.transaction_hash,
            status: if receipt.status() { "confirmed".to_string() } else { "failed".to_string() },
            block_number: Some(receipt.block_number.unwrap_or(0)),
            gas_used: Some(receipt.gas_used),
        })
    }

    async fn get_current_state(&self) -> Result<ChainState> {
        let provider = self.get_provider();
        let core_contract = ICore::new(self.addresses.core, provider);
        
        let state_res = core_contract.getCurrentState().call().await?;
        let gates_res = core_contract.getPrimeGates().call().await?;

        Ok(ChainState {
            current_state: state_res._0,
            prime_gates: gates_res._0,
            commit_count: U256::ZERO,
            last_transition: std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs(),
        })
    }

    async fn verify_proof_on_chain(&self, proof: Proof, signals: Vec<String>) -> Result<bool> {
        let provider = self.get_provider();
        let verifier = IVerifier::new(self.addresses.root_verifier, provider);

        let a = [
            U256::from_str_radix(&proof.pi_a[0], 10)?,
            U256::from_str_radix(&proof.pi_a[1], 10)?,
        ];
        
        let b = [
            [
                U256::from_str_radix(&proof.pi_b[0][0], 10)?,
                U256::from_str_radix(&proof.pi_b[0][1], 10)?,
            ],
            [
                U256::from_str_radix(&proof.pi_b[1][0], 10)?,
                U256::from_str_radix(&proof.pi_b[1][1], 10)?,
            ],
        ];

        let c = [
            U256::from_str_radix(&proof.pi_c[0], 10)?,
            U256::from_str_radix(&proof.pi_c[1], 10)?,
        ];

        let mut input = [U256::ZERO; 5];
        for (i, s) in signals.iter().take(5).enumerate() {
            input[i] = U256::from_str_radix(s, 10).unwrap_or(U256::ZERO);
        }

        let res = verifier.verifyProof(a, b, c, input).call().await?;
        Ok(res._0)
    }

    async fn get_network_id(&self) -> Result<u64> {
        let provider = self.get_provider();
        Ok(provider.get_chain_id().await?)
    }

    fn get_contract_addresses(&self) -> ContractAddresses {
        self.addresses.clone()
    }

    async fn is_nullifier_used(&self, _nullifier: B256) -> Result<bool> {
        Ok(false)
    }

    async fn compute_nullifier(&self, _proof: Proof, _nonce: u64) -> Result<B256> {
        Ok(B256::ZERO)
    }
}

