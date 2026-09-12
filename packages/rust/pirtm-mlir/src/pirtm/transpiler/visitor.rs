// crates/pirtm-mlir/src/pirtm/transpiler/visitor.rs

use crate::pirtm::dialect::ops::PirtmOp;
use num_rational::Rational64;
use pirtm_parser::ast::{BinOp, Expr, Program, Stmt, Type};
use std::collections::HashMap;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
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

#[derive(Clone, Debug, PartialEq)]
pub enum VarInfo {
    /// Immutable variable: holds an SSA value id.
    Ssa(String),
    /// Mutable variable: holds a pointer to the allocated stack slot.
    Ptr(String),
}

/// Visitor that walks the AST and emits MLIR operations.
pub struct MlirEmitterVisitor {
    ssa_counter: usize,
    env: HashMap<String, VarInfo>,
}

impl Default for MlirEmitterVisitor {
    fn default() -> Self {
        Self::new()
    }
}

impl MlirEmitterVisitor {
    pub fn new() -> Self {
        Self {
            ssa_counter: 0,
            env: HashMap::new(),
        }
    }

    pub fn fresh_id(&mut self) -> String {
        let id = format!("v{}", self.ssa_counter);
        self.ssa_counter += 1;
        id
    }

    pub fn resolve_type_to_llvm(&self, ty: &Type) -> String {
        match ty {
            Type::Simple(name) => match name.as_str() {
                "int" | "i64" => "i64".to_string(),
                "i32" => "i32".to_string(),
                "f64" | "float" => "f64".to_string(),
                "bool" | "unit" => "i1".to_string(),
                "str" | "String" => "!llvm.ptr".to_string(),
                _ => format!("llvm.struct_{}", name),
            },
            Type::Generic(name, params) => {
                let resolved_params: Vec<String> = params.iter()
                    .map(|p| self.resolve_type_to_llvm(p).replace("llvm.struct_", ""))
                    .collect();
                let suffix = format!("{}_{}", name, resolved_params.join("_"));
                format!("llvm.struct_{}", suffix)
            }
            Type::Function(_, _) => "!llvm.ptr".to_string(),
            Type::Tuple(elems) => {
                let resolved: Vec<String> = elems.iter().map(|t| self.resolve_type_to_llvm(t)).collect();
                format!("llvm.struct<{}>", resolved.join(", "))
            }
            Type::Reference { .. } => "!llvm.ptr".to_string(),
        }
    }

    /// Get the number of operations created.
    pub fn num_ops(&self) -> usize {
        self.ssa_counter
    }

    fn extract_last_op_id(&mut self, ops: &[PirtmOp]) -> String {
        ops.last().map(|op| match op {
            PirtmOp::OperatorAtom { result_id, .. } => result_id.clone(),
            PirtmOp::BinaryOp { result_id, .. } => result_id.clone(),
            PirtmOp::Constant { result_id, .. } => result_id.clone(),
            PirtmOp::FloatConstant { result_id, .. } => result_id.clone(),
            PirtmOp::StringConstant { result_id, .. } => result_id.clone(),
            PirtmOp::CharConstant { result_id, .. } => result_id.clone(),
            PirtmOp::BoolConstant { result_id, .. } => result_id.clone(),
            PirtmOp::Sigmoid { result_id, .. } => result_id.clone(),
            PirtmOp::MethodCall { result_id, .. } => result_id.clone(),
            PirtmOp::LogicalOp { result_id, .. } => result_id.clone(),
            PirtmOp::Tuple { result_id, .. } => result_id.clone(),
            PirtmOp::Load { result_id, .. } => result_id.clone(),
            PirtmOp::Alloca { result_id, .. } => result_id.clone(),
            PirtmOp::Not { result_id, .. } => result_id.clone(),
            _ => "v_unknown".to_string(),
        }).unwrap_or_else(|| self.fresh_id())
    }

    /// Emit a complete MLIR module for a whole program.
    pub fn emit_program(&mut self, program: &Program) -> Result<String, String> {
        let mut ops: Vec<PirtmOp> = Vec::new();
        for stmt in &program.stmts {
            self.visit_statement(stmt, &mut ops)?;
        }
        
        let body = ops
            .into_iter()
            .map(|op| op.emit_mlir().unwrap_or_else(|e| format!("// MLIR Error: {}", e)))
            .collect::<Vec<_>>()
            .join("\n");
            
        Ok(body)
    }

