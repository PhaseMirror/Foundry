//! Tensor manipulation operations (Reshape, Concat, Slice, Gather, Unsqueeze, Flatten)
//!
//! Shape and indexing operations with full generic type support.

use super::{OnnxHRMNode, Result};
use crate::error::CompilerError;
use crate::hrm::numeric::Numeric;
use hologram::Atlas;

/// Reshape operation
///
/// Reshapes the input tensor to a new shape. The total number of elements must remain the same.
#[derive(Debug, Clone, Copy)]
pub struct ReshapeOp;

impl<T: Numeric> OnnxHRMNode<T> for ReshapeOp {
    fn op_type(&self) -> &'static str {
        "Reshape"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;
        // Reshape doesn't change data, just returns input as-is
        // Shape tracking is done externally in HRM
        Ok(inputs[0].to_vec())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 2 {
            return Err(CompilerError::InvalidModel(format!(
                "Reshape requires 2 inputs (data, shape), got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// Concat operation
///
/// Concatenates tensors along a specified axis.
#[derive(Debug, Clone, Copy)]
pub struct ConcatOp {
    /// Axis along which to concatenate
    pub axis: i64,
}

impl ConcatOp {
    pub fn new(axis: i64) -> Self {
        Self { axis }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for ConcatOp {
    fn op_type(&self) -> &'static str {
        "Concat"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        // Simple concatenation: append all inputs
        let mut result = Vec::new();
        for input in inputs {
            result.extend_from_slice(input);
        }

        Ok(result)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.is_empty() {
            return Err(CompilerError::InvalidModel(
                "Concat requires at least 1 input".to_string(),
            ));
        }
        Ok(())
    }
}

/// Slice operation
///
/// Extracts a slice from the input tensor.
#[derive(Debug, Clone)]
pub struct SliceOp {
    /// Start indices for each dimension
    pub starts: Vec<i64>,
    /// End indices for each dimension
    pub ends: Vec<i64>,
    /// Steps for each dimension
    pub steps: Vec<i64>,
}

impl SliceOp {
    pub fn new(starts: Vec<i64>, ends: Vec<i64>, steps: Vec<i64>) -> Self {
        Self { starts, ends, steps }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for SliceOp {
    fn op_type(&self) -> &'static str {
        "Slice"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let input = inputs[0];
        let start = self.starts[0].max(0) as usize;
        let end = (self.ends[0].max(0) as usize).min(input.len());
        let step = self.steps.first().copied().unwrap_or(1).max(1) as usize;

        let mut result = Vec::new();
        let mut i = start;
        while i < end {
            result.push(input[i]);
            i += step;
        }

        Ok(result)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 && inputs.len() != 5 {
            return Err(CompilerError::InvalidModel(format!(
                "Slice requires 1 or 5 inputs, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// Gather operation
///
/// Gathers elements from input tensor along specified axis using indices.
#[derive(Debug, Clone, Copy)]
pub struct GatherOp {
    /// Axis along which to gather
    pub axis: i64,
}

impl GatherOp {
    pub fn new(axis: i64) -> Self {
        Self { axis }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for GatherOp {
    fn op_type(&self) -> &'static str {
        "Gather"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let data = inputs[0];
        let indices = inputs[1];

        let mut result = Vec::with_capacity(indices.len());
        for &idx_val in indices {
            let idx_i64 = idx_val.to_i64();

            // Handle negative indices (ONNX spec: -1 = last element, -2 = second-to-last, etc.)
            let idx = if idx_i64 < 0 {
                let positive_idx = (data.len() as i64 + idx_i64) as usize;
                if positive_idx >= data.len() {
                    return Err(CompilerError::InvalidModel(format!(
                        "Gather negative index {} (resolved to {}) out of bounds for data length {}",
                        idx_i64,
                        positive_idx,
                        data.len()
                    )));
                }
                positive_idx
            } else {
                let positive_idx = idx_i64 as usize;
                if positive_idx >= data.len() {
                    return Err(CompilerError::InvalidModel(format!(
                        "Gather index {} out of bounds for data length {}",
                        positive_idx,
                        data.len()
                    )));
                }
                positive_idx
            };

            result.push(data[idx]);
        }

        Ok(result)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 2 {
            return Err(CompilerError::InvalidModel(format!(
                "Gather requires 2 inputs (data, indices), got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// Unsqueeze operation
///
/// Adds dimensions of size 1 to the tensor shape.
#[derive(Debug, Clone)]
pub struct UnsqueezeOp {
    /// Axes to insert
    pub axes: Vec<i64>,
}

impl UnsqueezeOp {
    pub fn new(axes: Vec<i64>) -> Self {
        Self { axes }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for UnsqueezeOp {
    fn op_type(&self) -> &'static str {
        "Unsqueeze"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;
        // Unsqueeze doesn't change data, just shape metadata
        Ok(inputs[0].to_vec())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 && inputs.len() != 2 {
            return Err(CompilerError::InvalidModel(format!(
                "Unsqueeze requires 1 or 2 inputs, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// Flatten operation
///
/// Flattens the input tensor into a 2D matrix.
#[derive(Debug, Clone, Copy)]
pub struct FlattenOp {
    /// Axis to flatten from (default: 1)
    pub axis: i64,
}

impl FlattenOp {
    pub fn new(axis: i64) -> Self {
        Self { axis }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for FlattenOp {
    fn op_type(&self) -> &'static str {
        "Flatten"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;
        // Flatten doesn't change data, just returns input as-is
        Ok(inputs[0].to_vec())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 {
            return Err(CompilerError::InvalidModel(format!(
                "Flatten requires 1 input, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}
