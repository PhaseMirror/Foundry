use async_trait::async_trait;
use crate::identity::agent_id::{AgentIdentity, PrivilegeRing};
use crate::identity::attestation::{AttestationClaim, SignedAttestation};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::path::PathBuf;
use std::fs::{File, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use anyhow::{Result, anyhow};
use chrono::{Utc, Duration};
use ed25519_dalek::{SigningKey, Signer};
use base64::{Engine as _, engine::general_purpose};
use serde::{Deserialize, Serialize};

#[async_trait]
pub trait AgentRegistry: Send + Sync {
    async fn register(&self, identity: &AgentIdentity, ring: PrivilegeRing) -> Result<()>;
    async fn get_attestation(&self, did: &str) -> Result<Option<SignedAttestation>>;
    async fn get_ring(&self, did: &str) -> Result<Option<PrivilegeRing>>;
    async fn is_registered(&self, did: &str) -> Result<bool>;
}

pub struct MemoryAgentRegistry {
    entries: Arc<RwLock<HashMap<String, (String, PrivilegeRing)>>>,
    registry_identity: SigningKey,
    registry_did: String,
}

impl MemoryAgentRegistry {
    pub fn new(registry_identity: SigningKey, registry_did: String) -> Self {
        Self {
            entries: Arc::new(RwLock::new(HashMap::new())),
            registry_identity,
            registry_did,
        }
    }
}

#[async_trait]
impl AgentRegistry for MemoryAgentRegistry {
    async fn register(&self, identity: &AgentIdentity, ring: PrivilegeRing) -> Result<()> {
        let mut entries = self.entries.write().map_err(|_| anyhow!("Lock poisoned"))?;
        entries.insert(identity.did.to_string(), (identity.public_key.clone(), ring));
        Ok(())
    }

    async fn get_attestation(&self, did: &str) -> Result<Option<SignedAttestation>> {
        let entries = self.entries.read().map_err(|_| anyhow!("Lock poisoned"))?;
        let (pubkey_b64, _) = match entries.get(did) {
            Some(e) => e,
            None => return Ok(None),
        };

        let claim = AttestationClaim {
            subject_did: did.to_string(),
            public_key_b64: pubkey_b64.clone(),
            issued_at: Utc::now(),
            expires_at: Utc::now() + Duration::hours(24),
        };

        let payload = SignedAttestation::canonical_bytes(&claim);
        let signature = self.registry_identity.sign(&payload);
        let signature_b64 = general_purpose::STANDARD.encode(signature.to_bytes());

        Ok(Some(SignedAttestation {
            claim,
            registry_did: self.registry_did.clone(),
            signature_b64,
        }))
    }

    async fn get_ring(&self, did: &str) -> Result<Option<PrivilegeRing>> {
        let entries = self.entries.read().map_err(|_| anyhow!("Lock poisoned"))?;
        Ok(entries.get(did).map(|(_, ring)| *ring))
    }

    async fn is_registered(&self, did: &str) -> Result<bool> {
        let entries = self.entries.read().map_err(|_| anyhow!("Lock poisoned"))?;
        Ok(entries.contains_key(did))
    }
}

#[derive(Serialize, Deserialize)]
struct RegistryRecord {
    identity: AgentIdentity,
    ring: PrivilegeRing,
}

pub struct FileAgentRegistry {
    path: PathBuf,
    memory: MemoryAgentRegistry,
}

impl FileAgentRegistry {
    pub fn open(path: PathBuf, registry_identity: SigningKey, registry_did: String) -> Result<Self> {
        let memory = MemoryAgentRegistry::new(registry_identity, registry_did);
        
        if path.exists() {
            let file = File::open(&path)?;
            let reader = BufReader::new(file);
            for line in reader.lines() {
                let line = line?;
                if line.trim().is_empty() { continue; }
                let record: RegistryRecord = serde_json::from_str(&line)?;
                // Populate memory cache synchronously during open
                let mut entries = memory.entries.write().map_err(|_| anyhow!("Lock poisoned"))?;
                entries.insert(record.identity.did.to_string(), (record.identity.public_key.clone(), record.ring));
            }
        }

        Ok(Self { path, memory })
    }
}

#[async_trait]
impl AgentRegistry for FileAgentRegistry {
    async fn register(&self, identity: &AgentIdentity, ring: PrivilegeRing) -> Result<()> {
        // 1. Update memory
        self.memory.register(identity, ring).await?;

        // 2. Persist to disk (atomic append)
        let record = RegistryRecord {
            identity: identity.clone(),
            ring,
        };
        let json = serde_json::to_string(&record)?;
        let mut file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(&self.path)?;
        
        file.write_all(json.as_bytes())?;
        file.write_all(b"\n")?;
        file.flush()?;

        Ok(())
    }

    async fn get_attestation(&self, did: &str) -> Result<Option<SignedAttestation>> {
        self.memory.get_attestation(did).await
    }

    async fn get_ring(&self, did: &str) -> Result<Option<PrivilegeRing>> {
        self.memory.get_ring(did).await
    }

    async fn is_registered(&self, did: &str) -> Result<bool> {
        self.memory.is_registered(did).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::NamedTempFile;
    use crate::identity::agent_id::{AgentIdentity, AgentDID};
    use rand::RngCore;

    fn generate_key() -> SigningKey {
        let mut bytes = [0u8; 32];
        rand::thread_rng().fill_bytes(&mut bytes);
        SigningKey::from_bytes(&bytes)
    }

    #[tokio::test]
    async fn test_file_registry_persistence() -> Result<()> {
        let tmp_file = NamedTempFile::new()?;
        let path = tmp_file.path().to_path_buf();
        let registry_key = generate_key();
        let registry_did = "did:mesh:registry".to_string();

        let identity = AgentIdentity {
            did: AgentDID { method: "mesh".to_string(), unique_id: "agent1".to_string() },
            name: "agent1".to_string(),
            sponsor_email: "agent1@example.com".to_string(),
            public_key: "pubkey1".to_string(),
            private_key: None,
            capabilities: vec![],
            status: "active".to_string(),
            parent_did: None,
            delegation_depth: 0,
        };

        {
            let registry = FileAgentRegistry::open(path.clone(), registry_key.clone(), registry_did.clone())?;
            registry.register(&identity, PrivilegeRing::Standard).await?;
        }

        // Re-open and verify
        let registry2 = FileAgentRegistry::open(path, registry_key, registry_did)?;
        assert!(registry2.is_registered("did:mesh:agent1").await?);
        let ring = registry2.get_ring("did:mesh:agent1").await?;
        assert_eq!(ring, Some(PrivilegeRing::Standard));

        Ok(())
    }
}

