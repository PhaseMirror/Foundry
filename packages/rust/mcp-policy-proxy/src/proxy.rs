//! Port of `materia_commons/mcp_server/python_proxy.py` — the
//! `python-policy-proxy` stdio MCP server.
//!
//! One JSON-RPC message per line over stdio. The policy proxy answers
//! `initialize` / `tools/list` itself, applies the In-band SAT gate to
//! `tools/call`, and mocks tool execution on success.
//!
//! The run loop is generic over any `BufRead`/`Write` pair so that tests can
//! drive it in-process; production uses the stdin/stdout loop in
//! [`run_stdio`].

use crate::gate::{check_sat, SatOutcome};
use crate::jsonrpc::{error_response, result_response};
use serde_json::{json, Value};
use std::io::{self, BufRead, BufReader, BufWriter, Write};

/// `protocolVersion` reported on `initialize` (MCP 2024-11-05).
pub const PROTOCOL_VERSION: &str = "2024-11-05";
/// `serverInfo.name` as in the Python `initialize` response.
pub const PROXY_SERVER_NAME: &str = "python-policy-proxy";
/// `serverInfo.version` as in the Python `initialize` response.
pub const PROXY_SERVER_VERSION: &str = "1.0.0";
/// The single tool advertised by `tools/list`.
pub const PROXIED_TOOL_NAME: &str = "proxied_tool";
/// JSON-RPC error code used for SAT gate failures (`-32602` invalid params).
pub const SAT_GATE_ERROR_CODE: i64 = -32602;
/// `tools/call` error message when `_sat` is absent.
pub const MISSING_SAT_MESSAGE: &str = "Missing _sat in arguments. Policy proxy requires an In-band SAT.";
/// `tools/call` error message when `_sat` fails verification.
pub const INVALID_SAT_MESSAGE: &str = "Invalid _sat signature. Access denied.";

/// Handle one decoded JSON-RPC request.
///
/// Returns `None` when the proxy has nothing to say (unknown methods and
/// `notifications/initialized`), exactly like the Python `continue`.
pub fn handle_request(id: Value, method: &str, params: Option<&Value>, pub_key_hex: &str) -> Option<Value> {
    match method {
        "initialize" => Some(result_response(
            id,
            json!({
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {},
                "serverInfo": { "name": PROXY_SERVER_NAME, "version": PROXY_SERVER_VERSION }
            }),
        )),
        "notifications/initialized" => None,
        "tools/list" => Some(result_response(
            id,
            json!({
                "tools": [{
                    "name": PROXIED_TOOL_NAME,
                    "description": "A proxied tool",
                    "inputSchema": { "type": "object", "properties": {} }
                }]
            }),
        )),
        "tools/call" => {
            let arguments = params.and_then(|p| p.get("arguments")).cloned().unwrap_or(json!({}));
            let name = params.and_then(|p| p.get("name")).cloned().unwrap_or(Value::Null);
            match check_sat(&arguments, pub_key_hex) {
                SatOutcome::Missing => Some(error_response(id, SAT_GATE_ERROR_CODE, MISSING_SAT_MESSAGE)),
                SatOutcome::Invalid => Some(error_response(id, SAT_GATE_ERROR_CODE, INVALID_SAT_MESSAGE)),
                SatOutcome::Pass => {
                    let name_txt = match &name {
                        Value::String(s) => s.clone(),
                        other => other.to_string(),
                    };
                    Some(result_response(
                        id,
                        json!({
                            "content": [{ "type": "text", "text": format!("Successfully executed {name_txt} through policy proxy!") }],
                            "isError": false
                        }),
                    ))
                }
            }
        }
        _ => None,
    }
}

/// Process one raw JSON-RPC line; `Ok(Some(line))` when a response must be
/// emitted, `Ok(None)` when the request is silent, `Err` on malformed JSON.
pub fn handle_line(line: &str, pub_key_hex: &str) -> io::Result<Option<String>> {
    let req: Value = serde_json::from_str(line).map_err(|e| {
        io::Error::new(io::ErrorKind::InvalidData, format!("failed to parse JSON-RPC: {e}"))
    })?;
    let id = req.get("id").cloned().unwrap_or(Value::Null);
    let method = req.get("method").and_then(Value::as_str).unwrap_or("");
    let params = req.get("params");
    let Some(response) = handle_request(id, method, params, pub_key_hex) else {
        return Ok(None);
    };
    let serialized = serde_json::to_string(&response)?;
    Ok(Some(serialized))
}

/// Drive the proxy over an arbitrary reader/writer, one JSON-RPC message per
/// line. Empty lines are skipped; malformed lines are reported on stderr and
/// the loop continues, matching the Python `except` block.
pub fn run<R: BufRead, W: Write>(reader: R, writer: W, pub_key_hex: &str) -> io::Result<()> {
    let mut reader = BufReader::new(reader);
    let mut writer = BufWriter::new(writer);
    let mut line = String::new();
    loop {
        line.clear();
        let n = reader.read_line(&mut line)?;
        if n == 0 {
            break;
        }
        if line.trim().is_empty() {
            continue;
        }
        match handle_line(&line, pub_key_hex) {
            Ok(Some(response)) => {
                writeln!(writer, "{response}")?;
                writer.flush()?;
            }
            Ok(None) => {}
            Err(e) => eprintln!("Error handling request: {e}"),
        }
    }
    Ok(())
}

