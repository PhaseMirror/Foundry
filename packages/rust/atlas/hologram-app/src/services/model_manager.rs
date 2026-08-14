use std::path::PathBuf;

use sha2::{Digest, Sha256};
use tokio::sync::broadcast;

use crate::config::Config;
use crate::types::internal::ModelMetadata;
use crate::types::ollama::{ModelDetails, ModelInfo, PullResponse, ShowResponse};
use crate::{Error, Result};

use super::DownloadService;

/// Manages model storage, listing, and metadata
pub struct ModelManager {
    config: Config,
    download_service: DownloadService,
}

impl ModelManager {
    pub fn new(config: Config) -> Self {
        let download_service = DownloadService::new(config.clone());
        Self {
            config,
            download_service,
        }
    }

    /// List all available models
    pub async fn list(&self) -> Result<Vec<ModelInfo>> {
        let models_dir = &self.config.storage.models_dir;

        if !models_dir.exists() {
            return Ok(vec![]);
        }

        let mut models = Vec::new();
        let mut entries = tokio::fs::read_dir(models_dir).await?;

        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();

            // Look for .holo files or model directories
            if path.extension().map(|e| e == "holo").unwrap_or(false) {
                if let Some(model_info) = self.read_model_info(&path).await? {
                    models.push(model_info);
                }
            }
        }

        // Sort by modification time (newest first)
        models.sort_by(|a, b| b.modified_at.cmp(&a.modified_at));

        Ok(models)
    }

    /// Get information about a specific model
    pub async fn show(&self, name: &str) -> Result<ShowResponse> {
        let model_path = self.model_path(name);

        if !model_path.exists() {
            return Err(Error::ModelNotFound(name.to_string()));
        }

        // Read model metadata
        let metadata_path = model_path.with_extension("json");
        let metadata: ModelMetadata = if metadata_path.exists() {
            let content = tokio::fs::read_to_string(&metadata_path).await?;
            serde_json::from_str(&content)?
        } else {
            ModelMetadata::default()
        };

        Ok(ShowResponse {
            modelfile: format!("FROM {}", name),
            parameters: "".to_string(),
            template: "{{ .Prompt }}".to_string(),
            details: ModelDetails {
                format: "holo".to_string(),
                family: metadata.family.unwrap_or_else(|| "unknown".to_string()),
                families: None,
                parameter_size: metadata.parameter_size.unwrap_or_else(|| "unknown".to_string()),
                quantization_level: metadata.quantization.unwrap_or_else(|| "none".to_string()),
            },
        })
    }

    /// Delete a model
    pub async fn delete(&self, name: &str) -> Result<()> {
        let model_path = self.model_path(name);

        if !model_path.exists() {
            return Err(Error::ModelNotFound(name.to_string()));
        }

        // Delete model file
        tokio::fs::remove_file(&model_path).await?;

        // Delete metadata file if exists
        let metadata_path = model_path.with_extension("json");
        if metadata_path.exists() {
            tokio::fs::remove_file(&metadata_path).await?;
        }

        tracing::info!("Deleted model: {}", name);
        Ok(())
    }

    /// Pull a model from HuggingFace
    pub async fn pull(
        &self,
        name: &str,
    ) -> Result<broadcast::Receiver<PullResponse>> {
        self.download_service.pull(name).await
    }

    /// Check if a model exists locally
    pub fn exists(&self, name: &str) -> bool {
        self.model_path(name).exists()
    }

    /// Get the path to a model file
    pub fn model_path(&self, name: &str) -> PathBuf {
        // Convert model name to safe filename
        // e.g., "meta-llama/Llama-3.2-1B" -> "meta-llama--Llama-3.2-1B.holo"
        let safe_name = name.replace('/', "--");
        self.config.storage.models_dir.join(format!("{}.holo", safe_name))
    }

    /// Read model info from a .holo file
    async fn read_model_info(&self, path: &PathBuf) -> Result<Option<ModelInfo>> {
        let metadata = tokio::fs::metadata(path).await?;
        let modified = metadata.modified()?;
        let size = metadata.len();

        // Extract model name from filename
        let name = path
            .file_stem()
            .and_then(|s| s.to_str())
            .map(|s| s.replace("--", "/"))
            .unwrap_or_else(|| "unknown".to_string());

        // Calculate digest (first 12 chars of SHA256)
        let content = tokio::fs::read(path).await?;
        let mut hasher = Sha256::new();
        hasher.update(&content);
        let hash = hasher.finalize();
        let digest = format!("sha256:{}", hex::encode(&hash[..6]));

        // Read metadata if available
        let metadata_path = path.with_extension("json");
        let details = if metadata_path.exists() {
            let meta_content = tokio::fs::read_to_string(&metadata_path).await?;
            let meta: ModelMetadata = serde_json::from_str(&meta_content)?;
            Some(ModelDetails {
                format: "holo".to_string(),
                family: meta.family.unwrap_or_else(|| "unknown".to_string()),
                families: None,
                parameter_size: meta.parameter_size.unwrap_or_else(|| "unknown".to_string()),
                quantization_level: meta.quantization.unwrap_or_else(|| "none".to_string()),
            })
        } else {
            None
        };

        Ok(Some(ModelInfo {
            name,
            modified_at: chrono::DateTime::<chrono::Utc>::from(modified).to_rfc3339(),
            size,
            digest,
            details,
        }))
    }
}

// Helper for hex encoding
mod hex {
    pub fn encode(bytes: &[u8]) -> String {
        bytes.iter().map(|b| format!("{:02x}", b)).collect()
    }
}