    pub fn visit_statement(&mut self, stmt: &Stmt, ops: &mut Vec<PirtmOp>) -> Result<(), String> {
        match stmt {
            Stmt::Ensemble(decl) => {
                ops.push(PirtmOp::Ensemble {
                    name: decl.name.clone(),
                    version: decl.version.clone(),
                    prime_index: decl.prime,
                    spectral_radius: 0.0,
                    receipt_hash: "ensemble_decl".to_string(),
                });
                Ok(())
            }
            Stmt::Import(import_stmt) => {
                ops.push(PirtmOp::Import {
                    path: import_stmt.path.clone(),
                    alias: import_stmt.alias.clone(),
                    spectral_budget: import_stmt.spectral_budget.unwrap_or(0.0),
                    receipt_hash: "import_stmt".to_string(),
                });
                Ok(())
            }
            Stmt::Let { name, expr } => {
                self.visit_expression(expr, ops);
                let result_id = self.extract_last_op_id(ops);
                self.env.insert(name.clone(), VarInfo::Ssa(result_id));
                Ok(())
            }
            Stmt::LetMut { name, expr } => {
                self.visit_expression(expr, ops);
                let init_id = self.extract_last_op_id(ops);
                let ptr_id = self.fresh_id();
                ops.push(PirtmOp::Alloca { typ: "i64".to_string(), result_id: ptr_id.clone() });
                ops.push(PirtmOp::Store { ptr_id: ptr_id.clone(), val_id: init_id });
                self.env.insert(name.clone(), VarInfo::Ptr(ptr_id));
                Ok(())
            }
            Stmt::Assign { name, expr } => {
                let var_info = self.env.get(name).cloned();
                match var_info {
                    Some(VarInfo::Ptr(ptr_id)) => {
                        self.visit_expression(expr, ops);
                        let val_id = self.extract_last_op_id(ops);
                        ops.push(PirtmOp::Store { ptr_id, val_id });
                        Ok(())
                    }
                    Some(VarInfo::Ssa(_)) => {
                        Err(format!("Cannot assign to immutable variable '{}'", name))
                    }
                    None => {
                        let ptr_id = self.fresh_id();
                        ops.push(PirtmOp::Alloca { typ: "i64".to_string(), result_id: ptr_id.clone() });
                        self.visit_expression(expr, ops);
                        let val_id = self.extract_last_op_id(ops);
                        ops.push(PirtmOp::Store { ptr_id: ptr_id.clone(), val_id });
                        self.env.insert(name.clone(), VarInfo::Ptr(ptr_id));
                        Ok(())
                    }
                }
            }
            Stmt::Expr(expr) => {
                self.visit_expression(expr, ops);
                Ok(())
            }
            Stmt::Return(expr_opt) => {
                let mut ret_op = None;
                if let Some(expr) = expr_opt {
                    self.visit_expression(expr, ops);
                    ret_op = ops.pop().map(Box::new);
                }
                ops.push(PirtmOp::Return { value: ret_op });
                Ok(())
            }
            Stmt::Break => {
                ops.push(PirtmOp::Yield { value_id: "break".to_string() });
                Ok(())
            }
            Stmt::Continue => {
                ops.push(PirtmOp::Yield { value_id: "continue".to_string() });
                Ok(())
            }
            Stmt::Block(stmts) => {
                for s in stmts {
                    self.visit_statement(s, ops)?;
                }
                Ok(())
            }
            Stmt::If { cond, then_branch, else_branch } => {
                let mut cond_ops = Vec::new();
                self.visit_expression(cond, &mut cond_ops);
                let condition = Box::new(cond_ops.pop().unwrap_or(PirtmOp::BoolConstant { value: true, result_id: "0".to_string() }));
                let mut then_ops = Vec::new();
                for s in then_branch {
                    self.visit_statement(s, &mut then_ops)?;
                }
                let mut else_ops = Vec::new();
                if let Some(eb) = else_branch {
                    for s in eb {
                        self.visit_statement(s, &mut else_ops)?;
                    }
                }
                ops.push(PirtmOp::If { condition, then_ops, else_ops });
                Ok(())
            }
            Stmt::Loop { cond, body } => {
                let mut body_ops = Vec::new();
                for s in body {
                    self.visit_statement(s, &mut body_ops)?;
                }
                let condition = if let Some(c) = cond {
                    let mut c_ops = Vec::new();
                    self.visit_expression(c, &mut c_ops);
                    Box::new(c_ops.pop().unwrap_or(PirtmOp::BoolConstant { value: true, result_id: "1".to_string() }))
                } else {
                    Box::new(PirtmOp::BoolConstant { value: true, result_id: "1".to_string() })
                };
                ops.push(PirtmOp::While { condition, body_ops });
                Ok(())
            }
            Stmt::FnDef { name, generics: _, params, return_type: _, body } => {
                let saved_env = self.env.clone();
                for (pname, _) in params {
                    let pid = self.fresh_id();
                    self.env.insert(pname.clone(), VarInfo::Ssa(pid));
                }
                let mut body_ops = Vec::new();
                for s in body {
                    self.visit_statement(s, &mut body_ops)?;
                }
                self.env = saved_env;
                let args = params.iter().map(|(n, _)| n.clone()).collect();
                ops.push(PirtmOp::Func { name: name.clone(), args, body_ops });
                Ok(())
            }
            Stmt::StructDef { name, generics, fields } => {
                let suffix = if generics.is_empty() {
                    name.clone()
                } else {
                    let mut s = name.clone();
                    for p in generics {
                        s.push('_');
                        s.push_str(p);
                    }
                    s
                };
                let llvm_type_name = format!("llvm.struct_{}", suffix);
                let field_types = fields.iter().map(|(_, ty)| self.resolve_type_to_llvm(ty)).collect();
                let field_defs = fields.iter().map(|(n, ty)| (n.clone(), format!("{}", ty))).collect();
                ops.push(PirtmOp::StructDef { name: llvm_type_name, fields: field_types, generic_params: generics.clone(), field_defs });
                Ok(())
            }
            Stmt::EnumDef { name, generics, variants } => {
                let suffix = if generics.is_empty() {
                    name.clone()
                } else {
                    let mut s = name.clone();
                    for p in generics {
                        s.push('_');
                        s.push_str(p);
                    }
                    s
                };
                let llvm_type_name = format!("llvm.enum_{}", suffix);
                let v = variants.iter().map(|(n, t)| {
                    let typ = t.as_ref().map(|x| self.resolve_type_to_llvm(x));
                    (n.clone(), typ)
                }).collect();
                ops.push(PirtmOp::EnumDef { name: llvm_type_name, variants: v, generic_params: generics.clone() });
                Ok(())
            }
            Stmt::ImplDef { target: _, generics: _, methods } => {
                for m in methods {
                    self.visit_statement(m, ops)?;
                }
                Ok(())
            }
            Stmt::ExternFn { name, params, return_type, abi } => {
                let arg_types: Vec<String> = params.iter()
                    .map(|(_, ty)| self.resolve_type_to_llvm(ty))
                    .collect();
                let rt = if let Some(ret) = return_type {
                    self.resolve_type_to_llvm(ret)
                } else {
                    "void".to_string()
                };
                ops.push(PirtmOp::ExternFunc {
                    name: name.clone(),
                    abi: abi.clone(),
                    arg_types,
                    return_type: rt,
                });
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
            Expr::FloatLit(val) => {
                ops.push(PirtmOp::FloatConstant {
                    value: *val,
                    result_id: self.fresh_id(),
                });
            }
            Expr::CharLit(val) => {
                ops.push(PirtmOp::CharConstant {
                    value: *val,
                    result_id: self.fresh_id(),
                });
            }
            Expr::StringLit(val) => {
                ops.push(PirtmOp::StringConstant {
                    value: val.clone(),
                    result_id: self.fresh_id(),
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
                let var = self.env.get(name).cloned();
                if let Some(VarInfo::Ptr(ptr_id)) = var {
                    ops.push(PirtmOp::Load { ptr_id, result_id: self.fresh_id() });
                } else if let Some(VarInfo::Ssa(id)) = var {
                    ops.push(PirtmOp::OperatorAtom {
                        prime_index: 2,
                        result_id: id,
                        receipt_hash: "ident".to_string(),
                    });
                } else if name == "true" {
                    ops.push(PirtmOp::BoolConstant { value: true, result_id: self.fresh_id() });
                } else if name == "false" {
                    ops.push(PirtmOp::BoolConstant { value: false, result_id: self.fresh_id() });
                } else {
                    ops.push(PirtmOp::OperatorAtom {
                        prime_index: 2,
                        result_id: self.fresh_id(),
                        receipt_hash: "ident".to_string(),
                    });
                }
            }
            Expr::Binary { op, left, right } => {
                self.visit_expression(left, ops);
                let left_id = self.extract_last_op_id(ops);
                self.visit_expression(right, ops);
                let right_id = self.extract_last_op_id(ops);
                let op_kind = match op {
                    BinOp::Add => "add",
                    BinOp::Sub => "sub",
                    BinOp::Mul => "mul",
                    BinOp::Div => "div",
                    BinOp::Eq => "eq",
                    BinOp::Neq => "neq",
                    BinOp::Lt => "lt",
                    BinOp::Gt => "gt",
                    BinOp::Le => "le",
                    BinOp::Ge => "ge",
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
                    let operand_id = self.extract_last_op_id(ops);
                    ops.push(PirtmOp::Sigmoid {
                        operand_id,
                        result_id: self.fresh_id(),
                    });
                } else {
                    let mut arg_ops = Vec::new();
                    for a in args {
                        let mut a_ops = Vec::new();
                        self.visit_expression(a, &mut a_ops);
                        if let Some(op) = a_ops.pop() {
                            arg_ops.push(op);
                        }
                    }
                    ops.push(PirtmOp::Call {
                        name: name.clone(),
                        args: arg_ops,
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
            Expr::Sin(inner) => {
                self.visit_expression(inner, ops);
                ops.push(PirtmOp::OperatorAtom {
                    prime_index: 0,
                    result_id: self.fresh_id(),
                    receipt_hash: "sin".to_string(),
                });
            }
            Expr::Cos(inner) => {
                self.visit_expression(inner, ops);
                ops.push(PirtmOp::OperatorAtom {
                    prime_index: 0,
                    result_id: self.fresh_id(),
                    receipt_hash: "cos".to_string(),
                });
            }
            Expr::Log(inner) => {
                self.visit_expression(inner, ops);
                ops.push(PirtmOp::OperatorAtom {
                    prime_index: 0,
                    result_id: self.fresh_id(),
                    receipt_hash: "log".to_string(),
                });
            }
            Expr::StructInit { name, fields } => {
                let mut field_ops = Vec::new();
                for (fname, expr) in fields {
                    let mut e_ops = Vec::new();
                    self.visit_expression(expr, &mut e_ops);
                    if let Some(op) = e_ops.pop() {
                        field_ops.push((fname.clone(), Box::new(op)));
                    }
                }
                ops.push(PirtmOp::StructInit { name: format!("llvm.struct_{}", name), fields: field_ops });
            }
            Expr::FieldAccess { obj, field } => {
                let mut b_ops = Vec::new();
                self.visit_expression(obj, &mut b_ops);
                if let Some(op) = b_ops.pop() {
                    ops.push(PirtmOp::FieldAccess { base: Box::new(op), field: field.clone() });
                }
            }
            Expr::Match { expr, arms } => {
                let mut e_ops = Vec::new();
                self.visit_expression(expr, &mut e_ops);
                let target = Box::new(e_ops.pop().unwrap_or(PirtmOp::Constant { value: 0, result_id: "0".to_string() }));
                let mut arm_ops = Vec::new();
                for (pat, body) in arms {
                    let mut b_ops = Vec::new();
                    for stmt in body {
                        let _ = self.visit_statement(stmt, &mut b_ops);
                    }
                    arm_ops.push((pat.clone(), b_ops));
                }
                ops.push(PirtmOp::Match { value: target, arms: arm_ops });
            }
            Expr::MethodCall { obj, method, args } => {
                self.visit_expression(obj, ops);
                let obj_id = self.extract_last_op_id(ops);
                let mut arg_ids = Vec::new();
                for a in args {
                    self.visit_expression(a, ops);
                    let arg_id = self.extract_last_op_id(ops);
                    arg_ids.push(arg_id);
                }
                let result_id = self.fresh_id();
                ops.push(PirtmOp::MethodCall { obj_id, method: method.clone(), arg_ids, result_id });
            }
            Expr::LogicalOp { op, left, right } => {
                self.visit_expression(left, ops);
                let left_id = self.extract_last_op_id(ops);
                self.visit_expression(right, ops);
                let right_id = self.extract_last_op_id(ops);
                let result_id = self.fresh_id();
                ops.push(PirtmOp::LogicalOp { op: op.clone(), left_id, right_id, result_id });
            }
            Expr::Not(inner) => {
                self.visit_expression(inner, ops);
                let expr_id = self.extract_last_op_id(ops);
                let result_id = self.fresh_id();
                ops.push(PirtmOp::Not { expr_id, result_id });
            }
            Expr::Tuple(elems) => {
                let mut elem_ids = Vec::new();
                for e in elems {
                    self.visit_expression(e, ops);
                    let elem_id = self.extract_last_op_id(ops);
                    elem_ids.push(elem_id);
                }
                let result_id = self.fresh_id();
                ops.push(PirtmOp::Tuple { elem_ids, result_id });
            }
            Expr::Try(inner) => {
                self.visit_expression(inner, ops);
                let val_id = self.extract_last_op_id(ops);
                let result_id = self.fresh_id();
                ops.push(PirtmOp::MethodCall {
                    obj_id: val_id,
                    method: "unwrap".to_string(),
                    arg_ids: vec![],
                    result_id,
                });
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use pirtm_parser::ast::{BinOp, Expr, LogicalOp, Program, Stmt};

    #[test]
    fn test_visit_integer() {
        let mut v = MlirEmitterVisitor::new();
        let mut ops = Vec::new();
        v.visit_expression(&Expr::Literal(7), &mut ops);
        assert_eq!(ops.len(), 1);
        if let PirtmOp::OperatorAtom { prime_index, .. } = &ops[0] {
            assert_eq!(*prime_index, 7);
        } else {
            panic!("Expected OperatorAtom");
        }
    }

    #[test]
    fn test_visit_binary_add() {
        let mut v = MlirEmitterVisitor::new();
        let mut ops = Vec::new();
        let expr = Expr::Binary {
            op: BinOp::Add,
            left: Box::new(Expr::Literal(3)),
            right: Box::new(Expr::Literal(5)),
        };
        v.visit_expression(&expr, &mut ops);
        assert_eq!(ops.len(), 3, "expected 3 ops (2 atoms + 1 binary)");
        match &ops[2] {
            PirtmOp::BinaryOp { op_kind, .. } => assert_eq!(op_kind, "add"),
            _ => panic!("Expected BinaryOp"),
        }
    }

    #[test]
    fn test_visit_let_mut_and_assign() {
        let mut v = MlirEmitterVisitor::new();
        let mut ops = Vec::new();

        // let mut x = 10;
        let let_mut = Stmt::LetMut {
            name: "x".to_string(),
            expr: Expr::Literal(10),
        };
        v.visit_statement(&let_mut, &mut ops).unwrap();
        assert!(ops.iter().any(|op| matches!(op, PirtmOp::Alloca { .. })));
        assert!(ops.iter().any(|op| matches!(op, PirtmOp::Store { .. })));

        // x = 20;
        let assign = Stmt::Assign {
            name: "x".to_string(),
            expr: Expr::Literal(20),
        };
        v.visit_statement(&assign, &mut ops).unwrap();
    }

    #[test]
    fn test_assign_to_immutable_fails() {
        let mut v = MlirEmitterVisitor::new();
        let mut ops = Vec::new();

        // let y = 10;
        let let_immut = Stmt::Let {
            name: "y".to_string(),
            expr: Expr::Literal(10),
        };
        v.visit_statement(&let_immut, &mut ops).unwrap();

        // y = 20; -> should error
        let assign = Stmt::Assign {
            name: "y".to_string(),
            expr: Expr::Literal(20),
        };
        let res = v.visit_statement(&assign, &mut ops);
        assert!(res.is_err());
        assert!(res.unwrap_err().contains("Cannot assign to immutable variable 'y'"));
    }

    #[test]
    fn test_visit_method_call_and_logical_ops() {
        let mut v = MlirEmitterVisitor::new();
        let mut ops = Vec::new();

        // s.len()
        let mc = Expr::MethodCall {
            obj: Box::new(Expr::StringLit("hello".to_string())),
            method: "len".to_string(),
            args: vec![],
        };
        v.visit_expression(&mc, &mut ops);
        assert!(ops.iter().any(|op| matches!(op, PirtmOp::MethodCall { .. })));

        // a && b
        let log_op = Expr::LogicalOp {
            op: LogicalOp::And,
            left: Box::new(Expr::Ident("true".to_string())),
            right: Box::new(Expr::Ident("false".to_string())),
        };
        v.visit_expression(&log_op, &mut ops);
        assert!(ops.iter().any(|op| matches!(op, PirtmOp::LogicalOp { .. })));
    }

    #[test]
    fn test_emit_program_simple() {
        let prog = Program {
            stmts: vec![Stmt::Expr(Expr::Literal(42))],
        };
        let mut visitor = MlirEmitterVisitor::new();
        let mlir = visitor.emit_program(&prog).expect("emit should succeed");
        assert!(mlir.contains("pirtm.operator_atom 42"));
    }
}
