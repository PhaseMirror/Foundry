use axum::{routing::post, Json, Router};
use mcp_server_rs::{McpServer, McpRequest, McpResponse, McpTool};
use serde_json::Value;
use std::sync::Arc;

struct EchoTool;
impl McpTool for EchoTool {
    fn name(&self) -> String { "echo".to_string() }
    fn description(&self) -> String { "Echoes input".to_string() }
    fn call(&self, params: Value) -> Result<Value, String> {
        Ok(params)
    }
}

#[tokio::main]
async fn main() {
    let mut server = McpServer::new();
    server.register_tool(Box::new(EchoTool));
    let server = Arc::new(server);

    let app = Router::new()
        .route("/mcp", post(move |Json(req): Json<McpRequest>| async move {
            let server = Arc::clone(&server);
            Json(server.handle_request(req))
        }));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
