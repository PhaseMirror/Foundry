use std::sync::Arc;
use multiplicity_commander_core::CommanderCore;
use multiplicity_common::types::ProposalRequest;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use async_trait::async_trait;
use axum::{Json, extract::{Path, State}};
use super::McpTransport;

pub struct StdioTransport;

#[async_trait]
impl McpTransport for StdioTransport {
    async fn run(&self, core: Arc<CommanderCore>) -> anyhow::Result<()> {
        let mut stdin = BufReader::new(tokio::io::stdin());
        let mut stdout = tokio::io::stdout();
        let mut line = String::new();
        
        while stdin.read_line(&mut line).await? > 0 {
            let req_str = line.trim();
            if req_str.is_empty() {
                line.clear();
                continue;
            }
            
            if let Ok(req) = serde_json::from_str::<serde_json::Value>(req_str) {
                let id = req.get("id").cloned();
                let method = req.get("method").and_then(|m| m.as_str()).unwrap_or("");
                let params = req.get("params").cloned().unwrap_or(serde_json::Value::Null);
                
                match method {
                    "initialize" => {
                        let resp = serde_json::json!({
                            "jsonrpc": "2.0",
                            "id": id,
                            "result": {
                                "protocolVersion": "2024-11-05",
                                "capabilities": {
                                    "tools": {}
                                },
                                "serverInfo": {
                                    "name": "multiplicity-mcp",
                                    "version": "0.1.0"
                                }
                            }
                        });
                        self.write_response(&mut stdout, &resp).await?;
                    }
                    "notifications/initialized" => {}
                    "tools/list" => {
                        let tools_res = crate::list_tools().await;
                        let resp = serde_json::json!({
                            "jsonrpc": "2.0",
                            "id": id,
                            "result": tools_res.0
                        });
                        self.write_response(&mut stdout, &resp).await?;
                    }
                    "tools/call" => {
                        let name = params.get("name").and_then(|n| n.as_str()).unwrap_or("").to_string();
                        let arguments = params.get("arguments").cloned().unwrap_or(serde_json::Value::Null);
                        
                        let proposal = ProposalRequest {
                            proposal_id: "stdio-proposal".to_string(),
                            payload: arguments,
                            rationale: "Stdio MCP tool call".to_string(),
                            state_norm: 1.0,
                            drift_rate: 0.0,
                            contractivity_score: 0.7,
                            critique_results: vec![],
                            prime_gates: vec![],
                            kill_switch_active: false,
                            rollback_anchor_sha: None,
                            consecutive_failures: 0,
                        };
                        
                        let tool_resp = crate::call_tool(State(core.clone()), Path(name), Json(proposal)).await;
                        let resp = serde_json::json!({
                            "jsonrpc": "2.0",
                            "id": id,
                            "result": {
                                "content": [
                                    {
                                        "type": "text",
                                        "text": serde_json::to_string_pretty(&tool_resp.0)?
                                    }
                                ]
                            }
                        });
                        self.write_response(&mut stdout, &resp).await?;
                    }
                    _ => {
                        if let Some(req_id) = id {
                            let resp = serde_json::json!({
                                "jsonrpc": "2.0",
                                "id": req_id,
                                "error": {
                                    "code": -32601,
                                    "message": format!("Method not found: {}", method)
                                }
                            });
                            self.write_response(&mut stdout, &resp).await?;
                        }
                    }
                }
            }
            line.clear();
        }
        Ok(())
    }
}

impl StdioTransport {
    async fn write_response(&self, stdout: &mut tokio::io::Stdout, resp: &serde_json::Value) -> anyhow::Result<()> {
        let mut resp_str = serde_json::to_string(resp)?;
        resp_str.push('\n');
        stdout.write_all(resp_str.as_bytes()).await?;
        stdout.flush().await?;
        Ok(())
    }
}
