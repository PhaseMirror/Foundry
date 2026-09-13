//! Mirror of `core/scripts/verify_transpiler.py` — runs the natural-language
//! test vectors through the transpiler and asserts the extracted attributes.
//!
//! The Python drove the transpiler via a subprocess; this integration test
//! drives the in-process `PirtmTranspiler` (equivalent by construction).

use core_transpiler::{extract_attributes, PirtmTranspiler};

fn transpile_and_extract(nl_input: &str) -> (core_transpiler::ExtractedAttributes, String) {
    let mut transpiler = PirtmTranspiler::new();
    transpiler.parse_nl(nl_input);
    let mlir = transpiler.emit_mlir("generated_module");
    (extract_attributes(&mlir), mlir)
}

#[test]
fn official_test_vectors_pass() {
    let vectors: Vec<(&str, Vec<(&str, f64)>)> = vec![
        (
            "guarantee convergence with a 10% margin",
            vec![("epsilon", 0.10)],
        ),
        (
            "spectral radius < 0.92 and 5% stability margin",
            vec![("q_target", 0.92), ("epsilon", 0.05)],
        ),
        (
            "Ensure ε = 0.07 for p = 13",
            vec![("epsilon", 0.07), ("mod", 13.0)],
        ),
        (
            "operator norm of 0.4 with contraction coefficient of 0.88",
            vec![("op_norm_t", 0.4), ("q_target", 0.88)],
        ),
        (
            "nonlinear gain of 0.6 and 15% margin for prime index 19",
            vec![("op_norm_t", 0.6), ("epsilon", 0.15), ("mod", 19.0)],
        ),
    ];

    for (input, expected) in vectors {
        let (attrs, _mlir) = transpile_and_extract(input);
        for (key, expected_value) in expected {
            let actual = match key {
                "epsilon" => attrs.epsilon,
                "q_target" => attrs.q_target,
                "op_norm_t" => attrs.op_norm_t,
                "mod" => attrs.modulus.map(|m| m as f64),
                _ => unreachable!(),
            };
            assert!(
                actual.is_some() && (actual.unwrap() - expected_value).abs() < 1e-9,
                "FAILED: {key} expected {expected_value}, got {actual:?} for {input:?}"
            );
        }
    }
}
