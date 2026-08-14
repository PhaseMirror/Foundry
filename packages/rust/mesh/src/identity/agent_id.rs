use serde::{Deserialize, Serialize};
use ed25519_dalek::{SigningKey, VerifyingKey, Signature, Signer, Verifier};
use rand::rngs::OsRng;
use rand::RngCore;
use base64::{Engine as _, engine::general_purpose};
use sha2::{Sha256, Digest};
use crate::identity::keystore::KeyStore;
use anyhow::Result;
use std::str::FromStr;
use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
pub enum PrivilegeRing {
    System = 0,
    Trusted = 1,
    Standard = 2,
    Sandboxed = 3,
}

impl FromStr for PrivilegeRing {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "system" => Ok(PrivilegeRing::System),
            "trusted" => Ok(PrivilegeRing::Trusted),
            "standard" => Ok(PrivilegeRing::Standard),
            "sandboxed" => Ok(PrivilegeRing::Sandboxed),
            _ => Err(format!("Unknown privilege ring: {}", s)),
        }
    }
}

impl fmt::Display for PrivilegeRing {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PrivilegeRing::System => write!(f, "System"),
            PrivilegeRing::Trusted => write!(f, "Trusted"),
            PrivilegeRing::Standard => write!(f, "Standard"),
            PrivilegeRing::Sandboxed => write!(f, "Sandboxed"),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone, Hash, Eq, PartialEq)]
pub struct AgentDID {
    pub method: String,
    pub unique_id: String,
}

impl AgentDID {
    pub fn new(name: &str, org: Option<&str>) -> Self {
        let seed = format!("{}:{}", name, org.unwrap_or("default"));
        let mut hasher = Sha256::new();
        hasher.update(seed.as_bytes());
        let hash = hex::encode(hasher.finalize());
        Self {
            method: "mesh".to_string(),
            unique_id: hash[..32].to_string(),
        }
    }
}

impl std::fmt::Display for AgentDID {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "did:{}:{}", self.method, self.unique_id)
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct AgentIdentity {
    pub did: AgentDID,
    pub name: String,
    pub public_key: String, // Base64 encoded
    pub sponsor_email: String,
    pub capabilities: Vec<String>,
    pub status: String,
    pub parent_did: Option<String>,
    pub delegation_depth: u32,
    #[serde(skip)]
    pub private_key: Option<SigningKey>,
}

impl AgentIdentity {
    pub async fn create(
        name: String,
        sponsor: String,
        capabilities: Vec<String>,
        organization: Option<String>,
        keystore: Option<&dyn KeyStore>,
    ) -> Result<Self> {
        let mut rng = OsRng;
        let mut bytes = [0u8; 32];
        rng.fill_bytes(&mut bytes);
        let signing_key = SigningKey::from_bytes(&bytes);
        let public_key = signing_key.verifying_key();
        
        let did = AgentDID::new(&name, organization.as_deref());
        let did_str = did.to_string();
        
        let public_key_b64 = general_purpose::STANDARD.encode(public_key.to_bytes());

        if let Some(ks) = keystore {
            ks.save_key(&did_str, signing_key.clone()).await?;
        }

        Ok(Self {
            did,
            name,
            public_key: public_key_b64,
            sponsor_email: sponsor,
            capabilities,
            status: "active".to_string(),
            parent_did: None,
            delegation_depth: 0,
            private_key: Some(signing_key),
        })
    }

    pub async fn load(
        identity_json: &str,
        keystore: &dyn KeyStore,
    ) -> Result<Self> {
        let mut identity: Self = serde_json::from_str(identity_json)?;
        let private_key = keystore.load_key(&identity.did.to_string()).await?;
        identity.private_key = private_key;
        Ok(identity)
    }

    pub fn sign(&self, data: &[u8]) -> Option<Vec<u8>> {
        self.private_key.as_ref().map(|k| k.sign(data).to_vec())
    }

    pub fn verify_signature(&self, data: &[u8], signature: &[u8]) -> bool {
        let public_key_bytes = match general_purpose::STANDARD.decode(&self.public_key) {
            Ok(bytes) => bytes,
            Err(_) => return false,
        };
        let verifying_key = match VerifyingKey::from_bytes(public_key_bytes.as_slice().try_into().unwrap_or(&[0u8; 32])) {
            Ok(key) => key,
            Err(_) => return false,
        };
        let sig = match Signature::from_slice(signature) {
            Ok(sig) => sig,
            Err(_) => return false,
        };
        verifying_key.verify(data, &sig).is_ok()
    }
}
