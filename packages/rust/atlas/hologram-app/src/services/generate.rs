use std::sync::Arc;

use futures::StreamExt;
use tokio::sync::RwLock;
use tokio_stream::wrappers::BroadcastStream;
use tokio_stream::Stream;

use crate::config::Config;
use crate::types::ollama::{GenerateRequest, GenerateResponse};
use crate::{Error, Result};

use super::{ModelManager, ProcessManager};

/// Service for text generation
pub struct GenerateService {
    #[allow(dead_code)]
    config: Config,
    model_manager: Arc<ModelManager>,
    #[allow(dead_code)]
    process_manager: Arc<RwLock<ProcessManager>>,
}

impl GenerateService {
    pub fn new(
        config: Config,
        model_manager: Arc<ModelManager>,
        process_manager: Arc<RwLock<ProcessManager>>,
    ) -> Self {
        Self {
            config,
            model_manager,
            process_manager,
        }
    }

    /// Generate text (non-streaming)
    pub async fn generate(&self, request: GenerateRequest) -> Result<GenerateResponse> {
        // Validate model exists
        if !self.model_manager.exists(&request.model) {
            return Err(Error::ModelNotFound(request.model.clone()));
        }

        let now = chrono::Utc::now();

        // TODO: Actually run inference when hologram-onnx is integrated
        let response_text = format!(
            "[Hologram stub response - inference not yet implemented]\n\
             Model: {}\n\
             Prompt length: {} chars",
            request.model,
            request.prompt.len()
        );

        Ok(GenerateResponse {
            model: request.model,
            created_at: now.to_rfc3339(),
            response: response_text,
            done: true,
            context: None,
            total_duration: Some(0),
            load_duration: Some(0),
            prompt_eval_count: Some(0),
            prompt_eval_duration: Some(0),
            eval_count: Some(0),
            eval_duration: Some(0),
        })
    }

    /// Generate text with streaming
    pub async fn generate_stream(
        &self,
        request: GenerateRequest,
    ) -> Result<impl Stream<Item = Result<GenerateResponse>>> {
        // Validate model exists
        if !self.model_manager.exists(&request.model) {
            return Err(Error::ModelNotFound(request.model.clone()));
        }

        let (tx, rx) = tokio::sync::broadcast::channel(100);
        let model = request.model.clone();

        // Spawn streaming task
        tokio::spawn(async move {
            let now = chrono::Utc::now();

            // Simulate streaming response
            let response_parts = [
                "[Hologram stub response]\n",
                "Inference not yet implemented.\n",
                "This is a placeholder response.\n",
            ];

            for (i, part) in response_parts.iter().enumerate() {
                let is_last = i == response_parts.len() - 1;

                let _ = tx.send(GenerateResponse {
                    model: model.clone(),
                    created_at: now.to_rfc3339(),
                    response: part.to_string(),
                    done: is_last,
                    context: None,
                    total_duration: if is_last { Some(0) } else { None },
                    load_duration: None,
                    prompt_eval_count: None,
                    prompt_eval_duration: None,
                    eval_count: None,
                    eval_duration: None,
                });

                // Small delay to simulate streaming
                tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;
            }
        });

        let stream =
            BroadcastStream::new(rx).map(|r| r.map_err(|e| Error::Inference(e.to_string())));

        Ok(stream)
    }
}
