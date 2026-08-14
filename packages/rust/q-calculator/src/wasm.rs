use wasm_bindgen::prelude::*;
use nalgebra::{DMatrix, DVector};
use crate::{QAriCore, QAriParams};

#[wasm_bindgen]
pub struct WasmQAri {
    params: QAriParams,
}

#[wasm_bindgen]
impl WasmQAri {
    #[wasm_bindgen(constructor)]
    pub fn new(epsilon: f64, op_norm_t: f64, max_steps: usize, tol: f64) -> Self {
        console_error_panic_hook::set_once();
        let params = QAriParams {
            epsilon,
            op_norm_t,
            max_steps,
            tol,
        };
        Self { params }
    }

    /// Run the contractivity loop for a given initial state and matrices.
    /// In a real scenario, JS would pass arrays and we map them to nalgebra structures.
    /// For simplicity in this WASM wrapper, we expect 1D arrays for vectors and flatten matrices.
    #[wasm_bindgen]
    pub fn run_simulation(
        &self,
        x0: &[f64],
        xi_diag: &[f64],
        lam_diag: &[f64],
        g_vec: &[f64],
        dim: usize,
    ) -> Result<js_sys::Float64Array, JsValue> {
        let t_op = |x: &DVector<f64>| x * 0.75; // Example linear operator
        let core = QAriCore::new(t_op, Some(self.params.clone()));

        let x_init = DVector::from_row_slice(x0);
        let xi_m = DMatrix::from_diagonal(&DVector::from_row_slice(xi_diag));
        let lam_m = DMatrix::from_diagonal(&DVector::from_row_slice(lam_diag));
        let g_v = DVector::from_row_slice(g_vec);

        // For this simple simulation, we just use the same matrix at each step
        let steps = self.params.max_steps;
        let xi_seq = vec![xi_m; steps];
        let lam_seq = vec![lam_m; steps];
        let g_seq = vec![g_v; steps];

        match core.run(x_init, &xi_seq, &lam_seq, &g_seq) {
            Ok((final_x, _history)) => {
                let slice = final_x.as_slice();
                Ok(js_sys::Float64Array::from(slice))
            }
            Err(e) => Err(JsValue::from_str(&format!("Simulation Error: {:?}", e))),
        }
    }
}
