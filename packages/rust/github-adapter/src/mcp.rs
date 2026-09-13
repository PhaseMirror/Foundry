//! Port of `agents/mcp_client/client.py` — the `evaluate_transition` JSON-RPC
//! client used to reach the multiplicity MCP server.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use std::io::Error as IoError;
use tokio::io::{AsyncBufRead, AsyncBufReadExt, AsyncWrite, AsyncWriteExt, BufReader, BufWriter};
use tokio::net::TcpStream;
use tokio::process::Child;

/// `EvaluationMode` — `"simulate"` (dry-run) or `"commit"` (binding).
pub const MODE_SIMULATE: &str = "simulate";
pub const MODE_COMMIT: &str = "commit";

/// Mirrors the `TransitionRequest` dataclass. `transition_data` must match
/// `sigma::StateTransition` serialization (`{id, r_sc, l_eff}`).
#[derive(Debug, Clone, PartialEq, Serialize)]
pub struct TransitionRequest {
    pub agent_request_id: String,
    pub transition_data: Value,
    pub mode: String,
}

/// Mirrors the `TransitionResponse` dataclass: a flat result with
/// `status` and typed optional payloads. The Rust MCP server serializes
/// `EvaluateTransitionResponse` with a `"status"` tag; the field set matches
/// that wire format (`ratified`, `simulated`, `dissonance_trap`).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TransitionResponse {
    pub status: String,
    #[serde(default)]
    pub witness_id: Option<String>,
    #[serde(default)]
    pub ratified_block: Option<Value>,
    #[serde(default)]
    pub breach_type: Option<String>,
    #[serde(default)]
    pub details: Option<String>,
    #[serde(default)]
    pub conflict_log_id: Option<String>,
}

/// Errors surfaced by the client, mirroring the Python `RuntimeError` /
/// `ConnectionError` distinctions.
#[derive(Debug, thiserror::Error)]
pub enum McpError {
    /// `"MCP server closed connection"` (empty read line).
    #[error("MCP server closed connection")]
    Closed,
    /// `"JSON-RPC error {code}: {message}"`.
    #[error("JSON-RPC error {code}: {message}")]
    Rpc { code: i64, message: String },
    /// `"Missing 'result' in response"`.
    #[error("Missing 'result' in response")]
    MissingResult,
    /// Transport-level I/O failure.
    #[error("MCP transport error: {0}")]
    Io(#[from] IoError),
    /// Response is not valid JSON.
    #[error("Invalid JSON-RPC response: {0}")]
    Json(#[from] serde_json::Error),
}

/// Builds the JSON-RPC 2.0 request line (one line, newline-terminated).
///
/// Mirrors the client exactly:
/// `json.dumps({"jsonrpc":"2.0","id":1,"method":"tools/call","params":
/// {"name":"evaluate_transition","arguments":{...}}}) + "\n"`.
pub fn build_rpc_request(request: &TransitionRequest) -> String {
    let rpc = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "evaluate_transition",
            "arguments": {
                "agent_request_id": request.agent_request_id,
                "transition_data": request.transition_data,
                "mode": request.mode,
            }
        }
    });
    format!("{}\n", rpc)
}

/// Parses one response line into a `TransitionResponse`.
///
/// - JSON-RPC `error` object -> `McpError::Rpc`
/// - missing `result` -> `McpError::MissingResult`
/// - otherwise a `TransitionResponse` parsed from `result`.
pub fn parse_rpc_response(line: &str) -> Result<TransitionResponse, McpError> {
    let response_json: Value = serde_json::from_str(line)?;

    if let Some(error) = response_json.get("error") {
        let code = error.get("code").and_then(Value::as_i64).unwrap_or(0);
        let message = error
            .get("message")
            .and_then(Value::as_str)
            .unwrap_or_default()
            .to_string();
        return Err(McpError::Rpc { code, message });
    }

    let result = response_json.get("result").ok_or(McpError::MissingResult)?;
    Ok(serde_json::from_value(result.clone())?)
}

