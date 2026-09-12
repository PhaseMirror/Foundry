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
use crate::types::ollama::*;

/// POST /api/chat - Chat completion
pub async fn chat(
    State(state): State<AppState>,
    Json(request): Json<ChatRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    if request.stream {
        // Streaming response
        let stream = state
            .chat()
            .complete_stream(request)
            .await
            .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

        let sse_stream = stream.map(|result| -> Result<Event, Infallible> {
            Ok(result
                .map(|response| Event::default().json_data(response).unwrap())
                .unwrap_or_else(|e| Event::default().data(format!("error: {}", e))))
        });

        Ok(Sse::new(sse_stream).into_response())
    } else {
        // Non-streaming response
        let response = state
            .chat()
            .complete(request)
            .await
            .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

        Ok(Json(response).into_response())
    }
}

/// POST /api/generate - Text generation
pub async fn generate(
    State(state): State<AppState>,
    Json(request): Json<GenerateRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    if request.stream {
        // Streaming response
        let stream = state
            .generate()
            .generate_stream(request)
            .await
            .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

        let sse_stream = stream.map(|result| -> Result<Event, Infallible> {
            Ok(result
                .map(|response| Event::default().json_data(response).unwrap())
                .unwrap_or_else(|e| Event::default().data(format!("error: {}", e))))
        });

        Ok(Sse::new(sse_stream).into_response())
    } else {
        // Non-streaming response
        let response = state
            .generate()
            .generate(request)
            .await
            .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

        Ok(Json(response).into_response())
    }
}

/// GET /api/tags - List models
pub async fn tags(
    State(state): State<AppState>,
) -> Result<Json<ListModelsResponse>, (StatusCode, String)> {
    let models = state
        .models()
        .list()
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(ListModelsResponse { models }))
}

/// GET /api/ps - List running models
pub async fn ps(State(state): State<AppState>) -> Json<PsResponse> {
    let processes = state.processes();
    let guard = processes.read().await;
    Json(guard.list())
}

/// POST /api/pull - Pull a model
pub async fn pull(
    State(state): State<AppState>,
    Json(request): Json<PullRequest>,
) -> Result<impl IntoResponse, (StatusCode, String)> {
    let rx = state
        .models()
        .pull(&request.name)
        .await
        .map_err(|e| (StatusCode::BAD_REQUEST, e.to_string()))?;

    if request.stream {
        // Streaming progress updates
        let stream =
            tokio_stream::wrappers::BroadcastStream::new(rx).map(|result| -> Result<Event, Infallible> {
                Ok(result
                    .map(|progress| Event::default().json_data(progress).unwrap())
                    .unwrap_or_else(|e| Event::default().data(format!("error: {}", e))))
            });

        Ok(Sse::new(stream).into_response())
    } else {
        // Wait for completion and return final status
        let mut rx = rx;
        let mut last_response = None;

        while let Ok(progress) = rx.recv().await {
            last_response = Some(progress);
        }

        match last_response {
            Some(response) => Ok(Json(response).into_response()),
            None => Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                "No response received".to_string(),
            )),
        }
    }
}

/// POST /api/show - Show model info
pub async fn show(
    State(state): State<AppState>,
    Json(request): Json<ShowRequest>,
) -> Result<Json<ShowResponse>, (StatusCode, String)> {
    let response = state
        .models()
        .show(&request.name)
        .await
        .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

    Ok(Json(response))
}

/// DELETE /api/delete - Delete a model
pub async fn delete_model(
    State(state): State<AppState>,
    Json(request): Json<DeleteRequest>,
) -> Result<StatusCode, (StatusCode, String)> {
    state
        .models()
        .delete(&request.name)
        .await
        .map_err(|e| (StatusCode::from(e.clone()), e.to_string()))?;

    Ok(StatusCode::OK)
}

/// POST /api/embeddings - Generate embeddings
pub async fn embeddings(
    State(_state): State<AppState>,
    Json(request): Json<EmbeddingsRequest>,
) -> Result<Json<EmbeddingsResponse>, (StatusCode, String)> {
    // Stub implementation - return dummy embeddings
    let input_count = match &request.input {
        EmbeddingsInput::Single(_) => 1,
        EmbeddingsInput::Multiple(v) => v.len(),
    };

    // Return dummy 384-dimensional embeddings
    let embeddings: Vec<Vec<f32>> = (0..input_count).map(|_| vec![0.0f32; 384]).collect();

    Ok(Json(EmbeddingsResponse {
        model: request.model,
        embeddings,
    }))
}

/// GET /api/version - Get version info
pub async fn version() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "version": env!("CARGO_PKG_VERSION")
    }))
}
