use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpRequest {
    pub jsonrpc: String,
    pub id: Value,
    pub method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub params: Option<Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpResponse {
    pub jsonrpc: String,
    pub id: Value,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<McpError>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct McpError {
    pub code: i32,
    pub message: String,
}

pub trait McpTool: Send + Sync {
    fn name(&self) -> String;
    fn description(&self) -> String;
    fn call(&self, params: Value) -> Result<Value, String>;
}

pub struct McpServer {
    pub tools: HashMap<String, Box<dyn McpTool>>,
}

impl McpServer {
    pub fn new() -> Self {
        McpServer { tools: HashMap::new() }
    }

    pub fn register_tool(&mut self, tool: Box<dyn McpTool>) {
        self.tools.insert(tool.name(), tool);
    }

    pub fn handle_request(&self, req: McpRequest) -> McpResponse {
        let result = match req.method.as_str() {
            "tools/list" => Ok(serde_json::json!({
                "tools": self.tools.values().map(|t| serde_json::json!({
                    "name": t.name(),
                    "description": t.description(),
                })).collect::<Vec<_>>()
            })),
            "tools/call" => {
                let params = req.params.unwrap_or(serde_json::json!({}));
                let name = params["name"].as_str().unwrap_or("");
                if let Some(tool) = self.tools.get(name) {
                    tool.call(params["arguments"].clone()).map_err(|e| e).map(|v| v)
                } else {
                    Err("Tool not found".to_string())
                }
            }
            _ => Err("Method not found".to_string()),
        };

        match result {
            Ok(res) => McpResponse {
                jsonrpc: "2.0".to_string(),
                id: req.id,
                result: Some(res),
                error: None,
            },
            Err(e) => McpResponse {
                jsonrpc: "2.0".to_string(),
                id: req.id,
                result: None,
                error: Some(McpError { code: -32000, message: e }),
            },
        }
    }
}
