// crates/pirtm-mlir/src/ops.rs

/// Represents the PIRTM Dialect operations.
#[derive(Debug, Clone)]
pub enum PirtmOp {
    /// Ap(p, params): The fundamental prime-indexed operator atom.
    OperatorAtom {
        prime_index: u64,
        result_id: String,
        receipt_hash: String,
    },
    /// A binary operation that combines two SSA values.
    BinaryOp {
        op_kind: String,
        left_id: String,
        right_id: String,
        result_id: String,
        receipt_hash: String,
    },
    /// A constant value.
    Constant {
        value: i64,
        result_id: String,
    },
    /// Yield operation for block terminators.
    Yield {
        value_id: String,
    },
    /// Sigmoid unary operation.
    Sigmoid {
        operand_id: String,
        result_id: String,
    },
    /// Lowers to `scf.if`
    If {
        condition: Box<PirtmOp>,
        then_ops: Vec<PirtmOp>,
        else_ops: Vec<PirtmOp>,
    },
    /// Lowers to `scf.while`
    While {
        condition: Box<PirtmOp>,
        body_ops: Vec<PirtmOp>,
    },
    /// Lowers to `func.func`
    Func {
        name: String,
        args: Vec<String>,
        body_ops: Vec<PirtmOp>,
    },
    /// Lowers to `func.call`
    Call {
        name: String,
        args: Vec<PirtmOp>,
    },
    /// Lowers to `func.return`
    Return {
        value: Option<Box<PirtmOp>>,
    },
    /// Struct definition `llvm.struct`
    StructDef {
        name: String,
        fields: Vec<(String, String)>,
    },
    /// Enum definition (tagged union struct)
    EnumDef {
        name: String,
        variants: Vec<(String, Option<String>)>,
    },
    /// Struct initialization `llvm.undef` + `llvm.insertvalue`
    StructInit {
        name: String,
        fields: Vec<(String, Box<PirtmOp>)>,
    },
    /// Field access `llvm.extractvalue`
    FieldAccess {
        base: Box<PirtmOp>,
        field: String,
    },
    /// Match pattern `scf.switch` or nested `scf.if`
    Match {
        value: Box<PirtmOp>,
        arms: Vec<(String, Vec<PirtmOp>)>,
    },
}

impl PirtmOp {
    pub fn emit_mlir(&self) -> Result<String, String> {
        match self {
            PirtmOp::OperatorAtom { prime_index, result_id, receipt_hash } => {
                Ok(format!("  %{} = pirtm.operator_atom {} {{receipt = \"{}\"}} : !pirtm.stratum", result_id, prime_index, receipt_hash))
            }
            PirtmOp::BinaryOp { op_kind, left_id, right_id, result_id, receipt_hash } => {
                Ok(format!("  %{} = pirtm.binary_{} %{}, %{} {{receipt = \"{}\"}} : (!pirtm.stratum, !pirtm.stratum) -> !pirtm.stratum", result_id, op_kind, left_id, right_id, receipt_hash))
            }
            PirtmOp::Constant { value, result_id } => {
                Ok(format!("  %{} = pirtm.constant {} : i64", result_id, value))
            }
            PirtmOp::Yield { value_id } => {
                Ok(format!("  pirtm.yield %{} : !pirtm.stratum", value_id))
            },
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
                
                Ok(format!("func.func @{}({}) {{\n    {}\n    return\n}}", name, args_text, body_text))
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
            PirtmOp::StructDef { name, fields } => {
                let field_types = fields.iter().map(|(_, ty)| format!("!llvm.{}", ty)).collect::<Vec<_>>().join(", ");
                Ok(format!("!llvm.struct_{} = type {{ {} }}", name, field_types))
            }
            PirtmOp::EnumDef { name, variants } => {
                // Simplified enum type lowering as a tagged struct: { i32 (tag), payload }
                Ok(format!("!llvm.enum_{} = type {{ i32, i64 }}", name))
            }
            PirtmOp::StructInit { name, fields } => {
                let mut s = format!("%undef_{} = llvm.undef : !llvm.struct_{}", name, name);
                for (i, (_, op)) in fields.iter().enumerate() {
                    let val = op.emit_mlir()?;
                    s.push_str(&format!("\n    %ins_{}_{} = llvm.insertvalue {}, %undef_{}[{}] : !llvm.struct_{}", name, i, val, name, i, name));
                }
                Ok(s)
            }
            PirtmOp::FieldAccess { base, field } => {
                let base_val = base.emit_mlir()?;
                // Using 0 as a placeholder since we don't have symbol resolution for indices yet
                Ok(format!("%ext_field_{} = llvm.extractvalue {}, 0", field, base_val))
            }
            PirtmOp::Match { value, arms } => {
                let val_expr = value.emit_mlir()?;
                let mut switch_cases = String::new();
                for (i, (pat, ops)) in arms.iter().enumerate() {
                    let body = ops.iter().map(|op| op.emit_mlir()).collect::<Result<Vec<_>, _>>()?.join("\n      ");
                    switch_cases.push_str(&format!("case {} {{\n      {}\n      scf.yield\n    }}\n    ", i, body)); // placeholder index matching for now
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
    fn test_emit_sigmoid() {
        let op = PirtmOp::Sigmoid {
            operand_id: "x".to_string(),
            result_id: "y".to_string(),
        };
        let mlir = op.emit_mlir().unwrap();
        assert!(mlir.contains("pirtm.sigmoid"));
        assert!(mlir.contains("%y = pirtm.sigmoid %x"));
    }
}
