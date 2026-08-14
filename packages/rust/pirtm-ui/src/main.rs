use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    response::IntoResponse,
    routing::get,
    Router,
};
use tower_http::services::ServeDir;
use serde::Serialize;
use futures_util::{sink::SinkExt, stream::StreamExt};
use pirtm_stdlib::prelude::*;
use pirtm_invariants::PhaseMirrorInvariants;
use async_trait::async_trait;
use std::time::Duration;

#[derive(Serialize)]
#[serde(tag = "type")]
enum UiEvent {
    #[serde(rename = "user_input")] UserInput { text: String },
    #[serde(rename = "compiled")] Compiled { mocword: String, c: f64, rsc: f64 },
    #[serde(rename = "invariant_pass")] InvariantPass { message: String },
    #[serde(rename = "execution_start")] ExecStart { action: String },
    #[serde(rename = "execution_success")] ExecSuccess { action_id: String, message: String },
    #[serde(rename = "execution_failure")] ExecFailure { error: String },
    #[serde(rename = "retraction")] Retraction { message: String },
    #[serde(rename = "rollback")] Rollback { action_id: String, result: String },
    #[serde(rename = "invariant_fail")] InvariantFail { diagnostic: String, suggestion: String },
}

#[derive(Clone, Debug, PartialEq)]
enum Mode { Assert, Retract }

#[derive(Debug)]
enum VerifiedAction {
    Deploy { service: String, target: String, replicas: u32 },
    Revoke { previous_action_id: String },
}

#[async_trait]
trait ActionExecutor {
    async fn execute(&self, action: &VerifiedAction) -> Result<String, String>;
}

use k8s_openapi::api::apps::v1::Deployment;
use kube::{api::{Api, PostParams, DeleteParams}, Client};
use serde_json::json;

#[derive(Clone)]
struct KubeExecutor {}

impl KubeExecutor {
    async fn new() -> Result<Self, String> {
        // Mocking since k8s is not available locally
        println!("Initializing Mock KubeExecutor");
        Ok(Self {})
    }
}

#[async_trait]
impl ActionExecutor for KubeExecutor {
    async fn execute(&self, action: &VerifiedAction) -> Result<String, String> {
        match action {
            VerifiedAction::Deploy { service, .. } => {
                println!("MOCK: Deploying service {}", service);
                Ok(service.clone())
            }
            VerifiedAction::Revoke { previous_action_id } => {
                println!("MOCK: Revoking action {}", previous_action_id);
                Ok(previous_action_id.clone())
            }
        }
    }
}

struct DialogueFrame {
    strata: Vec<MOCWord>,
    executor: KubeExecutor,
    last_action_id: Option<String>,
}

impl DialogueFrame {
    fn new(executor: KubeExecutor) -> Self { Self { strata: Vec::new(), executor, last_action_id: None } }
}

async fn handle_socket(mut socket: WebSocket, executor: KubeExecutor) {
    let mut dialogue = DialogueFrame::new(executor);

    while let Some(Ok(msg)) = socket.recv().await {
        if let Message::Text(text) = msg {
            let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::UserInput { text: text.clone() }).unwrap())).await;
            
            let tokens: Vec<&str> = text.split_whitespace().collect();
            if tokens.is_empty() { continue; }

            let mut mode = Mode::Assert;
            let mut ast = Ap(2); 
            let mut first = true;
            let mut parsed_action = None;

            if tokens.contains(&"deploy") {
                parsed_action = Some(VerifiedAction::Deploy { service: "web-service".to_string(), target: "cluster".to_string(), replicas: 3 });
            } else if tokens.contains(&"revoke") {
                mode = Mode::Retract;
                parsed_action = Some(VerifiedAction::Revoke { previous_action_id: dialogue.last_action_id.clone().unwrap_or_default() });
            }

            for &t in &tokens {
                let p = match t.to_lowercase().as_str() {
                    "deploy" => 2, "scale" => 3, "web-service" => 5, "cluster" => 7, "on" => 5,
                    "with" => 11, "replicas" => 13, "3" => 17, "revoke" | "cancel" => { mode = Mode::Retract; 19 } 
                    "it" => 5, "all" => 1, 
                    _ => {
                        let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::InvariantFail { diagnostic: format!("Unknown token '{}'", t), suggestion: "".to_string() }).unwrap())).await;
                        continue;
                    }
                };
                if first { ast = Ap(p); first = false; } else { ast = ast + Ap(p); }
            }

            let new_stratum = MOCWord::StratumBoundary(Box::new(ast));
            let (c, r1, r2, r3) = EvalNF::evaluate(&new_stratum);
            let rsc = Resonance::calculate(r1, r2, r3);
            
            let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::Compiled { 
                mocword: format!("{:?}", new_stratum), c, rsc 
            }).unwrap())).await;

            if mode == Mode::Assert {
                if let Err(e) = PhaseMirrorInvariants::enforce_all(&new_stratum) {
                    let mut sugg = "".to_string();
                    if tokens.contains(&"all") {
                        sugg = format!("'all' maps to Ap(1) [Forbidden]. Nearest valid substitute: 'web-service' (Ap(5)). Did you mean: '{}'?", text.replace("all", "web-service"));
                    }
                    let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::InvariantFail { diagnostic: e.to_string(), suggestion: sugg }).unwrap())).await;
                } else {
                    dialogue.strata.push(new_stratum);
                    let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::InvariantPass { message: format!("Asserted. Context depth: {}", dialogue.strata.len()) }).unwrap())).await;
                    
                    if let Some(action) = &parsed_action {
                        let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::ExecStart { action: format!("{:?}", action) }).unwrap())).await;
                        match dialogue.executor.execute(action).await {
                            Ok(id) => {
                                dialogue.last_action_id = Some(id.clone());
                                let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::ExecSuccess { action_id: id, message: "Deployed successfully".to_string() }).unwrap())).await;
                            },
                            Err(e) => {
                                let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::ExecFailure { error: e }).unwrap())).await;
                            }
                        }
                    }
                }
            } else if mode == Mode::Retract {
                dialogue.strata.pop();
                let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::Retraction { message: format!("Context cleared. Context depth: {}", dialogue.strata.len()) }).unwrap())).await;
                if let Some(action) = &parsed_action {
                    let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::ExecStart { action: format!("{:?}", action) }).unwrap())).await;
                    match dialogue.executor.execute(action).await {
                        Ok(id) => {
                            dialogue.last_action_id = None;
                            let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::Rollback { action_id: id, result: "Rollback successful".to_string() }).unwrap())).await;
                        },
                        Err(e) => {
                            let _ = socket.send(Message::Text(serde_json::to_string(&UiEvent::ExecFailure { error: e }).unwrap())).await;
                        }
                    }
                }
            }
        }
    }
}

#[tokio::main]
async fn main() {
    let executor = KubeExecutor::new().await.unwrap_or_else(|e| {
        println!("Warning: Failed to init KubeExecutor, maybe cluster is not reachable. Error: {}", e);
        std::process::exit(1);
    });

    let app = Router::new()
        .route("/ws", get({
            let executor = executor.clone();
            move |ws: WebSocketUpgrade| async move {
                ws.on_upgrade(move |socket| handle_socket(socket, executor))
            }
        }))
        .fallback_service(ServeDir::new("static"));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3002").await.unwrap();
    println!("Phase Mirror UI listening on http://localhost:3002");
    axum::serve(listener, app).await.unwrap();
}
