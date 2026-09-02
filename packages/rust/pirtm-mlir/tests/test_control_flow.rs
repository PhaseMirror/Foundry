use pirtm_parser::parse;
use pirtm_mlir::pirtm::transpiler::visitor::MlirEmitterVisitor;

#[test]
fn test_parse_and_lower_while_loop_with_fn() {
    let source = r#"
fn compute_sum(n: i64) -> i64 {
    let mut sum = 0;
    let mut i = 1;
    while i <= n {
        sum = sum + i;
        i = i + 1;
    }
    return sum;
}

let total = compute_sum(10);
"#;

    let program = parse(source).expect("Failed to parse while loop program");
    assert_eq!(program.stmts.len(), 2);

    let mut visitor = MlirEmitterVisitor::new();
    let mlir_code = visitor.emit_program(&program).expect("Failed to emit MLIR");

    assert!(mlir_code.contains("func.func @compute_sum"));
    assert!(mlir_code.contains("scf.while"));
    assert!(mlir_code.contains("llvm.alloca"));
    assert!(mlir_code.contains("llvm.store"));
    assert!(mlir_code.contains("llvm.load"));
    assert!(mlir_code.contains("func.call @compute_sum"));
}

#[test]
fn test_parse_and_lower_if_else() {
    let source = r#"
fn check_parity(n: i64) -> i64 {
    let mut flag = 0;
    if n > 0 {
        flag = 1;
    } else {
        flag = 0;
    }
    return flag;
}
"#;

    let program = parse(source).expect("Failed to parse if-else program");
    let mut visitor = MlirEmitterVisitor::new();
    let mlir_code = visitor.emit_program(&program).expect("Failed to emit MLIR");

    assert!(mlir_code.contains("func.func @check_parity"));
    assert!(mlir_code.contains("scf.if"));
}
