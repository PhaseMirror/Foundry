//! End-to-end tests for the `python-policy-proxy` stdio loop (external API).
//!
//! These mirror the session a real MCP client runs: initialize, tools/list,
//! a SAT-gated `tools/call`, and a rejected call.

use ed25519_dalek::{Signer as _, SigningKey};
use mcp_policy_proxy::proxy;
use mcp_policy_proxy::signature::canonical_payload;
use serde_json::{json, Value};
use std::io::Cursor;

const PUB_KEY_BYTES: [u8; 32] = [17u8; 32];

fn pub_key_hex() -> String {
    hex::encode(SigningKey::from_bytes(&PUB_KEY_BYTES).verifying_key().to_bytes())
}

fn signed_sat() -> Value {
    let key = SigningKey::from_bytes(&PUB_KEY_BYTES);
    let claims = json!({"agent": "integration-test"});
    let payload = canonical_payload(&claims).unwrap();
    let signature = key.sign(payload.as_bytes());
    let mut token = claims;
    token["signature"] = Value::String(hex::encode(signature.to_bytes()));
    token
}

fn run_session(input: &str) -> String {
    let mut output = Vec::new();
    proxy::run(Cursor::new(input.to_string()), &mut output, &pub_key_hex()).unwrap();
    String::from_utf8(output).unwrap()
}

#[test]
fn full_client_session() {
    let sat = signed_sat();
    let args = json!({"_sat": sat});
    let input = format!(
        "{}\n{}\n{}\n{}\n",
        r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}"#,
        r#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#,
        format!(r#"{{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{{"name":"proxied_tool","arguments":{args}}}}}"#),
        r#"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"proxied_tool","arguments":{}}}"#,
    );
    let out = run_session(&input);
    let lines: Vec<&str> = out.lines().collect();
    assert_eq!(lines.len(), 4);

    let initialize: Value = serde_json::from_str(lines[0]).unwrap();
    assert_eq!(initialize["id"], 1);
    assert_eq!(initialize["result"]["protocolVersion"], "2024-11-05");
    assert_eq!(initialize["result"]["serverInfo"]["name"], "python-policy-proxy");

    let tools: Value = serde_json::from_str(lines[1]).unwrap();
    assert_eq!(tools["id"], 2);
    assert_eq!(tools["result"]["tools"][0]["name"], "proxied_tool");

    let call: Value = serde_json::from_str(lines[2]).unwrap();
    assert_eq!(call["result"]["isError"], false);
    assert_eq!(
        call["result"]["content"][0]["text"],
        "Successfully executed proxied_tool through policy proxy!"
    );

    let rejected: Value = serde_json::from_str(lines[3]).unwrap();
    assert_eq!(rejected["error"]["code"], -32602);
    assert!(rejected["error"]["message"].as_str().unwrap().contains("Missing _sat"));
}

#[test]
fn valid_sat_is_required() {
    let sat = signed_sat();
    let good = json!({"_sat": sat});
    let bad_line = format!(
        r#"{{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{{"name":"t","arguments":{good}}}}}"#
    );
    let good_out = run_session(&bad_line);
    assert!(good_out.contains("\"isError\":false"));

    let bad = json!({"_sat": {"signature": "deadbeef"}});
    let bad_line = format!(
        r#"{{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{{"name":"t","arguments":{bad}}}}}"#
    );
    let bad_out = run_session(&bad_line);
    let v: Value = serde_json::from_str(bad_out.trim_end()).unwrap();
    assert_eq!(v["error"]["message"], "Invalid _sat signature. Access denied.");
}