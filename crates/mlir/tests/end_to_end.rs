// tests/end_to_end.rs

//! End‑to‑end pipeline tests for the MLIR emitter.
//! Refactored to use the test_helpers module for DRY testing.

use pirtm_mlir::test_helpers::{count_pattern, maybe_check_governor, run_pipeline};

// Test 1: basic sigmoid pipeline
#[test]
fn test_e2e_basic_sigmoid_pipeline() {
    let result = run_pipeline("Ap(2)");
    assert!(result.mlir.contains("pirtm"));
    assert!(result.mlir.contains("func @main"));
}

// Test 2: complex expression with binaries and sigmoid
#[test]
fn test_e2e_complex_expression_with_binaries_and_sigmoid() {
    let source = r#"
        let a = Ap(3);
        let b = Ap(5);
        a + b
    "#;
    let result = run_pipeline(source);
    assert!(result.mlir.contains("pirtm.operator_atom"));
    assert!(
        result.mlir.contains("op_kind = \"add\""),
        "missing binary add"
    );
    assert!(result.mlir.contains("func @main"));
}

// Test 3: large expression tree
#[test]
fn test_e2e_large_expression_tree() {
    let source = r#"
        let a = Ap(1);
        let b = a + Ap(2);
        let c = b + Ap(3);
        let d = sigmoid(c);
        let e = d + Ap(4);
        sigmoid(e)
    "#;
    let result = run_pipeline(source);
    assert!(
        count_pattern(&result.mlir, "pirtm.binary_") >= 3,
        "not enough binary ops"
    );
    assert!(
        count_pattern(&result.mlir, "pirtm.sigmoid") >= 2,
        "expected at least two sigmoids"
    );
    assert!(result.mlir.contains("func @main"));
}

// Test 4: contractivity verification via SpectralGovernor
#[test]
fn test_e2e_contractivity_check() {
    let report = maybe_check_governor().expect("governor check failed");
    assert!(
        report.contraction_feasible,
        "sigmoid operator should be contractive"
    );
    assert!(
        report.spectral_radius < 1.0,
        "spectral radius should be < 1 for contractive system"
    );
}

// Test 5: edge cases with sigmoid
#[test]
fn test_e2e_sigmoid_edge_cases() {
    let result = run_pipeline("sigmoid(Ap(0))");
    assert!(result.mlir.contains("pirtm.sigmoid"));
}

// Test 6: error path - multiple expressions
#[test]
fn test_e2e_multiple_expressions() {
    let source = r#"
        Ap(10)
        Ap(20)
    "#;
    let result = run_pipeline(source);
    assert!(result.mlir.contains("pirtm.operator_atom"));
    assert!(result.mlir.contains("func @main"));
}

// Test 7: binary operation chain
#[test]
fn test_e2e_binary_chain() {
    let result = run_pipeline("Ap(1) + Ap(2) + Ap(3)");
    assert!(
        result.mlir.contains("op_kind = \"add\""),
        "missing binary add"
    );
    assert!(result.mlir.contains("func @main"));
}

pirtm_mlir::e2e_test!(
    test_e2e_multi_ensemble_scenario,
    r#"
        ensemble mainApp v1 prime=2;
        use coreTensorOps;
        let res = Ap(2) + 5;
    "#,
    [
        "pirtm.ensemble { name = \"mainApp\"",
        "pirtm.import { path = \"coreTensorOps\"",
        "spectral_budget = \"none\"",
        "pirtm.binary_op"
    ]
);
