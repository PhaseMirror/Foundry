use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn compute_hs_norm_sq(primes: &[f64], zeros: &[f64]) -> f64 {
    // A toy mock of the dense kernel computation
    let mut sum = 0.0;
    for (p, z) in primes.iter().zip(zeros.iter()) {
        sum += (p * z).sin().powi(2);
    }
    sum
}

#[wasm_bindgen]
pub fn kernel_version() -> String {
    "ZMT-WASM-v1.0 (Π₇ Interoperability)".to_string()
}
