// src/pirtm/dialect/ops.rs

#[derive(Debug, Clone)]
pub enum PirtmOp {
    OperatorAtom {
        prime_index: u64,
        result_id: String,
        receipt_hash: String,
    },
    BinaryOp {
        op_kind: String,
        left_id: String,
        right_id: String,
        result_id: String,
        receipt_hash: String,
    },
    Constant {
        result_id: String,
        receipt_hash: String,
    },
    Yield {
        value_id: String,
    },
    Sigmoid {
        operand_id: String,
        result_id: String,
        receipt_hash: String,
    },
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
        spectral_budget: Option<f64>,
        receipt_hash: String,
    },
}

impl PirtmOp {
    pub fn to_mlir(&self) -> String {
        match self {
            PirtmOp::OperatorAtom {
                prime_index,
                result_id,
                receipt_hash,
            } => {
                format!(
                    "pirtm.operator_atom {{ prime_index = {} : i64, result_id = \"{}\" : str, receipt_hash = \"{}\" : str }}",
                    prime_index, result_id, receipt_hash
                )
            }
            PirtmOp::BinaryOp {
                op_kind,
                left_id,
                right_id,
                result_id,
                receipt_hash,
            } => {
                format!(
                    "pirtm.binary_op {{ op_kind = \"{}\" : str, left_id = \"{}\" : str, right_id = \"{}\" : str, result_id = \"{}\" : str, receipt_hash = \"{}\" : str }}",
                    op_kind, left_id, right_id, result_id, receipt_hash
                )
            }
            PirtmOp::Constant {
                result_id,
                receipt_hash,
            } => {
                format!(
                    "pirtm.constant {{ result_id = \"{}\" : str, receipt_hash = \"{}\" : str }}",
                    result_id, receipt_hash
                )
            }
            PirtmOp::Yield { value_id } => {
                format!("pirtm.yield {{ value_id = \"{}\" : str }}", value_id)
            }
            PirtmOp::Sigmoid {
                operand_id,
                result_id,
                receipt_hash,
            } => {
                format!(
                    "pirtm.sigmoid {{ operand_id = \"{}\" : str, result_id = \"{}\" : str, receipt_hash = \"{}\" : str }}",
                    operand_id, result_id, receipt_hash
                )
            }
            PirtmOp::Ensemble {
                name,
                version,
                prime_index,
                spectral_radius,
                receipt_hash,
            } => {
                format!(
                    "pirtm.ensemble {{ name = \"{}\" : str, version = \"{}\" : str, prime_index = {} : i64, spectral_radius = {} : f64, receipt_hash = \"{}\" : str }}",
                    name, version, prime_index, spectral_radius, receipt_hash
                )
            }
            PirtmOp::Import {
                path,
                alias,
                spectral_budget,
                receipt_hash,
            } => {
                let alias_str = alias.as_deref().unwrap_or("");
                let budget_str = spectral_budget
                    .map(|b| b.to_string())
                    .unwrap_or_else(|| "none".to_string());
                format!(
                    "pirtm.import {{ path = \"{}\" : str, alias = \"{}\" : str, spectral_budget = \"{}\" : str, receipt_hash = \"{}\" : str }}",
                    path, alias_str, budget_str, receipt_hash
                )
            }
        }
    }

    pub fn emit_mlir(&self) -> Result<String, String> {
        Ok(self.to_mlir())
    }

    pub fn operator_atom(prime_index: u64) -> Self {
        Self::OperatorAtom {
            prime_index,
            result_id: String::new(),
            receipt_hash: "operator_atom".to_string(),
        }
    }

    /// Builder that inserts a sentinel placeholder for `result_id`. The visitor will later replace it with a fresh identifier.
    pub fn operator_atom_placeholder(prime_index: u64) -> Self {
        Self::OperatorAtom {
            prime_index,
            result_id: "<placeholder>".to_string(),
            receipt_hash: "operator_atom".to_string(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_emit_operator_atom() {
        let mut op = PirtmOp::operator_atom(2);
        if let PirtmOp::OperatorAtom {
            ref mut result_id, ..
        } = op
        {
            *result_id = "tmp_0".to_string();
        }
        let mlir = op.emit_mlir().unwrap();
        assert!(mlir.contains("pirtm.operator_atom"));
        assert!(mlir.contains("prime_index = 2"));
    }
}
