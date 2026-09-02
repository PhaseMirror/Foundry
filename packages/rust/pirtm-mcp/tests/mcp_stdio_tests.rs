use pirtm_mcp::McpServer;
use serde_json::{json, Value};
use std::io::Cursor;

#[test]
fn test_mcp_initialize_and_tools_list() {
    let server = McpServer::new();

    // 1. Initialize
    let init_req = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {}
    });

    let input = format!("{}\n", init_req);
    let mut output = Vec::new();
    server.run_stdio(Cursor::new(input), &mut output).expect("stdio run failed");

    let resp_str = String::from_utf8(output).expect("valid utf8");
    let resp: Value = serde_json::from_str(resp_str.trim()).expect("valid json");
    assert_eq!(resp["id"], 1);
    assert_eq!(resp["result"]["serverInfo"]["name"], "pirtm-governance-mcp");

    // 2. Tools list
    let list_req = json!({
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/list",
        "params": {}
    });

    let input2 = format!("{}\n", list_req);
    let mut output2 = Vec::new();
    server.run_stdio(Cursor::new(input2), &mut output2).expect("stdio run failed");

    let resp2_str = String::from_utf8(output2).expect("valid utf8");
    let resp2: Value = serde_json::from_str(resp2_str.trim()).expect("valid json");
    assert_eq!(resp2["id"], 2);
    let tools = resp2["result"]["tools"].as_array().expect("tools array");
    assert!(tools.iter().any(|t| t["name"] == "pirtm_compile"));
    assert!(tools.iter().any(|t| t["name"] == "pirtm_verify_ensemble"));
}

#[test]
fn test_mcp_call_verify_ensemble() {
    let server = McpServer::new();

    let call_req = json!({
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "pirtm_verify_ensemble",
            "arguments": {
                "name": "test_ensemble",
                "adjacency_matrix": [
                    [0.0, 0.5],
                    [0.5, 0.0]
                ],
                "lambdas": [0.8, 0.8]
            }
        }
    });

    let input = format!("{}\n", call_req);
    let mut output = Vec::new();
    server.run_stdio(Cursor::new(input), &mut output).expect("stdio run failed");

    let resp_str = String::from_utf8(output).expect("valid utf8");
    let resp: Value = serde_json::from_str(resp_str.trim()).expect("valid json");
    assert_eq!(resp["id"], 3);
    assert!(resp["result"]["content"][0]["text"].as_str().unwrap().contains("ACCEPT"));
}

#[test]
fn test_mcp_call_compile() {
    let server = McpServer::new();

    let call_req = json!({
        "jsonrpc": "2.0",
        "id": 4,
        "method": "tools/call",
        "params": {
            "name": "pirtm_compile",
            "arguments": {
                "source": "let x = 42;"
            }
        }
    });

    let input = format!("{}\n", call_req);
    let mut output = Vec::new();
    server.run_stdio(Cursor::new(input), &mut output).expect("stdio run failed");

    let resp_str = String::from_utf8(output).expect("valid utf8");
    let resp: Value = serde_json::from_str(resp_str.trim()).expect("valid json");
    assert_eq!(resp["id"], 4);
    assert!(resp["result"]["content"][0]["text"].as_str().unwrap().contains("SUCCESS"));
}
