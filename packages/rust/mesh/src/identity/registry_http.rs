use async_trait::async_trait;
use crate::identity::agent_id::{AgentIdentity, PrivilegeRing};
use crate::identity::attestation::SignedAttestation;
use crate::identity::registry::AgentRegistry;
use anyhow::{Result, anyhow};
use ed25519_dalek::{SigningKey, Signer};
use base64::{Engine as _, engine::general_purpose};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use chrono::{Utc, Duration};
use rand::Rng;

pub struct HttpAgentRegistry {
    base_url: String,
    registry_pubkey: String,
    agent_did: String,
    signing_key: SigningKey,
    client: reqwest::Client,
    cache: Arc<RwLock<HashMap<String, SignedAttestation>>>,
}

impl HttpAgentRegistry {
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
            cache: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    fn sign_body(&self, body: &[u8]) -> String {
        general_purpose::STANDARD.encode(self.signing_key.sign(body).to_bytes())
    }

    fn is_cache_fresh(&self, attestation: &SignedAttestation) -> bool {
        let now = Utc::now();
        if attestation.claim.expires_at <= now {
            return false;
        }

        // JITTERED REFRESH: Consider stale if within refresh window (1-2 hours before expiry)
        let mut rng = rand::thread_rng();
        let jitter_secs = rng.gen_range(3600..7200);
        let refresh_at = attestation.claim.expires_at - Duration::seconds(jitter_secs);
        
        now < refresh_at
    }
}

#[async_trait]
impl AgentRegistry for HttpAgentRegistry {
    async fn register(&self, identity: &AgentIdentity, ring: PrivilegeRing) -> Result<()> {
        let url = format!("{}/v1/agents/register", self.base_url);
        let req_body = serde_json::json!({
            "identity": identity,
            "ring": ring,
        });
        let body_bytes = serde_json::to_vec(&req_body)?;
        let signature = self.sign_body(&body_bytes);

        let response = self.client.post(url)
            .header("X-AGT-Signature", signature)
            .header("X-AGT-Agent-DID", &self.agent_did)
            .json(&req_body)
            .send()
            .await?;

        if response.status().is_success() {
            Ok(())
        } else {
            Err(anyhow!("Failed to register agent: {}", response.status()))
        }
    }

    async fn get_attestation(&self, did: &str) -> Result<Option<SignedAttestation>> {
        // 1. Check cache
        {
            let cache = self.cache.read().unwrap();
            if let Some(attestation) = cache.get(did) {
                if self.is_cache_fresh(attestation) {
                    return Ok(Some(attestation.clone()));
                }
            }
        }

        // 2. Fetch from network
        let url = format!("{}/v1/agents/{}/attestation", self.base_url, did);
        let signature = self.sign_body(b"");

        let response = self.client.get(url)
            .header("X-AGT-Signature", signature)
            .header("X-AGT-Agent-DID", &self.agent_did)
            .send()
            .await?;

        if response.status().is_success() {
            let attestation: Option<SignedAttestation> = response.json().await?;
            if let Some(ref a) = attestation {
                // FAIL-CLOSED: Verify attestation immediately
                a.verify(&self.registry_pubkey)
                    .map_err(|e| anyhow!("Attestation verification failed: {}", e))?;
                
                // Update cache
                let mut cache = self.cache.write().unwrap();
                cache.insert(did.to_string(), a.clone());
            }
            Ok(attestation)
        } else if response.status() == reqwest::StatusCode::NOT_FOUND {
            Ok(None)
        } else {
            // FAIL-CLOSED on network error if no cache available
            Err(anyhow!("Registry error: {}", response.status()))
        }
    }

    async fn get_ring(&self, did: &str) -> Result<Option<PrivilegeRing>> {
        let url = format!("{}/v1/agents/{}/ring", self.base_url, did);
        let signature = self.sign_body(b"");

        let response = self.client.get(url)
            .header("X-AGT-Signature", signature)
            .header("X-AGT-Agent-DID", &self.agent_did)
            .send()
            .await?;

        if response.status().is_success() {
            Ok(response.json().await?)
        } else if response.status() == reqwest::StatusCode::NOT_FOUND {
            Ok(None)
        } else {
            Err(anyhow!("Registry error: {}", response.status()))
        }
    }

    async fn is_registered(&self, did: &str) -> Result<bool> {
        Ok(self.get_attestation(did).await?.is_some())
    }
}
