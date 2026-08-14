use pirtm_parser::ast::{Expr, BinOp};

#[test]
fn test_transcendental_ast_nodes_can_be_constructed() {
    let sin_node = Expr::Sin(Box::new(Expr::Literal(1)));
    let cos_node = Expr::Cos(Box::new(Expr::Literal(1)));
    let log_node = Expr::Log(Box::new(Expr::Literal(1)));

    assert!(matches!(sin_node, Expr::Sin(_)));
    assert!(matches!(cos_node, Expr::Cos(_)));
    assert!(matches!(log_node, Expr::Log(_)));
}

#[test]
fn test_transcendental_contractivity_lean_file_exists() {
    // Validate that the contractivity proofs file is deployed in the correct location
    let lean_file = std::path::Path::new("../../crates/pirtm-stdlib/Lean/TranscendentalContractivity.lean");
    
    // As tests can be run from different working directories:
    let alt_lean_file1 = std::path::Path::new("crates/pirtm-stdlib/Lean/TranscendentalContractivity.lean");
    let alt_lean_file2 = std::path::Path::new("../pirtm-stdlib/Lean/TranscendentalContractivity.lean");

    assert!(
        lean_file.exists() || alt_lean_file1.exists() || alt_lean_file2.exists(),
        "TranscendentalContractivity.lean must exist to formally certify contractivity bounds"
    );
}
