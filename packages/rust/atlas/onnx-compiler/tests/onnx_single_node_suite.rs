//! Single-Node ONNX Operator Test Suite
//!
//! This test suite validates individual ONNX operators in isolation.

mod onnx_single_node;

// Operator test modules
#[path = "onnx_single_node/test_math.rs"]
mod test_math;

#[path = "onnx_single_node/test_matrix.rs"]
mod test_matrix;

#[path = "onnx_single_node/test_activation.rs"]
mod test_activation;

#[path = "onnx_single_node/test_tensor_manipulation.rs"]
mod test_tensor_manipulation;

#[path = "onnx_single_node/test_utility.rs"]
mod test_utility;

#[path = "onnx_single_node/test_normalization.rs"]
mod test_normalization;

#[cfg(test)]
mod infrastructure_tests {
    use super::onnx_single_node::*;

    #[test]
    fn test_infrastructure_zeros() {
        let z = zeros(5);
        assert_eq!(z, vec![0.0, 0.0, 0.0, 0.0, 0.0]);
    }

    #[test]
    fn test_infrastructure_ones() {
        let o = ones(3);
        assert_eq!(o, vec![1.0, 1.0, 1.0]);
    }

    #[test]
    fn test_infrastructure_range() {
        let r = range(0.0, 5);
        assert_eq!(r, vec![0.0, 1.0, 2.0, 3.0, 4.0]);
    }

    #[test]
    fn test_infrastructure_identity_matrix() {
        let i = identity_matrix(3);
        assert_eq!(i, vec![1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,]);
    }

    #[test]
    fn test_infrastructure_assert_tensors_equal() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![1.0001, 2.0001, 3.0001];
        assert_tensors_equal(&a, &b, 1e-3);
    }

    #[test]
    #[should_panic(expected = "Values don't match")]
    fn test_infrastructure_assert_tensors_equal_fails() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![1.1, 2.0, 3.0];
        assert_tensors_equal(&a, &b, 1e-6);
    }

    #[test]
    fn test_infrastructure_assert_sum_equals() {
        let t = vec![0.25, 0.25, 0.25, 0.25];
        assert_sum_equals(&t, 1.0, 1e-6);
    }

    #[test]
    fn test_infrastructure_onnx_graph_builder() {
        use hologram_onnx_compiler::proto::tensor_proto::DataType;

        let graph = OnnxGraphBuilder::new()
            .add_input("a", &[3], DataType::Float)
            .add_input("b", &[3], DataType::Float)
            .add_node("Add", &["a", "b"], &["output"])
            .add_output("output", &[3], DataType::Float)
            .build();

        assert_eq!(graph.graph.as_ref().unwrap().node.len(), 1);
        assert_eq!(graph.graph.as_ref().unwrap().input.len(), 2);
        assert_eq!(graph.graph.as_ref().unwrap().output.len(), 1);

        let node = &graph.graph.as_ref().unwrap().node[0];
        assert_eq!(node.op_type, "Add");
        assert_eq!(node.input, vec!["a", "b"]);
        assert_eq!(node.output, vec!["output"]);
    }
}
