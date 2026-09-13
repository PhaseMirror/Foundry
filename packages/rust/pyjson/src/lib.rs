//! Serialization compatible with Python's `json` module.
//!
//! `serde_json` only emits compact separators and does not match Python's
//! default-separator or `indent` formats exactly. This crate reproduces the
//! two Python formats actually used by the ported Python packages:
//!
//! * [`to_python_style`] — `json.dumps(value, sort_keys=True)` with default
//!   separators (`, ` and `: `).
//! * [`to_compact`] — `json.dumps(value, sort_keys=True, separators=(",", ":"))`.
//!
//! Both iterate key–value pairs as stored, so callers should build objects via
//! `serde_json`'s default `Map` (a `BTreeMap`, sorted keys) to get the
//! `sort_keys=True` ordering.
//!
//! Escaping of strings reuses `serde_json`, matching Python for the payloads
//! used across the ported packages (no non-ASCII escaping is applied, matching
//! Python's `ensure_ascii=False` for UTF-8-safe payloads).

#![forbid(unsafe_code)]

use serde_json::Value;

/// Render `value` the way Python `json.dumps(value, sort_keys=True)` does
/// (default separators `, ` and `: `).
pub fn to_python_style(value: &Value) -> String {
    match value {
        Value::Null => "null".to_string(),
        Value::Bool(b) => b.to_string(),
        Value::Number(n) => n.to_string(),
        Value::String(s) => serde_json::to_string(s).expect("string serialization cannot fail"),
        Value::Array(items) => {
            let inner = items
                .iter()
                .map(to_python_style)
                .collect::<Vec<_>>()
                .join(", ");
            format!("[{inner}]")
        }
        Value::Object(map) => {
            let inner = map
                .iter()
                .map(|(k, v)| {
                    format!(
                        "{}: {}",
                        serde_json::to_string(k).expect("key serialization cannot fail"),
                        to_python_style(v)
                    )
                })
                .collect::<Vec<_>>()
                .join(", ");
            format!("{{{inner}}}")
        }
    }
}

/// Serialize `value` compactly, matching
/// `json.dumps(value, sort_keys=True, separators=(",", ":"))`.
pub fn to_compact(value: &Value) -> String {
    serde_json::to_string(value).expect("serialization cannot fail")
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn python_style_default_separators() {
        let value = json!({
            "e": "f:g,h é\"x",
            "a": 1,
            "b": [true, {"c": "d"}],
            "empty_obj": {},
            "empty_arr": [],
            "f": 2.5,
        });
        assert_eq!(
            to_python_style(&value),
            concat!(
                r#"{"a": 1, "b": [true, {"c": "d"}], "e": "f:g,h é\"x", "#,
                r#""empty_arr": [], "empty_obj": {}, "f": 2.5}"#
            )
        );
    }

    #[test]
    fn compact_separators_match_python_compact() {
        let value = json!({"message": "m", "braid": "1:2;3:4"});
        assert_eq!(to_compact(&value), r#"{"braid":"1:2;3:4","message":"m"}"#);
    }

    #[test]
    fn numbers_match_python() {
        assert_eq!(to_python_style(&json!(5)), "5");
        assert_eq!(to_python_style(&json!(2.0)), "2.0");
        assert_eq!(to_python_style(&json!(0.05)), "0.05");
        assert_eq!(to_python_style(&json!(-3)), "-3");
    }
}