/// Run the proxy over the process stdin/stdout.
pub fn run_stdio(pub_key_hex: &str) -> io::Result<()> {
    let stdin = io::stdin();
    let stdout = io::stdout();
    run(stdin.lock(), stdout.lock(), pub_key_hex)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::signature::canonical_payload;
    use ed25519_dalek::{Signer as _, SigningKey};
    use serde_json::json;

    fn signed_sat(claims: Value) -> Value {
        let key = SigningKey::from_bytes(&[11u8; 32]);
        let payload = canonical_payload(&claims).unwrap();
        let signature = key.sign(payload.as_bytes());
        let mut token = claims;
        token["signature"] = Value::String(hex::encode(signature.to_bytes()));
        token
    }

    fn pub_key_hex() -> String {
        hex::encode(SigningKey::from_bytes(&[11u8; 32]).verifying_key().to_bytes())
    }

    fn invoke(line: &str) -> Option<String> {
        handle_line(line, &pub_key_hex()).unwrap()
    }

    #[test]
    fn initialize_reports_protocol_and_server_info() {
        let out = invoke(r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"#).unwrap();
        let v: Value = serde_json::from_str(&out).unwrap();
        assert_eq!(v["result"]["protocolVersion"], "2024-11-05");
        assert_eq!(v["result"]["serverInfo"]["name"], "python-policy-proxy");
        assert_eq!(v["result"]["serverInfo"]["version"], "1.0.0");
        assert_eq!(v["id"], 1);
    }

    #[test]
    fn initialized_notification_is_silent() {
        assert_eq!(invoke(r#"{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}"#), None);
    }

    #[test]
    fn tools_list_advertises_single_proxied_tool() {
        let out = invoke(r#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#).unwrap();
        let v: Value = serde_json::from_str(&out).unwrap();
        assert_eq!(v["result"]["tools"][0]["name"], "proxied_tool");
        assert_eq!(v["result"]["tools"][0]["inputSchema"]["type"], "object");
    }

    #[test]
    fn unknown_method_is_silent() {
        assert_eq!(invoke(r#"{"jsonrpc":"2.0","id":3,"method":"nope","params":{}}"#), None);
    }

    #[test]
    fn tools_call_without_sat_is_rejected() {
        let out = invoke(r#"{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"proxied_tool","arguments":{}}}"#).unwrap();
        let v: Value = serde_json::from_str(&out).unwrap();
        assert_eq!(v["error"]["code"], -32602);
        assert_eq!(v["error"]["message"], MISSING_SAT_MESSAGE);
    }

    #[test]
    fn tools_call_with_bad_sat_is_rejected() {
        let args = json!({"_sat": {"signature": "aa"}});
        let line = format!(r#"{{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{{"name":"proxied_tool","arguments":{args}}}}}"#);
        let out = invoke(&line).unwrap();
        let v: Value = serde_json::from_str(&out).unwrap();
        assert_eq!(v["error"]["code"], -32602);
        assert_eq!(v["error"]["message"], INVALID_SAT_MESSAGE);
    }

    #[test]
    fn tools_call_with_valid_sat_is_mocked_success() {
        let sat = signed_sat(json!({"agent": "ace"}));
        let args = json!({"_sat": sat, "arg": 1});
        let line = format!(r#"{{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{{"name":"proxied_tool","arguments":{args}}}}}"#);
        let out = invoke(&line).unwrap();
        let v: Value = serde_json::from_str(&out).unwrap();
        assert_eq!(v["result"]["isError"], false);
        assert_eq!(
            v["result"]["content"][0]["text"],
            "Successfully executed proxied_tool through policy proxy!"
        );
    }

    #[test]
    fn run_loop_echoes_multiline_session() {
        let sat = signed_sat(json!({"agent": "ace"}));
        let args = json!({"_sat": sat});
        let call = format!(r#"{{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{{"name":"proxied_tool","arguments":{args}}}}}"#);
        let input = format!(
            "{}\n{}\n\n{}\n",
            r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"#,
            r#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#,
            call
        );
        let mut output = Vec::new();
        run(io::Cursor::new(input), &mut output, &pub_key_hex()).unwrap();
        let text = String::from_utf8(output).unwrap();
        let lines: Vec<&str> = text.lines().collect();
        assert_eq!(lines.len(), 3);
        assert!(lines[0].contains("\"protocolVersion\":\"2024-11-05\""));
        assert!(lines[1].contains("\"proxied_tool\""));
        assert!(lines[2].contains("\"isError\":false"));
    }

    #[test]
    fn malformed_line_does_not_abort_loop() {
        let input = "not-json\n".to_string() + r#"{"jsonrpc":"2.0","id":1,"method":"tools/list"}"# + "\n";
        let mut output = Vec::new();
        run(io::Cursor::new(input), &mut output, &pub_key_hex()).unwrap();
        let text = String::from_utf8(output).unwrap();
        assert_eq!(text.lines().count(), 1);
    }
}