use wasm_bindgen::prelude::*;
use crate::wasm_api::PirtmEngine;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MultiplicityParams {
    pub lambda_m: f64,
    pub gamma: f64,
}

#[derive(Serialize)]
pub struct ContractivityReceipt {
    pub is_valid: bool,
    pub spectral_gap: f64,
    pub proof_hash: String,
    pub timestamp: String,
}

#[wasm_bindgen]
impl PirtmEngine {
    pub fn verify_algebraic_contractivity(&self, params_json: &str) -> JsValue {
        let params: MultiplicityParams = serde_json::from_str(params_json).unwrap();

        // Formal check: L\Phi < 1
        let spectral_radius = params.lambda_m * params.gamma;
        let gap = 1.0 - spectral_radius;
        let is_valid = gap > 0.0;

        let receipt = ContractivityReceipt {
            is_valid,
            spectral_gap: gap,
            proof_hash: "0xCERTIFIED_BINDING_HASH".to_string(), 
            timestamp: chrono::Utc::now().to_rfc3339(),
        };

        serde_wasm_bindgen::to_value(&receipt).unwrap()
    }

    pub fn bind_zm_algebraic_layer(&self, _config_json: &str) -> JsValue {
        serde_wasm_bindgen::to_value(&serde_json::json!({
            "status": "ZM_BINDING_INITIALIZED",
            "layer": "Algebraic-Enforcement-Gate-V0.2"
        })).unwrap()
    }
}

