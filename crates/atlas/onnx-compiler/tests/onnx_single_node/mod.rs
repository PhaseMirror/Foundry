//! Single-Node ONNX Operator Test Infrastructure
//!
//! This module provides utilities for testing individual ONNX operators in isolation.
//! Each operator is tested using single-node ONNX graphs with deterministic inputs
//! and known expected outputs.
//!
//! # Testing Strategy
//!
//! Single-node tests verify that each operator works correctly in isolation by:
//! - Creating minimal test cases with known inputs and outputs

#![allow(dead_code)]
#![allow(clippy::wrong_self_convention)]
//! - Testing edge cases (zeros, negatives, boundaries, special values)
//! - Testing various tensor shapes and dimensions
//! - Verifying numerical accuracy
//!
//! # Example
//!
//! ```
//! use hologram::Atlas;
//! use hologram_onnx_compiler::hrm::ops::{AddOp, OnnxHRMNode};
//!
//! let atlas = Atlas::with_cache().unwrap();
//! let add_op = AddOp;
//!
//! let a = vec![1.0_f32, 2.0, 3.0];
//! let b = vec![4.0_f32, 5.0, 6.0];
//! let expected = vec![5.0_f32, 7.0, 9.0];
//!
//! let result = add_op.execute(&atlas, &[&a, &b]).unwrap();
//! assert_tensors_equal(&result, &expected, 1e-6);
//! ```

use hologram::Atlas;
use hologram_onnx_compiler::hrm::ops::OnnxHRMNode;
use hologram_onnx_compiler::proto::tensor_proto::DataType;
use hologram_onnx_compiler::proto::tensor_shape_proto::{dimension::Value as DimValue, Dimension};
use hologram_onnx_compiler::proto::type_proto::Value as TypeValue;
use hologram_onnx_compiler::proto::{
    AttributeProto, GraphProto, ModelProto, NodeProto, TypeProto, ValueInfoProto,
};
use hologram_onnx_compiler::Result;

// ============================================================================
// Test Data Generation
// ============================================================================

/// Generate tensor filled with zeros
pub fn zeros(size: usize) -> Vec<f32> {
    vec![0.0; size]
}

/// Generate tensor filled with ones
pub fn ones(size: usize) -> Vec<f32> {
    vec![1.0; size]
}

/// Generate tensor with sequential values (0, 1, 2, ...)
pub fn range(start: f32, count: usize) -> Vec<f32> {
    (0..count).map(|i| start + i as f32).collect()
}

/// Generate tensor with sequential values from start to end with step
pub fn range_step(start: f32, end: f32, step: f32) -> Vec<f32> {
    let mut result = Vec::new();
    let mut current = start;
    while current < end {
        result.push(current);
        current += step;
    }
    result
}

/// Generate identity matrix (square matrix with 1s on diagonal)
pub fn identity_matrix(n: usize) -> Vec<f32> {
    let mut matrix = vec![0.0; n * n];
    for i in 0..n {
        matrix[i * n + i] = 1.0;
    }
    matrix
}

/// Generate matrix from nested vectors (row-major order)
pub fn matrix_from_rows(rows: &[Vec<f32>]) -> Vec<f32> {
    rows.iter().flat_map(|row| row.iter().copied()).collect()
}

/// Create custom tensor from values
pub fn custom(values: Vec<f32>) -> Vec<f32> {
    values
}

// ============================================================================
// Output Validation
// ============================================================================

/// Assert two tensors are equal within tolerance
pub fn assert_tensors_equal(actual: &[f32], expected: &[f32], tolerance: f32) {
    assert_eq!(
        actual.len(),
        expected.len(),
        "Tensor sizes don't match: actual={}, expected={}",
        actual.len(),
        expected.len()
    );

    for (i, (&a, &e)) in actual.iter().zip(expected.iter()).enumerate() {
        let diff = (a - e).abs();
        assert!(
            diff <= tolerance,
            "Values don't match at index {}: actual={}, expected={}, diff={}, tolerance={}",
            i,
            a,
            e,
            diff,
            tolerance
        );
    }
}

/// Assert tensor shape matches expected dimensions
pub fn assert_shape_equal(actual: &[usize], expected: &[usize]) {
    assert_eq!(
        actual, expected,
        "Shapes don't match: actual={:?}, expected={:?}",
        actual, expected
    );
}

/// Verify all values are finite (not NaN or Inf)
pub fn assert_all_finite(tensor: &[f32]) {
    for (i, &val) in tensor.iter().enumerate() {
        assert!(val.is_finite(), "Non-finite value at index {}: {}", i, val);
    }
}

