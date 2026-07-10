//! Single-Node Tests for Matrix Operators
//!
//! Tests the following ONNX matrix operators in isolation:
//! - MatMul: Matrix multiplication (N-D with broadcasting)
//! - Gemm: General matrix multiplication (Y = alpha*A@B + beta*C)

use crate::onnx_single_node::*;
use hologram::Atlas;
use hologram_onnx_compiler::hrm::ops::{GemmOp, MatMulOp, OnnxHRMNode};

#[cfg(test)]
mod test_matmul {
    use super::*;

    #[test]
    fn test_matmul_dot_product() {
        let atlas = Atlas::with_cache().unwrap();
        let matmul_op = MatMulOp::new();

        // Dot product: [3] × [3] → [1]
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];
        // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
        let expected = vec![32.0];

        let result = matmul_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_matmul_matrix_vector() {
        let atlas = Atlas::with_cache().unwrap();
        let matmul_op = MatMulOp::new();

        // Matrix-vector: [2, 3] × [3] → [2]
        let a = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0]; // 2x3 matrix (flattened)
        let b = vec![7.0, 8.0, 9.0]; // 3-vector
                                     // Row 0: 1*7 + 2*8 + 3*9 = 7 + 16 + 27 = 50
                                     // Row 1: 4*7 + 5*8 + 6*9 = 28 + 40 + 54 = 122
        let expected = vec![50.0, 122.0];

        let result = matmul_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_matmul_vector_matrix() {
        let atlas = Atlas::with_cache().unwrap();
        let matmul_op = MatMulOp::new();

        // Vector-matrix: [3] × [3*2] → [2]
        let a = vec![1.0, 2.0, 3.0]; // 3-vector
        let b = vec![4.0, 5.0, 6.0, 7.0, 8.0, 9.0]; // 3x2 matrix (flattened)
                                                    // Col 0: 1*4 + 2*6 + 3*8 = 4 + 12 + 24 = 40
                                                    // Col 1: 1*5 + 2*7 + 3*9 = 5 + 14 + 27 = 46
        let expected = vec![40.0, 46.0];

        let result = matmul_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_matmul_from_shapes() {
        // Test shape validation
        let shapes = vec![vec![2, 3], vec![3, 4]];
        let result = MatMulOp::from_shapes(&shapes);
        assert!(result.is_ok());

        // Invalid shapes - inner dimensions don't match
        let shapes = vec![vec![2, 3], vec![4, 5]];
        let result = MatMulOp::from_shapes(&shapes);
        assert!(result.is_err());
    }
}

#[cfg(test)]
mod test_gemm {
    use super::*;

    #[test]
    fn test_gemm_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let gemm_op = GemmOp::new(1.0, 0.0, false, false); // alpha=1.0, beta=0.0

        // With alpha=1, beta=0: Y = A@B
        // Dot product: 1*5 + 2*6 + 3*7 = 5 + 12 + 21 = 38
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![5.0, 6.0, 7.0];
        let c = vec![0.0]; // Not used when beta=0
        let expected = vec![38.0];

        let result = gemm_op.execute(&atlas, &[&a, &b, &c]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gemm_with_alpha() {
        let atlas = Atlas::with_cache().unwrap();
        let gemm_op = GemmOp::new(2.0, 0.0, false, false); // alpha=2.0, beta=0.0

        // Y = 2.0 * (A·B)
        // A·B = 1*5 + 2*6 + 3*7 = 38
        // Y = 2.0 * 38 = 76
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![5.0, 6.0, 7.0];
        let c = vec![0.0];
        let expected = vec![76.0];

        let result = gemm_op.execute(&atlas, &[&a, &b, &c]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gemm_with_beta() {
        let atlas = Atlas::with_cache().unwrap();
        let gemm_op = GemmOp::new(1.0, 1.0, false, false); // alpha=1.0, beta=1.0

        // Y = A·B + C
        // A·B = 1*5 + 2*6 + 3*7 = 38
        // Y = 38 + 10 = 48
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![5.0, 6.0, 7.0];
        let c = vec![10.0];
        let expected = vec![48.0];

        let result = gemm_op.execute(&atlas, &[&a, &b, &c]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gemm_with_alpha_beta() {
        let atlas = Atlas::with_cache().unwrap();
        let gemm_op = GemmOp::new(2.0, 0.5, false, false); // alpha=2.0, beta=0.5

        // Y = 2.0 * (A·B) + 0.5 * C
        // A·B = 1*5 + 2*6 + 3*7 = 38
        // Y = 2.0 * 38 + 0.5 * 10 = 76 + 5 = 81
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![5.0, 6.0, 7.0];
        let c = vec![10.0];
        let expected = vec![81.0];

        let result = gemm_op.execute(&atlas, &[&a, &b, &c]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gemm_default_params() {
        let gemm_op = GemmOp::default();
        assert_eq!(gemm_op.alpha, 1.0);
        assert_eq!(gemm_op.beta, 1.0);
        assert!(!gemm_op.trans_a);
        assert!(!gemm_op.trans_b);
    }

    #[test]
    fn test_gemm_from_shapes() {
        // Test shape validation
        let shapes = vec![vec![2, 3], vec![3, 4]];
        let result = GemmOp::from_shapes(&shapes);
        assert!(result.is_ok());
        let gemm_op = result.unwrap();
        assert_eq!(gemm_op.alpha, 1.0);
        assert_eq!(gemm_op.beta, 1.0);
    }
}
