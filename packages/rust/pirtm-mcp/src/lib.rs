pub mod protocol;
pub mod tools;

use protocol::{JsonRpcRequest, JsonRpcResponse};
use serde_json::json;
use std::io::{BufRead, Read, Write};

pub struct McpServer;

impl Default for McpServer {
    fn default() -> Self {
        Self::new()
    }
}

impl McpServer {
    pub fn new() -> Self {
        Self
    }

    pub fn handle_request(&self, req: JsonRpcRequest) -> Option<JsonRpcResponse> {
        let id = req.id;
        match req.method.as_str() {
            "initialize" => Some(JsonRpcResponse::success(
                id,
                json!({
                    "protocolVersion": "2024-11-05",
                    "serverInfo": {
                        "name": "pirtm-governance-mcp",
                        "version": "0.1.0"
                    },
                    "capabilities": {
                        "tools": {}
                    }
                }),
            )),
            "notifications/initialized" => None,
            "ping" => Some(JsonRpcResponse::success(id, json!({}))),
            "tools/list" => Some(JsonRpcResponse::success(id, tools::list_tools())),
            "tools/call" => {
                let params = req.params.unwrap_or(json!({}));
                let tool_name = params.get("name").and_then(|v| v.as_str()).unwrap_or("");
                let args = params.get("arguments").cloned().unwrap_or(json!({}));

                match tools::handle_call(tool_name, &args) {
                    Ok(result) => Some(JsonRpcResponse::success(id, result)),
                    Err(err) => Some(JsonRpcResponse::error(id, -32602, err)),
                }
            }
            other => Some(JsonRpcResponse::error(
                id,
                -32601,
                format!("Method not found: {}", other),
            )),
        }
    }

    pub fn run_stdio<R: BufRead, W: Write>(&self, mut reader: R, mut writer: W) -> Result<(), anyhow::Error> {
        let mut line = String::new();
        while reader.read_line(&mut line)? > 0 {
            let trimmed = line.trim();
            if !trimmed.is_empty() {
                if let Ok(req) = serde_json::from_str::<JsonRpcRequest>(trimmed) {
                    if let Some(resp) = self.handle_request(req) {
                        let resp_json = serde_json::to_string(&resp)?;
                        writeln!(writer, "{}", resp_json)?;
                        writer.flush()?;
                    }
                }
            }
            line.clear();
        }
        Ok(())
    }

    /// Handles an incoming connection that may be raw JSON-RPC or HTTP/1.1 (from reverse proxy / browser).
    pub fn run_connection<R: BufRead, W: Write>(&self, mut reader: R, mut writer: W) -> Result<(), anyhow::Error> {
        let mut first_line = String::new();
        if reader.read_line(&mut first_line)? == 0 {
            return Ok(());
        }

        let trimmed = first_line.trim();

        // 1. CORS Preflight OPTIONS
        if trimmed.starts_with("OPTIONS ") {
            let mut line = String::new();
            while reader.read_line(&mut line)? > 0 {
                if line == "\r\n" || line == "\n" || line.is_empty() {
                    break;
                }
                line.clear();
            }
            let resp = "HTTP/1.1 204 No Content\r\n\
Access-Control-Allow-Origin: *\r\n\
Access-Control-Allow-Methods: POST, GET, OPTIONS\r\n\
Access-Control-Allow-Headers: Content-Type, Authorization\r\n\
Access-Control-Max-Age: 86400\r\n\
Content-Length: 0\r\n\r\n";
            writer.write_all(resp.as_bytes())?;
            writer.flush()?;
            return Ok(());
        }

        // 2. Health Check Probe GET
        if trimmed.starts_with("GET /health") || trimmed.starts_with("GET / ") {
            let mut line = String::new();
            while reader.read_line(&mut line)? > 0 {
                if line == "\r\n" || line == "\n" || line.is_empty() {
                    break;
                }
                line.clear();
            }
            let body = r#"{"status":"healthy","server":"pirtm-governance-mcp","version":"0.1.0"}"#;
            let resp = format!(
                "HTTP/1.1 200 OK\r\n\
Content-Type: application/json\r\n\
Access-Control-Allow-Origin: *\r\n\
Content-Length: {}\r\n\r\n{}",
                body.len(),
                body
            );
            writer.write_all(resp.as_bytes())?;
            writer.flush()?;
            return Ok(());
        }

        // 3. HTTP POST JSON-RPC Request
        if trimmed.starts_with("POST ") {
            let mut content_length: usize = 0;
            let mut line = String::new();
            while reader.read_line(&mut line)? > 0 {
                let lower = line.to_lowercase();
                if lower.starts_with("content-length:") {
                    if let Some(val_str) = lower.strip_prefix("content-length:") {
                        content_length = val_str.trim().parse().unwrap_or(0);
                    }
                }
                if line == "\r\n" || line == "\n" {
                    break;
                }
                line.clear();
            }

            let mut body_buf = vec![0u8; content_length];
            reader.read_exact(&mut body_buf)?;

            let body_str = String::from_utf8_lossy(&body_buf);
            if let Ok(req) = serde_json::from_str::<JsonRpcRequest>(body_str.trim()) {
                let resp_val = self.handle_request(req).unwrap_or_else(|| {
                    JsonRpcResponse::success(None, json!({"status": "ok"}))
                });
                let resp_json = serde_json::to_string(&resp_val)?;
                let resp = format!(
                    "HTTP/1.1 200 OK\r\n\
Content-Type: application/json\r\n\
Access-Control-Allow-Origin: *\r\n\
Access-Control-Allow-Headers: Content-Type, Authorization\r\n\
Content-Length: {}\r\n\r\n{}",
                    resp_json.len(),
                    resp_json
                );
                writer.write_all(resp.as_bytes())?;
                writer.flush()?;
            } else {
                let err_body = r#"{"jsonrpc":"2.0","error":{"code":-32700,"message":"Parse error"}}"#;
                let resp = format!(
                    "HTTP/1.1 400 Bad Request\r\n\
Content-Type: application/json\r\n\
Access-Control-Allow-Origin: *\r\n\
Content-Length: {}\r\n\r\n{}",
                    err_body.len(),
                    err_body
                );
                writer.write_all(resp.as_bytes())?;
                writer.flush()?;
            }
            return Ok(());
        }

        // 4. Raw line-delimited JSON-RPC fallback
        if let Ok(req) = serde_json::from_str::<JsonRpcRequest>(trimmed) {
            if let Some(resp) = self.handle_request(req) {
                let resp_json = serde_json::to_string(&resp)?;
                writeln!(writer, "{}", resp_json)?;
                writer.flush()?;
            }
        }
        self.run_stdio(reader, writer)
    }
}
