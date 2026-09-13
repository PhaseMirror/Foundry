//! axum entrypoint mirroring `app/main.py` + `run.py`.
//!
//! - `GET  /health`  -> `{"status": "healthy"}`
//! - `POST /webhook` -> `{"status": <conclusion>}` (or
//!   `401 {"detail": "Invalid signature"}` /
//!   `500 {"detail": <error>}` /
//!   `{"msg": "Ignored event"}`).

use axum::{
    body::Bytes,
    extract::State,
    http::{HeaderMap, HeaderValue, StatusCode},
    response::{IntoResponse, Json},
    routing::{get, post},
    Router,
};
use github_adapter::config::Config;
use github_adapter::github::GithubClient;
use github_adapter::mcp::McpClient;
use github_adapter::payload::{is_supported_action, is_supported_event, PullRequestEvent};
use github_adapter::signature::verify_signature;
use github_adapter::webhook::run_transition;
use github_adapter::Outcome;
use serde_json::{json, Value};
use std::sync::Arc;
use tokio::sync::Mutex;

/// Server context wired at startup, mirroring the Python module globals
/// (`github_client`, `mcp_client`) created in `lifespan`.
pub struct AppState {
    pub github: GithubClient,
    pub mcp: Mutex<McpClient>,
    pub config: Config,
}

#[tokio::main]
async fn main() {
    let config = Config::from_env();

    // `lifespan`: TCP when host/port configured, subprocess otherwise.
    let mcp = if let (Some(host), Some(port)) = (&config.mcp_host, config.mcp_port) {
        McpClient::connect_tcp(host, port)
            .await
            .unwrap_or_else(|e| panic!("MCP TCP connect failed: {e}"))
    } else {
        let server_cmd = config.mcp_server_cmd.clone().unwrap_or_else(|| {
            vec![
                String::from("cargo"),
                String::from("run"),
                String::from("-p"),
                String::from("multiplicity-mcp"),
            ]
        });
        McpClient::spawn(&server_cmd)
            .await
            .unwrap_or_else(|e| panic!("MCP subprocess spawn failed: {e}"))
    };

    let state = Arc::new(AppState {
        github: GithubClient::new(&config.github_access_token),
        mcp: Mutex::new(mcp),
        config,
    });

    let app = Router::new()
        .route("/health", get(health))
        .route("/webhook", post(webhook))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8000")
        .await
        .expect("bind");
    tracing::info!(
        "github-adapter listening on {}",
        listener.local_addr().unwrap()
    );
    axum::serve(listener, app).await.expect("server");
}

async fn health() -> impl IntoResponse {
    Json(json!({ "status": "healthy" }))
}

/// `X-Hub-Signature-256` header value (empty when absent).
fn sign_header(headers: &HeaderMap) -> &str {
    headers
        .get("X-Hub-Signature-256")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
}

async fn webhook(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    body: Bytes,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    // 1. Verify signature.
    if !verify_signature(
        state.config.github_webhook_secret.as_bytes(),
        &body,
        sign_header(&headers),
    ) {
        return Err((
            StatusCode::UNAUTHORIZED,
            Json(json!({ "detail": "Invalid signature" })),
        ));
    }

    // 2. Parse event and action filters.
    let event_type = headers.get("X-GitHub-Event").map(HeaderValue::as_bytes);
    if !is_supported_event(event_type.and_then(|b| std::str::from_utf8(b).ok())) {
        return Ok(Json(json!({ "msg": "Ignored event" })));
    }
    let event: PullRequestEvent = match serde_json::from_slice(&body) {
        Ok(event) => event,
        Err(_) => return Ok(Json(json!({ "msg": "Ignored event" }))),
    };
    if !is_supported_action(&event.action) {
        return Ok(Json(json!({ "msg": "Ignored action" })));
    }

    // 3-8. Full governance flow (get_pr, check run, MCP, dispatch).
    let mut mcp = state.mcp.lock().await;
    match run_transition(&state.github, &mut mcp, &event, &state.config).await {
        Ok(Outcome::Evaluated(conclusion)) => Ok(Json(json!({ "status": conclusion }))),
        // mcp evaluation raised -> 500 (HTTPException(500, detail=str(e))).
        Ok(Outcome::Failed(detail)) => Err(server_error(&detail)),
        // transport/parse/github failure -> generic 500 like the unguarded
        // Python steps.
        Err(e) => Err(server_error(&e.to_string())),
    }
}

fn server_error(detail: &str) -> (StatusCode, Json<Value>) {
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        Json(json!({ "detail": detail })),
    )
}
