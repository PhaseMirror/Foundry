//! JSON-RPC 2.0 / MCP response construction shared by both proxies.

use serde_json::{json, Value};

/// Build a `result` response: `{"jsonrpc": "2.0", "id": id, "result": ...}`.
///
/// Mirrors the Python `res = {"jsonrpc": "2.0", "id": req_id, "result": ...}`
/// plus `json.dumps(res)`.
pub fn result_response(id: Value, result: Value) -> Value {
    json!({ "jsonrpc": "2.0", "id": id, "result": result })
}

/// Build an `error` response: `{"jsonrpc": "2.0", "id": id, "error": {...}}`.
pub fn error_response(id: Value, code: i64, message: &str) -> Value {
    json!({ "jsonrpc": "2.0", "id": id, "error": { "code": code, "message": message } })
}

/// Serialize a response for the JSON-RPC wire, matching Python `json.dumps`
/// (compact separators).
pub fn serialize_response(value: &Value) -> serde_json::Result<String> {
    serde_json::to_string(value)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn result_response_keeps_null_id() {
        assert_eq!(
            serialize_response(&result_response(Value::Null, json!({}))).unwrap(),
            r#"{"id":null,"jsonrpc":"2.0","result":{}}"#
        );
    }

    #[test]
    fn error_response_uses_param_error_code() {
        let v = error_response(json!(7), -32602, "Missing _sat in arguments.");
        assert_eq!(v["error"]["code"], -32602);
        assert_eq!(v["jsonrpc"], "2.0");
        assert_eq!(v["id"], 7);
    }
}