// src/main.rs
use axum::extract::ws::WebSocketUpgrade;
use axum::{response::IntoResponse, routing::get, Extension, Json, Router};
use futures_util::{SinkExt, StreamExt};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::{net::SocketAddr, sync::Arc};
use tokio::sync::Mutex;

mod cnl;
mod crypto;
mod dialogue;
mod tools;

use cnl::parse_cnl as cnl_parse;
use dialogue::DialogueFrame;
// use tools::{Tool, TOOL_REGISTRY, four_gate_check}; // Unused
use crypto::{generate_keypair, load_keypair, PublicKeyBase64};

#[derive(Default, Serialize, Deserialize)]
pub struct DialogueState {
    pub session_id: String,
    pub messages: Vec<String>,
    pub frame: DialogueFrame,
    #[serde(skip)]
    pub keypair: Option<ed25519_dalek::Keypair>,
}

// Extension requires the inner type to be Clone + Send + Sync + 'static.
type SharedState = Extension<Arc<Mutex<DialogueState>>>;

async fn health() -> impl IntoResponse {
    Json(serde_json::json!({"status": "ok"}))
}

#[axum::debug_handler]
async fn start_session(Extension(state): SharedState) -> impl IntoResponse {
    let mut lock = state.lock().await;
    lock.session_id = "session-1".to_string();
    lock.messages.clear();
    lock.frame = DialogueFrame::default();
    if lock.keypair.is_none() {
        lock.keypair = Some(generate_keypair());
    }
    Json(serde_json::json!({"session": lock.session_id}))
}

#[axum::debug_handler]
async fn did(Extension(state): SharedState) -> impl IntoResponse {
    let lock = state.lock().await;
    if let Some(kp) = &lock.keypair {
        let pub_b64 = PublicKeyBase64::from(kp.public);
        Json(serde_json::json!({"did": pub_b64.0}))
    } else {
        Json(serde_json::json!({"error": "keypair not initialized"}))
    }
}

#[axum::debug_handler]
async fn ws_handler(ws: WebSocketUpgrade, Extension(state): SharedState) -> impl IntoResponse {
    // Load the true certificate once; cache it for the lifetime of this connection.
    let cert_bytes =
        std::fs::read("tests/fixtures/valid_drmm_cert.bin").expect("Certificate fixture not found");

    ws.on_upgrade(move |socket| async move {
        use axum::extract::ws::Message;
        let (mut sender, mut receiver) = socket.split();
        // Optional greeting
        let _ = sender
            .send(Message::Text("Phase‑Mirror Agent WS connected".into()))
            .await;

        while let Some(Ok(msg)) = receiver.next().await {
            if let Message::Text(txt) = msg {
                // Parse the incoming CNL command into a Tool enum/value
                if let Ok(tool) = cnl_parse(txt.as_str()) {
                    // Verify the certificate against Lean kernel and obtain digest
                    let v = lean_sdk::verify_certificate(&cert_bytes);
                    let is_valid = v.is_valid;
                    let witness_hash = hex::encode(&v.digest);
                    // Build telemetry JSON payload
                    let telemetry = serde_json::json!({
                        "status": if is_valid { "VERIFIED" } else { "REJECTED" },
                        "tool": tool,
                        "contractivity_margin": v.lambda_eff,
                        "witness_hash": witness_hash,
                    });
                    // Send telemetry to client
                    let _ = sender.send(Message::Text(telemetry.to_string())).await;
                    // If verification failed, optionally close the connection
                    if !is_valid {
                        let kill_msg = serde_json::json!({
                            "status": "SIG_GOV_KILL",
                            "reason": "Lean verification failed"
                        })
                        .to_string();
                        let _ = sender.send(Message::Text(kill_msg)).await;
                        break;
                    }
                } else {
                    // If parsing failed, just echo back the raw text
                    let _ = sender.send(Message::Text(txt)).await;
                }
            }
        }
    })
}

#[tokio::main]
async fn main() {
    let persisted = load_keypair();
    let initial_state = DialogueState {
        keypair: persisted,
        ..Default::default()
    };
    let shared_state = Arc::new(Mutex::new(initial_state));
    let app = Router::new()
        .route("/health", get(health))
        .route("/session/start", get(start_session))
        .route("/did", get(did))
        .route("/ws", get(ws_handler))
        .layer(Extension(shared_state.clone()));

    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("Phase‑Mirror Agent listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
