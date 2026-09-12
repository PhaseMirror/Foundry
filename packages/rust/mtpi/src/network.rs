use anyhow::{Result, anyhow};
use std::env;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum RpcProfile {
    Default,
    Din,
    Fallback,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Network {
    Sepolia,
    Mainnet,
    Local,
    Anvil,
}

impl RpcProfile {
    #[allow(clippy::inherent_to_string)]
    pub fn to_string(&self) -> String {
        match self {
            RpcProfile::Default => "default".to_string(),
            RpcProfile::Din => "din".to_string(),
            RpcProfile::Fallback => "fallback".to_string(),
        }
    }
}

impl Network {
    #[allow(clippy::inherent_to_string)]
    pub fn to_string(&self) -> String {
        match self {
            Network::Sepolia => "sepolia".to_string(),
            Network::Mainnet => "mainnet".to_string(),
            Network::Local => "local".to_string(),
            Network::Anvil => "anvil".to_string(),
        }
    }
}

pub struct NetworkResolver;

impl NetworkResolver {
    pub fn env_key(profile: RpcProfile, network: Network, prefix: Option<&str>) -> String {
        let prefix_str = prefix.map(|p| format!("{}_", p.trim_end_matches('_'))).unwrap_or_default();
        format!("{}RPC_URL_{}_{}", 
            prefix_str, 
            profile.to_string().to_uppercase(), 
            network.to_string().to_uppercase()
        )
    }

    pub fn resolve_rpc_url(
        profile: RpcProfile,
        network: Network,
        legacy_keys: Vec<String>,
        allow_legacy: bool
    ) -> Result<String> {
        let base_key = Self::env_key(profile, network, None);
        let mut candidates = vec![
            base_key.clone(),
            Self::env_key(profile, network, Some("NEXT_PUBLIC")),
            Self::env_key(profile, network, Some("VITE")),
        ];

        if allow_legacy {
            candidates.extend(legacy_keys);
            if matches!(profile, RpcProfile::Default) {
                if matches!(network, Network::Sepolia) {
                    candidates.push("SEPOLIA_RPC_URL".to_string());
                }
                candidates.push("RPC_URL".to_string());
                candidates.push("NEXT_PUBLIC_RPC_URL".to_string());
                candidates.push("VITE_RPC_URL".to_string());
            }
        }

        for key in candidates {
            if let Ok(val) = env::var(&key) {
                if !val.trim().is_empty() {
                    return Ok(val);
                }
            }
        }

        Err(anyhow!("Missing RPC URL for profile {:?} on {:?}", profile, network))
    }
}
