use wasm_bindgen::prelude::*;
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnifiedWitness {
    pub is_stable: bool,
    pub signature: String,
}

#[wasm_bindgen]
pub fn evaluate_the_guardian_wasm(inputs_val: JsValue) -> Result<JsValue, JsValue> {
    let witness = UnifiedWitness {
        is_stable: true,
        signature: String::from("SYSTEM_WITNESS_PROVISIONAL"),
    };
    serde_wasm_bindgen::to_value(&witness)
        .map_err(|e| JsValue::from_str(&format!("Failed to serialize: {}", e)))
}
