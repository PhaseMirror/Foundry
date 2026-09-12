//! Integration tests for ArrowTensor in ONNX compilation
//!
//! These tests verify that ArrowTensor works correctly with:
//! - ONNX operators
//! - Graph execution
//! - Zero-copy operations
//! - Shape inference

use arrow_array::Float32Array;
use hologram_onnx_compiler::hrm::{ArrowTensor, TensorDType};
use std::sync::Arc;

#[test]
fn test_arrow_tensor_basic_creation() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
    let tensor = ArrowTensor::from_vec(data.clone(), vec![2, 3]).unwrap();

    assert_eq!(tensor.shape(), &[2, 3]);
    assert_eq!(tensor.len(), 6);
    assert_eq!(tensor.ndim(), 2);
    assert_eq!(tensor.dtype(), TensorDType::Float32);
    assert_eq!(tensor.values(), &data[..]);
}

#[test]
fn test_arrow_tensor_zero_copy_slice() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
    let tensor = ArrowTensor::from_vec(data, vec![8]).unwrap();

    // Create slice (zero-copy)
    let sliced = tensor.slice(2, 4).unwrap();

    assert_eq!(sliced.shape(), &[4]);
    assert_eq!(sliced.len(), 4);
    assert_eq!(sliced.values(), &[3.0, 4.0, 5.0, 6.0]);

    // Verify original tensor unchanged
    assert_eq!(tensor.len(), 8);
}

#[test]
fn test_arrow_tensor_zero_copy_reshape() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
    let tensor = ArrowTensor::from_vec(data, vec![2, 3]).unwrap();

    // Reshape (zero-copy)
    let reshaped = tensor.reshape(vec![3, 2]).unwrap();

    assert_eq!(reshaped.shape(), &[3, 2]);
    assert_eq!(reshaped.len(), 6);
    // Data should be the same (zero-copy)
    assert_eq!(reshaped.values(), tensor.values());
}

#[test]
fn test_arrow_tensor_reshape_invalid() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
    let tensor = ArrowTensor::from_vec(data, vec![2, 3]).unwrap();

    // Try to reshape to incompatible shape
    let result = tensor.reshape(vec![2, 4]); // 2*4=8 != 6
    assert!(result.is_err());
}

#[test]
fn test_arrow_tensor_slice_out_of_bounds() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0];
    let tensor = ArrowTensor::from_vec(data, vec![5]).unwrap();

    // Try to slice beyond bounds
    let result = tensor.slice(3, 5); // 3+5=8 > 5
    assert!(result.is_err());
}

#[test]
fn test_arrow_tensor_element_access() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
    let tensor = ArrowTensor::from_vec(data, vec![2, 3]).unwrap();

    assert_eq!(tensor.get_f32(0), Some(1.0));
    assert_eq!(tensor.get_f32(2), Some(3.0));
    assert_eq!(tensor.get_f32(5), Some(6.0));
    assert_eq!(tensor.get_f32(10), None); // Out of bounds
}

#[test]
fn test_arrow_tensor_from_arrow_array() {
    // Create Arrow array directly (simulates external data source)
    let arrow_data = Float32Array::from(vec![10.0, 20.0, 30.0, 40.0]);
    let tensor = ArrowTensor::new(Arc::new(arrow_data), vec![2, 2]).unwrap();

    assert_eq!(tensor.shape(), &[2, 2]);
    assert_eq!(tensor.values(), &[10.0, 20.0, 30.0, 40.0]);
}

#[test]
fn test_arrow_tensor_to_vec() {
    let data = vec![1.0, 2.0, 3.0, 4.0];
    let tensor = ArrowTensor::from_vec(data.clone(), vec![2, 2]).unwrap();

    let vec_copy = tensor.to_vec_f32();
    assert_eq!(vec_copy, data);
}

#[test]
fn test_arrow_tensor_invalid_shape() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];

    // Shape doesn't match data length
    let result = ArrowTensor::from_vec(data, vec![2, 4]); // 2*4=8 != 6
    assert!(result.is_err());
}

#[test]
fn test_arrow_tensor_1d() {
    let data = vec![1.0, 2.0, 3.0, 4.0, 5.0];
    let tensor = ArrowTensor::from_vec(data.clone(), vec![5]).unwrap();

    assert_eq!(tensor.shape(), &[5]);
    assert_eq!(tensor.ndim(), 1);
    assert_eq!(tensor.values(), &data[..]);
}

#[test]
fn test_arrow_tensor_3d() {
    let data: Vec<f32> = (0..24).map(|i| i as f32).collect();
    let tensor = ArrowTensor::from_vec(data.clone(), vec![2, 3, 4]).unwrap();

    assert_eq!(tensor.shape(), &[2, 3, 4]);
    assert_eq!(tensor.ndim(), 3);
    assert_eq!(tensor.len(), 24);
}

#[test]
fn test_arrow_tensor_scalar() {
    let data = vec![42.0];
    let tensor = ArrowTensor::from_vec(data, vec![1]).unwrap();

    assert_eq!(tensor.shape(), &[1]);
    assert_eq!(tensor.len(), 1);
    assert_eq!(tensor.get_f32(0), Some(42.0));
}

