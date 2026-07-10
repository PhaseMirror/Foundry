// src/pirtm/transpiler/visitor.rs

use crate::pirtm::dialect::ops::PirtmOp;
use num_rational::Rational64;
use pirtm_parser::ast::{BinOp, Expr, Program, Stmt};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy)]
pub enum MultiplicityError {
    Overflow,
    NonRational,
}

impl std::fmt::Display for MultiplicityError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MultiplicityError::Overflow => write!(f, "PM001: Multiplicity overflow"),
            MultiplicityError::NonRational => write!(f, "PM002: Non‑rational multiplicity"),
        }
    }
}

/// Compute p^m where `p` is a prime (u64) and `m` is a Rational64 exponent.
pub fn multiplicity_functor(p: u64, m: Rational64) -> Result<Rational64, MultiplicityError> {
    let numer = *m.numer();
    let denom = *m.denom();
    let p_num = (p as i128)
        .checked_pow(numer.abs() as u32)
        .ok_or(MultiplicityError::Overflow)?;
    let p_den = (p as i128)
        .checked_pow(denom.abs() as u32)
        .ok_or(MultiplicityError::Overflow)?;
    if numer < 0 && denom < 0 {
        Ok(Rational64::new(p_den as i64, p_num as i64))
    } else if numer < 0 {
        Ok(Rational64::new(1, (p_num * p_den) as i64))
    } else if denom < 0 {
        Ok(Rational64::new((p_num * p_den) as i64, 1))
    } else {
        Ok(Rational64::new(p_num as i64, p_den as i64))
    }
}

/// Visitor that walks the AST and emits MLIR operations.
pub struct MlirEmitterVisitor {
    /// Mapping from variable names to result identifiers.
    env: HashMap<String, String>,
    /// Counter for generating unique ids.
    counter: usize,
}

impl MlirEmitterVisitor {
    /// Create a new visitor.
    pub fn new() -> Self {
        Self {
            env: HashMap::new(),
            counter: 0,
        }
    }

    fn fresh_id(&mut self) -> String {
        let id = format!("tmp_{}", self.counter);
        self.counter += 1;
        id
    }

    /// Get the number of operations created.
    pub fn num_ops(&self) -> usize {
        self.counter
    }

    /// Emit a complete MLIR module for a whole program.
    pub fn emit_program(&mut self, program: &Program) -> Result<String, String> {
        let mut ops: Vec<PirtmOp> = Vec::new();
        for stmt in &program.stmts {
            self.visit_statement(stmt, &mut ops)?;
        }
        // Append a trivial return operation.
        let ret = PirtmOp::OperatorAtom {
            prime_index: 0,
            result_id: self.fresh_id(),
            receipt_hash: "ret".to_string(),
        };
        ops.push(ret);
        let body = ops
            .into_iter()
            .map(|op| op.emit_mlir().unwrap())
            .collect::<Vec<_>>()
            .join("\n");
        Ok(format!("func @main() {{\n{}\n}}", body))
    }

    fn visit_statement(&mut self, stmt: &Stmt, ops: &mut Vec<PirtmOp>) -> Result<(), String> {
        match stmt {
            Stmt::Ensemble(decl) => {
                ops.push(PirtmOp::Ensemble {
                    name: decl.name.clone(),
                    version: decl.version.clone(),
                    prime_index: decl.prime,
                    spectral_radius: 0.0, // Should be populated from manifest during validation
                    receipt_hash: "ensemble_decl".to_string(),
                });
                Ok(())
            }
            Stmt::Import(import_stmt) => {
                ops.push(PirtmOp::Import {
                    path: import_stmt.path.clone(),
                    alias: import_stmt.alias.clone(),
                    spectral_budget: import_stmt.spectral_budget,
                    receipt_hash: "import_stmt".to_string(),
                });
                Ok(())
            }
            Stmt::Let { name, expr } => {
                self.visit_expression(expr, ops);
                if let Some(op) = ops.last() {
                    let result_id = match op {
                        PirtmOp::OperatorAtom { result_id, .. } => result_id.clone(),
                        PirtmOp::BinaryOp { result_id, .. } => result_id.clone(),
                        PirtmOp::Sigmoid { result_id, .. } => result_id.clone(),
                        _ => "unknown".to_string(),
                    };
                    self.env.insert(name.clone(), result_id);
                }
                Ok(())
            }
            Stmt::Expr(expr) => {
                self.visit_expression(expr, ops);
                Ok(())
            }
            Stmt::Block(stmts) => {
                for s in stmts {
                    self.visit_statement(s, ops)?;
                }
                Ok(())
            }
        }
    }

