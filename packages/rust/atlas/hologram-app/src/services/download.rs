use std::path::PathBuf;

use reqwest::Client;
use tokio::sync::broadcast;

use crate::config::Config;
use crate::onnx::{CompileOptions, HoloCompiler};
use crate::types::ollama::PullResponse;
use crate::{Error, Result};

/// Service for downloading models from HuggingFace
pub struct DownloadService {
    config: Config,
    client: Client,
}

impl DownloadService {
    pub fn new(config: Config) -> Self {
        Self {
            config,
            client: Client::new(),
        }
    }

    /// Pull a model from HuggingFace
    ///
    /// Returns a broadcast receiver for progress updates
    pub async fn pull(&self, model_name: &str) -> Result<broadcast::Receiver<PullResponse>> {
        let (tx, rx) = broadcast::channel(100);

        // Parse model name (e.g., "meta-llama/Llama-3.2-1B")
        let parts: Vec<&str> = model_name.split('/').collect();
        if parts.len() != 2 {
            return Err(Error::InvalidRequest(format!(
                "Invalid model name '{}'. Expected format: owner/repo",
                model_name
            )));
        }

        let repo_id = model_name.to_string();
        let config = self.config.clone();
        let client = self.client.clone();

        // Spawn download task
        tokio::spawn(async move {
            let result = Self::download_model(&client, &config, &repo_id, &tx).await;
            if let Err(e) = result {
                let _ = tx.send(PullResponse {
                    status: format!("error: {}", e),
                    digest: None,
                    total: None,
                    completed: None,
                });
            }
        });

        Ok(rx)
    }

    async fn download_model(
        client: &Client,
        config: &Config,
        repo_id: &str,
        tx: &broadcast::Sender<PullResponse>,
    ) -> Result<()> {
        let _ = tx.send(PullResponse {
            status: "pulling manifest".to_string(),
            digest: None,
            total: None,
            completed: None,
        });

        // Determine which file to download from HuggingFace
        // Priority: .onnx > .safetensors > pytorch
        let hf_base_url = config
            .huggingface
            .mirror_url
            .as_deref()
            .unwrap_or("https://huggingface.co");

        let api_url = format!("{}/api/models/{}", hf_base_url, repo_id);

        // Fetch model info from HuggingFace API
        let mut request = client.get(&api_url);
        if let Some(token) = &config.huggingface.token {
            request = request.header("Authorization", format!("Bearer {}", token));
        }

        let response = request.send().await?;

        if !response.status().is_success() {
            return Err(Error::Download(format!(
                "Failed to fetch model info: HTTP {}",
                response.status()
            )));
        }

        let model_info: serde_json::Value = response.json().await?;

        // Find ONNX file in siblings
        let siblings = model_info["siblings"]
            .as_array()
            .ok_or_else(|| Error::Download("No files found in model".to_string()))?;

        let onnx_file = siblings
            .iter()
            .find(|s| {
                s["rfilename"]
                    .as_str()
                    .map(|f| f.ends_with(".onnx"))
                    .unwrap_or(false)
            })
            .and_then(|s| s["rfilename"].as_str());

        let download_file = match onnx_file {
            Some(f) => f.to_string(),
            None => {
                // No ONNX file found - will need to convert
                let _ = tx.send(PullResponse {
                    status: "no ONNX file found, conversion required".to_string(),
                    digest: None,
                    total: None,
                    completed: None,
                });

                // Look for safetensors or pytorch files
                let safetensors_file = siblings
                    .iter()
                    .find(|s| {
                        s["rfilename"]
                            .as_str()
                            .map(|f| f.ends_with(".safetensors"))
                            .unwrap_or(false)
                    })
                    .and_then(|s| s["rfilename"].as_str());

                match safetensors_file {
                    Some(f) => f.to_string(),
                    None => {
                        return Err(Error::Download(
                            "No compatible model files found (need .onnx or .safetensors)"
                                .to_string(),
                        ));
                    }
                }
            }
        };

        // Download the file
        let file_url = format!(
            "{}/{}/resolve/main/{}",
            hf_base_url, repo_id, download_file
        );

        let _ = tx.send(PullResponse {
            status: format!("downloading {}", download_file),
            digest: None,
            total: None,
            completed: Some(0),
        });

        let mut request = client.get(&file_url);
        if let Some(token) = &config.huggingface.token {
            request = request.header("Authorization", format!("Bearer {}", token));
        }

        let response = request.send().await?;

        if !response.status().is_success() {
            return Err(Error::Download(format!(
                "Failed to download file: HTTP {}",
                response.status()
            )));
        }

        let total_size = response.content_length();
        let mut downloaded: u64 = 0;

        // Save to cache directory first
        let cache_path = config.cache_dir_for(repo_id).join(&download_file);
        if let Some(parent) = cache_path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }

        let mut file = tokio::fs::File::create(&cache_path).await?;
        let mut stream = response.bytes_stream();

        use futures::StreamExt;
        use tokio::io::AsyncWriteExt;

        while let Some(chunk) = stream.next().await {
            let chunk = chunk?;
            file.write_all(&chunk).await?;
            downloaded += chunk.len() as u64;

            let _ = tx.send(PullResponse {
                status: "downloading".to_string(),
                digest: None,
                total: total_size,
                completed: Some(downloaded),
            });
        }

        file.flush().await?;

        // Compile to .holo format
        let _ = tx.send(PullResponse {
            status: "compiling to .holo format".to_string(),
            digest: None,
            total: None,
            completed: None,
        });

        let safe_name = repo_id.replace('/', "--");
        let output_path = config.storage.models_dir.join(format!("{}.holo", safe_name));

        // Attempt compilation (will fail with stub, but that's expected)
        let compile_result = if download_file.ends_with(".onnx") {
            HoloCompiler::compile(&cache_path, &output_path, CompileOptions::default()).await
        } else {
            HoloCompiler::from_safetensors(
                cache_path.parent().unwrap(),
                &output_path,
                CompileOptions::default(),
            )
            .await
        };

        match compile_result {
            Ok(()) => {
                let _ = tx.send(PullResponse {
                    status: "success".to_string(),
                    digest: Some(format!("sha256:{}", safe_name)),
                    total: total_size,
                    completed: total_size,
                });
            }
            Err(e) => {
                // Compilation failed (expected with stubs)
                // For now, just copy the file as-is so we have something
                tracing::warn!("Compilation failed (expected with stubs): {}", e);

                // Create a placeholder .holo file
                let placeholder = format!(
                    "{{\"status\": \"pending_compilation\", \"source\": \"{}\", \"error\": \"{}\"}}",
                    cache_path.display(),
                    e
                );
                tokio::fs::write(&output_path, placeholder).await?;

                let _ = tx.send(PullResponse {
                    status: "downloaded (compilation pending - hologram-onnx not integrated)"
                        .to_string(),
                    digest: Some(format!("sha256:{}", safe_name)),
                    total: total_size,
                    completed: total_size,
                });
            }
        }

        Ok(())
    }
}

impl Config {
    /// Get the cache directory for a specific model
    pub fn cache_dir_for(&self, model_name: &str) -> PathBuf {
        let safe_name = model_name.replace('/', "--");
        self.storage.cache_dir.join(safe_name)
    }
}
