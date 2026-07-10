pub mod ollama;
pub mod openai;

use axum::response::IntoResponse;

/// Health check endpoint
pub async fn health() -> impl IntoResponse {
    "Hologram is running"
}
