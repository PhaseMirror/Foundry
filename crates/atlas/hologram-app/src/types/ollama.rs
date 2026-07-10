//! Ollama-compatible API types

use serde::{Deserialize, Serialize};

/// Chat message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Message {
    pub role: String,
    pub content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub images: Option<Vec<String>>,
}

/// Chat completion request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatRequest {
    pub model: String,
    pub messages: Vec<Message>,
    #[serde(default)]
    pub stream: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub format: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<ModelOptions>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub keep_alive: Option<String>,
}

/// Chat completion response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatResponse {
    pub model: String,
    pub created_at: String,
    pub message: Message,
    pub done: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub total_duration: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub load_duration: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt_eval_count: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt_eval_duration: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub eval_count: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub eval_duration: Option<u64>,
}

/// Text generation request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateRequest {
    pub model: String,
    pub prompt: String,
    #[serde(default)]
    pub stream: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub suffix: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub images: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub format: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<ModelOptions>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub system: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub template: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<Vec<i64>>,
    #[serde(default)]
    pub raw: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub keep_alive: Option<String>,
}

/// Text generation response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateResponse {
    pub model: String,
    pub created_at: String,
    pub response: String,
    pub done: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context: Option<Vec<i64>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub total_duration: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub load_duration: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt_eval_count: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt_eval_duration: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub eval_count: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub eval_duration: Option<u64>,
}

/// Model options for generation
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ModelOptions {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_k: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub num_predict: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stop: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub seed: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub num_ctx: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub repeat_penalty: Option<f32>,
}

/// Model information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelInfo {
    pub name: String,
    pub modified_at: String,
    pub size: u64,
    pub digest: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<ModelDetails>,
}

/// Model details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelDetails {
    pub format: String,
    pub family: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub families: Option<Vec<String>>,
    pub parameter_size: String,
    pub quantization_level: String,
}

/// List models response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ListModelsResponse {
    pub models: Vec<ModelInfo>,
}

/// Pull model request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PullRequest {
    pub name: String,
    #[serde(default)]
    pub insecure: bool,
    #[serde(default)]
    pub stream: bool,
}

/// Pull model response (streaming)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PullResponse {
    pub status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub digest: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub total: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub completed: Option<u64>,
}

/// Show model request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShowRequest {
    pub name: String,
}

/// Show model response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShowResponse {
    pub modelfile: String,
    pub parameters: String,
    pub template: String,
    pub details: ModelDetails,
}

/// Delete model request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeleteRequest {
    pub name: String,
}

/// Running model info
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RunningModel {
    pub name: String,
    pub model: String,
    pub size: u64,
    pub digest: String,
    pub expires_at: String,
    pub size_vram: u64,
}

/// List running models response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PsResponse {
    pub models: Vec<RunningModel>,
}

/// Embeddings request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingsRequest {
    pub model: String,
    pub input: EmbeddingsInput,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub options: Option<ModelOptions>,
}

/// Embeddings input (single string or array)
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum EmbeddingsInput {
    Single(String),
    Multiple(Vec<String>),
}

/// Embeddings response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EmbeddingsResponse {
    pub model: String,
    pub embeddings: Vec<Vec<f32>>,
}