/// Verify tensor sums to expected value within tolerance
pub fn assert_sum_equals(tensor: &[f32], expected_sum: f32, tolerance: f32) {
    let actual_sum: f32 = tensor.iter().sum();
    let diff = (actual_sum - expected_sum).abs();
    assert!(
        diff <= tolerance,
        "Sum doesn't match: actual={}, expected={}, diff={}, tolerance={}",
        actual_sum,
        expected_sum,
        diff,
        tolerance
    );
}

// ============================================================================
// ONNX Graph Builder
// ============================================================================

/// Builder for creating ONNX graphs programmatically
///
/// This is primarily for reference and documentation. Most tests will
/// directly use the OnnxHRMNode trait instead of full ONNX graphs.
///
/// # Example
///
/// ```
/// let graph = OnnxGraphBuilder::new()
///     .add_input("a", &[3], DataType::Float)
///     .add_input("b", &[3], DataType::Float)
///     .add_node("Add", &["a", "b"], &["output"])
///     .add_output("output", &[3], DataType::Float)
///     .build();
/// ```
pub struct OnnxGraphBuilder {
    nodes: Vec<NodeProto>,
    inputs: Vec<ValueInfoProto>,
    outputs: Vec<ValueInfoProto>,
    current_attributes: Vec<AttributeProto>,
}

impl OnnxGraphBuilder {
    /// Create new graph builder
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            inputs: Vec::new(),
            outputs: Vec::new(),
            current_attributes: Vec::new(),
        }
    }

    /// Add input tensor specification
    pub fn add_input(mut self, name: &str, shape: &[i64], dtype: DataType) -> Self {
        self.inputs
            .push(Self::create_value_info(name, shape, dtype));
        self
    }

    /// Add output tensor specification
    pub fn add_output(mut self, name: &str, shape: &[i64], dtype: DataType) -> Self {
        self.outputs
            .push(Self::create_value_info(name, shape, dtype));
        self
    }

    /// Add operator node
    pub fn add_node(mut self, op_type: &str, inputs: &[&str], outputs: &[&str]) -> Self {
        let node = NodeProto {
            input: inputs.iter().map(|s| s.to_string()).collect(),
            output: outputs.iter().map(|s| s.to_string()).collect(),
            name: format!("{}_node", op_type.to_lowercase()),
            op_type: op_type.to_string(),
            domain: String::new(),
            attribute: self.current_attributes.clone(),
            doc_string: String::new(),
            device_configurations: Vec::new(),
            metadata_props: Vec::new(),
            overload: String::new(),
        };
        self.nodes.push(node);
        self.current_attributes.clear();
        self
    }

    /// Add integer attribute to next node
    pub fn add_int_attribute(mut self, name: &str, value: i64) -> Self {
        use hologram_onnx_compiler::proto::attribute_proto::AttributeType;

        self.current_attributes.push(AttributeProto {
            name: name.to_string(),
            ref_attr_name: String::new(),
            doc_string: String::new(),
            r#type: AttributeType::Int as i32,
            f: 0.0,
            i: value,
            s: Vec::new(),
            t: None,
            g: None,
            sparse_tensor: None,
            tp: None,
            floats: Vec::new(),
            ints: Vec::new(),
            strings: Vec::new(),
            tensors: Vec::new(),
            graphs: Vec::new(),
            sparse_tensors: Vec::new(),
            type_protos: Vec::new(),
        });
        self
    }

    /// Add float attribute to next node
    pub fn add_float_attribute(mut self, name: &str, value: f32) -> Self {
        use hologram_onnx_compiler::proto::attribute_proto::AttributeType;

        self.current_attributes.push(AttributeProto {
            name: name.to_string(),
            ref_attr_name: String::new(),
            doc_string: String::new(),
            r#type: AttributeType::Float as i32,
            f: value,
            i: 0,
            s: Vec::new(),
            t: None,
            g: None,
            sparse_tensor: None,
            tp: None,
            floats: Vec::new(),
            ints: Vec::new(),
            strings: Vec::new(),
            tensors: Vec::new(),
            graphs: Vec::new(),
            sparse_tensors: Vec::new(),
            type_protos: Vec::new(),
        });
        self
    }

    /// Build final ModelProto
    pub fn build(self) -> ModelProto {
        let graph = GraphProto {
            node: self.nodes,
            name: "test_graph".to_string(),
            initializer: Vec::new(),
            sparse_initializer: Vec::new(),
            doc_string: String::new(),
            input: self.inputs,
            output: self.outputs,
            value_info: Vec::new(),
            quantization_annotation: Vec::new(),
            metadata_props: Vec::new(),
        };

        ModelProto {
            ir_version: 8,
            opset_import: Vec::new(),
            producer_name: "hologram_test_suite".to_string(),
            producer_version: "1.0".to_string(),
            domain: String::new(),
            model_version: 1,
            doc_string: "Single-node operator test".to_string(),
            graph: Some(graph),
            metadata_props: Vec::new(),
            training_info: Vec::new(),
            functions: Vec::new(),
            configuration: Vec::new(),
        }
    }

    /// Serialize to ONNX binary format
    pub fn to_bytes(self) -> Result<Vec<u8>> {
        use prost::Message;
        let model = self.build();
        let mut buf = Vec::new();
        model.encode(&mut buf).map_err(|e| {
            hologram_onnx_compiler::CompilerError::ParseError(format!("Failed to encode: {}", e))
        })?;
        Ok(buf)
    }

    // Helper to create ValueInfoProto
    fn create_value_info(name: &str, shape: &[i64], dtype: DataType) -> ValueInfoProto {
        use hologram_onnx_compiler::proto::TensorShapeProto;

        let dims: Vec<Dimension> = shape
            .iter()
            .map(|&dim| Dimension {
                denotation: String::new(),
                value: Some(DimValue::DimValue(dim)),
            })
            .collect();

        let shape_proto = TensorShapeProto { dim: dims };

        let tensor_type = hologram_onnx_compiler::proto::type_proto::Tensor {
            elem_type: dtype as i32,
            shape: Some(shape_proto),
        };

        ValueInfoProto {
            name: name.to_string(),
            r#type: Some(TypeProto {
                denotation: String::new(),
                value: Some(TypeValue::TensorType(tensor_type)),
            }),
            doc_string: String::new(),
            metadata_props: Vec::new(),
        }
    }
}