    /// Translate an expression into PirtmOps, pushing to ops vector.
    pub fn visit_expression(&mut self, expr: &Expr, ops: &mut Vec<PirtmOp>) {
        match expr {
            Expr::Literal(val) => {
                ops.push(PirtmOp::OperatorAtom {
                    prime_index: *val as u64,
                    result_id: self.fresh_id(),
                    receipt_hash: "lit".to_string(),
                });
            }
            Expr::Atom { prime } => {
                ops.push(PirtmOp::OperatorAtom {
                    prime_index: *prime,
                    result_id: self.fresh_id(),
                    receipt_hash: "atom".to_string(),
                });
            }
            Expr::Ident(name) => {
                let id = self
                    .env
                    .get(name)
                    .cloned()
                    .unwrap_or_else(|| self.fresh_id());
                ops.push(PirtmOp::OperatorAtom {
                    prime_index: 2,
                    result_id: id,
                    receipt_hash: "ident".to_string(),
                });
            }
            Expr::Binary { op, left, right } => {
                // Push left and right operands first
                self.visit_expression(left, ops);
                let left_id = self.fresh_id();
                self.visit_expression(right, ops);
                let right_id = self.fresh_id();
                let op_kind = match op {
                    BinOp::Add => "add",
                    BinOp::Sub => "sub",
                };
                let result_id = self.fresh_id();
                ops.push(PirtmOp::BinaryOp {
                    op_kind: op_kind.to_string(),
                    left_id,
                    right_id,
                    result_id,
                    receipt_hash: "bin".to_string(),
                });
            }
            Expr::Call { name, args } => {
                if name == "sigmoid" && !args.is_empty() {
                    self.visit_expression(&args[0], ops);
                    let operand_id = ops
                        .last()
                        .map(|op| match op {
                            PirtmOp::OperatorAtom { result_id, .. } => result_id.clone(),
                            PirtmOp::BinaryOp { result_id, .. } => result_id.clone(),
                            _ => "unknown".to_string(),
                        })
                        .unwrap_or_else(|| self.fresh_id());
                    ops.push(PirtmOp::Sigmoid {
                        operand_id,
                        result_id: self.fresh_id(),
                        receipt_hash: "sigmoid".to_string(),
                    });
                } else {
                    ops.push(PirtmOp::OperatorAtom {
                        prime_index: 0,
                        result_id: self.fresh_id(),
                        receipt_hash: "call".to_string(),
                    });
                }
            }
            Expr::If {
                cond,
                then_branch,
                else_branch,
            } => {
                self.visit_expression(cond, ops);
                for stmt in then_branch {
                    let _ = self.visit_statement(stmt, ops);
                }
                if let Some(else_stmts) = else_branch {
                    for stmt in else_stmts {
                        let _ = self.visit_statement(stmt, ops);
                    }
                }
                ops.push(PirtmOp::OperatorAtom {
                    prime_index: 0,
                    result_id: self.fresh_id(),
                    receipt_hash: "if".to_string(),
                });
            }
            Expr::Successor(inner) => self.visit_expression(inner, ops),
            Expr::StratumBoundary(inner) => self.visit_expression(inner, ops),
            Expr::PrimeShift(inner) => self.visit_expression(inner, ops),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use pirtm_parser::ast::{BinOp, Expr, Program, Stmt};

    #[test]
    fn visit_integer() {
        let mut v = MlirEmitterVisitor::new();
        let mut ops = Vec::new();
        v.visit_expression(&Expr::Literal(7), &mut ops);
        let op = &ops[0];
        if let PirtmOp::OperatorAtom { prime_index, .. } = op {
            assert_eq!(*prime_index, 7);
        } else {
            panic!("Expected OperatorAtom");
        }
    }

    #[test]
    fn visit_binary_add() {
        let mut v = MlirEmitterVisitor::new();
        let mut ops = Vec::new();
        let expr = Expr::Binary {
            op: BinOp::Add,
            left: Box::new(Expr::Literal(3)),
            right: Box::new(Expr::Literal(5)),
        };
        v.visit_expression(&expr, &mut ops);
        // Should have two literals and one binary op
        assert!(ops.len() == 3, "expected 3 ops (2 literals + 1 binary)");
        // Last op should be the binary
        match &ops[2] {
            PirtmOp::BinaryOp { op_kind, .. } => assert_eq!(op_kind, "add"),
            _ => panic!("Expected BinaryOp"),
        }
    }

    #[test]
    fn emit_program_simple() {
        let prog = Program {
            stmts: vec![Stmt::Expr(Expr::Literal(42))],
        };
        let mut visitor = MlirEmitterVisitor::new();
        let mlir = visitor.emit_program(&prog).expect("emit should succeed");
        assert!(mlir.contains("func @main"));
        assert!(mlir.contains("pirtm.operator_atom"));
        assert!(mlir.contains("prime_index = 42"));
    }
}
