// src/crypto.rs
use base64::{engine::general_purpose::STANDARD as b64, Engine as _};
use ed25519_dalek::{Keypair, PublicKey, SecretKey, KEYPAIR_LENGTH, SIGNATURE_LENGTH};
use rand::rngs::OsRng;
use std::fs;
use std::path::Path;

/// Generate a fresh Ed25519 keypair.
pub fn generate_keypair() -> Keypair {
    Keypair::generate(&mut OsRng)
}

/// Load a persisted keypair from "keypair.bin" if it exists.
pub fn load_keypair() -> Option<Keypair> {
    let path = Path::new("keypair.bin");
    if path.exists() {
        let bytes = fs::read(path).ok()?;
        if bytes.len() != KEYPAIR_LENGTH {
            return None;
        }
        let secret = SecretKey::from_bytes(&bytes[0..32]).ok()?;
        let public = PublicKey::from_bytes(&bytes[32..64]).ok()?;
        Some(Keypair { secret, public })
    } else {
        None
    }
}

/// Persist a keypair to "keypair.bin".
pub fn save_keypair(kp: &Keypair) -> std::io::Result<()> {
    let mut data = Vec::with_capacity(KEYPAIR_LENGTH);
    data.extend_from_slice(&kp.secret.to_bytes());
    data.extend_from_slice(&kp.public.to_bytes());
    fs::write("keypair.bin", data)
}

/// Simple wrapper for base64 encoding of a public key.
pub struct PublicKeyBase64(pub String);

impl From<PublicKey> for PublicKeyBase64 {
    fn from(pk: PublicKey) -> Self {
        PublicKeyBase64(b64.encode(pk.as_bytes()))
    }
}
