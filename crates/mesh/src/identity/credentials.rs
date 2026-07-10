use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc, Duration};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use uuid::Uuid;
use sha2::{Sha256, Digest};
use base64::{Engine as _, engine::general_purpose};
use rand::{thread_rng, RngCore};

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
pub enum CredentialStatus {
    Active,
    Rotated,
    Revoked,
    Expired,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Credential {
    pub credential_id: String,
    pub agent_did: String,
    pub token_hash: String,
    pub capabilities: Vec<String>,
    pub resources: Vec<String>,
    pub expires_at: DateTime<Utc>,
    pub status: CredentialStatus,
}

impl Credential {
    pub fn issue(
        agent_did: String,
        capabilities: Vec<String>,
        resources: Vec<String>,
        ttl_seconds: i64,
    ) -> (Self, String) {
        let mut token_bytes = [0u8; 32];
        thread_rng().fill_bytes(&mut token_bytes);
        let token = general_purpose::URL_SAFE_NO_PAD.encode(token_bytes);
        
        let mut hasher = Sha256::new();
        hasher.update(token.as_bytes());
        let token_hash = hex::encode(hasher.finalize());

        let credential_id = format!("cred_{}", Uuid::new_v4().simple());
        let now = Utc::now();

        let cred = Self {
            credential_id: credential_id.clone(),
            agent_did,
            token_hash,
            capabilities,
            resources,
            expires_at: now + Duration::seconds(ttl_seconds),
            status: CredentialStatus::Active,
        };
        (cred, token)
    }

    pub fn is_valid(&self) -> bool {
        self.status == CredentialStatus::Active && Utc::now() < self.expires_at
    }

    pub fn verify_token(&self, token: &str) -> bool {
        let mut hasher = Sha256::new();
        hasher.update(token.as_bytes());
        let token_hash = hex::encode(hasher.finalize());
        self.token_hash == token_hash
    }

    pub fn revoke(&mut self) {
        self.status = CredentialStatus::Revoked;
    }
}

pub struct CredentialManager {
    default_ttl: i64,
    credentials: Arc<RwLock<HashMap<String, Credential>>>,
}

impl CredentialManager {
    pub fn new(default_ttl: i64) -> Self {
        Self {
            default_ttl,
            credentials: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    pub fn issue(
        &self,
        agent_did: String,
        capabilities: Vec<String>,
        resources: Vec<String>,
    ) -> (Credential, String) {
        let (cred, token) = Credential::issue(agent_did, capabilities, resources, self.default_ttl);
        let mut credentials = self.credentials.write().unwrap();
        credentials.insert(cred.credential_id.clone(), cred.clone());
        (cred, token)
    }

    pub fn validate(&self, token: &str) -> Option<Credential> {
        let credentials = self.credentials.read().unwrap();
        
        // This is naive; in production, we should index by token_hash
        for cred in credentials.values() {
            if cred.verify_token(token) && cred.is_valid() {
                return Some(cred.clone());
            }
        }
        None
    }

    pub fn revoke(&self, credential_id: &str) -> bool {
        let mut credentials = self.credentials.write().unwrap();
        if let Some(cred) = credentials.get_mut(credential_id) {
            cred.revoke();
            true
        } else {
            false
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_credential_lifecycle() {
        let manager = CredentialManager::new(900);
        let (cred, token) = manager.issue("did:mesh:test-agent".to_string(), vec![], vec![]);
        
        // Validate
        assert!(manager.validate(&token).is_some());
        
        // Revoke
        manager.revoke(&cred.credential_id);
        assert!(manager.validate(&token).is_none());
    }
}
