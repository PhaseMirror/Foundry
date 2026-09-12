use serde::{Deserialize, Serialize};
use crate::identity::agent_id::AgentIdentity;


#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MTLSConfig {
    pub cert_path: Option<String>,
    pub key_path: Option<String>,
    pub ca_cert_path: Option<String>,
    pub verify_peer: bool,
    pub require_client_cert: bool,
}

impl Default for MTLSConfig {
    fn default() -> Self {
        Self {
            cert_path: None,
            key_path: None,
            ca_cert_path: None,
            verify_peer: true,
            require_client_cert: true,
        }
    }
}

pub struct MTLSIdentityVerifier {
    pub identity: AgentIdentity,
    pub config: MTLSConfig,
}

impl MTLSIdentityVerifier {
    pub fn new(identity: AgentIdentity, config: Option<MTLSConfig>) -> Self {
        Self {
            identity,
            config: config.unwrap_or_default(),
        }
    }

    pub fn create_self_signed_cert(&self) -> anyhow::Result<(String, String)> {
        let cert = rcgen::generate_simple_self_signed(vec![format!("{}", self.identity.did)])?;
        
        let cert_pem = cert.cert.pem();
        let key_pem = cert.key_pair.serialize_pem();
        
        Ok((cert_pem, key_pem))
    }
}

