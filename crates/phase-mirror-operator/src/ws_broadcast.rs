use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    response::IntoResponse,
    routing::get,
    Router,
};
use futures::{stream::StreamExt, SinkExt};
use serde::Serialize;
use std::sync::Arc;
use tokio::sync::broadcast;
use tokio::net::TcpListener;

/// Events that exactly mirror the UiEvent enum used by pirtm-ui
#[derive(Clone, Serialize, Debug)]
#[serde(tag = "type")]
pub enum OperatorEvent {
    #[serde(rename = "user_input")] UserInput { text: String },
    #[serde(rename = "compiled")] Compiled { mocword: String, c: f64, rsc: f64 },
    #[serde(rename = "invariant_pass")] InvariantPass { message: String },
    #[serde(rename = "invariant_fail")] InvariantFail { diagnostic: String, suggestion: String },
    #[serde(rename = "execution_start")] ExecStart { action: String },
    #[serde(rename = "execution_success")] ExecSuccess { action_id: String, message: String },
    #[serde(rename = "execution_failure")] ExecFailure { error: String },
    #[serde(rename = "retraction")] Retraction { message: String },
    #[serde(rename = "rollback")] Rollback { action_id: String, result: String },
}

/// Shared state: a sender that all WebSocket tasks read from
pub struct OperatorState {
    pub tx: broadcast::Sender<OperatorEvent>,
}

impl OperatorState {
    pub fn new() -> Self {
        let (tx, _) = broadcast::channel(256);
        Self { tx }
    }

    /// Publish an event to all connected clients
    pub fn emit(&self, event: OperatorEvent) {
        let _ = self.tx.send(event);
    }
}

/// Spawns the Axum WebSocket server on the given port and returns a handle to broadcast events
pub async fn start_ws_server(port: u16) -> Arc<OperatorState> {
    let state = Arc::new(OperatorState::new());
    let app_state = state.clone();

    // Build the router
    let app = Router::new()
        .route("/ws", get(ws_handler))
        .with_state(app_state);

    // Bind to the port in a background task
    let addr = format!("0.0.0.0:{}", port);
    let listener = TcpListener::bind(&addr).await.unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    tracing::info!("WebSocket server listening on ws://{}", addr);
    state
}

/// The WebSocket upgrade handler
async fn ws_handler(
    ws: WebSocketUpgrade,
    state: axum::extract::State<Arc<OperatorState>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_socket(socket, state.0))
}

/// Handle each client connection: forward broadcast events to the client
async fn handle_socket(socket: WebSocket, state: Arc<OperatorState>) {
    let (mut sender, mut receiver) = socket.split();
    let mut rx = state.tx.subscribe();

    // Forward broadcast messages to the client
    let send_task = tokio::spawn(async move {
        while let Ok(event) = rx.recv().await {
            let json = serde_json::to_string(&event).unwrap();
            if sender.send(Message::Text(json.into())).await.is_err() {
                break; // client disconnected
            }
        }
    });

    // Keep the connection alive by ignoring incoming messages (or we could handle pings)
    while let Some(Ok(_)) = receiver.next().await {}

    send_task.abort();
}
