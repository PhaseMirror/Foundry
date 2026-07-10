//! Shape-related operations
//!
//! Operations that create, query, or manipulate tensor shapes.

use super::{OnnxHRMNode, Result};
use crate::error::CompilerError;
use crate::hrm::numeric::Numeric;
use hologram::Atlas;

/// Constant operation - returns a constant tensor value
#[derive(Debug, Clone)]
pub struct ConstantOp<T: Numeric> {
    pub value: Vec<T>,
}

impl<T: Numeric> ConstantOp<T> {
    pub fn new(value: Vec<T>) -> Self {
        Self { value }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for ConstantOp<T> {
    fn op_type(&self) -> &'static str {
        "Constant"
    }

    fn execute(
        &self,
        _atlas: &Atlas,
        _inputs: &[&[T]],
    ) -> Result<Vec<T>> {
        self.validate_inputs(_inputs)?;
        Ok(self.value.clone())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if !inputs.is_empty() {
            return Err(CompilerError::InvalidModel(format!(
                "Constant requires 0 inputs, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// Shape operation - returns the shape of the input tensor
#[derive(Debug, Clone)]
pub struct ShapeOp {
    pub shape: Vec<i64>,
}

impl ShapeOp {
    pub fn new(shape: Vec<i64>) -> Self {
        Self { shape }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for ShapeOp {
    fn op_type(&self) -> &'static str {
        "Shape"
    }

    fn execute(
        &self,
        _atlas: &Atlas,
        _inputs: &[&[T]],
    ) -> Result<Vec<T>> {
        self.validate_inputs(_inputs)?;
        // Convert shape (i64) to target numeric type
        Ok(self.shape.iter().map(|&dim| T::from_i64(dim)).collect())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 {
            return Err(CompilerError::InvalidModel(format!(
                "Shape requires 1 input, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// ArgMax operation - finds indices of maximum values along specified axis
#[derive(Debug, Clone, Copy)]
pub struct ArgMaxOp {
    /// Axis along which to find argmax
    pub axis: i64,
    /// Whether to keep dimensions
    pub keepdims: bool,
}

impl ArgMaxOp {
    pub fn new(axis: i64, keepdims: bool) -> Self {
        Self { axis, keepdims }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for ArgMaxOp {
    fn op_type(&self) -> &'static str {
        "ArgMax"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let data = inputs[0];
        if data.is_empty() {
            return Ok(Vec::new());
        }

        // Find index of maximum value
        let mut max_idx = 0;
        let mut max_val = data[0];

        for (idx, &val) in data.iter().enumerate().skip(1) {
            if val.gt(&max_val) {
                max_val = val;
                max_idx = idx;
            }
        }

        Ok(vec![T::from_i64(max_idx as i64)])
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 {
            return Err(CompilerError::InvalidModel(format!(
                "ArgMax requires 1 input, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// Range operation - generates 1D tensor from start to limit with step
#[derive(Debug, Clone, Copy)]
pub struct RangeOp;

impl<T: Numeric> OnnxHRMNode<T> for RangeOp {
    fn op_type(&self) -> &'static str {
        "Range"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        if inputs[0].is_empty() || inputs[1].is_empty() || inputs[2].is_empty() {
            return Err(CompilerError::InvalidModel(
                "Range inputs must be non-empty scalars".to_string(),
            ));
        }

        let start = inputs[0][0];
        let limit = inputs[1][0];
        let delta = inputs[2][0];

        if delta == T::zero() {
            return Err(CompilerError::InvalidModel(
                "Range delta cannot be zero".to_string(),
            ));
        }

        let mut values = Vec::new();
        let mut current = start;

        let zero = T::zero();
        if delta.gt(&zero) {
            while current.lt(&limit) {
                values.push(current);
                current = current.add(delta);
            }
        } else {
            while current.gt(&limit) {
                values.push(current);
                current = current.add(delta);
            }
        }

        Ok(values)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 3 {
            return Err(CompilerError::InvalidModel(format!(
                "Range requires 3 inputs (start, limit, delta), got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}

/// Transpose operation
///
/// Transposes the input tensor by permuting its dimensions.
/// For 2D tensors: (M, N) → (N, M)
#[derive(Debug, Clone)]
pub struct TransposeOp {
    /// Shape of input tensor
    pub input_shape: Vec<usize>,
    /// Permutation of axes (if None, reverses dimensions)
    pub perm: Option<Vec<usize>>,
}

impl TransposeOp {
    pub fn new(input_shape: Vec<usize>, perm: Option<Vec<usize>>) -> Self {
        Self { input_shape, perm }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for TransposeOp {
    fn op_type(&self) -> &'static str {
        "Transpose"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let data = inputs[0];

        if data.is_empty() {
            return Ok(Vec::new());
        }

        // Get permutation (default: reverse dimensions)
        let perm = self
            .perm
            .clone()
            .unwrap_or_else(|| (0..self.input_shape.len()).rev().collect());

        // Calculate output shape
        let output_shape: Vec<usize> = perm.iter().map(|&i| self.input_shape[i]).collect();

        // Calculate strides for input and output
        let input_strides = calculate_strides(&self.input_shape);
        let output_strides = calculate_strides(&output_shape);

        let total_elements: usize = self.input_shape.iter().product();
        let mut output = vec![T::zero(); total_elements];

        // Transpose by computing new indices
        for (i, &value) in data.iter().enumerate().take(total_elements) {
            // Convert linear index to multi-dimensional index in input
            let mut input_coords = vec![0; self.input_shape.len()];
            let mut remaining = i;
            for (dim, &stride) in input_strides.iter().enumerate() {
                input_coords[dim] = remaining / stride;
                remaining %= stride;
            }

            // Permute coordinates
            let mut output_coords = vec![0; output_shape.len()];
            for (out_dim, &in_dim) in perm.iter().enumerate() {
                output_coords[out_dim] = input_coords[in_dim];
            }

            // Convert multi-dimensional index to linear index in output
            let output_idx: usize = output_coords
                .iter()
                .zip(output_strides.iter())
                .map(|(&coord, &stride)| coord * stride)
                .sum();

            output[output_idx] = value;
        }

        Ok(output)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 {
            return Err(CompilerError::InvalidModel(format!(
                "Transpose requires 1 input, got {}",
                inputs.len()
            )));
        }

        let expected_size: usize = self.input_shape.iter().product();
        if inputs[0].len() != expected_size {
            return Err(CompilerError::InvalidModel(format!(
                "Transpose input size mismatch: expected {}, got {}",
                expected_size,
                inputs[0].len()
            )));
        }

        if let Some(ref perm) = self.perm {
            if perm.len() != self.input_shape.len() {
                return Err(CompilerError::InvalidModel(format!(
                    "Transpose permutation length {} doesn't match input rank {}",
                    perm.len(),
                    self.input_shape.len()
                )));
            }

            // Check that perm is a valid permutation
            let mut seen = vec![false; perm.len()];
            for &p in perm {
                if p >= perm.len() {
                    return Err(CompilerError::InvalidModel(format!(
                        "Transpose permutation index {} out of bounds for rank {}",
                        p,
                        perm.len()
                    )));
                }
                if seen[p] {
                    return Err(CompilerError::InvalidModel(format!(
                        "Transpose permutation has duplicate index {}",
                        p
                    )));
                }
                seen[p] = true;
            }
        }

        Ok(())
    }
}

/// Calculate strides for a given shape (row-major layout)
fn calculate_strides(shape: &[usize]) -> Vec<usize> {
    let mut strides = vec![1; shape.len()];
    for i in (0..shape.len().saturating_sub(1)).rev() {
        strides[i] = strides[i + 1] * shape[i + 1];
    }
    strides
}

/// Squeeze operation
///
/// Removes dimensions of size 1 from tensor shape.
#[derive(Debug, Clone)]
pub struct SqueezeOp {
    /// Shape of input tensor
    pub input_shape: Vec<usize>,
    /// Axes to squeeze (if None, squeeze all axes with size 1)
    pub axes: Option<Vec<i64>>,
}

impl SqueezeOp {
    pub fn new(input_shape: Vec<usize>, axes: Option<Vec<i64>>) -> Self {
        Self { input_shape, axes }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for SqueezeOp {
    fn op_type(&self) -> &'static str {
        "Squeeze"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        // Squeeze doesn't change data, just shape metadata
        // Return input data as-is
        Ok(inputs[0].to_vec())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 1 {
            return Err(CompilerError::InvalidModel(format!(
                "Squeeze requires 1 input, got {}",
                inputs.len()
            )));
        }

        let expected_size: usize = self.input_shape.iter().product();
        if inputs[0].len() != expected_size {
            return Err(CompilerError::InvalidModel(format!(
                "Squeeze input size mismatch: expected {}, got {}",
                expected_size,
                inputs[0].len()
            )));
        }

        // Validate axes if provided
        if let Some(ref axes) = self.axes {
            for &axis in axes {
                let axis_idx = if axis < 0 {
                    (self.input_shape.len() as i64 + axis) as usize
                } else {
                    axis as usize
                };

                if axis_idx >= self.input_shape.len() {
                    return Err(CompilerError::InvalidModel(format!(
                        "Squeeze axis {} out of bounds for rank {}",
                        axis,
                        self.input_shape.len()
                    )));
                }

                if self.input_shape[axis_idx] != 1 {
                    return Err(CompilerError::InvalidModel(format!(
                        "Squeeze axis {} has size {}, must be 1",
                        axis, self.input_shape[axis_idx]
                    )));
                }
            }
        }

        Ok(())
    }
}

/// Expand operation
///
/// Broadcasts the input tensor to a target shape.
#[derive(Debug, Clone)]
pub struct ExpandOp {
    /// Target shape for broadcasting
    pub target_shape: Vec<usize>,
}

impl ExpandOp {
    pub fn new(target_shape: Vec<usize>) -> Self {
        Self { target_shape }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for ExpandOp {
    fn op_type(&self) -> &'static str {
        "Expand"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        // For now, implement simple broadcasting
        // Full implementation would need proper broadcasting logic
        let input = inputs[0];

        if input.is_empty() {
            return Ok(Vec::new());
        }

        // If target shape is empty, return input as-is
        if self.target_shape.is_empty() {
            return Ok(input.to_vec());
        }

        // Simple case: broadcast scalar to target shape
        if input.len() == 1 {
            let total_elements: usize = self.target_shape.iter().product();
            return Ok(vec![input[0]; total_elements]);
        }

        // For now, return input as-is (full broadcasting would be more complex)
        // This is a placeholder for compilation to proceed
        Ok(input.to_vec())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.is_empty() {
            return Err(CompilerError::InvalidModel(
                "Expand requires at least 1 input".to_string(),
            ));
        }
        Ok(())
    }
}
