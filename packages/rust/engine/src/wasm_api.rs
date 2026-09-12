use wasm_bindgen::prelude::*;
use crate::spectral::SpectralGovernor;
use governance_core_rs::DissonanceReport;
use governance_core_rs::phase_mirror::policy::evaluate_state_transition;
use serde_json::json;
use nalgebra::{DMatrix, DVector};

#[wasm_bindgen]
pub struct PirtmEngine {
    governor: SpectralGovernor,
    state: Vec<f64>,
    prev_kl: Option<f64>,
    step_count: usize,
}

#[wasm_bindgen]
impl PirtmEngine {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        Self {
            governor: SpectralGovernor::new(10),
            state: vec![0.1; 10],
            prev_kl: None,
            step_count: 0,
        }
    }
    
    // Add getter for state
    pub fn get_state(&self) -> Vec<f64> {
        self.state.clone()
    }

    // Add setter for state
    pub fn set_state(&mut self, state: Vec<f64>) {
        self.state = state;
    }

    // Reset step count and state
    pub fn reset(&mut self) {
        self.state = vec![0.1; 10];
        self.prev_kl = None;
        self.step_count = 0;
    }
// ...

    pub fn evaluate_spectral_density(&mut self, _input: &str) -> JsValue {
        // Sedona Spine: Mandatory route through Rust logic
        let report = self.governor.analyze(|x| x.map(|v| v.sin() * 0.8));
        
        let result = serde_wasm_bindgen::to_value(&report).unwrap();
        
        // Phase 4: Sealed Memory - Explicit zeroing of internal buffers if applicable
        // The SpectralGovernor analysis is pure, but we ensure no local leaks.
        self.governor.clear_history(); 
        
        result
    }

    pub fn verify_governance_context(&self, ctx: JsValue) -> JsValue {
        // Deserialize JS context to string inputs for evaluate_state_transition
        let context: serde_json::Value = serde_wasm_bindgen::from_value(ctx).unwrap();
        let input_text = context["input_text"].as_str().unwrap();
        let snapshot_json = context["snapshot_json"].as_str().unwrap();
        let trigger = context["trigger"].as_str().unwrap();

        // Sedona Spine: Mandatory route through Rust logic
        let report: DissonanceReport = evaluate_state_transition(input_text, snapshot_json, trigger);
        serde_wasm_bindgen::to_value(&report).unwrap()
    }

    pub fn compute_step_recurrence(&self, state: JsValue) -> JsValue {
        use crate::recurrence::step;

        let s: serde_json::Value = serde_wasm_bindgen::from_value(state).unwrap();
        
        let x_t_val = s["x_t_val"].as_f64().unwrap();
        let xi_t_val = s["xi_t_val"].as_f64().unwrap();
        let lam_t_val = s["lam_t_val"].as_f64().unwrap();
        let epsilon = s["epsilon"].as_f64().unwrap();
        let op_norm_t = s["op_norm_t"].as_f64().unwrap();
        let t = s["t"].as_u64().unwrap() as usize;
        let gain = s["gain"].as_f64().unwrap();

        // Scope calculation to ensure local vectors are dropped immediately
        let (x_next_val, info) = {
            let x_t = DVector::from_element(1, x_t_val);
            let xi_t = DMatrix::from_element(1, 1, xi_t_val);
            let lam_t = DMatrix::from_element(1, 1, lam_t_val);
            let g_t = DVector::zeros(1);

            // Operator with gain: sin(gain * x)
            let t_op = |x: &DVector<f64>| x.map(|val| (val * gain).sin());
            // Identity projector
            let p_op = |x: &DVector<f64>| x.clone();

            let (x_next, info) = step(
                &x_t,
                &xi_t,
                &lam_t,
                &t_op,
                &g_t,
                &p_op,
                epsilon,
                op_norm_t,
                t,
            );
            (x_next[0], info)
        };

        let result = json!({
            "x_next": x_next_val,
            "info": info
        });

        serde_wasm_bindgen::to_value(&result).unwrap()
    }

    pub fn validate_and_seal(&mut self, payload: JsValue, manifold: JsValue) -> Result<JsValue, JsValue> {
        use crate::recurrence::{step};
        
        let p: serde_json::Value = serde_wasm_bindgen::from_value(payload).unwrap();
        let epsilon = p["epsilon"].as_f64().unwrap();
        let gain = p["gain"].as_f64().unwrap();
        
        // Deserialize manifold
        let m: serde_json::Value = serde_wasm_bindgen::from_value(manifold).unwrap();
        let ref_dist: Vec<f64> = m["distribution"]
            .as_array()
            .map(|arr| arr.iter().map(|v| v.as_f64().unwrap()).collect())
            .unwrap_or_else(|| vec![0.1; self.state.len()]);
        
        // Convert self.state (Vec<f64>) to DVector
        let x_t = DVector::from_vec(self.state.clone());
        let xi_t = DMatrix::from_element(x_t.len(), x_t.len(), 0.8);
        let lam_t = DMatrix::from_element(x_t.len(), x_t.len(), 0.1);
        let g_t = DVector::zeros(x_t.len());

        // Setup operator/projector
        let t_op = |x: &DVector<f64>| x.map(|val| (val * gain).sin());
        let p_op = |x: &DVector<f64>| x.map(|val| val.clamp(-1.0, 1.0));
        
        // 1. Memory convolution via step
        let (next_state, info) = step(
            &x_t,
            &xi_t,
            &lam_t,
            &t_op,
            &g_t,
            &p_op,
            epsilon,
            1.0, // op_norm_t
            self.step_count,
        );
        
        // 2. Lawful projection
        let projected_state = next_state.map(|v| v.clamp(-0.95, 0.95));
        
        // 3. Compute initial KL divergence against reference distribution
        let ref_vector = DVector::from_vec(ref_dist);
        let kl_initial = crate::ward_monitor::compute_kl_divergence(&projected_state, &ref_vector);
        
        // 4. Pole-zero proximity and initial weighted dissonance
        let zeta_proximity = 0.05 + 0.02 * (gain * epsilon).cos().abs();
        let rho_initial = kl_initial * (1.0 + zeta_proximity);
        
        // 5. Apply Zeno corrective map if dissonance exceeds warning threshold (0.85)
        let mut final_state = projected_state;
        if rho_initial > 0.85 && rho_initial < 1.0 {
            let diff = (rho_initial - 0.5).abs().max(1e-5);
            let kappa = 0.1 * (-1.0 / diff).exp();
            
            // Dissonance gradient approximation: direction towards reference distribution
            let grad = &final_state - &ref_vector;
            let corrected = &final_state - kappa * grad;
            
            // Orthogonal projection Pi_M onto the lawful manifold M
            final_state = corrected.map(|v| v.clamp(-0.95, 0.95));
        }
        
        // Re-evaluate metrics on final state
        let kl_residual = crate::ward_monitor::compute_kl_divergence(&final_state, &ref_vector);
        let rho = kl_residual * (1.0 + zeta_proximity);
        
        // 6. Drift velocity
        let drift_velocity = if let Some(prev) = self.prev_kl {
            kl_residual - prev
        } else {
            0.0
        };
        self.prev_kl = Some(kl_residual);
        
        // 7. Threshold verification (Fail-Closed)
        let _warning_threshold = 0.85;
        let critical_threshold = 1.0;
        
        let is_valid = rho < critical_threshold;
        
        if !is_valid {
            // Purge volatile state memory
            self.state = vec![0.0; self.state.len()];
            self.prev_kl = None;
            
            return Ok(serde_wasm_bindgen::to_value(&json!({
                "is_valid": false,
                "spectral_gap": 0.0,
                "proof_hash": "FATAL_DRIFT_HALT_FREEZE",
                "timestamp": chrono::Utc::now().to_rfc3339(),
                "residual": info.residual,
                "kl_residual": kl_residual,
                "zeta_proximity": zeta_proximity,
                "drift_velocity": drift_velocity
            })).unwrap());
        }
        
        self.state = final_state.iter().cloned().collect();
        self.step_count += 1;
        
        let gap = 1.0 - (0.9 * 0.9); // Placeholder spectral radius
        
        Ok(serde_wasm_bindgen::to_value(&json!({
            "is_valid": true,
            "spectral_gap": gap,
            "proof_hash": "0xCERTIFIED_SEAL_HASH",
            "timestamp": chrono::Utc::now().to_rfc3339(),
            "residual": info.residual,
            "kl_residual": kl_residual,
            "zeta_proximity": zeta_proximity,
            "drift_velocity": drift_velocity
        })).unwrap())
    }
}

#[wasm_bindgen]
pub fn get_version() -> String {
    "PIRTM-RS-0.1.0-SEDONA".to_string()
}
