//! Serialization compatible with Python's `json.dumps(sort_keys=True)` using
//! the default separators (`, ` and `: `).
//!
//! `serde_json` only emits compact separators, so this module walks a
//! [`serde_json::Value`] (whose objects sort keys when the `preserve_order`
//! feature is disabled) and re-emits it with Python's default separators.
//! Escaping of strings reuses `serde_json` so it matches Python's `json`
//! module byte-for-byte for the payloads used in this crate.

use serde_json::Value;

/// Render `value` the way Python `json.dumps(value, sort_keys=True)` does.
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

/// Serialize `value` compactly, matching Python `json.dumps(value, sort_keys=True, separators=(",", ":"))`.
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
