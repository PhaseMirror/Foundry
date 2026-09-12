//! Single-Node Tests for Tensor Manipulation Operators
//!
//! Tests the following ONNX tensor manipulation operators in isolation:
//! - Reshape: Reshape tensor to new shape
//! - Concat: Concatenate tensors along an axis
//! - Slice: Extract a slice from a tensor
//! - Gather: Gather elements by indices
//! - Unsqueeze: Add dimensions of size 1
//! - Flatten: Flatten tensor to 2D

use crate::onnx_single_node::*;
use hologram::Atlas;
use hologram_onnx_compiler::hrm::ops::{
    ConcatOp, FlattenOp, GatherOp, OnnxHRMNode, ReshapeOp, SliceOp, UnsqueezeOp,
};

#[cfg(test)]
mod test_reshape {
    use super::*;

    #[test]
    fn test_reshape_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let reshape_op = ReshapeOp;

        // Reshape from [6] to [2, 3] (conceptually)
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let shape = vec![2.0, 3.0]; // New shape as f32 values
        let expected = data.clone(); // Data unchanged, only shape metadata changes

        let result = reshape_op.execute(&atlas, &[&data, &shape]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_reshape_preserves_data() {
        let atlas = Atlas::with_cache().unwrap();
        let reshape_op = ReshapeOp;

        let test_cases = vec![
            // Various data sizes
            (vec![1.0, 2.0, 3.0, 4.0], vec![2.0, 2.0]),
            (vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0], vec![4.0, 2.0]),
            (vec![1.0], vec![1.0]),
        ];

        for (data, shape) in test_cases {
            let result = reshape_op.execute(&atlas, &[&data, &shape]).unwrap();
            assert_tensors_equal(&result, &data, 1e-6);
        }
    }

    #[test]
    fn test_reshape_various_shapes() {
        let atlas = Atlas::with_cache().unwrap();
        let reshape_op = ReshapeOp;

        // Different reshape operations
        for size in [4, 12, 24, 100].iter() {
            let data: Vec<f32> = (0..*size).map(|i| i as f32).collect();
            let shape = vec![*size as f32];

            let result = reshape_op.execute(&atlas, &[&data, &shape]).unwrap();
            assert_tensors_equal(&result, &data, 1e-6);
        }
    }

    #[test]
    fn test_reshape_validates_inputs() {
        let atlas = Atlas::with_cache().unwrap();
        let reshape_op = ReshapeOp;

        // Wrong number of inputs
        let data = vec![1.0, 2.0, 3.0];
        assert!(reshape_op.execute(&atlas, &[&data]).is_err());
    }
}

#[cfg(test)]
mod test_concat {
    use super::*;

    #[test]
    fn test_concat_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let concat_op = ConcatOp::new(0); // Axis 0

