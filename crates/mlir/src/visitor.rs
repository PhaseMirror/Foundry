// crates/pirtm-mlir/src/visitor.rs
use crate::ops::{PirtmOp, SsaBlock, FuncOp, ModuleOp};
use pirtm_parser::ast::{Program, Stmt, Expr, BinOp};
use std::collections::HashMap;

/// Type alias for the Lean Proof FFI hook.
pub type LeanProofFFI = Box<dyn Fn(u64) -> Result<pirtm_parser::ast::ContractivityReceipt, String>>;

pub struct MlirEmitterVisitor {
    lean_proof_ffi: LeanProofFFI,
    ssa_counter: usize,
    env: HashMap<String, String>,
}

impl MlirEmitterVisitor {
    pub fn new(lean_proof_ffi: LeanProofFFI) -> Self {
        Self {
            lean_proof_ffi,
            ssa_counter: 0,
            env: HashMap::new(),
        }
    }

    fn fresh_id(&mut self) -> String {
        let id = format!("v{}", self.ssa_counter);
        self.ssa_counter += 1;
        id
    }

    pub fn visit_program(&mut self, prog: &Program) -> ModuleOp {
        let mut block = SsaBlock::new();
        let mut last_val = None;

        for stmt in prog {
            last_val = Some(self.visit_stmt(stmt, &mut block));
        }

        // Default yield if block is not empty
        if let Some(val_id) = last_val {
            block.ops.push(PirtmOp::Yield { value_id: val_id });
        }

        let func = FuncOp {
            name: "main".to_string(),
            region: block,
        };

        ModuleOp {
            funcs: vec![func],
        }
    }

    pub fn visit_stmt(&mut self, stmt: &Stmt, block: &mut SsaBlock) -> String {
        match stmt {
            Stmt::Expr { expr, receipt: _ } => {
                self.visit_expr(expr, block)
            }
            Stmt::Let { name, value, receipt: _ } => {
                let val_id = self.visit_expr(value, block);
                self.env.insert(name.clone(), val_id.clone());
                val_id
            }
            Stmt::Block { stmts, receipt: _ } => {
                let mut last_val = self.fresh_id(); // fallback
                // For simplicity, we inline blocks. Proper MLIR would use scf.execute_region.
                for s in stmts {
                    last_val = self.visit_stmt(s, block);
                }
                last_val
            }
        }
    }

    pub fn visit_expr(&mut self, expr: &Expr, block: &mut SsaBlock) -> String {
        match expr {
            Expr::Literal(v) => {
                let result_id = self.fresh_id();
                block.ops.push(PirtmOp::Constant {
                    value: *v as i64,
                    result_id: result_id.clone(),
                });
                result_id
            }
            Expr::Ident(name) => {
                self.env.get(name).cloned().unwrap_or_else(|| {
                    // Resolve external identifiers if needed
                    let id = self.fresh_id();
                    id
                })
            }
            Expr::Atom { prime_index, receipt } => {
                let result_id = self.fresh_id();
                block.ops.push(PirtmOp::OperatorAtom {
                    prime_index: *prime_index,
                    result_id: result_id.clone(),
                    receipt_hash: receipt.hash.clone(),
                });
                result_id
            }
            Expr::Binary { op, left, right, receipt } => {
                let left_id = self.visit_expr(left, block);
                let right_id = self.visit_expr(right, block);
                let result_id = self.fresh_id();
                
                let op_kind = match op {
                    BinOp::Add => "add",
                    BinOp::Sub => "sub",
                    BinOp::Mul => "mul",
                    BinOp::Div => "div",
                }.to_string();

                block.ops.push(PirtmOp::BinaryOp {
                    op_kind,
                    left_id,
                    right_id,
                    result_id: result_id.clone(),
                    receipt_hash: receipt.hash.clone(),
                });
                result_id
            }
        }
    }
}
