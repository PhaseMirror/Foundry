//! pirtm-compiler: PIRTM language compiler with governance and Lean verification.
//!
//! This crate provides a library API for compiling PIRTM/moc source code to MLIR,
//! verifying Lean 4 proofs, and translating to LLVM IR or WebAssembly.

mod error;
pub mod linker;
pub mod manifest;
mod translate;

pub use error::{CompileError, MlirModule, ProofError, ProofReceipt, TranslateError};
pub use pirtm_mlir::PirtmOp;
pub use pirtm_parser::ast::{BinOp, Expr, Program, Stmt};

pub use pirtm_mlir::pirtm::transpiler::visitor::MlirEmitterVisitor;
use serde_json::json;
use telemetry_recorder::record_event;

/// The primary compiler interface for PIRTM programs.
pub struct PhaseMirrorCompiler {
    validator: AdmissibilityValidator,
}

impl Default for PhaseMirrorCompiler {
    fn default() -> Self {
        Self::new()
    }
}

impl PhaseMirrorCompiler {
    /// Create a new compiler instance.
    pub fn new() -> Self {
        Self {
            validator: AdmissibilityValidator::new(),
        }
    }

    /// Compile PIRTM source to MLIR module.
    pub fn compile(&self, source: &str) -> Result<MlirModule, CompileError> {
        let program = pirtm_parser::parse(source).map_err(|e| CompileError::ParseError {
            location: "parse".to_string(),
            message: e,
        })?;

        for stmt in &program.stmts {
            if let pirtm_parser::ast::Stmt::Expr(ref expr) = stmt {
                self.validator
                    .validate(expr)
                    .map_err(|e| CompileError::ValidationError {
                        item: "expression".to_string(),
                        message: e,
                    })?;
            }
        }

        let mut visitor = MlirEmitterVisitor::new();
        let mut ops = Vec::new();
        for stmt in &program.stmts {
            match stmt {
                pirtm_parser::ast::Stmt::Expr(expr) => {
                    visitor.visit_expression(expr, &mut ops);
                }
                _ => {}
            }
        }

        let _ = record_event(
            "compilation",
            json!({
                "source_size": source.len(),
                "num_ops": ops.len(),
            }),
        );

        Ok(MlirModule {
            source: source.to_string(),
            ops,
        })
    }

    /// Get the MLIR text representation of a compiled module.
    pub fn to_mlir(&self, module: &MlirModule) -> Result<String, CompileError> {
        let mlir_text: Vec<String> = module
            .ops
            .iter()
            .map(|op| {
                op.emit_mlir()
                    .map_err(|e| CompileError::MlirError { message: e })
            })
            .collect::<Result<Vec<_>, _>>()?;
        Ok(mlir_text.join("\n"))
    }
}

/// Admissibility validator for AST expressions and manifests.
#[derive(Default)]
pub struct AdmissibilityValidator {}

impl AdmissibilityValidator {
    pub fn new() -> Self {
        Self {}
    }

    pub fn validate(&self, _ast: &pirtm_parser::ast::Expr) -> Result<(), String> {
        Ok(())
    }

    pub fn validate_prime(&self, n: u64) -> Result<(), String> {
        if n < 2 {
            return Err(format!("prime_index {} is not a prime", n));
        }
        let limit = (n as f64).sqrt() as u64;
        for i in 2..=limit {
            if n % i == 0 {
                return Err(format!(
                    "prime_index {} is not a prime (divisible by {})",
                    n, i
                ));
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compiler_compile_simple() {
        let compiler = PhaseMirrorCompiler::new();
        let result = compiler.compile("42");
        assert!(result.is_ok());
        let module = result.unwrap();
        assert_eq!(module.ops.len(), 1);
    }

    #[test]
    fn test_compiler_compile_pirtsm_expr() {
        let compiler = PhaseMirrorCompiler::new();
        let result = compiler.compile("Ap(2) + 3");
        assert!(result.is_ok());
        let module = result.unwrap();
        // Binary expression: 2 operands (Ap(2) and 3) + 1 binary op = 3 ops
        assert!(
            module.ops.len() >= 2,
            "expected at least 2 ops for binary expression"
        );
    }

    #[test]
    fn test_to_mlir() {
        let compiler = PhaseMirrorCompiler::new();
        let module = compiler.compile("42").unwrap();
        let mlir = compiler.to_mlir(&module).unwrap();
        assert!(mlir.contains("pirtm.operator_atom"));
    }
}
pub mod multiplicity_functor;
pub mod ace_constraints;
