use crate::identity::agent_id::AgentIdentity;
use ed25519_dalek::SigningKey;
use rand::rngs::OsRng;
use rand::RngCore;
use base64::{Engine as _, engine::general_purpose};

pub struct KeyRotationManager;

impl KeyRotationManager {
    pub fn rotate_keys(identity: &mut AgentIdentity) {
        let mut rng = OsRng;
        let mut bytes = [0u8; 32];
        rng.fill_bytes(&mut bytes);
        let new_signing_key = SigningKey::from_bytes(&bytes);
        let new_public_key = new_signing_key.verifying_key();
        
        identity.public_key = general_purpose::STANDARD.encode(new_public_key.to_bytes());
        identity.private_key = Some(new_signing_key);
    }
}
