use async_trait::async_trait;
use ed25519_dalek::SigningKey;
use crate::identity::keystore::KeyStore;
use crate::identity::attestation::SignedAttestation;
use anyhow::{Result, anyhow};
use ed25519_dalek::Signer;
use base64::{Engine as _, engine::general_purpose};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub struct AttestedKeyResponse {
    pub key_b64: String,
    pub attestation: SignedAttestation,
}

pub struct HttpKeyStore {
    base_url: String,
    registry_pubkey: String,
    agent_did: String,
    signing_key: SigningKey,
    client: reqwest::Client,
}

impl HttpKeyStore {
    pub fn new(
        base_url: String, 
        registry_pubkey: String,
        agent_did: String,
        signing_key: SigningKey,
    ) -> Self {
        Self {
            base_url,
            registry_pubkey,
            agent_did,
            signing_key,
            client: reqwest::Client::new(),
        }
    }

    fn sign_body(&self, body: &[u8]) -> String {
        general_purpose::STANDARD.encode(self.signing_key.sign(body).to_bytes())
    }
}

#[async_trait]
impl KeyStore for HttpKeyStore {
    async fn save_key(&self, agent_did: &str, key: SigningKey) -> Result<()> {
        let url = format!("{}/v1/agents/{}/key", self.base_url, agent_did);
        let key_b64 = general_purpose::STANDARD.encode(key.to_bytes());
        let body = serde_json::to_vec(&key_b64)?;
        let signature = self.sign_body(&body);

        let response = self.client.post(url)
            .header("X-AGT-Signature", signature)
            .header("X-AGT-Agent-DID", &self.agent_did)
            .json(&key_b64)
            .send()
            .await?;

        if response.status().is_success() {
            Ok(())
        } else {
            Err(anyhow!("Failed to save key: {}", response.status()))
        }
    }

    async fn load_key(&self, agent_did: &str) -> Result<Option<SigningKey>> {
        let url = format!("{}/v1/agents/{}/key", self.base_url, agent_did);
        let signature = self.sign_body(b"");

        let response = self.client.get(url)
            .header("X-AGT-Signature", signature)
            .header("X-AGT-Agent-DID", &self.agent_did)
            .send()
            .await?;

        if response.status().is_success() {
            let res: Option<AttestedKeyResponse> = response.json().await?;
            if let Some(attested_res) = res {
                // FAIL-CLOSED: Verify attestation
                attested_res.attestation.verify(&self.registry_pubkey)
                    .map_err(|e| anyhow!("Registry attestation verification failed: {}", e))?;
                
                let bytes = general_purpose::STANDARD.decode(attested_res.key_b64)?;
                let key_bytes: [u8; 32] = bytes.try_into().map_err(|_| anyhow!("Invalid key length"))?;
                let signing_key = SigningKey::from_bytes(&key_bytes);
                
                // Verify that the key matches the attestation subject
                let public_key_b64 = general_purpose::STANDARD.encode(signing_key.verifying_key().to_bytes());
                if public_key_b64 != attested_res.attestation.claim.public_key_b64 {
                    return Err(anyhow!("Key mismatch: private key does not match attested public key"));
                }
                
                Ok(Some(signing_key))
            } else {
                Ok(None)
            }
        } else if response.status() == reqwest::StatusCode::NOT_FOUND {
            Ok(None)
        } else {
            Err(anyhow!("Registry error: {}", response.status()))
        }
    }

    async fn delete_key(&self, _agent_did: &str) -> Result<()> {
        Err(anyhow!("Delete not implemented in HttpKeyStore v1"))
    }
}
