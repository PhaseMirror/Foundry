use wasm_bindgen::prelude::*;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

#[derive(Serialize, Deserialize)]
pub struct StateTransition {
    pub id: String,
    pub r_sc: f64,
    pub l_eff: f64,
}

#[wasm_bindgen]
pub struct WasmSigmaKernel {
    tau_r: f64,
    max_l_eff: f64,
}

#[wasm_bindgen]
impl WasmSigmaKernel {
    #[wasm_bindgen(constructor)]
    pub fn new(tau_r: f64, max_l_eff: f64) -> Self {
        Self { tau_r, max_l_eff }
    }

    /// Evaluates a state transition strictly in the browser sandbox.
    /// Returns a JSON string of the UnifiedWitness if successful, or throws a JS error.
    #[wasm_bindgen]
    pub fn evaluate_and_sign(&self, transition_json: &str, operator_key: &str, kernel_key: &str) -> Result<String, JsValue> {
        let transition: StateTransition = serde_json::from_str(transition_json)
            .map_err(|e| JsValue::from_str(&format!("Parse error: {}", e)))?;

        // 1. Dissonance Check
        let passes_tau_r = (transition.r_sc - self.tau_r).abs() < 1e-6;
        let passes_l_eff = transition.l_eff < self.max_l_eff;

        if !passes_tau_r || !passes_l_eff {
            return Err(JsValue::from_str(&format!(
                "Threshold Violation: R_sc={}, L_eff={}",
                transition.r_sc, transition.l_eff
            )));
        }

        // 2. Generate UnifiedWitness metrics hash
        let mut metrics_hasher = Sha256::new();
        metrics_hasher.update(format!("{}-{}", transition.r_sc, transition.l_eff).as_bytes());
        let metrics_hash = hex::encode(metrics_hasher.finalize());

        // 3. Dual-Signature Protocol
        let timestamp = "browser-timestamp"; // Mocked for WASM sandbox
        
        let mut core_hasher = Sha256::new();
        core_hasher.update(transition.id.as_bytes());
        core_hasher.update(timestamp.as_bytes());
        core_hasher.update(metrics_hash.as_bytes());
        let core_hash = hex::encode(core_hasher.finalize());

        let mut p_hasher = Sha256::new();
        p_hasher.update(core_hash.as_bytes());
        p_hasher.update(operator_key.as_bytes());
        let primary_signature = hex::encode(p_hasher.finalize());

        let mut s_hasher = Sha256::new();
        s_hasher.update(core_hash.as_bytes());
        s_hasher.update(kernel_key.as_bytes());
        let secondary_signature = hex::encode(s_hasher.finalize());

        let witness_json = format!(
            r#"{{"transition_id":"{}","timestamp":"{}","metrics_hash":"{}","primary_signature":"{}","secondary_signature":"{}"}}"#,
            transition.id, timestamp, metrics_hash, primary_signature, secondary_signature
        );

        Ok(witness_json)
    }
}

#[wasm_bindgen]
pub fn matrix_evaluate(kernel_json: &str, input_json: &str) -> Result<String, JsValue> {
    let kernel: pirtm_stdlib::matrix_engine::TensorKernel = serde_json::from_str(kernel_json)
        .map_err(|e| JsValue::from_str(&format!("Parse error kernel: {}", e)))?;
    let input: pirtm_stdlib::matrix_engine::PrimeMonomialMatrix = serde_json::from_str(input_json)
        .map_err(|e| JsValue::from_str(&format!("Parse error input: {}", e)))?;

    match pirtm_stdlib::matrix_engine::evaluate(&kernel, &input) {
        Ok(result) => Ok(serde_json::to_string(&result).unwrap()),
        Err(e) => Err(JsValue::from_str(&e.to_string())),
    }
}

pub mod fuzz_tests;