impl Default for OnnxGraphBuilder {
    fn default() -> Self {
        Self::new()
    }
}

// ============================================================================
// Test Execution Helpers
// ============================================================================

/// Execute operator with given inputs and return result
///
/// This is a convenience wrapper around OnnxHRMNode::execute that handles
/// Atlas initialization.
pub fn execute_operator<T, Op>(op: &Op, inputs: &[&[T]]) -> Result<Vec<T>>
where
    T: hologram_onnx_compiler::hrm::numeric::Numeric,
    Op: OnnxHRMNode<T>,
{
    let atlas = Atlas::with_cache()?;
    op.execute(&atlas, inputs)
}

/// Test case for an operator
pub struct OperatorTestCase<T> {
    pub name: &'static str,
    pub inputs: Vec<Vec<T>>,
    pub expected: Vec<T>,
    pub tolerance: f32,
}

impl<T: Clone> OperatorTestCase<T> {
    /// Create new test case
    pub fn new(name: &'static str, inputs: Vec<Vec<T>>, expected: Vec<T>, tolerance: f32) -> Self {
        Self {
            name,
            inputs,
            expected,
            tolerance,
        }
    }
}

/// Run multiple test cases for an operator
pub fn run_test_cases<T, Op>(op: &Op, test_cases: Vec<OperatorTestCase<T>>) -> Result<()>
where
    T: hologram_onnx_compiler::hrm::numeric::Numeric,
    Op: OnnxHRMNode<T>,
{
    let atlas = Atlas::with_cache()?;

    for test_case in test_cases {
        // Convert Vec<Vec<T>> to Vec<&[T]> for execute
        let input_refs: Vec<&[T]> = test_case.inputs.iter().map(|v| v.as_slice()).collect();

        let result = op.execute(&atlas, &input_refs).map_err(|e| {
            hologram_onnx_compiler::CompilerError::ParseError(format!(
                "Test case '{}' failed: {}",
                test_case.name, e
            ))
        })?;

        // Convert result and expected to f32 slices for comparison
        let result_f32: Vec<f32> = result.iter().map(|x| x.to_f32()).collect();
        let expected_f32: Vec<f32> = test_case.expected.iter().map(|x| x.to_f32()).collect();

        assert_tensors_equal(&result_f32, &expected_f32, test_case.tolerance);
    }

    Ok(())
}

// ============================================================================
// Test Generation Macros
// ============================================================================

