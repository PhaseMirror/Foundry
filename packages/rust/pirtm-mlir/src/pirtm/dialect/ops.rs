// crates/pirtm-mlir/src/pirtm/dialect/ops.rs

use pirtm_parser::ast::LogicalOp;

/// Represents the PIRTM Dialect operations.
#[derive(Debug, Clone, PartialEq)]
pub enum PirtmOp {
    Ensemble {
        name: String,
        version: String,
        prime_index: u64,
        spectral_radius: f64,
        receipt_hash: String,
    },
    Import {
        path: String,
        alias: Option<String>,
        spectral_budget: f64,
        receipt_hash: String,
    },
    /// Ap(p): The fundamental prime-indexed operator atom.
    OperatorAtom {
        prime_index: u64,
        result_id: String,
        receipt_hash: String,
    },
    /// Allocate mutable stack slot: llvm.alloca
    Alloca {
        typ: String,
        result_id: String,
    },
    /// Store value to pointer: llvm.store
    Store {
        ptr_id: String,
        val_id: String,
    },
    /// Load value from pointer: llvm.load
    Load {
        ptr_id: String,
        result_id: String,
    },
    /// Method call dispatch: lowers to runtime/FFI call
    MethodCall {
        obj_id: String,
        method: String,
        arg_ids: Vec<String>,
        result_id: String,
    },
    /// Logical operation with short-circuiting: scf.if
    LogicalOp {
        op: LogicalOp,
        left_id: String,
        right_id: String,
        result_id: String,
    },
    /// Logical Not operation: arith.xori %x, 1
    Not {
        expr_id: String,
        result_id: String,
    },
    /// Tuple construction: llvm.undef + llvm.insertvalue
    Tuple {
        elem_ids: Vec<String>,
        result_id: String,
    },
    /// Binary arithmetic/comparison operation
    BinaryOp {
        op_kind: String,
        left_id: String,
        right_id: String,
        result_id: String,
        receipt_hash: String,
    },
    /// Integer constant
    Constant {
        value: i64,
        result_id: String,
    },
    /// Float constant
    FloatConstant {
        value: f64,
        result_id: String,
    },
    /// String constant
    StringConstant {
        value: String,
        result_id: String,
    },
    /// Character constant
    CharConstant {
        value: char,
        result_id: String,
    },
    /// Boolean constant
    BoolConstant {
        value: bool,
        result_id: String,
    },
    /// Yield operation for block terminators
    Yield {
        value_id: String,
    },
    /// Sigmoid unary operation
    Sigmoid {
        operand_id: String,
        result_id: String,
    },
    /// Conditional branching: scf.if
    If {
        condition: Box<PirtmOp>,
        then_ops: Vec<PirtmOp>,
        else_ops: Vec<PirtmOp>,
    },
    /// Loop construct: scf.while
    While {
        condition: Box<PirtmOp>,
        body_ops: Vec<PirtmOp>,
    },
    /// Function definition: func.func
    Func {
        name: String,
        args: Vec<String>,
        body_ops: Vec<PirtmOp>,
    },
    /// External C-ABI function declaration
    ExternFunc {
        name: String,
        abi: String,
        arg_types: Vec<String>,
        return_type: String,
    },
    /// Function call: func.call
    Call {
        name: String,
        args: Vec<PirtmOp>,
    },
    /// Return statement: func.return
    Return {
        value: Option<Box<PirtmOp>>,
    },
    /// Struct definition: llvm.struct
    StructDef {
        name: String,
        fields: Vec<String>,
        generic_params: Vec<String>,
        field_defs: Vec<(String, String)>,
    },
    /// Enum definition (tagged union struct)
    EnumDef {
        name: String,
        variants: Vec<(String, Option<String>)>,
        generic_params: Vec<String>,
    },
    /// Struct initialization: llvm.undef + llvm.insertvalue
    StructInit {
        name: String,
        fields: Vec<(String, Box<PirtmOp>)>,
    },
    /// Field access: llvm.extractvalue
    FieldAccess {
        base: Box<PirtmOp>,
        field: String,
    },
    /// Pattern matching: scf.switch / nested scf.if
    Match {
        value: Box<PirtmOp>,
        arms: Vec<(String, Vec<PirtmOp>)>,
    },
}

