//! Single-Node Tests for Utility Operators
//!
//! Tests the following ONNX utility/shape operators in isolation:
//! - Constant: Return a constant tensor
//! - Range: Generate a range of values
//! - Shape: Return the shape of input
//! - ArgMax: Find index of maximum value
//! - Transpose: Transpose tensor dimensions
//! - Squeeze: Remove dimensions of size 1

use crate::onnx_single_node::*;
use hologram::Atlas;
use hologram_onnx_compiler::hrm::ops::{
    ArgMaxOp, ConstantOp, OnnxHRMNode, RangeOp, ShapeOp, SqueezeOp, TransposeOp,
};

#[cfg(test)]
mod test_constant {
    use super::*;

    #[test]
    fn test_constant_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let constant_op = ConstantOp::new(vec![1.0, 2.0, 3.0]);

        let expected = vec![1.0, 2.0, 3.0];

        let result = constant_op.execute(&atlas, &[]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_constant_single_value() {
        let atlas = Atlas::with_cache().unwrap();
        let constant_op = ConstantOp::new(vec![42.0]);

        let expected = vec![42.0];

        let result = constant_op.execute(&atlas, &[]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_constant_various_values() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            // Integers
            vec![1.0, 2.0, 3.0, 4.0, 5.0],
            // Floats
            vec![1.5, 2.7, 3.9],
            // Negatives
            vec![-1.0, -2.0, -3.0],
            // Mixed
            vec![-1.5, 0.0, 1.5, 3.0],
            // Large values
            vec![1e6, 1e7, 1e8],
        ];

        for expected in test_cases {
            let constant_op = ConstantOp::new(expected.clone());
            let result = constant_op.execute(&atlas, &[]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-3);
        }
    }

    #[test]
    fn test_constant_no_inputs() {
        let atlas = Atlas::with_cache().unwrap();
        let constant_op = ConstantOp::new(vec![1.0, 2.0, 3.0]);

        // Constant should work with no inputs
        let result = constant_op.execute(&atlas, &[]).unwrap();
        assert_eq!(result, vec![1.0, 2.0, 3.0]);

        // Constant should reject inputs (ONNX Constant takes no inputs)
        let dummy = vec![0.0];
        let result_with_input = constant_op.execute(&atlas, &[&dummy]);
        assert!(result_with_input.is_err(), "ConstantOp should reject inputs");
    }
}

#[cfg(test)]
mod test_range {
    use super::*;

    #[test]
    fn test_range_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let range_op = RangeOp;

        // Range from 0 to 5 with step 1
        let start = vec![0.0];
        let limit = vec![5.0];
        let delta = vec![1.0];
        let expected = vec![0.0, 1.0, 2.0, 3.0, 4.0];

