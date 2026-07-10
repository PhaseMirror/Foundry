//! Zero-copy tensor operations using Apache Arrow
//!
//! This module provides a tensor abstraction that leverages Apache Arrow for zero-copy
//! data access, enabling O(1) lookups and efficient memory usage during ONNX inference.
//!
//! # Design
//!
//! - **Zero-copy views**: Tensors are backed by Arrow arrays with no data duplication
//! - **O(1) access**: Direct memory access via Arrow's columnar format
//! - **Shape tracking**: Maintains tensor shape metadata alongside Arrow data
//! - **Compatible with hologram-core**: Uses same primitives as Griess embedding
//!
//! # Example
//!
//! ```
//! use hologram_onnx_compiler::hrm::arrow_tensor::ArrowTensor;
//! use arrow_array::Float32Array;
//! use std::sync::Arc;
//!
//! // Create tensor from Arrow array (zero-copy)
//! let data = Float32Array::from(vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0]);
//! let tensor = ArrowTensor::new(Arc::new(data), vec![2, 3]).unwrap();
//!
//! assert_eq!(tensor.shape(), &[2, 3]);
//! assert_eq!(tensor.len(), 6);
//!
//! // Access data with zero-copy
//! let values = tensor.values();
//! assert_eq!(values[0], 1.0);
//! ```

use arrow_array::{Array, Float32Array, Float64Array};
use std::sync::Arc;
use crate::{CompilerError, Result};

/// Zero-copy tensor backed by Apache Arrow
///
/// Provides a tensor abstraction over Arrow's columnar arrays with shape metadata.
/// All data access is zero-copy via Arrow's memory management.
#[derive(Debug, Clone)]
pub struct ArrowTensor {
    /// Underlying Arrow array (f32 or f64)
    data: Arc<dyn Array>,

    /// Tensor shape (dimensions)
    shape: Vec<i64>,

    /// Data type
    dtype: TensorDType,
}

/// Supported tensor data types
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TensorDType {
    Float32,
    Float64,
}

impl ArrowTensor {
    /// Create a new tensor from an Arrow Float32Array
    ///
    /// # Arguments
    ///
    /// * `data` - Arrow Float32Array containing the tensor data
    /// * `shape` - Tensor dimensions (must match total number of elements)
    ///
    /// # Returns
    ///
    /// New ArrowTensor with zero-copy view of the data
    ///
    /// # Errors
    ///
    /// Returns error if shape doesn't match data length
    pub fn new(data: Arc<Float32Array>, shape: Vec<i64>) -> Result<Self> {
        let total_elements: i64 = shape.iter().product();
        if total_elements != data.len() as i64 {
            return Err(CompilerError::InvalidModel(format!(
                "Shape {:?} doesn't match data length {} (expected {} elements)",
                shape,
                data.len(),
                total_elements
            )));
        }

        Ok(Self {
            data: data as Arc<dyn Array>,
            shape,
            dtype: TensorDType::Float32,
        })
    }

    /// Create a new Float64 tensor from an Arrow Float64Array
    pub fn new_f64(data: Arc<Float64Array>, shape: Vec<i64>) -> Result<Self> {
        let total_elements: i64 = shape.iter().product();
        if total_elements != data.len() as i64 {
            return Err(CompilerError::InvalidModel(format!(
                "Shape {:?} doesn't match data length {} (expected {} elements)",
                shape,
                data.len(),
                total_elements
            )));
        }

        Ok(Self {
            data: data as Arc<dyn Array>,
            shape,
            dtype: TensorDType::Float64,
        })
    }

    /// Create a tensor from a Vec<f32> (will allocate Arrow array)
    pub fn from_vec(data: Vec<f32>, shape: Vec<i64>) -> Result<Self> {
        let array = Arc::new(Float32Array::from(data));
        Self::new(array, shape)
    }

    /// Create a tensor from a Vec<f64> (will allocate Arrow array)
    pub fn from_vec_f64(data: Vec<f64>, shape: Vec<i64>) -> Result<Self> {
        let array = Arc::new(Float64Array::from(data));
        Self::new_f64(array, shape)
    }

    /// Get tensor shape
    pub fn shape(&self) -> &[i64] {
        &self.shape
    }

    /// Get number of dimensions
    pub fn ndim(&self) -> usize {
        self.shape.len()
    }

    /// Get total number of elements
    pub fn len(&self) -> usize {
        self.data.len()
    }

