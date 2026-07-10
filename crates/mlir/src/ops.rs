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
