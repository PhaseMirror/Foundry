use drmm_ir_parser::{canonical_hash, canonicalize, parse_ir_file, validate_ir, IrDocument};
use std::collections::HashMap;

#[test]
fn test_valid_identity() {
    let doc = parse_ir_file("tests/valid/identity.json").unwrap();
    assert_eq!(doc.ir_version, "1.0.0");
    assert_eq!(doc.schema_version, "1.0.0");
    assert_eq!(doc.layer, drmm_ir_parser::IrLayer::Core);
    assert_eq!(doc.nodes.len(), 2);
    assert_eq!(doc.nodes[0].id(), "op_000001");
    assert_eq!(doc.nodes[1].id(), "lit_000002");
}

#[test]
fn test_missing_version() {
    let result = parse_ir_file("tests/invalid/missing_version.json");
    assert!(result.is_err());
}

#[test]
fn test_bad_id() {
    let result = parse_ir_file("tests/invalid/bad_id.json");
    assert!(result.is_err());
}

#[test]
fn test_canonical_hash_deterministic() {
    let doc = parse_ir_file("tests/valid/identity.json").unwrap();
    let hash1 = canonical_hash(&doc).unwrap();
    let hash2 = canonical_hash(&doc).unwrap();
    assert_eq!(hash1, hash2);
    assert_eq!(hash1.len(), 64);
}

#[test]
fn test_canonicalize_stable() {
    let doc = parse_ir_file("tests/valid/identity.json").unwrap();
    let json = canonicalize(&doc).unwrap();
    let reparsed: IrDocument = serde_json::from_str(&json).unwrap();
    assert_eq!(reparsed.ir_version, "1.0.0");
}

#[test]
fn test_duplicate_id_in_nodes() {
    let mut doc = parse_ir_file("tests/valid/identity.json").unwrap();
    doc.nodes.push(drmm_ir_parser::Expr::Literal {
        id: "op_000001".to_string(),
        value: drmm_ir_parser::LiteralValue::Integer(1),
        metadata: HashMap::new(),
    });
    let result = validate_ir(&doc);
    assert!(matches!(
        result,
        Err(drmm_ir_parser::IrError::DuplicateId(_))
    ));
}

#[test]
fn test_tensor_shape_mismatch() {
    let mut doc = parse_ir_file("tests/valid/identity.json").unwrap();
    doc.nodes.clear();
    doc.nodes.push(drmm_ir_parser::Expr::Tensor {
        id: "ten_000001".to_string(),
        rank: 2,
        shape: vec![3],
        scalar_type: drmm_ir_parser::ScalarType::Real,
        metadata: HashMap::new(),
    });
    let result = validate_ir(&doc);
    assert!(matches!(
        result,
        Err(drmm_ir_parser::IrError::TensorShapeMismatch)
    ));
}

#[test]
fn test_iteration_count_zero() {
    let mut doc = parse_ir_file("tests/valid/identity.json").unwrap();
    doc.nodes.clear();
    doc.nodes.push(drmm_ir_parser::Expr::Iterate {
        id: "itr_000001".to_string(),
        iterations: drmm_ir_parser::IterationSpec::FixedCount { count: 0 },
        operator: Box::new(drmm_ir_parser::Expr::Operator {
            id: "op_000001".to_string(),
            name: "identity".to_string(),
            params: HashMap::new(),
            metadata: HashMap::new(),
        }),
        input: Box::new(drmm_ir_parser::Expr::Literal {
            id: "lit_000001".to_string(),
            value: drmm_ir_parser::LiteralValue::Integer(0),
            metadata: HashMap::new(),
        }),
        metadata: HashMap::new(),
    });
    let result = validate_ir(&doc);
    assert!(matches!(
        result,
        Err(drmm_ir_parser::IrError::IterationCountZero)
    ));
}

#[test]
fn test_empty_branch() {
    let mut doc = parse_ir_file("tests/valid/identity.json").unwrap();
    doc.nodes.clear();
    doc.nodes.push(drmm_ir_parser::Expr::Branch {
        id: "brn_000001".to_string(),
        conditions: vec![],
        default: None,
        metadata: HashMap::new(),
    });
    let result = validate_ir(&doc);
    assert!(matches!(result, Err(drmm_ir_parser::IrError::EmptyBranch)));
}
