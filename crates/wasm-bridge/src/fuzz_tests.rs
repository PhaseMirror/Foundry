#[cfg(test)]
mod tests {
    use proptest::prelude::*;
    use crate::{WasmSigmaKernel, StateTransition};
    use wasm_bindgen::JsValue;

    proptest! {
        // Fuzz test running 100,000 iterations to guarantee the constraints hold
        #![proptest_config(ProptestConfig::with_cases(100000))]
        #[test]
        fn fuzz_sigma_kernel_bounds(
            r_sc in -100.0..100.0f64,
            l_eff in -10.0..10.0f64,
        ) {
            let kernel = WasmSigmaKernel::new(47.06998778, 1.0);
            
            let transition = StateTransition {
                id: "fuzz-tx".to_string(),
                r_sc,
                l_eff,
            };
            
            let payload = serde_json::to_string(&transition).unwrap();
            let result = kernel.evaluate_and_sign(&payload, "op-key", "kernel-key");
            
            let passes_tau_r = (r_sc - 47.06998778).abs() < 1e-6;
            let passes_l_eff = l_eff < 1.0;
            
            if passes_tau_r && passes_l_eff {
                // If it passes bounds, it MUST yield a valid string
                prop_assert!(result.is_ok());
            } else {
                // If bounds are violated, it MUST fail-closed with a trap
                prop_assert!(result.is_err());
                let err_msg = result.unwrap_err().as_string().unwrap();
                prop_assert!(err_msg.contains("Threshold Violation"));
            }
        }
    }
}
