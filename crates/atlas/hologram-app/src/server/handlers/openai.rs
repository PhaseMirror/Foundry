use axum::{
    extract::State,
    http::StatusCode,
    response::{
        sse::{Event, Sse},
        IntoResponse, Json,
    },
};
use futures::stream::StreamExt;
use std::convert::Infallible;

use crate::server::state::AppState;
use crate::types::ollama::Message;
use crate::types::openai::*;

/// POST /v1/chat/completions - OpenAI-compatible chat completions
pub async fn chat_completions(
    State(state): State<AppState>,
    Json(request): Json<OpenAIChatRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    // Convert OpenAI request to Ollama format
    let ollama_messages: Vec<Message> = request
        .messages
        .iter()
        .map(|m| Message {
            role: m.role.clone(),
            content: m.content.clone(),
            images: None,
        })
        .collect();

    let ollama_request = crate::types::ollama::ChatRequest {
        model: request.model.clone(),
        messages: ollama_messages,
        stream: request.stream,
        format: None,
        options: Some(crate::types::ollama::ModelOptions {
            temperature: request.temperature,
            top_p: request.top_p,
            num_predict: request.max_tokens,
            stop: request.stop.clone(),
            ..Default::default()
        }),
        keep_alive: None,
    };

    if request.stream {
        // Streaming response
        let stream = state
            .chat()
            .complete_stream(ollama_request)
            .await
            .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

        let id = format!("chatcmpl-{}", uuid::Uuid::new_v4());
        let model = request.model.clone();
        let created = chrono::Utc::now().timestamp();

        let sse_stream = stream.map(move |result| -> Result<Event, Infallible> {
            Ok(match result {
                Ok(response) => {
                    let openai_response = OpenAIChatStreamResponse {
                        id: id.clone(),
                        object: "chat.completion.chunk".to_string(),
                        created,
                        model: model.clone(),
                        choices: vec![OpenAIStreamChoice {
                            index: 0,
                            delta: OpenAIDelta {
                                role: if response.done {
                                    None
                                } else {
                                    Some("assistant".to_string())
                                },
                                content: if response.done {
                                    None
                                } else {
                                    Some(response.message.content)
                                },
                            },
                            finish_reason: if response.done {
                                Some("stop".to_string())
                            } else {
                                None
                            },
                        }],
                    };
                    Event::default().data(serde_json::to_string(&openai_response).unwrap())
                }
                Err(e) => Event::default().data(format!("error: {}", e)),
            })
        });

        Ok(Sse::new(sse_stream).into_response())
    } else {
        // Non-streaming response
        let response = state
            .chat()
            .complete(ollama_request)
            .await
            .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

        let openai_response = OpenAIChatResponse {
            id: format!("chatcmpl-{}", uuid::Uuid::new_v4()),
            object: "chat.completion".to_string(),
            created: chrono::Utc::now().timestamp(),
            model: request.model,
            choices: vec![OpenAIChoice {
                index: 0,
                message: OpenAIMessage {
                    role: "assistant".to_string(),
                    content: response.message.content,
                    name: None,
                },
                finish_reason: Some("stop".to_string()),
            }],
            usage: OpenAIUsage {
                prompt_tokens: response.prompt_eval_count.unwrap_or(0) as i32,
                completion_tokens: response.eval_count.unwrap_or(0) as i32,
                total_tokens: (response.prompt_eval_count.unwrap_or(0)
                    + response.eval_count.unwrap_or(0)) as i32,
            },
        };

        Ok(Json(openai_response).into_response())
    }
}

/// GET /v1/models - List available models (OpenAI format)
pub async fn models(
    State(state): State<AppState>,
) -> Result<Json<OpenAIModelsResponse>, (StatusCode, String)> {
    let models = state
        .models()
        .list()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let openai_models: Vec<OpenAIModel> = models
        .iter()
        .map(|m| {
            let created = chrono::DateTime::parse_from_rfc3339(&m.modified_at)
                .map(|dt| dt.timestamp())
                .unwrap_or(0);

            OpenAIModel {
                id: m.name.clone(),
                object: "model".to_string(),
                created,
                owned_by: "hologram".to_string(),
            }
        })
        .collect();

    Ok(Json(OpenAIModelsResponse {
        object: "list".to_string(),
        data: openai_models,
    }))
}
