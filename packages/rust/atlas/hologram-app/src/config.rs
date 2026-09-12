use serde::{Deserialize, Serialize};
use std::path::PathBuf;

use crate::Result;

/// Main configuration for Hologram
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    /// Base directory for Hologram data (~/.hologram by default)
    pub home_dir: PathBuf,

    /// Server configuration
    pub server: ServerConfig,

    /// Model storage configuration
    pub storage: StorageConfig,

    /// HuggingFace configuration
    pub huggingface: HuggingFaceConfig,

    /// ONNX runtime configuration
    pub onnx: OnnxConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServerConfig {
    pub host: String,
    pub port: u16,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StorageConfig {
    pub models_dir: PathBuf,
    pub cache_dir: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HuggingFaceConfig {
    pub token: Option<String>,
    pub mirror_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OnnxConfig {
    pub num_threads: usize,
    pub use_gpu: bool,
}

impl Default for Config {
    fn default() -> Self {
        let home = dirs::home_dir()
            .unwrap_or_else(|| PathBuf::from("."))
            .join(".hologram");

        Self {
            home_dir: home.clone(),
            server: ServerConfig {
                host: "127.0.0.1".to_string(),
                port: 11434,
            },
            storage: StorageConfig {
                models_dir: home.join("models"),
                cache_dir: home.join("cache"),
            },
            huggingface: HuggingFaceConfig {
                token: std::env::var("HF_TOKEN").ok(),
                mirror_url: None,
            },
            onnx: OnnxConfig {
                num_threads: num_cpus::get(),
                use_gpu: false,
            },
        }
    }
}

impl Config {
    /// Create config from a home directory path
    pub fn from_home_dir(home: PathBuf) -> Self {
        Self {
            home_dir: home.clone(),
            storage: StorageConfig {
                models_dir: home.join("models"),
                cache_dir: home.join("cache"),
            },
            ..Default::default()
        }
    }

    /// Load config from a file
    pub fn from_file(path: &PathBuf) -> Result<Self> {
        let content = std::fs::read_to_string(path)?;
        let config: Config = serde_json::from_str(&content)?;
        Ok(config)
    }

    /// Save config to a file
    pub fn save(&self, path: &PathBuf) -> Result<()> {
        let content = serde_json::to_string_pretty(self)?;
        std::fs::write(path, content)?;
        Ok(())
    }

    /// Ensure all required directories exist
    pub fn ensure_dirs(&self) -> Result<()> {
        std::fs::create_dir_all(&self.home_dir)?;
        std::fs::create_dir_all(&self.storage.models_dir)?;
        std::fs::create_dir_all(&self.storage.cache_dir)?;
        Ok(())
    }

    /// Get the server address
    pub fn server_addr(&self) -> String {
        format!("{}:{}", self.server.host, self.server.port)
    }
}
