use std::sync::Arc;
use tokio::sync::RwLock;
use std::collections::HashMap;
use multiplicity_commander_core::CommanderCore;
use multiplicity_common::types::ProposalRequest;
use axum::{
    routing::{get, post},
    Router, extract::{State, Query},
    response::sse::{Event, Sse},
    http::{StatusCode, HeaderMap},
    Json,
};
use serde::Deserialize;
use async_trait::async_trait;
use futures::stream::{self, Stream};
use tokio::sync::mpsc;
use tokio_stream::wrappers::ReceiverStream;
use super::McpTransport;
use uuid::Uuid;

pub struct HttpTransport {
    pub port: u16,
}

#[derive(Clone)]
struct AppState {
    core: Arc<CommanderCore>,
    sessions: Arc<RwLock<HashMap<String, mpsc::Sender<Result<Event, std::convert::Infallible>>>>>,
}

impl axum::extract::FromRef<AppState> for Arc<CommanderCore> {
    fn from_ref(state: &AppState) -> Self {
        state.core.clone()
    }
}

#[async_trait]
impl McpTransport for HttpTransport {
    async fn run(&self, core: Arc<CommanderCore>) -> anyhow::Result<()> {
        let state = AppState {
            core,
            sessions: Arc::new(RwLock::new(HashMap::new())),
        };

        let app = Router::new()
            .route("/tools", get(crate::list_tools))
            .route("/call/:tool_name", post(crate::call_tool))
            .route("/tools/log", get(sse_log_handler))
            .route("/sse", get(sse_handler))
            .route("/message", post(message_handler))
            .with_state(state);

        let addr = format!("127.0.0.1:{}", self.port);
        let listener = tokio::net::TcpListener::bind(&addr).await?;
        tracing::info!("Multiplicity HTTP MCP Server listening on {}", listener.local_addr()?);
        
        axum::serve(listener, app).await?;
        Ok(())
    }
}

async fn sse_log_handler(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Sse<impl Stream<Item = Result<Event, std::convert::Infallible>>>, StatusCode> {
    let expected_token = std::env::var("COMMANDER_SSE_BEARER_TOKEN").map_err(|_| {
        StatusCode::UNAUTHORIZED
    })?;

    let auth_header = headers.get("Authorization")
        .and_then(|h| h.to_str().ok())
        .and_then(|s| s.strip_prefix("Bearer "))
        .ok_or(StatusCode::UNAUTHORIZED)?;

    if auth_header != expected_token {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let receiver = state.core.archivum.subscribe();
    let stream = stream::unfold(receiver, |mut rx| async move {
        match rx.recv().await {
            Ok(event) => {
                let event_type = match event {
                    multiplicity_commander_core::events::UnifiedEvent::WitnessAdded(_) => "witness",
                    multiplicity_commander_core::events::UnifiedEvent::PolicyEvaluated { .. } => "policy",
                    multiplicity_commander_core::events::UnifiedEvent::ReplicationEvent { .. } => "replication",
                    multiplicity_commander_core::events::UnifiedEvent::SystemStatus { .. } => "system",
                };
                let event = Event::default()
                    .event(event_type)
                    .data(serde_json::to_string(&event).unwrap_or_default());
                Some((Ok(event), rx))
            }
            Err(_) => None,
        }
    });

    Ok(Sse::new(stream).keep_alive(axum::response::sse::KeepAlive::default()))
}

#[derive(Deserialize)]
struct SessionQuery {
    sessionId: String,
}

async fn sse_handler(
    State(state): State<AppState>,
) -> Sse<impl Stream<Item = Result<Event, std::convert::Infallible>>> {
    let session_id = Uuid::new_v4().to_string();
    let (tx, rx) = mpsc::channel(100);
    
    state.sessions.write().await.insert(session_id.clone(), tx.clone());
    
    let endpoint_url = format!("/message?sessionId={}", session_id);
    let init_event = Event::default()
        .event("endpoint")
        .data(endpoint_url);
        
    let _ = tx.send(Ok(init_event)).await;
    
    Sse::new(ReceiverStream::new(rx)).keep_alive(axum::response::sse::KeepAlive::default())
}

async fn message_handler(
    State(state): State<AppState>,
    Query(query): Query<SessionQuery>,
    Json(req): Json<serde_json::Value>,
) -> StatusCode {
    let tx = {
        let sessions = state.sessions.read().await;
        match sessions.get(&query.sessionId) {
            Some(tx) => tx.clone(),
            None => return StatusCode::NOT_FOUND,
        }
    };
    
    let id = req.get("id").cloned();
    let method = req.get("method").and_then(|m| m.as_str()).unwrap_or("");
    let params = req.get("params").cloned().unwrap_or(serde_json::Value::Null);
    
    let resp = match method {
        "initialize" => {
            serde_json::json!({
                "jsonrpc": "2.0",
                "id": id,
                "result": {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {
                        "tools": {}
                    },
                    "serverInfo": {
                        "name": "multiplicity-mcp-http",
                        "version": "0.1.0"
                    }
                }
            })
        }
        "notifications/initialized" => {
            return StatusCode::ACCEPTED;
        }
        "tools/list" => {
            let tools_res = crate::list_tools().await;
            serde_json::json!({
                "jsonrpc": "2.0",
                "id": id,
                "result": tools_res.0
            })
        }
        "tools/call" => {
            let name = params.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
            let arguments = params.get("arguments").cloned().unwrap_or(serde_json::Value::Null);
            
            let proposal = ProposalRequest {
                proposal_id: "http-proposal".to_string(),
                payload: arguments,
                rationale: "HTTP MCP tool call".to_string(),
                state_norm: 1.0,
                drift_rate: 0.0,
                contractivity_score: 0.7,
                critique_results: vec![],
                prime_gates: vec![],
                kill_switch_active: false,
                rollback_anchor_sha: None,
                consecutive_failures: 0,
            };
            
            let tool_resp = crate::call_tool(axum::extract::State(state.core.clone()), axum::extract::Path(name), Json(proposal)).await;
            serde_json::json!({
                "jsonrpc": "2.0",
                "id": id,
                "result": {
                    "content": [
                        {
                            "type": "text",
                            "text": serde_json::to_string_pretty(&tool_resp.0).unwrap_or_default()
                        }
                    ]
                }
            })
        }
        _ => {
            if let Some(req_id) = id {
                serde_json::json!({
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "error": {
                        "code": -32601,
                        "message": format!("Method not found: {}", method)
                    }
                })
            } else {
                return StatusCode::BAD_REQUEST;
            }
        }
    };
    
    let event = Event::default()
        .event("message")
        .data(serde_json::to_string(&resp).unwrap_or_default());
        
    let _ = tx.send(Ok(event)).await;
    
    StatusCode::ACCEPTED
}
