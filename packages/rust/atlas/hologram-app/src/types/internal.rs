//! Internal types used within the application

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Internal model representation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredModel {
    pub name: String,
    pub path: PathBuf,
    pub size: u64,
    pub digest: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub modified_at: chrono::DateTime<chrono::Utc>,
    pub format: ModelFormat,
    pub metadata: ModelMetadata,
}

/// Model file format
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum ModelFormat {
    Holo,
    Onnx,
    SafeTensors,
}

/// Model metadata
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ModelMetadata {
    pub family: Option<String>,
    pub parameter_size: Option<String>,
    pub quantization: Option<String>,
    pub context_length: Option<usize>,
    pub source: Option<ModelSource>,
}

/// Where the model came from
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelSource {
    pub provider: String,
    pub repo_id: String,
    pub revision: Option<String>,
}

/// Download progress information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DownloadProgress {
    pub status: DownloadStatus,
    pub total_bytes: Option<u64>,
    pub downloaded_bytes: u64,
    pub file_name: Option<String>,
}

/// Download status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DownloadStatus {
    Pending,
    Downloading,
    Converting,
    Compiling,
    Complete,
    Failed,
}

/// A running model process
#[derive(Debug, Clone)]
pub struct LoadedModelProcess {
    pub id: String,
    pub model_name: String,
    pub loaded_at: chrono::DateTime<chrono::Utc>,
    pub expires_at: chrono::DateTime<chrono::Utc>,
    pub memory_usage: u64,
}
