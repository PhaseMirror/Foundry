//! Single-Node Tests for Math Operators
//!
//! Tests the following ONNX math operators in isolation:
//! - Add: Element-wise addition
//! - Sub: Element-wise subtraction
//! - Mul: Element-wise multiplication
//! - Div: Element-wise division

use crate::onnx_single_node::*;
use hologram::Atlas;

#[cfg(test)]
mod test_add {
    use super::*;
    use hologram_onnx_compiler::hrm::ops::{AddOp, OnnxHRMNode};

    #[test]
    fn test_add_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let add_op = AddOp;

        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];
        let expected = vec![5.0, 7.0, 9.0];

        let result = add_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_add_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();
        let add_op = AddOp;

        let test_cases = vec![
            // Zeros
            (
                vec![0.0, 0.0, 0.0],
                vec![1.0, 2.0, 3.0],
                vec![1.0, 2.0, 3.0],
            ),
            // Negatives
            (
                vec![-1.0, -2.0, -3.0],
                vec![1.0, 2.0, 3.0],
                vec![0.0, 0.0, 0.0],
            ),
            // Large values
            (vec![1e6, 1e7], vec![1e6, 1e7], vec![2e6, 2e7]),
            // Single element
            (vec![5.0], vec![10.0], vec![15.0]),
        ];

        for (a, b, expected) in test_cases {
            let result = add_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-3);
        }
    }

    #[test]
    fn test_add_various_shapes() {
        let atlas = Atlas::with_cache().unwrap();
        let add_op = AddOp;

        // Different sizes
        for size in [2, 5, 10, 100].iter() {
            let a: Vec<f32> = (0..*size).map(|i| i as f32).collect();
            let b: Vec<f32> = (0..*size).map(|i| (i * 2) as f32).collect();
            let expected: Vec<f32> = (0..*size).map(|i| (i * 3) as f32).collect();

            let result = add_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_add_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let add_op = AddOp;

        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];

        // Commutative: a + b == b + a
        let result_ab = add_op.execute(&atlas, &[&a, &b]).unwrap();
        let result_ba = add_op.execute(&atlas, &[&b, &a]).unwrap();
        assert_tensors_equal(&result_ab, &result_ba, 1e-6);

        // Identity: a + 0 == a
        let zero = vec![0.0, 0.0, 0.0];
        let result_identity = add_op.execute(&atlas, &[&a, &zero]).unwrap();
        assert_tensors_equal(&result_identity, &a, 1e-6);
    }
}

#[cfg(test)]
mod test_sub {
    use super::*;
    use hologram_onnx_compiler::hrm::ops::{OnnxHRMNode, SubOp};

    #[test]
    fn test_sub_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let sub_op = SubOp;

        let a = vec![5.0, 7.0, 9.0];
        let b = vec![1.0, 2.0, 3.0];
        let expected = vec![4.0, 5.0, 6.0];

        let result = sub_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_sub_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();
        let sub_op = SubOp;

        let test_cases = vec![
            // Zeros
            (
                vec![1.0, 2.0, 3.0],
                vec![0.0, 0.0, 0.0],
                vec![1.0, 2.0, 3.0],
            ),
            // Negatives
            (
                vec![1.0, 2.0, 3.0],
                vec![1.0, 2.0, 3.0],
                vec![0.0, 0.0, 0.0],
            ),
            // Result negative
            (vec![1.0, 2.0], vec![2.0, 4.0], vec![-1.0, -2.0]),
            // Large values
            (vec![1e7, 1e8], vec![1e6, 1e7], vec![9e6, 9e7]),
        ];

        for (a, b, expected) in test_cases {
            let result = sub_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-3);
        }
    }

    #[test]
    fn test_sub_various_shapes() {
        let atlas = Atlas::with_cache().unwrap();
        let sub_op = SubOp;

        // Different sizes
        for size in [2, 5, 10, 50].iter() {
            let a: Vec<f32> = (0..*size).map(|i| (i * 2) as f32).collect();
            let b: Vec<f32> = (0..*size).map(|i| i as f32).collect();
            let expected: Vec<f32> = (0..*size).map(|i| i as f32).collect();

            let result = sub_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_sub_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let sub_op = SubOp;

        let a = vec![5.0, 7.0, 9.0];

        // Identity: a - 0 == a
        let zero = vec![0.0, 0.0, 0.0];
        let result_identity = sub_op.execute(&atlas, &[&a, &zero]).unwrap();
        assert_tensors_equal(&result_identity, &a, 1e-6);

        // Inverse: a - a == 0
        let result_inverse = sub_op.execute(&atlas, &[&a, &a]).unwrap();
        assert_tensors_equal(&result_inverse, &zero, 1e-6);
    }
}

