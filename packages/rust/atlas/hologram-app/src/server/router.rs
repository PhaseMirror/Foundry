use axum::{
    routing::{delete, get, post},
    Router,
};
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

use super::handlers;
use super::state::AppState;

/// Create the API router with all endpoints
pub fn create_router(state: AppState) -> Router {
    Router::new()
        // Health check
        .route("/", get(handlers::health))
        .route("/health", get(handlers::health))
        // Ollama-compatible endpoints
        .route("/api/chat", post(handlers::ollama::chat))
        .route("/api/generate", post(handlers::ollama::generate))
        .route("/api/tags", get(handlers::ollama::tags))
        .route("/api/ps", get(handlers::ollama::ps))
        .route("/api/pull", post(handlers::ollama::pull))
        .route("/api/show", post(handlers::ollama::show))
        .route("/api/delete", delete(handlers::ollama::delete_model))
        .route("/api/embeddings", post(handlers::ollama::embeddings))
        .route("/api/version", get(handlers::ollama::version))
        // OpenAI-compatible endpoints
        .route("/v1/chat/completions", post(handlers::openai::chat_completions))
        .route("/v1/models", get(handlers::openai::models))
        // State and middleware
        .with_state(state)
        .layer(CorsLayer::permissive())
        .layer(TraceLayer::new_for_http())
}
