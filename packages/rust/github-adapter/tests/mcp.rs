//! Port of `agents/mcp_client/client.py` — request building, response parsing,
//! and the wire loop.

use github_adapter::mcp::{
    build_rpc_request, parse_rpc_response, send_rpc, TransitionRequest, TransitionResponse,
    MODE_COMMIT, MODE_SIMULATE,
};
use serde_json::{json, Value};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader, BufWriter};

fn request(mode: &str) -> TransitionRequest {
    TransitionRequest {
        agent_request_id: String::from("github-check-12"),
        transition_data: json!({ "id": "pr-7", "r_sc": 47.01, "l_eff": 0.026 }),
        mode: String::from(mode),
    }
}

#[test]
fn build_rpc_request_matches_wire_contract() {
    let line = build_rpc_request(&request(MODE_SIMULATE));
    assert!(line.ends_with('\n'));
    let parsed: Value = serde_json::from_str(line.trim_end()).unwrap();

    assert_eq!(parsed["jsonrpc"], "2.0");
    assert_eq!(parsed["id"], 1);
    assert_eq!(parsed["method"], "tools/call");
    assert_eq!(parsed["params"]["name"], "evaluate_transition");
    assert_eq!(
        parsed["params"]["arguments"]["agent_request_id"],
        "github-check-12"
    );
    assert_eq!(parsed["params"]["arguments"]["mode"], "simulate");
    assert_eq!(
        parsed["params"]["arguments"]["transition_data"]["id"],
        "pr-7"
    );
}

#[test]
fn parse_ratified_response() {
    let line = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "status": "ratified",
            "witness_id": "w-9",
            "ratified_block": { "id": "blk-1" }
        }
    })
    .to_string();

    let response = parse_rpc_response(&line).unwrap();
    assert_eq!(response.status, "ratified");
    assert_eq!(response.witness_id.as_deref(), Some("w-9"));
    assert!(response.ratified_block.is_some());
}

#[test]
fn parse_simulated_response() {
    let line = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "result": { "status": "simulated", "ratified_block": {} }
    })
    .to_string();

    let response = parse_rpc_response(&line).unwrap();
    assert_eq!(response.status, "simulated");
    assert_eq!(response.witness_id, None);
}

#[test]
fn parse_dissonance_trap_response() {
    let line = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "result": {
            "status": "dissonance_trap",
            "breach_type": "rl_collision",
            "details": "r_sc 47.01 collides with pr-5",
            "conflict_log_id": "cl-2"
        }
    })
    .to_string();

    let response = parse_rpc_response(&line).unwrap();
    assert_eq!(response.status, "dissonance_trap");
    assert_eq!(response.breach_type.as_deref(), Some("rl_collision"));
    assert_eq!(response.conflict_log_id.as_deref(), Some("cl-2"));
}

#[test]
fn rpc_error_becomes_mcp_error() {
    let line = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "error": { "code": -32602, "message": "invalid params" }
    })
    .to_string();

    let err = parse_rpc_response(&line).unwrap_err();
    assert_eq!(err.to_string(), "JSON-RPC error -32602: invalid params");
}

#[test]
fn missing_result_becomes_mcp_error() {
    let err = parse_rpc_response(r#"{"jsonrpc":"2.0","id":1}"#).unwrap_err();
    assert_eq!(err.to_string(), "Missing 'result' in response");
}

#[test]
fn invalid_json_becomes_mcp_error() {
    let err = parse_rpc_response("not json").unwrap_err();
    assert!(err.to_string().starts_with("Invalid JSON-RPC response:"));
}

#[tokio::test]
async fn send_rpc_round_trips_over_duplex() {
    let (a, b) = tokio::io::duplex(4096);
    let (c_rx, c_tx) = tokio::io::split(a);
    let mut client_writer = BufWriter::new(c_tx);
    let mut client_reader = BufReader::new(c_rx);

    let server = tokio::spawn(async move {
        let mut b = b;
        let mut reader = BufReader::new(&mut b);
        let mut line = String::new();
        reader.read_line(&mut line).await.unwrap();
        assert!(line.contains("\"method\":\"tools/call\""));
        assert!(line.contains("\"name\":\"evaluate_transition\""));
        drop(reader);
        let reply = json!({
            "jsonrpc": "2.0",
            "id": 1,
            "result": { "status": "simulated", "ratified_block": {} }
        })
        .to_string()
            + "\n";
        b.write_all(reply.as_bytes()).await.unwrap();
    });

    let response = send_rpc(
        &mut client_writer,
        &mut client_reader,
        &request(MODE_SIMULATE),
    )
    .await
    .unwrap();
    assert_eq!(response.status, "simulated");

    server.await.unwrap();
}

#[tokio::test]
async fn send_rpc_detects_closed_connection() {
    let (a, b) = tokio::io::duplex(4096);
    let (c_rx, c_tx) = tokio::io::split(a);

    // The server reads the request, then closes without responding.
    let server = tokio::spawn(async move {
        let mut b = b;
        let mut reader = BufReader::new(&mut b);
        let mut line = String::new();
        reader.read_line(&mut line).await.unwrap();
        drop(reader);
        drop(b); // close connection -> client read_line returns 0
    });

    let mut client_writer = BufWriter::new(c_tx);
    let mut client_reader = BufReader::new(c_rx);

    let err = send_rpc(
        &mut client_writer,
        &mut client_reader,
        &request(MODE_COMMIT),
    )
    .await
    .unwrap_err();
    assert_eq!(err.to_string(), "MCP server closed connection");
    server.await.unwrap();
}

#[test]
fn response_round_trips_through_serde() {
    let response = TransitionResponse {
        status: String::from("ratified"),
        witness_id: Some(String::from("w-1")),
        ratified_block: Some(json!({ "id": "blk" })),
        breach_type: None,
        details: None,
        conflict_log_id: None,
    };
    let json = serde_json::to_value(&response).unwrap();
    let back: TransitionResponse = serde_json::from_value(json).unwrap();
    assert_eq!(back, response);
}
