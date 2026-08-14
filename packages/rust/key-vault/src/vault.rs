use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use hkdf::Hkdf;
use rand::RngExt;
use sha2::Sha256;
use serde::{Deserialize, Serialize};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum VaultError {
    #[error("Encryption failure")]
    EncryptionError,
    #[error("Decryption failure")]
    DecryptionError,
    #[error("Serialization failure")]
    SerializationError,
    #[error("Invalid record")]
    InvalidRecord,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct VaultRecord {
    pub version: u8,
    pub salt: Vec<u8>,
    pub iv: Vec<u8>,
    pub ct: Vec<u8>,
}

pub struct SeedVault {
    pub namespace: String,
}

impl SeedVault {
    pub fn new(namespace: &str) -> Self {
        SeedVault {
            namespace: namespace.to_string(),
        }
    }

    pub fn encrypt(&self, seed: &[u8], kek_material: &[u8]) -> Result<VaultRecord, VaultError> {
        let mut rng = rand::rng();
        let mut salt = [0u8; 16];
        let mut iv = [0u8; 12];
        rng.fill(&mut salt);
        rng.fill(&mut iv);

        let kek = derive_kek(kek_material, &salt)?;
        let cipher = Aes256Gcm::new_from_slice(&kek).map_err(|_| VaultError::EncryptionError)?;
        let nonce = Nonce::from_slice(&iv);

        let ct = cipher
            .encrypt(nonce, seed)
            .map_err(|_| VaultError::EncryptionError)?;

        Ok(VaultRecord {
            version: 1,
            salt: salt.to_vec(),
            iv: iv.to_vec(),
            ct,
        })
    }

    pub fn decrypt(&self, rec: &VaultRecord, kek_material: &[u8]) -> Result<Vec<u8>, VaultError> {
        if rec.version != 1 {
            return Err(VaultError::InvalidRecord);
        }

        let kek = derive_kek(kek_material, &rec.salt)?;
        let cipher = Aes256Gcm::new_from_slice(&kek).map_err(|_| VaultError::DecryptionError)?;
        let nonce = Nonce::from_slice(&rec.iv);

        let pt = cipher
            .decrypt(nonce, rec.ct.as_slice())
            .map_err(|_| VaultError::DecryptionError)?;

        Ok(pt)
    }
}

pub fn derive_kek(ikm: &[u8], salt: &[u8]) -> Result<[u8; 32], VaultError> {
    let hk = Hkdf::<Sha256>::new(Some(salt), ikm);
    let mut okm = [0u8; 32];
    hk.expand(&[1], &mut okm).map_err(|_| VaultError::EncryptionError)?;
    Ok(okm)
}
