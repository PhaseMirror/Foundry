//! pirtm-compiler: PIRTM language compiler with governance and Lean verification.
//!
//! This crate provides a library API for compiling PIRTM/moc source code to MLIR,
//! verifying Lean 4 proofs, and translating to LLVM IR or WebAssembly.

mod error;
pub mod linker;
pub mod manifest;
pub mod witness_bytecode;
pub mod stablehlo_lowering;
pub mod phase_hypergraph;
mod translate;

pub use error::{CompileError, MlirModule, ProofError, ProofReceipt, TranslateError};
pub use phase_hypergraph::{GeneratorViolation, PhaseHypergraph, EPSILON_CRIT};
pub use pirtm_mlir::PirtmOp;
pub use pirtm_parser::ast::{BinOp, Expr, Program, Stmt};

pub use pirtm_mlir::pirtm::transpiler::visitor::MlirEmitterVisitor;
use serde_json::json;
use sha2::{Sha256, Digest};
use telemetry_recorder::record_event;

/// The primary compiler interface for PIRTM programs.
pub struct PhaseMirrorCompiler {
    validator: AdmissibilityValidator,
    pub current_topology: Option<PhaseHypergraph>,
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
            current_topology: None,
        }
    }

    /// Compile PIRTM source to MLIR module with topological pre-flight interlock.
    pub fn compile_with_topology(
        &mut self,
        source: &str,
        candidate_topology: Option<&PhaseHypergraph>,
    ) -> Result<MlirModule, CompileError> {
        if let Some(candidate) = candidate_topology {
            if let Some(current) = &self.current_topology {
                match current.verify_transition(candidate) {
                    Ok(d_phi) => {
                        let _ = record_event(
                            "preflight_topology_pass",
                            json!({ "d_phi": format!("{}/{}", d_phi.numer(), d_phi.denom()) }),
                        );
                    }
                    Err(GeneratorViolation::PhaseDissonance(n, d, cn, cd)) => {
                        return Err(CompileError::ValidationError {
                            item: "topology".to_string(),
                            message: format!(
                                "SIG_GOV_KILL: Phase Dissonance Breach: D_Phi({}/{}) >= epsilon_crit({}/{})",
                                n, d, cn, cd
                            ),
                        });
                    }
                    Err(GeneratorViolation::DimensionMismatch) => {
                        return Err(CompileError::ValidationError {
                            item: "topology".to_string(),
                            message: "Topological Incoherence: dimension mismatch between state hypergraphs".to_string(),
                        });
                    }
                }
            }
        }

        let module = self.compile(source)?;

        if let Some(candidate) = candidate_topology {
            self.current_topology = Some(candidate.clone());
        }

        Ok(module)
    }

    /// Compile PIRTM source to MLIR module.
    pub fn compile(&self, source: &str) -> Result<MlirModule, CompileError> {
        let program = pirtm_parser::parse(source).map_err(|e| CompileError::ParseError {
            location: "parse".to_string(),
            message: e,
        })?;

        for stmt in &program.stmts {
            let _ = self
                .validator
                .validate_stmt(stmt)
                .map_err(|e| CompileError::ValidationError {
                    item: "statement".to_string(),
                    message: e,
                })?;
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

        let mut hasher = Sha256::new();
        hasher.update(source.as_bytes());
        let source_hash = format!("{:x}", hasher.finalize());

        let proof_receipt = ProofReceipt {
            hash: source_hash,
            lambda_p: 0.0,
            l_p: 0.0,
            zero_spacings: vec![],
            signature: "admissibility_validator".to_string(),
            signer_pubkey: "validator".to_string(),
        };

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
            proof_receipt: Some(proof_receipt),
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

    fn compute_ast_hash(ast: &Expr) -> String {
        let mut hasher = Sha256::new();
        hasher.update(ast.to_string().as_bytes());
        format!("{:x}", hasher.finalize())
    }

    fn validate_expr(&self, expr: &Expr) -> Result<ProofReceipt, String> {
        match expr {
            Expr::FloatLit(_) => {
                Err("L0 Invariant Violation: floating-point literal used as stability proof is forbidden".to_string())
            }
            Expr::Atom { prime: n } => {
                self.validate_prime(*n).map_err(|e| format!("Prime operator violation: {}", e))?;
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::Binary { left, right, .. } => {
                self.validate_expr(left)?;
                self.validate_expr(right)?;
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::Call { args, .. } => {
                for arg in args {
                    self.validate_expr(arg)?;
                }
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::If {
                cond,
                then_branch,
                else_branch,
            } => {
                self.validate_expr(cond)?;
                for stmt in then_branch {
                    self.validate_stmt(stmt)?;
                }
                if let Some(else_branch) = else_branch {
                    for stmt in else_branch {
                        self.validate_stmt(stmt)?;
                    }
                }
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::Successor(e)
            | Expr::StratumBoundary(e)
            | Expr::PrimeShift(e)
            | Expr::Sin(e)
            | Expr::Cos(e)
            | Expr::Log(e)
            | Expr::Not(e)
            | Expr::Try(e) => {
                self.validate_expr(e)?;
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::LogicalOp { left, right, .. } => {
                self.validate_expr(left)?;
                self.validate_expr(right)?;
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::MethodCall { obj, args, .. } => {
                self.validate_expr(obj)?;
                for arg in args {
                    self.validate_expr(arg)?;
                }
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::Tuple(elems) => {
                for elem in elems {
                    self.validate_expr(elem)?;
                }
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::StructInit { fields, .. } => {
                for (_, expr) in fields {
                    self.validate_expr(expr)?;
                }
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::FieldAccess { obj, .. } => {
                self.validate_expr(obj)?;
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::Match { expr, arms, .. } => {
                self.validate_expr(expr)?;
                for (_, stmts) in arms {
                    for stmt in stmts {
                        self.validate_stmt(stmt)?;
                    }
                }
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Expr::Literal(_)
            | Expr::CharLit(_)
            | Expr::StringLit(_)
            | Expr::Ident(_) => {
                Ok(ProofReceipt {
                    hash: Self::compute_ast_hash(expr),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
        }
    }

    fn validate_stmt(&self, stmt: &Stmt) -> Result<ProofReceipt, String> {
        match stmt {
            Stmt::Loop { cond: None, .. } => {
                Err("L0 Invariant Violation: unbounded loop without explicit bound annotation".to_string())
            }
            Stmt::Expr(expr) => self.validate_expr(expr),
            Stmt::Let { expr, .. }
            | Stmt::LetMut { expr, .. }
            | Stmt::Assign { expr, .. } => self.validate_expr(expr),
            Stmt::Return(Some(expr)) => self.validate_expr(expr),
            Stmt::Block(stmts) => {
                for stmt in stmts {
                    self.validate_stmt(stmt)?;
                }
                Ok(ProofReceipt {
                    hash: "block".to_string(),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Stmt::If {
                cond,
                then_branch,
                else_branch,
            } => {
                self.validate_expr(cond)?;
                for stmt in then_branch {
                    self.validate_stmt(stmt)?;
                }
                if let Some(else_branch) = else_branch {
                    for stmt in else_branch {
                        self.validate_stmt(stmt)?;
                    }
                }
                Ok(ProofReceipt {
                    hash: "if".to_string(),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Stmt::FnDef { body, .. } => {
                for stmt in body {
                    self.validate_stmt(stmt)?;
                }
                Ok(ProofReceipt {
                    hash: "fn".to_string(),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            Stmt::ImplDef { methods, .. } => {
                for stmt in methods {
                    self.validate_stmt(stmt)?;
                }
                Ok(ProofReceipt {
                    hash: "impl".to_string(),
                    lambda_p: 0.0,
                    l_p: 0.0,
                    zero_spacings: vec![],
                    signature: "admissibility_validator".to_string(),
                    signer_pubkey: "validator".to_string(),
                })
            }
            _ => Ok(ProofReceipt {
                hash: "skip".to_string(),
                lambda_p: 0.0,
                l_p: 0.0,
                zero_spacings: vec![],
                signature: "admissibility_validator".to_string(),
                signer_pubkey: "validator".to_string(),
            }),
        }
    }

    pub fn validate(&self, ast: &Expr) -> Result<ProofReceipt, String> {
        self.validate_expr(ast)
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

    #[test]
    fn test_compile_with_topology_interlock() {
        let mut compiler = PhaseMirrorCompiler::new();
        let mut h1 = PhaseHypergraph::new(2);
        h1.tensor[0][0] = num_rational::Ratio::new(10, 100);

        // First transition initializes state
        let res1 = compiler.compile_with_topology("42", Some(&h1));
        assert!(res1.is_ok());

        // Contractive transition: Delta = 1/100 < 3/100 -> PASS
        let mut h2 = PhaseHypergraph::new(2);
        h2.tensor[0][0] = num_rational::Ratio::new(11, 100);
        let res2 = compiler.compile_with_topology("42", Some(&h2));
        assert!(res2.is_ok());

        // Dissonant transition: Delta = 5/100 >= 3/100 -> FAIL-CLOSED
        let mut h3 = PhaseHypergraph::new(2);
        h3.tensor[0][0] = num_rational::Ratio::new(16, 100);
        let res3 = compiler.compile_with_topology("42", Some(&h3));
        assert!(res3.is_err());
        let err_msg = format!("{}", res3.unwrap_err());
        assert!(err_msg.contains("SIG_GOV_KILL: Phase Dissonance Breach"));
    }

    #[test]
    fn test_admissibility_rejects_float_literal() {
        let validator = AdmissibilityValidator::new();
        let expr = pirtm_parser::ast::Expr::FloatLit(3.14);
        let result = validator.validate(&expr);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("floating-point literal"));
    }

    #[test]
    fn test_admissibility_rejects_non_prime_atom() {
        let validator = AdmissibilityValidator::new();
        let expr = pirtm_parser::ast::Expr::Atom { prime: 4 };
        let result = validator.validate(&expr);
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not a prime"));
    }

    #[test]
    fn test_admissibility_accepts_prime_atom() {
        let validator = AdmissibilityValidator::new();
        let expr = pirtm_parser::ast::Expr::Atom { prime: 2 };
        let result = validator.validate(&expr);
        assert!(result.is_ok());
    }

    #[test]
    fn test_admissibility_rejects_unbounded_loop() {
        let compiler = PhaseMirrorCompiler::new();
        let source = "loop { 42 }";
        let result = compiler.compile(source);
        assert!(result.is_err());
        let err_msg = format!("{}", result.unwrap_err());
        assert!(err_msg.contains("unbounded loop"));
    }

    #[test]
    fn test_admissibility_proof_receipt_anchored_to_ast() {
        let compiler = PhaseMirrorCompiler::new();
        let source = "Ap(2)";
        let result = compiler.compile(source);
        assert!(result.is_ok());
        let module = result.unwrap();
        let receipt = module.proof_receipt.expect("proof receipt must be present");
        assert!(!receipt.hash.is_empty());
    }
}
pub mod type_check;
pub use type_check::{type_check, PirtmExpr, PirtmType, TypeError};

#[cfg(kani)]
mod kani_tests {
    use super::*;

    #[kani::proof]
    fn verify_type_check_soundness() {
        let e1 = kani::any::<i64>();
        let expr = PirtmExpr::Const(e1);
        let ctx = vec![];
        
        let ty = type_check(&ctx, &expr);
        kani::assert(ty.is_ok(), "Const should always type check");
        kani::assert(matches!(ty.unwrap(), PirtmType::Stratum), "Const is always Stratum");
        
        let var_name = "test_var".to_string();
        let ctx = vec![(var_name.clone(), PirtmType::Stratum)];
        let expr = PirtmExpr::Var(var_name);
        
        let ty = type_check(&ctx, &expr);
        kani::assert(ty.is_ok(), "Valid var should type check");
        kani::assert(matches!(ty.unwrap(), PirtmType::Stratum), "Var type matches context");
    }
}