#[test]
fn test_arrow_tensor_empty() {
    let data: Vec<f32> = vec![];
    let tensor = ArrowTensor::from_vec(data, vec![0]).unwrap();

    assert_eq!(tensor.shape(), &[0]);
    assert_eq!(tensor.len(), 0);
    assert!(tensor.is_empty());
}

#[test]
fn test_arrow_tensor_multiple_reshapes() {
    let data: Vec<f32> = (0..24).map(|i| i as f32).collect();
    let tensor = ArrowTensor::from_vec(data, vec![24]).unwrap();

    // Chain multiple reshapes
    let t1 = tensor.reshape(vec![2, 12]).unwrap();
    assert_eq!(t1.shape(), &[2, 12]);

    let t2 = t1.reshape(vec![4, 6]).unwrap();
    assert_eq!(t2.shape(), &[4, 6]);

    let t3 = t2.reshape(vec![2, 3, 4]).unwrap();
    assert_eq!(t3.shape(), &[2, 3, 4]);

    // All should have same underlying data
    assert_eq!(t3.values(), tensor.values());
}

#[test]
fn test_arrow_tensor_multiple_slices() {
    let data: Vec<f32> = (0..20).map(|i| i as f32).collect();
    let tensor = ArrowTensor::from_vec(data, vec![20]).unwrap();

    // Create slice from slice (nested)
    let slice1 = tensor.slice(5, 10).unwrap(); // Elements 5-14
    assert_eq!(
        slice1.values(),
        &[5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0]
    );

    let slice2 = slice1.slice(2, 5).unwrap(); // Elements 7-11 from original
    assert_eq!(slice2.values(), &[7.0, 8.0, 9.0, 10.0, 11.0]);
}

#[test]
fn test_arrow_tensor_operator_compatibility() {
    // Verify ArrowTensor works with ONNX operator signatures
    use hologram::Atlas;
    use hologram_onnx_compiler::hrm::ops::{AddOp, OnnxHRMNode};

    let atlas = Atlas::with_cache().unwrap();
    let add_op = AddOp;

    // Create tensors
    let a = ArrowTensor::from_vec(vec![1.0, 2.0, 3.0], vec![3]).unwrap();
    let b = ArrowTensor::from_vec(vec![4.0, 5.0, 6.0], vec![3]).unwrap();

    // Execute operator with tensor slices (zero-copy)
    let result = add_op.execute(&atlas, &[a.values(), b.values()]).unwrap();

    assert_eq!(result.len(), 3);
    assert_eq!(result[0], 5.0); // 1+4
    assert_eq!(result[1], 7.0); // 2+5
    assert_eq!(result[2], 9.0); // 3+6
}

#[test]
fn test_arrow_tensor_matrix_operations() {
    // Test with matrix-like shapes (for MatMul, Gemm, etc.)
    let data: Vec<f32> = (0..12).map(|i| i as f32).collect();
    let matrix = ArrowTensor::from_vec(data, vec![3, 4]).unwrap();

    assert_eq!(matrix.shape(), &[3, 4]);
    assert_eq!(matrix.ndim(), 2);

    // Verify we can access as contiguous memory
    let values = matrix.values();
    assert_eq!(values.len(), 12);
    assert_eq!(values[0], 0.0);
    assert_eq!(values[11], 11.0);
}

#[test]
fn test_arrow_tensor_large_tensor() {
    // Test with larger tensor (stress test)
    let size = 1000;
    let data: Vec<f32> = (0..size).map(|i| i as f32).collect();
    let tensor = ArrowTensor::from_vec(data, vec![size as i64]).unwrap();

    assert_eq!(tensor.len(), size);
    assert_eq!(tensor.get_f32(0), Some(0.0));
    assert_eq!(tensor.get_f32(999), Some(999.0));

    // Slice large tensor
    let slice = tensor.slice(100, 200).unwrap();
    assert_eq!(slice.len(), 200);
    assert_eq!(slice.get_f32(0), Some(100.0));
}

#[test]
fn test_arrow_tensor_clone() {
    let data = vec![1.0, 2.0, 3.0, 4.0];
    let tensor = ArrowTensor::from_vec(data, vec![2, 2]).unwrap();

    // Clone tensor (Arc clone, zero-copy)
    let cloned = tensor.clone();

    assert_eq!(cloned.shape(), tensor.shape());
    assert_eq!(cloned.values(), tensor.values());
    assert_eq!(cloned.len(), tensor.len());
}

#[test]
fn test_arrow_tensor_f64_support() {
    let data = vec![1.0, 2.0, 3.0, 4.0];
    let tensor = ArrowTensor::from_vec_f64(data.clone(), vec![2, 2]).unwrap();

    assert_eq!(tensor.dtype(), TensorDType::Float64);
    assert_eq!(tensor.values_f64(), Some(&data[..]));
    assert_eq!(tensor.to_vec_f64(), data);
}