        let a = vec![1.0, 2.0, 3.0];
        let b = vec![4.0, 5.0, 6.0];
        let expected = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];

        let result = concat_op.execute(&atlas, &[&a, &b]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_concat_multiple_tensors() {
        let atlas = Atlas::with_cache().unwrap();
        let concat_op = ConcatOp::new(0);

        let a = vec![1.0, 2.0];
        let b = vec![3.0, 4.0];
        let c = vec![5.0, 6.0];
        let expected = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];

        let result = concat_op.execute(&atlas, &[&a, &b, &c]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_concat_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();
        let concat_op = ConcatOp::new(0);

        let test_cases = vec![
            // Single element tensors
            (vec![vec![1.0], vec![2.0]], vec![1.0, 2.0]),
            // Different sizes
            (
                vec![vec![1.0, 2.0, 3.0], vec![4.0]],
                vec![1.0, 2.0, 3.0, 4.0],
            ),
            // Single input
            (vec![vec![1.0, 2.0, 3.0]], vec![1.0, 2.0, 3.0]),
        ];

        for (inputs, expected) in test_cases {
            let input_refs: Vec<&[f32]> = inputs.iter().map(|v| v.as_slice()).collect();
            let result = concat_op.execute(&atlas, &input_refs).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_concat_preserves_order() {
        let atlas = Atlas::with_cache().unwrap();
        let concat_op = ConcatOp::new(0);

        let a = vec![10.0, 20.0, 30.0];
        let b = vec![1.0, 2.0, 3.0];

        let result_ab = concat_op.execute(&atlas, &[&a, &b]).unwrap();
        let result_ba = concat_op.execute(&atlas, &[&b, &a]).unwrap();

        // Order matters
        assert_eq!(result_ab, vec![10.0, 20.0, 30.0, 1.0, 2.0, 3.0]);
        assert_eq!(result_ba, vec![1.0, 2.0, 3.0, 10.0, 20.0, 30.0]);
    }
}

#[cfg(test)]
mod test_slice {
    use super::*;

    #[test]
    fn test_slice_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let slice_op = SliceOp::new(vec![1], vec![4], vec![1]); // [1:4:1]

        let input = vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
        let expected = vec![1.0, 2.0, 3.0];

        let result = slice_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_slice_with_step() {
        let atlas = Atlas::with_cache().unwrap();
        let slice_op = SliceOp::new(vec![0], vec![6], vec![2]); // [0:6:2]

        let input = vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
        let expected = vec![0.0, 2.0, 4.0];

        let result = slice_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_slice_edge_cases() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            // Full slice [0:6:1]
            (
                SliceOp::new(vec![0], vec![6], vec![1]),
                vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
                vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
            ),
            // Single element [2:3:1]
            (
                SliceOp::new(vec![2], vec![3], vec![1]),
                vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
                vec![2.0],
            ),
            // Last element [5:6:1]
            (
                SliceOp::new(vec![5], vec![6], vec![1]),
                vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
                vec![5.0],
            ),
            // Empty slice [3:3:1]
            (
                SliceOp::new(vec![3], vec![3], vec![1]),
                vec![0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
                vec![],
            ),
        ];

        for (slice_op, input, expected) in test_cases {
            let result = slice_op.execute(&atlas, &[&input]).unwrap();
            assert_tensors_equal(&result, &expected, 1e-6);
        }
    }

    #[test]
    fn test_slice_boundary_handling() {
        let atlas = Atlas::with_cache().unwrap();

        let input = vec![1.0, 2.0, 3.0];

        // End beyond bounds - should clamp to input length
        let slice_op = SliceOp::new(vec![0], vec![100], vec![1]);
        let result = slice_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &input, 1e-6);

        // Large step
        let slice_op = SliceOp::new(vec![0], vec![3], vec![5]);
        let result = slice_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &[1.0], 1e-6);
    }
}

#[cfg(test)]
mod test_gather {
    use super::*;

    #[test]
    fn test_gather_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let gather_op = GatherOp::new(0);

        let data = vec![10.0, 20.0, 30.0, 40.0, 50.0];
        let indices = vec![0.0, 2.0, 4.0]; // Indices as f32
        let expected = vec![10.0, 30.0, 50.0];

