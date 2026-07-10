//! OpenAI-compatible API types

use serde::{Deserialize, Serialize};

/// OpenAI chat message
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIMessage {
    pub role: String,
    pub content: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
}

/// OpenAI chat completion request
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIChatRequest {
    pub model: String,
    pub messages: Vec<OpenAIMessage>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub temperature: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_p: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub n: Option<i32>,
    #[serde(default)]
    pub stream: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub stop: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub max_tokens: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub presence_penalty: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub frequency_penalty: Option<f32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub user: Option<String>,
}

/// OpenAI chat completion response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIChatResponse {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub model: String,
    pub choices: Vec<OpenAIChoice>,
    pub usage: OpenAIUsage,
}

/// OpenAI choice
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIChoice {
    pub index: i32,
    pub message: OpenAIMessage,
    pub finish_reason: Option<String>,
}

/// OpenAI streaming choice (delta format)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIStreamChoice {
    pub index: i32,
    pub delta: OpenAIDelta,
    pub finish_reason: Option<String>,
}

/// OpenAI delta for streaming
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIDelta {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub role: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub content: Option<String>,
}

/// OpenAI streaming response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIChatStreamResponse {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub model: String,
    pub choices: Vec<OpenAIStreamChoice>,
}

/// OpenAI usage stats
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIUsage {
    pub prompt_tokens: i32,
    pub completion_tokens: i32,
    pub total_tokens: i32,
}

/// OpenAI models list response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIModelsResponse {
    pub object: String,
    pub data: Vec<OpenAIModel>,
}

/// OpenAI model info
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIModel {
    pub id: String,
    pub object: String,
    pub created: i64,
    pub owned_by: String,
}

/// OpenAI error response
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIError {
    pub error: OpenAIErrorDetail,
}

/// OpenAI error detail
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenAIErrorDetail {
    pub message: String,
    #[serde(rename = "type")]
    pub error_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub param: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub code: Option<String>,
}
