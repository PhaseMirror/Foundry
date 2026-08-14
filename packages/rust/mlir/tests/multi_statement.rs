// tests/multi_statement.rs

use pirtm_mlir::pirtm::transpiler::visitor::MlirEmitterVisitor;
use pirtm_parser::parse;

#[test]
fn multi_statement_integration() {
    // Program with let binding, if expression, and a dummy function call
    let source = r#"
        let x = Ap(2);
        if (Ap(3)) {
            x + 1;
        } else {
            Ap(5);
        };
        dummy_func(x);
    "#;
    let prog = parse(source).expect("parse should succeed");
    let mut visitor = MlirEmitterVisitor::new();
    let mlir = visitor.emit_program(&prog).expect("emit should succeed");
    // Basic sanity checks
    assert!(mlir.contains("func @main"));
    // The let binding should emit an operator_atom for prime 2
    assert!(mlir.contains("pirtm.operator_atom"));
    assert!(mlir.contains("prime_index = 2"));
    // The dummy call currently emits a placeholder atom 0
    assert!(mlir.contains("prime_index = 0"));
}
