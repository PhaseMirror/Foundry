use serde::{Deserialize, Serialize};
use anyhow::{Result, anyhow};
use reqwest::{Client, Url};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProofSubmission {
    pub proof: Vec<u8>,
    pub public_inputs: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TransactionResult {
    pub tx_hash: String,
    pub block_number: u64,
}

pub struct MultiplicityClient {
    pub http_client: Client,
    pub base_url: Url,
}

impl MultiplicityClient {
    pub fn new(base_url: &str) -> Result<Self> {
        let client = Client::builder()
            .build()?;
        
        let url = Url::parse(base_url)?;
        
        Ok(MultiplicityClient {
            http_client: client,
            base_url: url,
        })
    }

    pub async fn submit_zk_proof(&self, submission: ProofSubmission) -> Result<TransactionResult> {
        let url = self.base_url.join("submit-proof")?;
        
        let response = self.http_client
            .post(url)
            .json(&submission)
            .send()
            .await?;
            
        if !response.status().is_success() {
            return Err(anyhow!("Server error: {}", response.status()));
        }
        
        let result = response.json::<TransactionResult>().await?;
        Ok(result)
    }

    pub async fn get_system_health(&self) -> Result<bool> {
        let url = self.base_url.join("health")?;
        let response = self.http_client.get(url).send().await?;
        Ok(response.status().is_success())
    }
}
