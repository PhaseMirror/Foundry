// crates/pirtm-mlir/src/lib.rs

pub mod pirtm {
    pub mod dialect;
    pub mod transpiler;
}

pub mod test_helpers;

/// Helper to lower a single expression.
pub fn lower_expr(expr: &pirtm_parser::ast::Expr) -> Vec<pirtm::dialect::ops::PirtmOp> {
    let mut visitor = pirtm::transpiler::visitor::MlirEmitterVisitor::new();
    let mut ops = Vec::new();
    visitor.visit_expression(expr, &mut ops);
    ops
}

/// Helper to lower an entire program to MLIR.
pub fn lower_program(program: &pirtm_parser::ast::Program) -> Result<String, String> {
    let mut visitor = pirtm::transpiler::visitor::MlirEmitterVisitor::new();
    visitor.emit_program(program)
}

// Re‑export for convenience
pub use pirtm::dialect::ops::PirtmOp;
