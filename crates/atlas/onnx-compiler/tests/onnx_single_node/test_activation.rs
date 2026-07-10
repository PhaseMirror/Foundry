//! Single-Node Tests for Activation Operators
//!
//! Tests the following ONNX activation operators in isolation:
//! - Relu: ReLU activation (max(0, x))
//! - Sigmoid: Sigmoid activation (1 / (1 + exp(-x)))
//! - Tanh: Hyperbolic tangent activation

use crate::onnx_single_node::*;
use hologram::Atlas;
use hologram_onnx_compiler::hrm::ops::{OnnxHRMNode, ReluOp, SigmoidOp, TanhOp};

#[cfg(test)]
mod test_relu {
    use super::*;

    #[test]
    fn test_relu_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let relu_op = ReluOp;

        let input = vec![-2.0, -1.0, 0.0, 1.0, 2.0];
        let expected = vec![0.0, 0.0, 0.0, 1.0, 2.0];

        let result = relu_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_relu_all_negative() {
        let atlas = Atlas::with_cache().unwrap();
        let relu_op = ReluOp;

        let input = vec![-5.0, -10.0, -100.0];
        let expected = vec![0.0, 0.0, 0.0];

        let result = relu_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_relu_all_positive() {
        let atlas = Atlas::with_cache().unwrap();
        let relu_op = ReluOp;

        let input = vec![1.0, 5.0, 10.0, 100.0];
        let expected = input.clone();

        let result = relu_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_relu_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let relu_op = ReluOp;

        // Test various sizes
        for size in [5, 10, 50, 100].iter() {
            let input: Vec<f32> = (0..*size)
                .map(|i| i as f32 - (*size as f32 / 2.0))
                .collect();
            let result = relu_op.execute(&atlas, &[&input]).unwrap();

            // Verify all results are non-negative
            assert!(result.iter().all(|&x| x >= 0.0));

            // Verify positive values unchanged
            for (i, &val) in input.iter().enumerate() {
                if val > 0.0 {
                    assert!((result[i] - val).abs() < 1e-6);
                }
            }
        }
    }
}

#[cfg(test)]
mod test_sigmoid {
    use super::*;

    #[test]
    fn test_sigmoid_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let sigmoid_op = SigmoidOp;

        // sigmoid(0) = 0.5
        let input = vec![0.0];
        let expected = vec![0.5];

        let result = sigmoid_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_sigmoid_known_values() {
        let atlas = Atlas::with_cache().unwrap();
        let sigmoid_op = SigmoidOp;

        // Known sigmoid values
        let input = vec![-2.0, -1.0, 0.0, 1.0, 2.0];
        let expected = vec![
            0.1192029, // sigmoid(-2)
            0.2689414, // sigmoid(-1)
            0.5,       // sigmoid(0)
            0.7310586, // sigmoid(1)
            0.8807971, // sigmoid(2)
        ];

        let result = sigmoid_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-5);
    }

    #[test]
    fn test_sigmoid_extreme_values() {
        let atlas = Atlas::with_cache().unwrap();
        let sigmoid_op = SigmoidOp;

        // Large positive → ~1.0
        let large_pos = vec![10.0, 20.0];
        let result_pos = sigmoid_op.execute(&atlas, &[&large_pos]).unwrap();
        assert!(result_pos.iter().all(|&x| x > 0.99 && x <= 1.0));

        // Large negative → ~0.0
        let large_neg = vec![-10.0, -20.0];
        let result_neg = sigmoid_op.execute(&atlas, &[&large_neg]).unwrap();
        assert!(result_neg.iter().all(|&x| (0.0..0.01).contains(&x)));
    }

    #[test]
    fn test_sigmoid_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let sigmoid_op = SigmoidOp;

        let input = vec![-5.0, -2.0, 0.0, 2.0, 5.0];
        let result = sigmoid_op.execute(&atlas, &[&input]).unwrap();

        // All values in (0, 1)
        assert!(result.iter().all(|&x| x > 0.0 && x < 1.0));

        // Symmetric property: sigmoid(-x) = 1 - sigmoid(x)
        for i in 0..input.len() {
            let neg_input = vec![-input[i]];
            let neg_result = sigmoid_op.execute(&atlas, &[&neg_input]).unwrap();
            let sum = result[i] + neg_result[0];
            assert!((sum - 1.0_f32).abs() < 1e-5, "sigmoid symmetry failed");
        }
    }
}

#[cfg(test)]
mod test_tanh {
    use super::*;

    #[test]
    fn test_tanh_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let tanh_op = TanhOp;

        // tanh(0) = 0
        let input = vec![0.0];
        let expected = vec![0.0];

        let result = tanh_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_tanh_known_values() {
        let atlas = Atlas::with_cache().unwrap();
        let tanh_op = TanhOp;

        // Known tanh values
        let input = vec![-2.0, -1.0, 0.0, 1.0, 2.0];
        let expected = vec![
            -0.9640276, // tanh(-2)
            -0.7615942, // tanh(-1)
            0.0,        // tanh(0)
            0.7615942,  // tanh(1)
            0.9640276,  // tanh(2)
        ];

        let result = tanh_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-5);
    }

    #[test]
    fn test_tanh_extreme_values() {
        let atlas = Atlas::with_cache().unwrap();
        let tanh_op = TanhOp;

        // Large positive → ~1.0
        let large_pos = vec![10.0, 20.0];
        let result_pos = tanh_op.execute(&atlas, &[&large_pos]).unwrap();
        assert!(result_pos.iter().all(|&x| x > 0.99 && x <= 1.0));

        // Large negative → ~-1.0
        let large_neg = vec![-10.0, -20.0];
        let result_neg = tanh_op.execute(&atlas, &[&large_neg]).unwrap();
        assert!(result_neg.iter().all(|&x| (-1.0..-0.99).contains(&x)));
    }

    #[test]
    fn test_tanh_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let tanh_op = TanhOp;

        let input = vec![-5.0, -2.0, 0.0, 2.0, 5.0];
        let result = tanh_op.execute(&atlas, &[&input]).unwrap();

        // All values in (-1, 1)
        assert!(result.iter().all(|&x| x > -1.0 && x < 1.0));

        // Odd function property: tanh(-x) = -tanh(x)
        for i in 0..input.len() {
            let neg_input = vec![-input[i]];
            let neg_result = tanh_op.execute(&atlas, &[&neg_input]).unwrap();
            let diff = (result[i] + neg_result[0]) as f32;
            assert!(diff.abs() < 1e-5, "tanh odd function property failed");
        }
    }
}