#[cfg(test)]
mod test_mul {
    use super::*;
    use hologram_onnx_compiler::hrm::ops::{MulOp, OnnxHRMNode};

    #[test]
    fn test_mul_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let mul_op = MulOp;

        let a = vec![2.0, 3.0, 4.0];
        let b = vec![5.0, 6.0, 7.0];
        let expected = vec![10.0, 18.0, 28.0];

        let result = mul_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_mul_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();
        let mul_op = MulOp;

        let test_cases = vec![
            // Zeros
            (
                vec![1.0, 2.0, 3.0],
                vec![0.0, 0.0, 0.0],
                vec![0.0, 0.0, 0.0],
            ),
            // Ones (identity)
            (
                vec![5.0, 10.0, 15.0],
                vec![1.0, 1.0, 1.0],
                vec![5.0, 10.0, 15.0],
            ),
            // Negatives
            (vec![-2.0, 3.0], vec![4.0, -5.0], vec![-8.0, -15.0]),
            // Large values
            (vec![1e3, 1e4], vec![1e2, 1e3], vec![1e5, 1e7]),
        ];

        for (a, b, expected) in test_cases {
            let result = mul_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-3);
        }
    }

    #[test]
    fn test_mul_various_shapes() {
        let atlas = Atlas::with_cache().unwrap();
        let mul_op = MulOp;

        // Different sizes
        for size in [2, 5, 10, 50].iter() {
            let a: Vec<f32> = (1..=*size).map(|i| i as f32).collect();
            let b: Vec<f32> = (1..=*size).map(|i| (i * 2) as f32).collect();
            let expected: Vec<f32> = (1..=*size).map(|i| (i * i * 2) as f32).collect();

            let result = mul_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_mul_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let mul_op = MulOp;

        let a = vec![2.0, 3.0, 4.0];
        let b = vec![5.0, 6.0, 7.0];

        // Commutative: a * b == b * a
        let result_ab = mul_op.execute(&atlas, &[&a, &b]).unwrap();
        let result_ba = mul_op.execute(&atlas, &[&b, &a]).unwrap();
        assert_tensors_equal(&result_ab, &result_ba, 1e-6);

        // Identity: a * 1 == a
        let one = vec![1.0, 1.0, 1.0];
        let result_identity = mul_op.execute(&atlas, &[&a, &one]).unwrap();
        assert_tensors_equal(&result_identity, &a, 1e-6);

        // Zero: a * 0 == 0
        let zero = vec![0.0, 0.0, 0.0];
        let result_zero = mul_op.execute(&atlas, &[&a, &zero]).unwrap();
        assert_tensors_equal(&result_zero, &zero, 1e-6);
    }
}

#[cfg(test)]
mod test_div {
    use super::*;
    use hologram_onnx_compiler::hrm::ops::{DivOp, OnnxHRMNode};

    #[test]
    fn test_div_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let div_op = DivOp;

        let a = vec![10.0, 20.0, 30.0];
        let b = vec![2.0, 4.0, 5.0];
        let expected = vec![5.0, 5.0, 6.0];

        let result = div_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_div_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();
        let div_op = DivOp;

        let test_cases = vec![
            // Ones (identity)
            (
                vec![5.0, 10.0, 15.0],
                vec![1.0, 1.0, 1.0],
                vec![5.0, 10.0, 15.0],
            ),
            // Negatives
            (vec![10.0, -20.0], vec![-2.0, 4.0], vec![-5.0, -5.0]),
            // Large values
            (vec![1e6, 1e8], vec![1e3, 1e4], vec![1e3, 1e4]),
            // Fractions
            (vec![1.0, 2.0], vec![2.0, 4.0], vec![0.5, 0.5]),
        ];

        for (a, b, expected) in test_cases {
            let result = div_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-3);
        }
    }

    #[test]
    fn test_div_various_shapes() {
        let atlas = Atlas::with_cache().unwrap();
        let div_op = DivOp;

        // Different sizes
        for size in [2, 5, 10, 50].iter() {
            let a: Vec<f32> = (1..=*size).map(|i| (i * 10) as f32).collect();
            let b: Vec<f32> = (1..=*size).map(|_i| 2.0).collect();
            let expected: Vec<f32> = (1..=*size).map(|i| (i * 5) as f32).collect();

            let result = div_op.execute(&atlas, &[&a, &b]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_div_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let div_op = DivOp;

        let a = vec![10.0, 20.0, 30.0];

        // Identity: a / 1 == a
        let one = vec![1.0, 1.0, 1.0];
        let result_identity = div_op.execute(&atlas, &[&a, &one]).unwrap();
        assert_tensors_equal(&result_identity, &a, 1e-6);

        // Self-division: a / a == 1
        let result_self = div_op.execute(&atlas, &[&a, &a]).unwrap();
        assert_tensors_equal(&result_self, &one, 1e-6);
    }
}
