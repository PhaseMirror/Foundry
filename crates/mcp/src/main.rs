use anyhow::Result;
use multiplicity_mcp::archivum::InMemoryArchivum;
use multiplicity_mcp::handler;
use multiplicity_mcp::schema;
use sigma::{SigmaKernel, PolicyEngine, WitnessLedger};
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader, BufWriter};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::Mutex;
use tracing::{error, info};
use tracing_subscriber;
use tokio::signal::unix::{signal, SignalKind};

#[tokio::main]
async fn main() -> Result<()> {
    // Initialise logging.
    tracing_subscriber::fmt::init();

    // Parse command‑line arguments: --listen <addr:port>
    let listen_addr: Option<SocketAddr> = std::env::args()
        .skip(1)
        .collect::<Vec<_>>()
        .chunks(2)
        .find_map(|chunk| {
            if chunk[0] == "--listen" {
                chunk.get(1).and_then(|addr| addr.parse().ok())
            } else {
                None
            }
        });

    let engine = PolicyEngine::new();
    let ledger = WitnessLedger::new("witnesses.jsonl");

    // --- 1. Build the Sigma Kernel (loads Lean-generated thresholds) ---
    let kernel = SigmaKernel::from_lean_export(engine, ledger, "thresholds.postcard", "thresholds.json");
    let kernel = Arc::new(Mutex::new(kernel));

    // --- 2. Create the Archivum (in‑memory for now; replace with persistent later) ---
    let archivum: Arc<dyn multiplicity_mcp::archivum::Archivum> = Arc::new(InMemoryArchivum::new());

    if let Some(addr) = listen_addr {
        // --- TCP mode ---
        info!("Starting TCP MCP server on {}", addr);
        let listener = TcpListener::bind(&addr).await?;
        info!("Listening for incoming connections");

        // Graceful shutdown handling
        let mut shutdown = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())?;
        loop {
            tokio::select! {
                accept_res = listener.accept() => {
                    match accept_res {
                        Ok((stream, peer)) => {
                            info!("Accepted connection from {}", peer);
                            let kernel_clone = Arc::clone(&kernel);
                            let archivum_clone = Arc::clone(&archivum);
                            tokio::spawn(async move {
                                if let Err(e) = handle_connection(stream, kernel_clone, archivum_clone).await {
                                    error!(error = %e, "Connection handling failed for {}", peer);
                                }
                            });
                        }
                        Err(e) => {
                            error!(error = %e, "Error accepting connection");
                        }
                    }
                }
                _ = shutdown.recv() => {
                    info!("Received SIGTERM, shutting down gracefully");
                    break;
                }
            }
        }
    } else {
        // --- stdio mode (original) ---
        info!("Starting stdio MCP server (legacy mode)");
        handle_stdio(kernel, archivum).await?;
    }

    Ok(())
}

async fn handle_connection(
    mut stream: TcpStream,
    kernel: Arc<Mutex<SigmaKernel>>,
    archivum: Arc<dyn multiplicity_mcp::archivum::Archivum>,
) -> Result<()> {
    let (reader, writer) = stream.split();
    let mut reader = BufReader::new(reader);
    let mut writer = BufWriter::new(writer);
    let mut line = String::new();

    loop {
        line.clear();
        if reader.read_line(&mut line).await? == 0 {
            break;
        }
        if line.trim().is_empty() {
            continue;
        }

        let request: serde_json::Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(e) => {
                let error_resp = serde_json::json!({
                    "jsonrpc": "2.0",
                    "id": null,
                    "error": {
                        "code": -32700,
                        "message": format!("Parse error: {}", e),
                    },
                });
                writer.write_all(serde_json::to_string(&error_resp)?.as_bytes()).await?;
                writer.write_all(b"\n").await?;
                continue;
            }
        };

        let response = match handle_rpc_request(request, &kernel, &archivum).await {
            Ok(resp) => resp,
            Err(err) => {
                error!(error = %err, "Failed to handle RPC request");
                continue;
            }
        };

        writer.write_all(serde_json::to_string(&response)?.as_bytes()).await?;
        writer.write_all(b"\n").await?;
        writer.flush().await?;
    }

    Ok(())
}

async fn handle_stdio(
    kernel: Arc<Mutex<SigmaKernel>>,
    archivum: Arc<dyn multiplicity_mcp::archivum::Archivum>,
) -> Result<()> {
    let stdin = tokio::io::stdin();
    let mut reader = tokio::io::BufReader::new(stdin);
    let stdout = tokio::io::stdout();
    let mut writer = tokio::io::BufWriter::new(stdout);
    let mut line = String::new();

    loop {
        line.clear();
        if reader.read_line(&mut line).await? == 0 {
            break;
        }
        if line.trim().is_empty() {
            continue;
        }

        let request: serde_json::Value = match serde_json::from_str(&line) {
            Ok(v) => v,
            Err(e) => {
                let error_resp = serde_json::json!({
                    "jsonrpc": "2.0",
                    "id": null,
                    "error": {
                        "code": -32700,
                        "message": format!("Parse error: {}", e),
                    },
                });
                writer.write_all(serde_json::to_string(&error_resp)?.as_bytes()).await?;
                writer.write_all(b"\n").await?;
                continue;
            }
        };

        let response = match handle_rpc_request(request, &kernel, &archivum).await {
            Ok(resp) => resp,
            Err(err) => {
                error!(error = %err, "Failed to handle RPC request");
                continue;
            }
        };

        writer.write_all(serde_json::to_string(&response)?.as_bytes()).await?;
        writer.write_all(b"\n").await?;
        writer.flush().await?;
    }

    Ok(())
}

async fn handle_rpc_request(
    request: serde_json::Value,
    kernel: &Arc<Mutex<SigmaKernel>>,
    archivum: &Arc<dyn multiplicity_mcp::archivum::Archivum>,
) -> Result<serde_json::Value> {
    let id = request.get("id").cloned();
    let method = request
        .get("method")
        .and_then(|m| m.as_str())
        .unwrap_or("");

    // Handle simple health ping
    if method == "ping" {
        return Ok(serde_json::json!({
            "jsonrpc": "2.0",
            "id": id,
            "result": "pong",
        }));
    }
    if method != "tools/call" {
        return Ok(serde_json::json!({
            "jsonrpc": "2.0",
            "id": id,
            "error": {
                "code": -32601,
                "message": "Method not found",
            },
        }));
    }

    let params = request.get("params").ok_or_else(|| anyhow::anyhow!("Missing params"))?;
    let tool_name = params
        .get("name")
        .and_then(|n| n.as_str())
        .ok_or_else(|| anyhow::anyhow!("Missing tool name"))?;

    if tool_name != "evaluate_transition" {
        return Ok(serde_json::json!({
            "jsonrpc": "2.0",
            "id": id,
            "error": {
                "code": -32601,
                "message": format!("Tool '{}' not supported", tool_name),
            },
        }));
    }

    let args = params
        .get("arguments")
        .ok_or_else(|| anyhow::anyhow!("Missing arguments"))?;

    let req: schema::EvaluateTransitionRequest = serde_json::from_value(args.clone())
        .map_err(|e| anyhow::anyhow!("Invalid arguments: {}", e))?;

    let response = handler::handle_evaluate_transition(kernel, archivum, req).await;

    Ok(serde_json::json!({
        "jsonrpc": "2.0",
        "id": id,
        "result": response,
    }))
}
