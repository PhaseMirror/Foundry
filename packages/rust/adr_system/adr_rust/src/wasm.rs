use crate::engine::{EsiEngine, EngineState};
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct WasmEngine {
    engine: EsiEngine,
}

#[wasm_bindgen]
impl WasmEngine {
    #[wasm_bindgen(constructor)]
    pub fn new(policy_active: bool, event_log_count: usize, spoliation_flags: u32) -> Self {
        let state = EngineState::new(policy_active, event_log_count, spoliation_flags);
        Self {
            engine: EsiEngine::new(state),
        }
    }

    #[wasm_bindgen]
    pub fn compute_risk_level(&self) -> String {
        // Expose as read-only string calculation
        self.engine.compute_risk_level().to_string()
    }
}
