use async_trait::async_trait;
use ed25519_dalek::SigningKey;
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::path::PathBuf;
use std::fs;
use anyhow::{Result, anyhow};
use serde::{Deserialize, Serialize};
use sha2::Digest;
use argon2::Argon2;
use chacha20poly1305::{
    aead::{Aead, KeyInit},
    XChaCha20Poly1305, XNonce,
};
use rand::rngs::OsRng;
use rand::RngCore;
use base64::{Engine as _, engine::general_purpose};

#[async_trait]
pub trait KeyStore: Send + Sync {
    async fn save_key(&self, agent_did: &str, key: SigningKey) -> Result<()>;
    async fn load_key(&self, agent_did: &str) -> Result<Option<SigningKey>>;
    async fn delete_key(&self, agent_did: &str) -> Result<()>;
}

pub struct MemoryKeyStore {
    keys: Arc<RwLock<HashMap<String, SigningKey>>>,
}

impl MemoryKeyStore {
    pub fn new() -> Self {
        Self {
            keys: Arc::new(RwLock::new(HashMap::new())),
        }
    }
}

#[async_trait]
impl KeyStore for MemoryKeyStore {
    async fn save_key(&self, agent_did: &str, key: SigningKey) -> Result<()> {
        let mut keys = self.keys.write().map_err(|_| anyhow!("Lock poisoned"))?;
        keys.insert(agent_did.to_string(), key);
        Ok(())
    }

    async fn load_key(&self, agent_did: &str) -> Result<Option<SigningKey>> {
        let keys = self.keys.read().map_err(|_| anyhow!("Lock poisoned"))?;
        Ok(keys.get(agent_did).cloned())
    }

    async fn delete_key(&self, agent_did: &str) -> Result<()> {
        let mut keys = self.keys.write().map_err(|_| anyhow!("Lock poisoned"))?;
        keys.remove(agent_did);
        Ok(())
    }
}

#[derive(Serialize, Deserialize)]
struct EncryptedKeyFile {
    salt: String,
    nonce: String,
    ciphertext: String,
}

pub struct FileKeyStore {
    base_dir: PathBuf,
    kek: [u8; 32],
}

impl FileKeyStore {
    pub fn new(base_dir: PathBuf, passphrase: &str) -> Result<Self> {
        if !base_dir.exists() {
            fs::create_dir_all(&base_dir)?;
        }

        // Derive KEK using a fixed salt for the store's master key derivation 
        // (In a real system, the salt for KEK would be stored in a config or generated once)
        // For simplicity and to match the spec's "never stored" for KEK, we use a stable salt here.
        let salt = b"microsoft-agt-rust-stable-salt-01"; 
        let argon2 = Argon2::default();
        let mut kek = [0u8; 32];
        argon2.hash_password_into(passphrase.as_bytes(), salt, &mut kek)
            .map_err(|e| anyhow!("KDF failure: {}", e))?;

        Ok(Self { base_dir, kek })
    }

    fn get_path(&self, agent_did: &str) -> PathBuf {
        let mut hasher = sha2::Sha256::new();
        sha2::Digest::update(&mut hasher, agent_did.as_bytes());
        let hash = hex::encode(sha2::Digest::finalize(hasher));
        self.base_dir.join(format!("{}.json", hash))
    }
}

#[async_trait]
impl KeyStore for FileKeyStore {
    async fn save_key(&self, agent_did: &str, key: SigningKey) -> Result<()> {
        let path = self.get_path(agent_did);
        
        // Generate random salt and nonce for this specific key
        let mut salt_bytes = [0u8; 16];
        let mut nonce_bytes = [0u8; 24];
        OsRng.fill_bytes(&mut salt_bytes);
        OsRng.fill_bytes(&mut nonce_bytes);

        let cipher = XChaCha20Poly1305::new(&self.kek.into());
        let nonce = XNonce::from_slice(&nonce_bytes);
        
        let ciphertext = cipher.encrypt(nonce, key.to_bytes().as_slice())
            .map_err(|e| anyhow!("Encryption failure: {}", e))?;

        let key_file = EncryptedKeyFile {
            salt: general_purpose::STANDARD.encode(salt_bytes),
            nonce: general_purpose::STANDARD.encode(nonce_bytes),
            ciphertext: general_purpose::STANDARD.encode(ciphertext),
        };

        let json = serde_json::to_string_pretty(&key_file)?;
        let tmp_path = path.with_extension("tmp");
        fs::write(&tmp_path, json)?;
        fs::rename(tmp_path, path)?;

        Ok(())
    }

    async fn load_key(&self, agent_did: &str) -> Result<Option<SigningKey>> {
        let path = self.get_path(agent_did);
        if !path.exists() {
            return Ok(None);
        }

        let json = fs::read_to_string(path)?;
        let key_file: EncryptedKeyFile = serde_json::from_str(&json)?;

        let nonce_bytes = general_purpose::STANDARD.decode(key_file.nonce)?;
        let ciphertext = general_purpose::STANDARD.decode(key_file.ciphertext)?;

        let cipher = XChaCha20Poly1305::new(&self.kek.into());
        let nonce = XNonce::from_slice(&nonce_bytes);
        
        let plaintext = cipher.decrypt(nonce, ciphertext.as_slice())
            .map_err(|e| anyhow!("Decryption failure: {}", e))?;

        let key_bytes: [u8; 32] = plaintext.try_into()
            .map_err(|_| anyhow!("Invalid key length"))?;
        
        Ok(Some(SigningKey::from_bytes(&key_bytes)))
    }

    async fn delete_key(&self, agent_did: &str) -> Result<()> {
        let path = self.get_path(agent_did);
        if path.exists() {
            fs::remove_file(path)?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[tokio::test]
    async fn test_file_keystore_roundtrip() {
        let dir = tempdir().unwrap();
        let store = FileKeyStore::new(dir.path().to_path_buf(), "correct-passphrase").unwrap();
        let agent_did = "did:mesh:test-agent";
        
        let mut bytes = [0u8; 32];
        OsRng.fill_bytes(&mut bytes);
        let key = SigningKey::from_bytes(&bytes);

        store.save_key(agent_did, key.clone()).await.unwrap();
        let loaded_key = store.load_key(agent_did).await.unwrap().unwrap();
        
        assert_eq!(key.to_bytes(), loaded_key.to_bytes());
    }

    #[tokio::test]
    async fn test_file_keystore_wrong_passphrase() {
        let dir = tempdir().unwrap();
        let store_save = FileKeyStore::new(dir.path().to_path_buf(), "correct-passphrase").unwrap();
        let agent_did = "did:mesh:test-agent";
        
        let mut bytes = [0u8; 32];
        OsRng.fill_bytes(&mut bytes);
        let key = SigningKey::from_bytes(&bytes);
        store_save.save_key(agent_did, key).await.unwrap();

        let store_load = FileKeyStore::new(dir.path().to_path_buf(), "wrong-passphrase").unwrap();
        let result = store_load.load_key(agent_did).await;
        
        assert!(result.is_err());
        assert!(result.unwrap_err().to_string().contains("Decryption failure"));
    }
}