        let result = range_op.execute(&atlas, &[&start, &limit, &delta]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_range_with_step() {
        let atlas = Atlas::with_cache().unwrap();
        let range_op = RangeOp;

        // Range from 0 to 10 with step 2
        let start = vec![0.0];
        let limit = vec![10.0];
        let delta = vec![2.0];
        let expected = vec![0.0, 2.0, 4.0, 6.0, 8.0];

        let result = range_op.execute(&atlas, &[&start, &limit, &delta]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_range_negative_step() {
        let atlas = Atlas::with_cache().unwrap();
        let range_op = RangeOp;

        // Range from 5 to 0 with step -1
        let start = vec![5.0];
        let limit = vec![0.0];
        let delta = vec![-1.0];
        let expected = vec![5.0, 4.0, 3.0, 2.0, 1.0];

        let result = range_op.execute(&atlas, &[&start, &limit, &delta]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_range_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();
        let range_op = RangeOp;

        // Empty range (start >= limit with positive step)
        let start = vec![5.0];
        let limit = vec![5.0];
        let delta = vec![1.0];
        let result = range_op.execute(&atlas, &[&start, &limit, &delta]).unwrap();
        assert_eq!(result.len(), 0);

        // Single element
        let start = vec![0.0];
        let limit = vec![1.0];
        let delta = vec![1.0];
        let result = range_op.execute(&atlas, &[&start, &limit, &delta]).unwrap();
        assert_tensors_equal(&result, &[0.0], 1e-6);

        // Large step (only one element)
        let start = vec![0.0];
        let limit = vec![10.0];
        let delta = vec![100.0];
        let result = range_op.execute(&atlas, &[&start, &limit, &delta]).unwrap();
        assert_tensors_equal(&result, &[0.0], 1e-6);
    }

    #[test]
    fn test_range_zero_delta() {
        let atlas = Atlas::with_cache().unwrap();
        let range_op = RangeOp;

        // Zero delta should error
        let start = vec![0.0];
        let limit = vec![5.0];
        let delta = vec![0.0];

        assert!(range_op.execute(&atlas, &[&start, &limit, &delta]).is_err());
    }
}

#[cfg(test)]
mod test_shape {
    use super::*;

    #[test]
    fn test_shape_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let shape_op = ShapeOp::new(vec![3, 4]);

        let input = vec![
            1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0,
        ];
        let expected = vec![3.0, 4.0]; // Shape as f32

        let result = shape_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_shape_1d() {
        let atlas = Atlas::with_cache().unwrap();
        let shape_op = ShapeOp::new(vec![5]);

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let expected = vec![5.0];

        let result = shape_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_shape_various_dimensions() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            // 1D
            (ShapeOp::new(vec![10]), vec![10.0]),
            // 2D
            (ShapeOp::new(vec![2, 5]), vec![2.0, 5.0]),
            // 3D
            (ShapeOp::new(vec![2, 3, 4]), vec![2.0, 3.0, 4.0]),
            // 4D
            (ShapeOp::new(vec![1, 2, 3, 4]), vec![1.0, 2.0, 3.0, 4.0]),
        ];

        for (shape_op, expected) in test_cases {
            let dummy_input = vec![0.0]; // Shape doesn't depend on actual input data
            let result = shape_op.execute(&atlas, &[&dummy_input]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_shape_independence_from_data() {
        let atlas = Atlas::with_cache().unwrap();
        let shape_op = ShapeOp::new(vec![2, 3]);

        // Shape result should be same regardless of input data
        let input1 = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let input2 = vec![10.0, 20.0, 30.0, 40.0, 50.0, 60.0];
        let expected = vec![2.0, 3.0];

        let result1 = shape_op.execute(&atlas, &[&input1]).unwrap();
        let result2 = shape_op.execute(&atlas, &[&input2]).unwrap();

        assert_tensors_equal(&result1, &expected, 1e-6);
        assert_tensors_equal(&result2, &expected, 1e-6);
        assert_tensors_equal(&result1, &result2, 1e-6);
    }
}

#[cfg(test)]
mod test_argmax {
    use super::*;

    #[test]
    fn test_argmax_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let argmax_op = ArgMaxOp::new(0, false);

        let input = vec![1.0, 5.0, 3.0, 2.0, 4.0];
        let expected = vec![1.0]; // Index 1 has max value (5.0)

        let result = argmax_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_argmax_first_element() {
        let atlas = Atlas::with_cache().unwrap();
        let argmax_op = ArgMaxOp::new(0, false);

        let input = vec![10.0, 5.0, 3.0, 2.0, 1.0];
        let expected = vec![0.0]; // Index 0 has max value

        let result = argmax_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_argmax_last_element() {
        let atlas = Atlas::with_cache().unwrap();
        let argmax_op = ArgMaxOp::new(0, false);

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let expected = vec![4.0]; // Index 4 has max value

        let result = argmax_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_argmax_negative_values() {
        let atlas = Atlas::with_cache().unwrap();
        let argmax_op = ArgMaxOp::new(0, false);

        let input = vec![-5.0, -2.0, -10.0, -3.0];
        let expected = vec![1.0]; // Index 1 has max value (-2.0)

        let result = argmax_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_argmax_duplicate_max() {
        let atlas = Atlas::with_cache().unwrap();
        let argmax_op = ArgMaxOp::new(0, false);

        // When there are duplicate max values, should return first occurrence
        let input = vec![1.0, 5.0, 3.0, 5.0, 2.0];
        let expected = vec![1.0]; // First occurrence of max (5.0)

        let result = argmax_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_argmax_single_element() {
        let atlas = Atlas::with_cache().unwrap();
        let argmax_op = ArgMaxOp::new(0, false);

        let input = vec![42.0];
        let expected = vec![0.0]; // Only one element, index 0

        let result = argmax_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_argmax_empty_input() {
        let atlas = Atlas::with_cache().unwrap();
        let argmax_op = ArgMaxOp::new(0, false);

        let input: Vec<f32> = vec![];
        let result = argmax_op.execute(&atlas, &[&input]).unwrap();

        // Empty input should return empty result
        assert_eq!(result.len(), 0);
    }
}

#[cfg(test)]
mod test_transpose {
    use super::*;

    #[test]
    fn test_transpose_basic_2d() {
        let atlas = Atlas::with_cache().unwrap();
        // 2x3 matrix: [[1, 2, 3], [4, 5, 6]]
        let transpose_op = TransposeOp::new(vec![2, 3], None);

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        // Transposed: 3x2 matrix: [[1, 4], [2, 5], [3, 6]]
        let expected = vec![1.0, 4.0, 2.0, 5.0, 3.0, 6.0];

        let result = transpose_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_transpose_explicit_perm() {
        let atlas = Atlas::with_cache().unwrap();
        // 2x3 matrix with explicit permutation [1, 0]
        let transpose_op = TransposeOp::new(vec![2, 3], Some(vec![1, 0]));

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let expected = vec![1.0, 4.0, 2.0, 5.0, 3.0, 6.0];

        let result = transpose_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_transpose_3d() {
        let atlas = Atlas::with_cache().unwrap();
        // 2x2x2 tensor with permutation [2, 0, 1]
        let transpose_op = TransposeOp::new(vec![2, 2, 2], Some(vec![2, 0, 1]));

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
        // Expected result based on permutation [2, 0, 1]
        // Original shape: (2, 2, 2), Output shape: (2, 2, 2)
        let expected = vec![1.0, 3.0, 5.0, 7.0, 2.0, 4.0, 6.0, 8.0];

        let result = transpose_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_transpose_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            // 1x1 matrix
            (vec![1], None, vec![42.0], vec![42.0]),
            // 1x4 matrix (row vector)
            (
                vec![1, 4],
                None,
                vec![1.0, 2.0, 3.0, 4.0],
                vec![1.0, 2.0, 3.0, 4.0],
            ),
            // 4x1 matrix (column vector)
            (
                vec![4, 1],
                None,
                vec![1.0, 2.0, 3.0, 4.0],
                vec![1.0, 2.0, 3.0, 4.0],
            ),
            // Square matrix 2x2
            (
                vec![2, 2],
                None,
                vec![1.0, 2.0, 3.0, 4.0],
                vec![1.0, 3.0, 2.0, 4.0],
            ),
        ];

        for (shape, perm, input, expected) in test_cases {
            let transpose_op = TransposeOp::new(shape, perm);
            let result = transpose_op.execute(&atlas, &[&input]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_transpose_properties() {
        let atlas = Atlas::with_cache().unwrap();

        // Double transpose returns original
        let transpose_op1 = TransposeOp::new(vec![2, 3], None);
        let transpose_op2 = TransposeOp::new(vec![3, 2], None);

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];

        let result1 = transpose_op1.execute(&atlas, &[&input]).unwrap();
        let result2 = transpose_op2.execute(&atlas, &[&result1]).unwrap();

        assert_tensors_equal(&result2, &input, 1e-6);
    }

    #[test]
    fn test_transpose_invalid_input() {
        let atlas = Atlas::with_cache().unwrap();
        let transpose_op = TransposeOp::new(vec![2, 3], None);

        // Wrong size input
        let wrong_input = vec![1.0, 2.0, 3.0]; // Expected 6 elements
        let result = transpose_op.execute(&atlas, &[&wrong_input]);
        assert!(result.is_err());
    }

    #[test]
    fn test_transpose_invalid_perm() {
        let atlas = Atlas::with_cache().unwrap();

        // Out of bounds permutation
        let transpose_op = TransposeOp::new(vec![2, 3], Some(vec![0, 5]));
        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let result = transpose_op.execute(&atlas, &[&input]);
        assert!(result.is_err());

        // Duplicate indices in permutation
        let transpose_op = TransposeOp::new(vec![2, 3], Some(vec![0, 0]));
        let result = transpose_op.execute(&atlas, &[&input]);
        assert!(result.is_err());
    }
}

#[cfg(test)]
mod test_squeeze {
    use super::*;

    #[test]
    fn test_squeeze_basic() {
        let atlas = Atlas::with_cache().unwrap();
        // Shape [1, 3, 1] -> squeeze all
        let squeeze_op = SqueezeOp::new(vec![1, 3, 1], None);

        let input = vec![1.0, 2.0, 3.0];
        let expected = vec![1.0, 2.0, 3.0]; // Data unchanged

        let result = squeeze_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_squeeze_specific_axes() {
        let atlas = Atlas::with_cache().unwrap();
        // Shape [1, 3, 1, 2] -> squeeze axes [0, 2]
        let squeeze_op = SqueezeOp::new(vec![1, 3, 1, 2], Some(vec![0, 2]));

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let expected = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];

        let result = squeeze_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_squeeze_negative_axes() {
        let atlas = Atlas::with_cache().unwrap();
        // Shape [1, 3, 1] -> squeeze axis -1 (last dimension)
        let squeeze_op = SqueezeOp::new(vec![1, 3, 1], Some(vec![-1]));

        let input = vec![1.0, 2.0, 3.0];
        let expected = vec![1.0, 2.0, 3.0];

        let result = squeeze_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_squeeze_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            // No dimensions to squeeze
            (vec![2, 3], None, vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
            // All dimensions are 1
            (vec![1, 1, 1], None, vec![42.0]),
            // Leading dimension is 1
            (vec![1, 4], None, vec![1.0, 2.0, 3.0, 4.0]),
            // Trailing dimension is 1
            (vec![4, 1], None, vec![1.0, 2.0, 3.0, 4.0]),
        ];

        for (shape, axes, input) in test_cases {
            let squeeze_op = SqueezeOp::new(shape, axes);
            let result = squeeze_op.execute(&atlas, &[&input]).unwrap();
            assert_tensors_equal(&result, &input, 1e-6);
        }
    }

    #[test]
    fn test_squeeze_invalid_axis() {
        let atlas = Atlas::with_cache().unwrap();

        // Try to squeeze axis with size != 1
        let squeeze_op = SqueezeOp::new(vec![2, 3, 1], Some(vec![0])); // Axis 0 has size 2
        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let result = squeeze_op.execute(&atlas, &[&input]);
        assert!(result.is_err());
    }

    #[test]
    fn test_squeeze_invalid_axis_out_of_bounds() {
        let atlas = Atlas::with_cache().unwrap();

        // Axis out of bounds
        let squeeze_op = SqueezeOp::new(vec![1, 3, 1], Some(vec![5]));
        let input = vec![1.0, 2.0, 3.0];
        let result = squeeze_op.execute(&atlas, &[&input]);
        assert!(result.is_err());
    }

    #[test]
    fn test_squeeze_wrong_input_size() {
        let atlas = Atlas::with_cache().unwrap();
        let squeeze_op = SqueezeOp::new(vec![1, 3, 1], None);

        // Wrong size input
        let wrong_input = vec![1.0, 2.0]; // Expected 3 elements
        let result = squeeze_op.execute(&atlas, &[&wrong_input]);
        assert!(result.is_err());
    }
}