/// Generate a basic operator test
///
/// Creates a test function that:
/// - Sets up Atlas
/// - Creates operator
/// - Executes with given inputs
/// - Asserts result matches expected
///
/// # Example
///
/// ```ignore
/// test_operator_basic! {
///     test_add_basic,
///     AddOp,
///     inputs: [vec![1.0, 2.0, 3.0], vec![4.0, 5.0, 6.0]],
///     expected: vec![5.0, 7.0, 9.0],
///     tolerance: 1e-6
/// }
/// ```
#[macro_export]
macro_rules! test_operator_basic {
    (
        $test_name:ident,
        $op_init:expr,
        inputs: [$($input:expr),+ $(,)?],
        expected: $expected:expr,
        tolerance: $tolerance:expr
    ) => {
        #[test]
        fn $test_name() {
            let atlas = hologram::Atlas::with_cache().unwrap();
            let op = $op_init;

            let result = op.execute(&atlas, &[$(&$input),+]).unwrap();
            $crate::onnx_single_node::assert_tensors_equal(&result, &$expected, $tolerance);
        }
    };
}

/// Generate an edge cases test with multiple test cases
///
/// Creates a test function that loops through multiple test cases,
/// executing each and asserting the result.
///
/// # Example
///
/// ```ignore
/// test_operator_edge_cases! {
///     test_add_edge_cases,
///     AddOp,
///     test_cases: [
///         // Zeros
///         (vec![0.0, 0.0], vec![1.0, 2.0], vec![1.0, 2.0]),
///         // Negatives
///         (vec![-1.0, -2.0], vec![1.0, 2.0], vec![0.0, 0.0]),
///     ],
///     tolerance: 1e-6
/// }
/// ```
#[macro_export]
macro_rules! test_operator_edge_cases {
    (
        $test_name:ident,
        $op_init:expr,
        test_cases: [$(($($input:expr),+ , $expected:expr)),* $(,)?],
        tolerance: $tolerance:expr
    ) => {
        #[test]
        fn $test_name() {
            let atlas = hologram_hrm::Atlas::with_cache().unwrap();
            let op = $op_init;

            $(
                let result = op.execute(&atlas, &[$(&$input),+]).unwrap();
                $crate::onnx_single_node::assert_tensors_equal(&result, &$expected, $tolerance);
            )*
        }
    };
}

/// Generate test module for an operator
///
/// Creates a complete test module with basic structure for an operator.
///
/// # Example
///
/// ```ignore
/// test_operator_module! {
///     test_add,
///     AddOp,
///     {
///         #[test]
///         fn test_add_basic() {
///             // Test implementation
///         }
///
///         #[test]
///         fn test_add_properties() {
///             // Test implementation
///         }
///     }
/// }
/// ```
#[macro_export]
macro_rules! test_operator_module {
    (
        $mod_name:ident,
        $op_type:ty,
        { $($test_content:item)* }
    ) => {
        #[cfg(test)]
        mod $mod_name {
            use super::*;
            use hologram::Atlas;
            use hologram_onnx_compiler::hrm::ops::{$op_type, OnnxHRMNode};

            $($test_content)*
        }
    };
}

/// Helper macro to execute operator and unwrap result
///
/// Reduces boilerplate for operator execution in tests.
///
/// # Example
///
/// ```ignore
/// let atlas = Atlas::with_cache().unwrap();
/// let op = AddOp;
/// let a = vec![1.0, 2.0];
/// let b = vec![3.0, 4.0];
///
/// let result = execute_op!(atlas, op, [&a, &b]);
/// ```
#[macro_export]
macro_rules! execute_op {
    ($atlas:expr, $op:expr, [$($input:expr),+ $(,)?]) => {
        $op.execute(&$atlas, &[$($input),+]).unwrap()
    };
}

/// Helper macro to setup test with Atlas and operator
///
/// Reduces the repetitive setup code in tests.
///
/// # Example
///
/// ```ignore
/// setup_test!(AddOp => atlas, op);
/// // Now you have `atlas` and `op` variables ready to use
/// ```
#[macro_export]
macro_rules! setup_test {
    ($op_init:expr => $atlas:ident, $op:ident) => {
        let $atlas = hologram::Atlas::with_cache().unwrap();
        let $op = $op_init;
    };
}

// ============================================================================
// Re-exports for convenience
// ============================================================================

// Re-export commonly used items for convenience in test files
pub use hologram_onnx_compiler::hrm::numeric::Numeric;

// ============================================================================
// Test Modules
// ============================================================================

mod generated_tests;
