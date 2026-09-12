use crate::ast::*;
use crate::error::{IrError, Result};
use std::collections::HashSet;
use std::fs;

/// Parse and validate an IR document from a JSON string.
pub fn parse_ir(json_str: &str) -> Result<IrDocument> {
    let doc: IrDocument = serde_json::from_str(json_str)?;
    validate_ir(&doc)?;
    Ok(doc)
}

/// Load, parse, and validate an IR document from a file path.
pub fn parse_ir_file(path: &str) -> Result<IrDocument> {
    let content = fs::read_to_string(path)?;
    parse_ir(&content)
}

/// Validate an IR document against the frozen DRMM IR v1.0 specification.
///
/// Checks performed:
/// 1. `ir_version` and `schema_version` must be `"1.0.0"`.
/// 2. Node identifiers must match `^[a-z]+_[0-9]{6}$` and be unique within each scope
///    (top-level `nodes` list and `output` tree are independent scopes).
/// 3. Tensor shapes must match declared rank and contain only positive dimensions.
/// 4. Iteration counts and tolerances must be strictly positive.
/// 5. Branches must contain at least one condition.
pub fn validate_ir(doc: &IrDocument) -> Result<()> {
    // 1. Version checks
    if doc.ir_version != "1.0.0" {
        return Err(IrError::UnsupportedVersion(doc.ir_version.clone()));
    }
    if doc.schema_version != "1.0.0" {
        return Err(IrError::UnsupportedSchema(doc.schema_version.clone()));
    }
    // semantics_version and certificate_version can be any string.

    // 2. Ensure all node ids are unique within each scope (top-level nodes and the
    //    output tree are independent scopes) and follow pattern ^[a-z]+_[0-9]{6}$.
    let mut node_ids = HashSet::new();
    for node in &doc.nodes {
        let id = node.id();
        if !is_valid_id(id) {
            return Err(IrError::InvalidId(id.to_string()));
        }
        if !node_ids.insert(id.to_string()) {
            return Err(IrError::DuplicateId(id.to_string()));
        }
    }

    let mut output_ids = HashSet::new();
    let mut output_nodes = Vec::new();
    collect_nodes(&doc.output, &mut output_nodes);
    for node in output_nodes {
        let id = node.id();
        if !is_valid_id(id) {
            return Err(IrError::InvalidId(id.to_string()));
        }
        if !output_ids.insert(id.to_string()) {
            return Err(IrError::DuplicateId(id.to_string()));
        }
    }

    // 3. Validate tensor shapes and iteration/branch semantics
    for node in &doc.nodes {
        if let Expr::Tensor { rank, shape, .. } = node {
            if shape.len() != *rank as usize {
                return Err(IrError::TensorShapeMismatch);
            }
            if shape.contains(&0) {
                return Err(IrError::TensorDimensionNonPositive);
            }
        }
        if let Expr::Iterate { iterations, .. } = node {
            match iterations {
                IterationSpec::FixedCount { count } => {
                    if *count == 0 {
                        return Err(IrError::IterationCountZero);
                    }
                }
                IterationSpec::UntilTolerance {
                    tolerance,
                    max_iter,
                } => {
                    if *tolerance <= 0.0 {
                        return Err(IrError::ToleranceNonPositive);
                    }
                    if let Some(max) = max_iter {
                        if *max == 0 {
                            return Err(IrError::MaxIterZero);
                        }
                    }
                }
            }
        }
        // Branch validation: at least one condition
        if let Expr::Branch { conditions, .. } = node {
            if conditions.is_empty() {
                return Err(IrError::EmptyBranch);
            }
        }
    }

    // 4. The output expression is a self-contained tree whose node ids were already
    //    collected and uniqueness-checked above. No cross-node id references exist in v1.0,
    //    so no additional reference resolution is required.

    Ok(())
}

/// Recursively collect all expression nodes from a tree into `acc`.
fn collect_nodes<'a>(expr: &'a Expr, acc: &mut Vec<&'a Expr>) {
    acc.push(expr);
    match expr {
        Expr::Weight { expr: inner, .. } => collect_nodes(inner, acc),
        Expr::Compose { sequence, .. } => {
            for e in sequence {
                collect_nodes(e, acc);
            }
        }
        Expr::Iterate {
            operator, input, ..
        } => {
            collect_nodes(operator, acc);
            collect_nodes(input, acc);
        }
        Expr::Branch {
            conditions,
            default,
            ..
        } => {
            for cond in conditions {
                collect_nodes(&cond.predicate, acc);
                collect_nodes(&cond.consequence, acc);
            }
            if let Some(def) = default {
                collect_nodes(def, acc);
            }
        }
        _ => {} // leaf nodes
    }
}

/// Validate a node identifier against the required pattern `^[a-z]+_[0-9]{6}$`.
fn is_valid_id(id: &str) -> bool {
    let parts: Vec<&str> = id.split('_').collect();
    if parts.len() != 2 {
        return false;
    }
    if parts[0].is_empty() || !parts[0].chars().all(|c| c.is_ascii_lowercase()) {
        return false;
    }
    if parts[1].len() != 6 {
        return false;
    }
    parts[1].chars().all(|c| c.is_ascii_digit())
}
