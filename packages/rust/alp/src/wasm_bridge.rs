use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use serde_wasm_bindgen;
use alp::evaluate_preservation;

#[derive(Debug, Deserialize, Serialize)]
pub struct PolicyInput {
    pub id: String,
    pub payload: serde_json::Value,
    pub mutating: bool,
    pub server_binding: Option<String>,
}

#[wasm_bindgen]
pub fn evaluate_policy(input: JsValue) -> Result<JsValue, JsValue> {
    // Convert JsValue (from JS) to PolicyInput using serde_wasm_bindgen
    let policy_input: PolicyInput = serde_wasm_bindgen::from_value(input)
        .map_err(|e| JsValue::from_str(&format!("Deserialize error: {}", e)))?;
    // Serialize back to JSON string for the Rust engine API
    let json_str = serde_json::to_string(&policy_input)
        .map_err(|e| JsValue::from_str(&format!("Serialize error: {}", e)))?;
    // Call the Rust side function (to be added in lib.rs)
    match evaluate_preservation(&json_str) {
        Ok(risk) => Ok(JsValue::from_str(&risk)),
        Err(e) => Err(JsValue::from_str(&format!("Eval error: {}", e))),
    }
}
