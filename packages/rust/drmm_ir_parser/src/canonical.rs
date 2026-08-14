use crate::ast::*;
use crate::error::Result;
use serde_json::{Map, Value};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;

/// Canonicalize an IR document into a stable, deterministic JSON string.
///
/// The canonical form sorts top-level nodes by `id` and recursively
/// sorts object keys lexicographically. Arrays of objects are sorted
/// by their `"id"` field when present.
pub fn canonicalize(doc: &IrDocument) -> Result<String> {
    let mut sorted_doc = doc.clone();
    sorted_doc.nodes.sort_by(|a, b| a.id().cmp(b.id()));
    let value = serde_json::to_value(sorted_doc)?;
    let canonical_value = canonicalize_value(&value);
    Ok(serde_json::to_string(&canonical_value)?)
}

/// Compute the SHA-256 hash of the canonical JSON representation.
///
/// Returns the hash as a lowercase hex string.
pub fn canonical_hash(doc: &IrDocument) -> Result<String> {
    let json = canonicalize(doc)?;
    let mut hasher = Sha256::new();
    hasher.update(json.as_bytes());
    let result = hasher.finalize();
    Ok(hex::encode(result))
}

/// Canonicalize an IR document using the explicit `canonicalize_doc` path
/// (alias for `canonicalize`; preserved for API symmetry with the ADR spec).
pub fn canonicalize_doc(doc: &IrDocument) -> Result<String> {
    canonicalize(doc)
}

/// Recursively sort object keys and array elements for deterministic output.
fn canonicalize_value(value: &Value) -> Value {
    match value {
        Value::Object(map) => {
            let sorted: BTreeMap<_, _> = map.iter().collect();
            let mut new_map = Map::new();
            for (k, v) in sorted {
                new_map.insert(k.clone(), canonicalize_value(v));
            }
            Value::Object(new_map)
        }
        Value::Array(arr) => {
            if arr.iter().all(|v| v.is_object()) {
                let mut objects: Vec<&Value> = arr.iter().collect();
                objects.sort_by(|a, b| {
                    let id_a = a.get("id").and_then(|v| v.as_str()).unwrap_or("");
                    let id_b = b.get("id").and_then(|v| v.as_str()).unwrap_or("");
                    id_a.cmp(id_b)
                });
                let new_arr: Vec<Value> = objects.into_iter().map(canonicalize_value).collect();
                Value::Array(new_arr)
            } else {
                let new_arr: Vec<Value> = arr.iter().map(canonicalize_value).collect();
                Value::Array(new_arr)
            }
        }
        _ => value.clone(),
    }
}