impl PirtmOp {
    /// Emit MLIR text for this operation.
    pub fn emit_mlir(&self) -> Result<String, String> {
        match self {
            PirtmOp::Ensemble { name, version, .. } => {
                Ok(format!("  pirtm.ensemble @{} version \"{}\"", name, version))
            }
            PirtmOp::Import { path, .. } => {
                Ok(format!("  pirtm.import \"{}\"", path))
            }
            PirtmOp::OperatorAtom { prime_index, result_id, receipt_hash } => {
                Ok(format!("  %{} = pirtm.operator_atom {} {{receipt = \"{}\"}} : !pirtm.stratum", result_id, prime_index, receipt_hash))
            }
            PirtmOp::Alloca { typ, result_id } => {
                Ok(format!("  %{} = llvm.alloca 1 x {} : (!llvm.ptr)", result_id, typ))
            }
            PirtmOp::Store { ptr_id, val_id } => {
                Ok(format!("  llvm.store %{}, %{} : !llvm.ptr", val_id, ptr_id))
            }
            PirtmOp::Load { ptr_id, result_id } => {
                Ok(format!("  %{} = llvm.load %{} : !llvm.ptr -> i64", result_id, ptr_id))
            }
            PirtmOp::MethodCall { obj_id, method, arg_ids, result_id } => {
                let func_name = match method.as_str() {
                    "len" => "string_len",
                    "push" => "vec_push",
                    "insert" => "map_insert",
                    "to_str" => "string_to_str",
                    "concat" => "string_concat",
                    "char_at" => "string_char_at",
                    "slice" => "string_slice",
                    "get" => "array_get",
                    "unwrap" => "option_unwrap",
                    _ => method.as_str(),
                };
                let mut all_args = vec![format!("%{}", obj_id)];
                for a in arg_ids {
                    all_args.push(format!("%{}", a));
                }
                let args_str = all_args.join(", ");
                Ok(format!("  %{} = func.call @{}({}) : () -> !pirtm.stratum", result_id, func_name, args_str))
            }
            PirtmOp::LogicalOp { op, left_id, right_id, result_id } => {
                match op {
                    LogicalOp::And => Ok(format!(
                        "  %{} = scf.if %{} -> (i1) {{\n    scf.yield %{} : i1\n  }} else {{\n    %c0_{} = arith.constant false\n    scf.yield %c0_{} : i1\n  }}",
                        result_id, left_id, right_id, result_id, result_id
                    )),
                    LogicalOp::Or => Ok(format!(
                        "  %{} = scf.if %{} -> (i1) {{\n    %c1_{} = arith.constant true\n    scf.yield %c1_{} : i1\n  }} else {{\n    scf.yield %{} : i1\n  }}",
                        result_id, left_id, result_id, result_id, right_id
                    )),
                }
            }
            PirtmOp::Not { expr_id, result_id } => {
                Ok(format!("  %c_true_{} = arith.constant true\n  %{} = arith.xori %{}, %c_true_{} : i1", result_id, result_id, expr_id, result_id))
            }
            PirtmOp::Tuple { elem_ids, result_id } => {
                let typ = format!("struct<{}>", vec!["i64"; elem_ids.len()].join(", "));
                let mut s = format!("  %undef_{} = llvm.undef : !llvm.{}\n", result_id, typ);
                let mut prev = format!("%undef_{}", result_id);
                for (i, elem) in elem_ids.iter().enumerate() {
                    let next = format!("%ins{}_{}", i, result_id);
                    s.push_str(&format!("  {} = llvm.insertvalue %{}, {}[{}] : !llvm.{}\n", next, elem, prev, i, typ));
                    prev = next;
                }
                s.push_str(&format!("  %{} = llvm.mlir.addressof {} : !llvm.{}", result_id, prev, typ));
                Ok(s)
            }
            PirtmOp::BinaryOp { op_kind, left_id, right_id, result_id, receipt_hash } => {
                match op_kind.as_str() {
                    "add" => Ok(format!("  %{} = arith.addi %{}, %{} : i64", result_id, left_id, right_id)),
                    "sub" => Ok(format!("  %{} = arith.subi %{}, %{} : i64", result_id, left_id, right_id)),
                    "mul" => Ok(format!("  %{} = arith.muli %{}, %{} : i64", result_id, left_id, right_id)),
                    "div" => Ok(format!("  %{} = arith.divsi %{}, %{} : i64", result_id, left_id, right_id)),
                    "eq" => Ok(format!("  %{} = arith.cmpi eq, %{}, %{} : i64", result_id, left_id, right_id)),
                    "neq" => Ok(format!("  %{} = arith.cmpi ne, %{}, %{} : i64", result_id, left_id, right_id)),
                    "lt" => Ok(format!("  %{} = arith.cmpi slt, %{}, %{} : i64", result_id, left_id, right_id)),
                    "gt" => Ok(format!("  %{} = arith.cmpi sgt, %{}, %{} : i64", result_id, left_id, right_id)),
                    "le" => Ok(format!("  %{} = arith.cmpi sle, %{}, %{} : i64", result_id, left_id, right_id)),
                    "ge" => Ok(format!("  %{} = arith.cmpi sge, %{}, %{} : i64", result_id, left_id, right_id)),
                    _ => Ok(format!("  %{} = pirtm.binary_{} %{}, %{} {{receipt = \"{}\"}} : (!pirtm.stratum, !pirtm.stratum) -> !pirtm.stratum", result_id, op_kind, left_id, right_id, receipt_hash)),
                }
            }
            PirtmOp::Constant { value, result_id } => {
                Ok(format!("  %{} = arith.constant {} : i64", result_id, value))
            }
            PirtmOp::FloatConstant { value, result_id } => {
                Ok(format!("  %{} = arith.constant {:?} : f64", result_id, value))
            }
            PirtmOp::StringConstant { value, result_id } => {
                Ok(format!("  %{} = llvm.mlir.constant(\"{}\") : !llvm.ptr", result_id, value))
            }
            PirtmOp::CharConstant { value, result_id } => {
                Ok(format!("  %{} = arith.constant {} : i32", result_id, *value as u32))
            }
            PirtmOp::BoolConstant { value, result_id } => {
                let v = if *value { 1 } else { 0 };
                Ok(format!("  %{} = arith.constant {} : i1", result_id, v))
            }
            PirtmOp::Yield { value_id } => {
                Ok(format!("  pirtm.yield %{} : !pirtm.stratum", value_id))
            }
            PirtmOp::Sigmoid { operand_id, result_id } => {
                Ok(format!("  %{} = pirtm.sigmoid %{} : (tensor<?xf64>) -> tensor<?xf64>", result_id, operand_id))
            }
            PirtmOp::If { condition, then_ops, else_ops } => {
                let cond_text = condition.emit_mlir()?;
                let then_text = then_ops.iter().map(|op| op.emit_mlir()).collect::<Result<Vec<_>, _>>()?.join("\n    ");
                
                let else_text = if !else_ops.is_empty() {
                    let else_body = else_ops.iter().map(|op| op.emit_mlir()).collect::<Result<Vec<_>, _>>()?.join("\n    ");
                    format!(" else {{\n    {}\n  }}", else_body)
                } else {
                    String::new()
                };
                
                Ok(format!("scf.if {} {{\n    {}\n  }}{}", cond_text, then_text, else_text))
            }
            PirtmOp::While { condition, body_ops } => {
                let cond_text = condition.emit_mlir()?;
                let body_text = body_ops.iter().map(|op| op.emit_mlir()).collect::<Result<Vec<_>, _>>()?.join("\n      ");
                
                Ok(format!("scf.while ({}) : (i1) -> () {{\n    ^bb0(%arg0: i1):\n      scf.condition(%arg0)\n  }} do {{\n    ^bb0:\n      {}\n      scf.yield\n  }}", cond_text, body_text))
            }
            PirtmOp::Func { name, args, body_ops } => {
                let args_text = args.iter().map(|a| format!("%{}: i64", a)).collect::<Vec<_>>().join(", ");
                let body_text = body_ops.iter().map(|op| op.emit_mlir()).collect::<Result<Vec<_>, _>>()?.join("\n    ");
                
                Ok(format!("func.func @{}({}) {{\n    {}\n    func.return\n}}", name, args_text, body_text))
            }
            PirtmOp::ExternFunc { name, abi, arg_types, return_type } => {
                let args = arg_types.join(", ");
                let ret = if return_type == "void" || return_type == "i1" || return_type.is_empty() { String::new() } else { format!(" -> {}", return_type) };
                let linkage = if abi == "C" { " attributes {llvm.linkage = #llvm.linkage<external>}" } else { "" };
                Ok(format!("func.func private @{}({}){}{}", name, args, ret, linkage))
            }
            PirtmOp::Call { name, args } => {
                let args_text = args.iter().map(|op| op.emit_mlir()).collect::<Result<Vec<_>, _>>()?.join(", ");
                Ok(format!("func.call @{}({}) : () -> ()", name, args_text))
            }
            PirtmOp::Return { value } => {
                if let Some(val) = value {
                    Ok(format!("func.return {}", val.emit_mlir()?))
                } else {
                    Ok("func.return".to_string())
                }
            }
            PirtmOp::StructDef { name, fields, .. } => {
                let field_types = fields.join(", ");
                Ok(format!("!{} = type {{ {} }}", name, field_types))
            }
            PirtmOp::EnumDef { name, .. } => {
                Ok(format!("!{} = type {{ i32, i64 }}", name))
            }
            PirtmOp::StructInit { name, fields } => {
                let mut s = format!("%undef_init = llvm.undef : !{}", name);
                for (i, (_, op)) in fields.iter().enumerate() {
                    let val = op.emit_mlir()?;
                    s.push_str(&format!("\n    %ins_{} = llvm.insertvalue {}, %undef_init[{}] : !{}", i, val, i, name));
                }
                Ok(s)
            }
            PirtmOp::FieldAccess { base, field } => {
                let base_val = base.emit_mlir()?;
                Ok(format!("%ext_field_{} = llvm.extractvalue {}, 0", field, base_val))
            }
            PirtmOp::Match { value, arms } => {
                let val_expr = value.emit_mlir()?;
                let mut switch_cases = String::new();
                for (i, (_pat, ops)) in arms.iter().enumerate() {
                    let body = ops.iter().map(|op| op.emit_mlir()).collect::<Result<Vec<_>, _>>()?.join("\n      ");
                    switch_cases.push_str(&format!("case {} {{\n      {}\n      scf.yield\n    }}\n    ", i, body));
                }
                Ok(format!("scf.switch {} {{\n    {}\n  }}", val_expr, switch_cases))
            }
        }
    }
}