/// The request/response loop over a writer + reader pair.
///
/// Segregated so the wire protocol can be exercised in-memory
/// (`tokio::io::duplex`) without a live server.
pub async fn send_rpc(
    writer: &mut (impl AsyncWrite + Unpin),
    reader: &mut (impl AsyncBufRead + Unpin),
    request: &TransitionRequest,
) -> Result<TransitionResponse, McpError> {
    writer
        .write_all(build_rpc_request(request).as_bytes())
        .await?;
    writer.flush().await?;

    let mut buffer = String::new();
    let read = reader.read_line(&mut buffer).await?;
    if read == 0 {
        return Err(McpError::Closed);
    }

    parse_rpc_response(buffer.trim_end())
}

/// Connection mode for the MCP server, mirroring the Python `__aenter__`
/// branch: TCP when `host`/`port` are set, otherwise a spawned subprocess
/// (`server_cmd`).
enum Transport {
    Tcp {
        reader: BufReader<tokio::net::tcp::OwnedReadHalf>,
        writer: BufWriter<tokio::net::tcp::OwnedWriteHalf>,
    },
    Stdio {
        child: Box<Child>,
        reader: BufReader<tokio::process::ChildStdout>,
        writer: BufWriter<tokio::process::ChildStdin>,
    },
}

impl Transport {
    /// `asyncio.open_connection(host, port)`.
    async fn connect_tcp(host: &str, port: u16) -> std::io::Result<Self> {
        let stream = TcpStream::connect((host, port)).await?;
        let (rx, tx) = stream.into_split();
        Ok(Transport::Tcp {
            reader: BufReader::new(rx),
            writer: BufWriter::new(tx),
        })
    }

    /// `asyncio.create_subprocess_exec(*server_cmd, stdin=PIPE, stdout=PIPE,
    /// stderr=PIPE)`.
    async fn spawn(server_cmd: &[String]) -> std::io::Result<Self> {
        let mut command = tokio::process::Command::new(&server_cmd[0]);
        command
            .args(&server_cmd[1..])
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped());
        let mut child = command.spawn()?;
        let stdout = child
            .stdout
            .take()
            .ok_or_else(|| IoError::other("stdout pipe unavailable"))?;
        let stdin = child
            .stdin
            .take()
            .ok_or_else(|| IoError::other("stdin pipe unavailable"))?;
        Ok(Transport::Stdio {
            reader: BufReader::new(stdout),
            writer: BufWriter::new(stdin),
            child: Box::new(child),
        })
    }

    async fn send(&mut self, request: &TransitionRequest) -> Result<TransitionResponse, McpError> {
        match self {
            Transport::Tcp { reader, writer } => send_rpc(writer, reader, request).await,
            Transport::Stdio { reader, writer, .. } => send_rpc(writer, reader, request).await,
        }
    }
}

impl Drop for Transport {
    /// Best-effort mirror of `__aexit__`: dropping the writer closes the
    /// connection/pipe and the spawned process is terminated.
    fn drop(&mut self) {
        if let Transport::Stdio { child, .. } = self {
            let _ = child.start_kill();
        }
    }
}

/// Client mirroring `SigmaMCPClient`: connect via TCP or subprocess, then
/// evaluate transitions over JSON-RPC.
pub struct McpClient {
    transport: Transport,
}

impl McpClient {
    /// TCP mode (`self.host and self.port`).
    pub async fn connect_tcp(host: &str, port: u16) -> std::io::Result<Self> {
        Ok(Self {
            transport: Transport::connect_tcp(host, port).await?,
        })
    }

    /// stdio subprocess mode (`self.server_cmd`).
    pub async fn spawn(server_cmd: &[String]) -> std::io::Result<Self> {
        Ok(Self {
            transport: Transport::spawn(server_cmd).await?,
        })
    }

    /// Port of `SigmaMCPClient.evaluate_transition`.
    pub async fn evaluate_transition(
        &mut self,
        request: &TransitionRequest,
    ) -> Result<TransitionResponse, McpError> {
        self.transport.send(request).await
    }
}
