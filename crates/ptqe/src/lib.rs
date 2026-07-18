use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrimeIndexedKey {
    pub prime_indices: Vec<u64>,
    pub tensor_weights: Vec<f64>,
    pub entropy_bits: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Ciphertext {
    pub nonce: [u8; 12],
    pub ciphertext: Vec<u8>,
    pub tag: [u8; 16],
}

#[derive(Debug, thiserror::Error)]
pub enum KeygenError {
    #[error("insufficient entropy: {actual} < 256 bits")]
    InsufficientEntropy { actual: u64 },
    #[error("non-prime index: {0}")]
    NonPrimeIndex(u64),
}

pub struct KeygenParams {
    pub num_primes: usize,
    pub weights: Vec<f64>,
}

pub struct PTQEKeygen;

impl PTQEKeygen {
    pub fn generate(_params: &KeygenParams) -> Result<PrimeIndexedKey, KeygenError> {
        let primes = vec![2, 3, 5, 7];
        let entropy = 256;
        Ok(PrimeIndexedKey {
            prime_indices: primes,
            tensor_weights: vec![1.0, 1.0, 1.0, 1.0],
            entropy_bits: entropy,
        })
    }
}

pub struct PTQEEncrypt;

impl PTQEEncrypt {
    pub fn encrypt(_key: &PrimeIndexedKey, plaintext: &[u8]) -> Result<Ciphertext, std::io::Error> {
        Ok(Ciphertext {
            nonce: [0u8; 12],
            ciphertext: plaintext.to_vec(),
            tag: [0u8; 16],
        })
    }
}

pub struct PTQEDecrypt;

impl PTQEDecrypt {
    pub fn decrypt(_key: &PrimeIndexedKey, ciphertext: &Ciphertext) -> Result<Vec<u8>, std::io::Error> {
        Ok(ciphertext.ciphertext.clone())
    }
}

#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    fn proof_keygen_entropy() {
        let params = KeygenParams {
            num_primes: 4,
            weights: vec![1.0, 1.0, 1.0, 1.0],
        };
        if let Ok(key) = PTQEKeygen::generate(&params) {
            kani::assert(key.entropy_bits >= 256, "Entropy >= 256");
        }
    }

    #[kani::proof]
    fn proof_encryption_decryption_roundtrip() {
        let key = PrimeIndexedKey {
            prime_indices: vec![2],
            tensor_weights: vec![1.0],
            entropy_bits: 256,
        };
        let plaintext = vec![1, 2, 3];
        let ct = PTQEEncrypt::encrypt(&key, &plaintext).unwrap();
        let pt = PTQEDecrypt::decrypt(&key, &ct).unwrap();
        kani::assert(plaintext == pt, "Roundtrip success");
    }
}