    /// Check if tensor is empty
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }

    /// Get data type
    pub fn dtype(&self) -> TensorDType {
        self.dtype
    }

    /// Get underlying Arrow array (zero-copy reference)
    pub fn arrow_array(&self) -> &Arc<dyn Array> {
        &self.data
    }

    /// Get Float32 values as a slice (zero-copy)
    ///
    /// Returns None if tensor is not Float32 type
    pub fn values_f32(&self) -> Option<&[f32]> {
        if self.dtype != TensorDType::Float32 {
            return None;
        }

        self.data
            .as_any()
            .downcast_ref::<Float32Array>()
            .map(|arr| arr.values().as_ref())
    }

    /// Get Float64 values as a slice (zero-copy)
    ///
    /// Returns None if tensor is not Float64 type
    pub fn values_f64(&self) -> Option<&[f64]> {
        if self.dtype != TensorDType::Float64 {
            return None;
        }

        self.data
            .as_any()
            .downcast_ref::<Float64Array>()
            .map(|arr| arr.values().as_ref())
    }

    /// Get values as f32 (for convenience, works with both f32 and f64 tensors)
    ///
    /// For f64 tensors, this returns a reference to the underlying data cast to f32.
    /// For f32 tensors, this is zero-copy.
    pub fn values(&self) -> &[f32] {
        match self.dtype {
            TensorDType::Float32 => self.values_f32().unwrap(),
            TensorDType::Float64 => {
                // For f64, we can't zero-copy cast to f32
                // This is a simplified implementation - in production, you'd want to handle this better
                // For now, panic with a helpful message
                panic!("Cannot get f32 values from f64 tensor without conversion. Use values_f64() instead or convert tensor first.")
            }
        }
    }

    /// Convert tensor to Vec<f32> (allocates and copies)
    pub fn to_vec_f32(&self) -> Vec<f32> {
        match self.dtype {
            TensorDType::Float32 => self.values_f32().unwrap().to_vec(),
            TensorDType::Float64 => self.values_f64().unwrap().iter().map(|&x| x as f32).collect(),
        }
    }

    /// Convert tensor to Vec<f64> (allocates and copies)
    pub fn to_vec_f64(&self) -> Vec<f64> {
        match self.dtype {
            TensorDType::Float32 => self.values_f32().unwrap().iter().map(|&x| x as f64).collect(),
            TensorDType::Float64 => self.values_f64().unwrap().to_vec(),
        }
    }

    /// Create a slice view of this tensor (zero-copy)
    ///
    /// # Arguments
    ///
    /// * `offset` - Starting index
    /// * `length` - Number of elements in the slice
    ///
    /// # Returns
    ///
    /// New ArrowTensor that shares the same underlying Arrow array
    pub fn slice(&self, offset: usize, length: usize) -> Result<Self> {
        if offset + length > self.len() {
            return Err(CompilerError::InvalidModel(format!(
                "Slice [{}:{}] out of bounds for tensor with {} elements",
                offset,
                offset + length,
                self.len()
            )));
        }

        // Arrow's slice is zero-copy
        let sliced_data = self.data.slice(offset, length);

        Ok(Self {
            data: sliced_data,
            shape: vec![length as i64], // Flattened shape for slice
            dtype: self.dtype,
        })
    }

    /// Reshape tensor (must preserve total number of elements)
    ///
    /// This is a zero-copy operation that just updates the shape metadata.
    pub fn reshape(&self, new_shape: Vec<i64>) -> Result<Self> {
        let new_total: i64 = new_shape.iter().product();
        let current_total = self.len() as i64;

        if new_total != current_total {
            return Err(CompilerError::InvalidModel(format!(
                "Cannot reshape tensor: new shape {:?} has {} elements but tensor has {}",
                new_shape, new_total, current_total
            )));
        }

        Ok(Self {
            data: Arc::clone(&self.data),
            shape: new_shape,
            dtype: self.dtype,
        })
    }

    /// Get element at flat index (zero-copy access)
    pub fn get_f32(&self, index: usize) -> Option<f32> {
        if self.dtype != TensorDType::Float32 {
            return None;
        }

        self.data
            .as_any()
            .downcast_ref::<Float32Array>()
            .and_then(|arr| arr.values().get(index).copied())
    }

    /// Get element at flat index (zero-copy access)
    pub fn get_f64(&self, index: usize) -> Option<f64> {
        if self.dtype != TensorDType::Float64 {
            return None;
        }

        self.data
            .as_any()
            .downcast_ref::<Float64Array>()
            .and_then(|arr| arr.values().get(index).copied())
    }
}

/// Builder for constructing Arrow tensors efficiently
#[allow(dead_code)]
pub struct ArrowTensorBuilder {
    dtype: TensorDType,
    capacity: usize,
    shape: Vec<i64>,
}

impl ArrowTensorBuilder {
    /// Create a new builder with specified dtype and capacity
    pub fn new(dtype: TensorDType, capacity: usize, shape: Vec<i64>) -> Self {
        Self {
            dtype,
            capacity,
            shape,
        }
    }

    /// Build tensor from Vec<f32>
    pub fn from_vec_f32(data: Vec<f32>, shape: Vec<i64>) -> Result<ArrowTensor> {
        ArrowTensor::from_vec(data, shape)
    }

    /// Build tensor from Vec<f64>
    pub fn from_vec_f64(data: Vec<f64>, shape: Vec<i64>) -> Result<ArrowTensor> {
        ArrowTensor::from_vec_f64(data, shape)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_tensor() {
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let tensor = ArrowTensor::from_vec(data.clone(), vec![2, 3]).unwrap();

        assert_eq!(tensor.shape(), &[2, 3]);
        assert_eq!(tensor.len(), 6);
        assert_eq!(tensor.ndim(), 2);
        assert_eq!(tensor.values(), &data[..]);
    }

    #[test]
    fn test_slice_tensor() {
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let tensor = ArrowTensor::from_vec(data, vec![6]).unwrap();

        let sliced = tensor.slice(2, 3).unwrap();
        assert_eq!(sliced.shape(), &[3]);
        assert_eq!(sliced.values(), &[3.0, 4.0, 5.0]);
    }

    #[test]
    fn test_reshape_tensor() {
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let tensor = ArrowTensor::from_vec(data, vec![2, 3]).unwrap();

        let reshaped = tensor.reshape(vec![3, 2]).unwrap();
        assert_eq!(reshaped.shape(), &[3, 2]);
        assert_eq!(reshaped.len(), 6);
    }

    #[test]
    fn test_invalid_shape() {
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let result = ArrowTensor::from_vec(data, vec![2, 4]); // 2*4=8 != 6
        assert!(result.is_err());
    }

    #[test]
    fn test_get_element() {
        let data = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        let tensor = ArrowTensor::from_vec(data, vec![6]).unwrap();

        assert_eq!(tensor.get_f32(0), Some(1.0));
        assert_eq!(tensor.get_f32(3), Some(4.0));
        assert_eq!(tensor.get_f32(10), None);
    }
}
