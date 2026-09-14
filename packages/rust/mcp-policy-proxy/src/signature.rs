//! Ed25519 SAT verification — port of `verify_sat` from
//! `materia_commons/mcp_server/python_proxy.py` and `github_adapter.py`.
//!
//! The Python reference:
//!
//! ```text
//! token_copy = dict(sat_token)
//! signature_hex = token_copy.pop("signature", "")
//! payload = json.dumps(token_copy, separators=(',', ':'), sort_keys=True)
//! public_key = Ed25519PublicKey.from_public_bytes(bytes.fromhex(pub_key_hex))
//! public_key.verify(bytes.fromhex(signature_hex), payload.encode('utf-8'))
//! ```
//!
//! Fidelity notes:
//! * Canonical payload serialization delegates to `pyjson::to_compact`, which
//!   reproduces `separators=(",", ":")` with sorted keys (serde_json's default
//!   `Map` is a `BTreeMap`).
//! * `verify_strict` is used because the Python `cryptography` bindings verify
//!   with the strict (cofactor-aware) semantics.

use ed25519_dalek::{Signature, VerifyingKey};
use pyjson::to_compact;
use serde_json::Value;

/// `token_copy.pop("signature", "")` — the signature hex string, if present.
pub fn signature_hex(token: &Value) -> Option<String> {
    match token.get("signature") {
        Some(Value::String(sig)) => Some(sig.clone()),
        _ => None,
    }
}

/// Canonical payload for signing: the token with `signature` removed,
/// serialized compactly with sorted keys (Python `sort_keys=True,
/// separators=(',', ':')`).
pub fn canonical_payload(token: &Value) -> Option<String> {
    let obj = token.as_object()?;
    let mut filtered = serde_json::Map::new();
    for (key, value) in obj {
        if key != "signature" {
            filtered.insert(key.clone(), value.clone());
        }
    }
    Some(to_compact(&Value::Object(filtered)))
}

/// Verify that `token.signature` is a valid Ed25519 signature over the
/// canonicalized claim set, under the hex public key `pub_key_hex`.
///
/// Returns `false` on any malformed input (bad hex, wrong key/signature
/// length, or a failed signature check) — exactly the Python behavior of
/// catching the exception and returning `False`.
pub fn verify_sat(token: &Value, pub_key_hex: &str) -> bool {
    let Some(signature_hex) = signature_hex(token) else {
        return false;
    };
    let Some(payload) = canonical_payload(token) else {
        return false;
    };
    let Ok(signature_bytes) = hex::decode(signature_hex) else {
        return false;
    };
    if signature_bytes.len() != ed25519_dalek::SIGNATURE_LENGTH {
        return false;
    }
    let Ok(public_bytes) = hex::decode(pub_key_hex) else {
        return false;
    };
    if public_bytes.len() != ed25519_dalek::PUBLIC_KEY_LENGTH {
        return false;
    }
    let Ok(signature) = Signature::try_from(signature_bytes.as_slice()) else {
        return false;
    };
    let Ok(verifying_key) = VerifyingKey::from_bytes(public_bytes.as_slice().try_into().unwrap()) else {
        return false;
    };
    verifying_key.verify_strict(payload.as_bytes(), &signature).is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;
    use ed25519_dalek::{Signer as _, SigningKey};
    use serde_json::json;

    fn fixture_secret_key() -> SigningKey {
        SigningKey::from_bytes(&[7u8; 32])
    }

    fn signed_token(secret: &SigningKey, mut claims: Value) -> Value {
        let payload = canonical_payload(&claims).unwrap();
        let signature = secret.sign(payload.as_bytes());
        claims
            .as_object_mut()
            .unwrap()
            .insert("signature".to_string(), Value::String(hex::encode(signature.to_bytes())));
        claims
    }

    fn pub_key_hex(secret: &SigningKey) -> String {
        hex::encode(secret.verifying_key().to_bytes())
    }

    #[test]
    fn canonical_payload_strips_signature_and_sorts_keys() {
        let token = json!({
            "b": 2,
            "signature": "deadbeef",
            "a": 1,
            "c": {"z": 1, "y": 2}
        });
        // Single quote risk: keys must sort a < b < c.
        assert_eq!(
            canonical_payload(&token).unwrap(),
            r#"{"a":1,"b":2,"c":{"y":2,"z":1}}"#
        );
    }

    #[test]
    fn verifies_a_valid_signed_token() {
        let secret = fixture_secret_key();
        let token = signed_token(&secret, json!({"agent": "ace", "iat": 1699999999}));
        assert!(verify_sat(&token, &pub_key_hex(&secret)));
    }

    #[test]
    fn rejects_wrong_public_key() {
        let secret = fixture_secret_key();
        let other = SigningKey::from_bytes(&[9u8; 32]);
        let token = signed_token(&secret, json!({"agent": "ace"}));
        assert!(!verify_sat(&token, &pub_key_hex(&other)));
    }

    #[test]
    fn rejects_tampered_payload() {
        let secret = fixture_secret_key();
        let mut token = signed_token(&secret, json!({"agent": "ace"}));
        token["agent"] = Value::String("mallory".to_string());
        assert!(!verify_sat(&token, &pub_key_hex(&secret)));
    }

    #[test]
    fn rejects_missing_signature_field() {
        let secret = fixture_secret_key();
        let token = json!({"agent": "ace"});
        assert!(!verify_sat(&token, &pub_key_hex(&secret)));
    }

    #[test]
    fn rejects_bad_hex_and_bad_lengths() {
        let secret = fixture_secret_key();
        let token = signed_token(&secret, json!({"agent": "ace"}));
        let pk = pub_key_hex(&secret);
        assert!(!verify_sat(&token, "not-hex"));
        assert!(!verify_sat(&token, &format!("00{}", pk)));
        let mut bad = signed_token(&secret, json!({"agent": "ace"}));
        bad.as_object_mut().unwrap().insert("signature".to_string(), Value::String("aa".to_string()));
        assert!(!verify_sat(&bad, &pk));
    }

    #[test]
    fn rejects_non_object_token() {
        let secret = fixture_secret_key();
        assert!(!verify_sat(&json!([1, 2, 3]), &pub_key_hex(&secret)));
    }
}