/// Represents an MLIR Block containing a sequence of operations.
#[derive(Debug, Clone)]
pub struct SsaBlock {
    pub args: Vec<String>,
    pub ops: Vec<PirtmOp>,
}

impl SsaBlock {
    pub fn new() -> Self {
        Self { args: Vec::new(), ops: Vec::new() }
    }
    pub fn emit_mlir(&self) -> String {
        let mut out = String::new();
        if !self.args.is_empty() {
            out.push_str(&format!("^bb0({}):\n", self.args.join(", ")));
        }
        for op in &self.ops {
            out.push_str(&format!("{}\n", op.emit_mlir().unwrap()));
        }
        out
    }
}

/// Represents a func.func operation.
#[derive(Debug, Clone)]
pub struct FuncOp {
    pub name: String,
    pub region: SsaBlock,
}

impl FuncOp {
    pub fn emit_mlir(&self) -> String {
        let mut out = format!("func.func @{}() -> !pirtm.stratum {{\n", self.name);
        out.push_str(&self.region.emit_mlir());
        out.push_str("}\n");
        out
    }
}

/// Represents the top-level builtin.module.
#[derive(Debug, Clone)]
pub struct ModuleOp {
    pub funcs: Vec<FuncOp>,
}

impl ModuleOp {
    pub fn emit_mlir(&self) -> String {
        let mut out = "module {\n".to_string();
        for func in &self.funcs {
            let func_str = func.emit_mlir();
            for line in func_str.lines() {
                out.push_str(&format!("  {}\n", line));
            }
        }
        out.push_str("}\n");
        out
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_emit_alloca_store_load() {
        let alloca = PirtmOp::Alloca {
            typ: "i64".to_string(),
            result_id: "ptr0".to_string(),
        };
        let mlir = alloca.emit_mlir().unwrap();
        assert!(mlir.contains("llvm.alloca"));

        let store = PirtmOp::Store {
            ptr_id: "ptr0".to_string(),
            val_id: "val0".to_string(),
        };
        let mlir_store = store.emit_mlir().unwrap();
        assert!(mlir_store.contains("llvm.store"));

        let load = PirtmOp::Load {
            ptr_id: "ptr0".to_string(),
            result_id: "loaded0".to_string(),
        };
        let mlir_load = load.emit_mlir().unwrap();
        assert!(mlir_load.contains("llvm.load"));
    }

    #[test]
    fn test_emit_logical_short_circuit() {
        let log_and = PirtmOp::LogicalOp {
            op: LogicalOp::And,
            left_id: "a".to_string(),
            right_id: "b".to_string(),
            result_id: "res".to_string(),
        };
        let mlir = log_and.emit_mlir().unwrap();
        assert!(mlir.contains("scf.if %a -> (i1)"));
        assert!(mlir.contains("scf.yield %b"));
        assert!(mlir.contains("arith.constant false"));
    }

    #[test]
    fn test_emit_method_call() {
        let mc = PirtmOp::MethodCall {
            obj_id: "str0".to_string(),
            method: "len".to_string(),
            arg_ids: vec![],
            result_id: "len0".to_string(),
        };
        let mlir = mc.emit_mlir().unwrap();
        assert!(mlir.contains("call @string_len(%str0)"));
    }
}