        let result = gather_op.execute(&atlas, &[&data, &indices]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gather_out_of_order() {
        let atlas = Atlas::with_cache().unwrap();
        let gather_op = GatherOp::new(0);

        let data = vec![10.0, 20.0, 30.0, 40.0];
        let indices = vec![3.0, 1.0, 2.0, 0.0];
        let expected = vec![40.0, 20.0, 30.0, 10.0];

        let result = gather_op.execute(&atlas, &[&data, &indices]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gather_duplicate_indices() {
        let atlas = Atlas::with_cache().unwrap();
        let gather_op = GatherOp::new(0);

        let data = vec![10.0, 20.0, 30.0];
        let indices = vec![1.0, 1.0, 2.0, 1.0];
        let expected = vec![20.0, 20.0, 30.0, 20.0];

        let result = gather_op.execute(&atlas, &[&data, &indices]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gather_single_index() {
        let atlas = Atlas::with_cache().unwrap();
        let gather_op = GatherOp::new(0);

        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let indices = vec![2.0];
        let expected = vec![3.0];

        let result = gather_op.execute(&atlas, &[&data, &indices]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_gather_out_of_bounds() {
        let atlas = Atlas::with_cache().unwrap();
        let gather_op = GatherOp::new(0);

        let data = vec![1.0, 2.0, 3.0];
        let indices = vec![5.0]; // Out of bounds

        assert!(gather_op.execute(&atlas, &[&data, &indices]).is_err());
    }
}

#[cfg(test)]
mod test_unsqueeze {
    use super::*;

    #[test]
    fn test_unsqueeze_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let unsqueeze_op = UnsqueezeOp::new(vec![0]);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let expected = input.clone(); // Data unchanged, only shape metadata changes

        let result = unsqueeze_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_unsqueeze_preserves_data() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            // Different axis values
            (UnsqueezeOp::new(vec![0]), vec![1.0, 2.0, 3.0]),
            (UnsqueezeOp::new(vec![1]), vec![1.0, 2.0, 3.0, 4.0]),
            (UnsqueezeOp::new(vec![0, 2]), vec![1.0, 2.0]),
        ];

        for (unsqueeze_op, data) in test_cases {
            let result = unsqueeze_op.execute(&atlas, &[&data]).unwrap();
            assert_tensors_equal(&result, &data, 1e-6);
        }
    }

    #[test]
    fn test_unsqueeze_various_sizes() {
        let atlas = Atlas::with_cache().unwrap();
        let unsqueeze_op = UnsqueezeOp::new(vec![0]);

        // Different data sizes
        for size in [1, 5, 10, 100].iter() {
            let data: Vec<f32> = (0..*size).map(|i| i as f32).collect();
            let result = unsqueeze_op.execute(&atlas, &[&data]).unwrap();
            assert_tensors_equal(&result, &data, 1e-6);
        }
    }

    #[test]
    fn test_unsqueeze_element_preservation() {
        let atlas = Atlas::with_cache().unwrap();
        let unsqueeze_op = UnsqueezeOp::new(vec![0]);

        let input = vec![1.5, 2.7, 3.9, 4.2, 5.1];
        let result = unsqueeze_op.execute(&atlas, &[&input]).unwrap();

        // Every element preserved exactly
        assert_eq!(result.len(), input.len());
        for (i, &val) in input.iter().enumerate() {
            assert_eq!(result[i], val);
        }
    }
}

#[cfg(test)]
mod test_flatten {
    use super::*;

    #[test]
    fn test_flatten_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let flatten_op = FlattenOp::new(1);

        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let expected = input.clone(); // Data unchanged, only shape metadata changes

        let result = flatten_op.execute(&atlas, &[&input]).unwrap();
        assert_tensors_equal(&result, &expected, 1e-6);
    }

    #[test]
    fn test_flatten_different_axes() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            // Different axis values
            (FlattenOp::new(0), vec![1.0, 2.0, 3.0, 4.0]),
            (FlattenOp::new(1), vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0]),
            (FlattenOp::new(2), vec![1.0, 2.0]),
        ];

        for (flatten_op, data) in test_cases {
            let result = flatten_op.execute(&atlas, &[&data]).unwrap();
            assert_tensors_equal(&result, &data, 1e-6);
        }
    }

    #[test]
    fn test_flatten_various_sizes() {
        let atlas = Atlas::with_cache().unwrap();
        let flatten_op = FlattenOp::new(1);

        // Different data sizes
        for size in [2, 6, 12, 24, 100].iter() {
            let data: Vec<f32> = (0..*size).map(|i| i as f32).collect();
            let result = flatten_op.execute(&atlas, &[&data]).unwrap();
            assert_tensors_equal(&result, &data, 1e-6);
        }
    }

    #[test]
    fn test_flatten_element_preservation() {
        let atlas = Atlas::with_cache().unwrap();
        let flatten_op = FlattenOp::new(1);

        let input = vec![1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8];
        let result = flatten_op.execute(&atlas, &[&input]).unwrap();

        // Every element preserved in order
        assert_eq!(result.len(), input.len());
        for i in 0..input.len() {
            assert_eq!(result[i], input[i]);
        }
    }
}
