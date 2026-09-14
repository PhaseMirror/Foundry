//! The missing / invalid / valid In-band SAT gate shared by both proxies.
//!
//! Both `python_proxy.py` and `github_adapter.py` implement the same check on
//! `tools/call`: the `arguments` object must carry an `_sat` token that passes
//! [`signature::verify_sat`]. The only difference between the two programs is
//! the error message text and what happens after the gate passes.

use crate::signature::verify_sat;
use serde_json::Value;

/// Classification of a `tools/call` against the SAT gate.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SatOutcome {
    /// `_sat` is present and the signature verifies.
    Pass,
    /// `_sat` is absent from `arguments`.
    Missing,
    /// `_sat` is present but the signature does not verify.
    Invalid,
}

/// Classify `arguments` under the SAT gate with hex public key `pub_key_hex`.
pub fn check_sat(arguments: &Value, pub_key_hex: &str) -> SatOutcome {
    match arguments.get("_sat") {
        None => SatOutcome::Missing,
        Some(token) if verify_sat(token, pub_key_hex) => SatOutcome::Pass,
        Some(_) => SatOutcome::Invalid,
    }
}

/// Return `arguments` with the `_sat` key removed, as both proxies do before
/// delegating (`clean_args = {k: v for k, v in args.items() if k != "_sat"}`).
pub fn strip_sat(arguments: &Value) -> Value {
    let mut stripped = arguments.clone();
    if let Some(map) = stripped.as_object_mut() {
        map.remove("_sat");
    }
    stripped
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn missing_absent_invalid_classify() {
        assert_eq!(check_sat(&json!({"a": 1}), "00"), SatOutcome::Missing);
        assert_eq!(check_sat(&json!({"a": 1, "_sat": {"signature": "aa"}}), "00"), SatOutcome::Invalid);
    }

    #[test]
    fn strip_removes_only_sat() {
        assert_eq!(
            strip_sat(&json!({"name": "proxied_tool", "_sat": {"signature": "aa"}})),
            json!({"name": "proxied_tool"})
        );
        assert_eq!(strip_sat(&json!({"a": 1})), json!({"a": 1}));
    }
}