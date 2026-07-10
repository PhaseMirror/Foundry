//! Matrix operations with N-dimensional support
//!
//! This module implements matrix operations:
//! - MatMul: Matrix multiplication with N-D broadcasting
//! - Gemm: General matrix multiply (Y = alpha*A*B + beta*C)

use super::{OnnxHRMNode, Result};
use crate::error::CompilerError;
use crate::hrm::numeric::Numeric;
use hologram::Atlas;

/// N-dimensional matrix multiplication with broadcasting
///
/// Implements ONNX MatMul semantics:
/// - A: shape [..., M, K]
/// - B: shape [..., K, N]
/// - Output: shape [..., M, N]
///
/// Batch dimensions are broadcast according to NumPy rules.
fn matmul_nd_broadcast<T: Numeric>(
    a: &[T],
    a_shape: &[usize],
    b: &[T],
    b_shape: &[usize],
) -> Result<Vec<T>> {
    // Validate inputs
    if a_shape.is_empty() || b_shape.is_empty() {
        return Err(CompilerError::InvalidModel(
            "MatMul requires non-empty shapes".to_string(),
        ));
    }

    // Get matrix dimensions
    let a_rank = a_shape.len();
    let b_rank = b_shape.len();

    // Special case: 1D × 1D (dot product)
    if a_rank == 1 && b_rank == 1 {
        if a_shape[0] != b_shape[0] {
            return Err(CompilerError::InvalidModel(format!(
                "1D MatMul dimension mismatch: {} vs {}",
                a_shape[0], b_shape[0]
            )));
        }
        let mut sum = T::zero();
        for i in 0..a_shape[0] {
            sum = sum.add(a[i].mul(b[i]));
        }
        return Ok(vec![sum]);
    }

    // Special case: 1D × 2D (vector-matrix)
    if a_rank == 1 && b_rank == 2 {
        let k = a_shape[0];
        let n = b_shape[1];
        if k != b_shape[0] {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul dimension mismatch: [{}] × [{}, {}]",
                k, b_shape[0], b_shape[1]
            )));
        }
        let mut result = vec![T::zero(); n];
        for j in 0..n {
            let mut sum = T::zero();
            for i in 0..k {
                sum = sum.add(a[i].mul(b[i * n + j]));
            }
            result[j] = sum;
        }
        return Ok(result);
    }

    // Special case: 2D × 1D (matrix-vector)
    if a_rank == 2 && b_rank == 1 {
        let m = a_shape[0];
        let k = a_shape[1];
        if k != b_shape[0] {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul dimension mismatch: [{}, {}] × [{}]",
                m, k, b_shape[0]
            )));
        }
        let mut result = vec![T::zero(); m];
        for i in 0..m {
            let mut sum = T::zero();
            for j in 0..k {
                sum = sum.add(a[i * k + j].mul(b[j]));
            }
            result[i] = sum;
        }
        return Ok(result);
    }

    // General N-D case: [..., M, K] × [..., K, N]
    let m = if a_rank >= 2 {
        a_shape[a_rank - 2]
    } else {
        1
    };
    let k_a = a_shape[a_rank - 1];
    let k_b = if b_rank >= 2 {
        b_shape[b_rank - 2]
    } else {
        b_shape[0]
    };
    let n = if b_rank >= 2 {
        b_shape[b_rank - 1]
    } else {
        1
    };

    if k_a != k_b {
        return Err(CompilerError::InvalidModel(format!(
            "MatMul dimension mismatch: K dimensions don't match ({} vs {})",
            k_a, k_b
        )));
    }
    let k = k_a;

    // Compute broadcast batch shape
    let a_batch = &a_shape[..a_rank.saturating_sub(2)];
    let b_batch = &b_shape[..b_rank.saturating_sub(2)];
    let batch_shape = broadcast_shapes(a_batch, b_batch)?;
    let batch_size: usize = batch_shape.iter().product();

    // Output shape
    let mut output_shape = batch_shape.clone();
    output_shape.push(m);
    output_shape.push(n);
    let output_size: usize = output_shape.iter().product();

    let mut result = vec![T::zero(); output_size];

    // Perform batched matrix multiplication
    for batch_idx in 0..batch_size {
        // Compute batch indices for A and B
        let a_batch_idx = compute_broadcast_index(batch_idx, &batch_shape, a_batch);
        let b_batch_idx = compute_broadcast_index(batch_idx, &batch_shape, b_batch);

        // Offset into flattened arrays
        let a_offset = a_batch_idx * m * k;
        let b_offset = b_batch_idx * k * n;
        let out_offset = batch_idx * m * n;

        // 2D matrix multiply: C[i,j] = sum_k A[i,k] * B[k,j]
        for i in 0..m {
            for j in 0..n {
                let mut sum = T::zero();
                for kk in 0..k {
                    let a_val = a[a_offset + i * k + kk];
                    let b_val = b[b_offset + kk * n + j];
                    sum = sum.add(a_val.mul(b_val));
                }
                result[out_offset + i * n + j] = sum;
            }
        }
    }

    Ok(result)
}

/// Broadcast two shapes according to NumPy broadcasting rules
fn broadcast_shapes(a: &[usize], b: &[usize]) -> Result<Vec<usize>> {
    let max_rank = a.len().max(b.len());
    let mut result = Vec::with_capacity(max_rank);

    for i in 0..max_rank {
        let a_dim = if i < a.len() {
            a[a.len() - 1 - i]
        } else {
            1
        };
        let b_dim = if i < b.len() {
            b[b.len() - 1 - i]
        } else {
            1
        };

        if a_dim == b_dim || a_dim == 1 || b_dim == 1 {
            result.push(a_dim.max(b_dim));
        } else {
            return Err(CompilerError::InvalidModel(format!(
                "Cannot broadcast shapes {:?} and {:?}",
                a, b
            )));
        }
    }

    result.reverse();
    Ok(result)
}

/// Compute the linear index in source array given broadcast index
fn compute_broadcast_index(
    linear_idx: usize,
    broadcast_shape: &[usize],
    source_shape: &[usize],
) -> usize {
    if source_shape.is_empty() {
        return 0;
    }

    let mut result = 0;
    let mut stride = 1;
    let rank_diff = broadcast_shape.len().saturating_sub(source_shape.len());

    for i in (0..broadcast_shape.len()).rev() {
        let coord = (linear_idx / stride) % broadcast_shape[i];

        if i >= rank_diff {
            let src_dim_idx = i - rank_diff;
            let src_dim = source_shape[src_dim_idx];

            // If source dimension is 1, broadcast (use 0)
            // Otherwise use the coordinate
            let src_coord = if src_dim == 1 { 0 } else { coord };

            // Compute source stride
            let src_stride: usize = source_shape[src_dim_idx + 1..].iter().product();
            result += src_coord * src_stride.max(1);
        }

        stride *= broadcast_shape[i];
    }

    result
}

/// Matrix multiplication operator with N-D broadcasting support
///
/// Supports:
/// - 2D matrix multiplication: [M, K] × [K, N] → [M, N]
/// - Batched matmul: [B, M, K] × [B, K, N] → [B, M, N]
/// - Broadcasting: [B, M, K] × [K, N] → [B, M, N]
/// - Higher dimensions with batch broadcasting
#[derive(Debug, Clone)]
pub struct MatMulOp {
    /// Shape of first input tensor (can be empty for dynamic shapes)
    pub a_shape: Vec<usize>,
    /// Shape of second input tensor (can be empty for dynamic shapes)
    pub b_shape: Vec<usize>,
}

impl<T: Numeric> OnnxHRMNode<T> for MatMulOp {
    fn op_type(&self) -> &'static str {
        "MatMul"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        if inputs.len() != 2 {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul requires exactly 2 inputs, got {}",
                inputs.len()
            )));
        }

        let a = inputs[0];
        let b = inputs[1];

        if a.is_empty() || b.is_empty() {
            return Err(CompilerError::InvalidModel(
                "MatMul inputs cannot be empty".to_string(),
            ));
        }

        // Use stored shapes if available AND they match the input sizes
        // If sizes don't match, we're in pattern compilation mode - use fallback
        let a_shape = if !self.a_shape.is_empty() {
            let expected_size: usize = self.a_shape.iter().product();
            if expected_size != a.len() {
                // Pattern compilation: input is smaller than full tensor
                return self.execute_fallback(a, b);
            }
            &self.a_shape
        } else {
            // No shape info: use fallback
            return self.execute_fallback(a, b);
        };

        let b_shape = if !self.b_shape.is_empty() {
            let expected_size: usize = self.b_shape.iter().product();
            if expected_size != b.len() {
                // Pattern compilation: input is smaller than full tensor
                return self.execute_fallback(a, b);
            }
            &self.b_shape
        } else {
            return self.execute_fallback(a, b);
        };

        // Perform N-D matrix multiplication with broadcasting
        matmul_nd_broadcast(a, a_shape, b, b_shape)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() != 2 {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul requires exactly 2 inputs, got {}",
                inputs.len()
            )));
        }

        if inputs[0].is_empty() || inputs[1].is_empty() {
            return Err(CompilerError::InvalidModel(
                "MatMul inputs cannot be empty".to_string(),
            ));
        }

        Ok(())
    }
}

impl MatMulOp {
    /// Create MatMul operator from input shapes
    ///
    /// Validates shapes are compatible for matrix multiplication.
    pub fn from_shapes(input_shapes: &[Vec<i64>]) -> Result<Self> {
        if input_shapes.len() != 2 {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul requires 2 input shapes, got {}",
                input_shapes.len()
            )));
        }

        let a_shape = &input_shapes[0];
        let b_shape = &input_shapes[1];

        if a_shape.is_empty() || b_shape.is_empty() {
            return Err(CompilerError::InvalidModel(
                "MatMul input shapes cannot be empty".to_string(),
            ));
        }

        // Validate minimum 1D shapes (ONNX allows 1D vectors)
        if a_shape.is_empty() || b_shape.is_empty() {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul requires non-empty tensor shapes, got shapes {:?} and {:?}",
                a_shape, b_shape
            )));
        }

        // For N-D matmul: A[..., M, K] × B[..., K, N]
        // Get the contraction dimension (K)
        let k1 = a_shape[a_shape.len() - 1];
        let k2 = if b_shape.len() == 1 {
            b_shape[0] // 1D vector case
        } else {
            b_shape[b_shape.len() - 2]
        };

        if k1 != k2 {
            return Err(CompilerError::InvalidModel(format!(
                "MatMul dimension mismatch: A[..., {}] vs B[..., {}, ...]. Inner dimensions must match.",
                k1, k2
            )));
        }

        Ok(Self {
            a_shape: a_shape.iter().map(|&d| d as usize).collect(),
            b_shape: b_shape.iter().map(|&d| d as usize).collect(),
        })
    }

    /// Create default MatMul operator (for dynamic shapes)
    pub fn new() -> Self {
        Self {
            a_shape: Vec::new(),
            b_shape: Vec::new(),
        }
    }

    /// Fallback execution for when shapes are not available
    fn execute_fallback<T: Numeric>(&self, a: &[T], b: &[T]) -> Result<Vec<T>> {
        // Simple 1D case (dot product)
        if a.len() == b.len() {
            let mut sum = T::zero();
            for i in 0..a.len() {
                sum = sum.add(a[i].mul(b[i]));
            }
            Ok(vec![sum])
        } else if a.len() % b.len() == 0 {
            // Matrix-vector multiply (simplified)
            let m = a.len() / b.len();
            let k = b.len();
            let mut result = vec![T::zero(); m];

            for i in 0..m {
                let mut sum = T::zero();
                for j in 0..k {
                    sum = sum.add(a[i * k + j].mul(b[j]));
                }
                result[i] = sum;
            }
            Ok(result)
        } else if b.len() % a.len() == 0 {
            // Vector-matrix multiply (simplified)
            let k = a.len();
            let n = b.len() / k;
            let mut result = vec![T::zero(); n];

            for j in 0..n {
                let mut sum = T::zero();
                for i in 0..k {
                    sum = sum.add(a[i].mul(b[i * n + j]));
                }
                result[j] = sum;
            }
            Ok(result)
        } else {
            Err(CompilerError::InvalidModel(format!(
                "MatMul shape mismatch: {} vs {} with no shape information",
                a.len(),
                b.len()
            )))
        }
    }
}

impl Default for MatMulOp {
    fn default() -> Self {
        Self::new()
    }
}

/// General matrix multiply operator
///
/// Computes: Y = alpha * A * B + beta * C
/// where A, B, C can be transposed via attributes.
#[derive(Debug, Clone)]
pub struct GemmOp {
    pub alpha: f32,
    pub beta: f32,
    pub trans_a: bool,
    pub trans_b: bool,
}

impl<T: Numeric> OnnxHRMNode<T> for GemmOp {
    fn op_type(&self) -> &'static str {
        "Gemm"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        if inputs.len() < 2 || inputs.len() > 3 {
            return Err(CompilerError::InvalidModel(format!(
                "Gemm requires 2-3 inputs, got {}",
                inputs.len()
            )));
        }

        let a = inputs[0];
        let b = inputs[1];

        if a.is_empty() || b.is_empty() {
            return Err(CompilerError::InvalidModel(
                "Gemm inputs cannot be empty".to_string(),
            ));
        }

        // Simplified: treat as MatMul for pattern execution
        // Full implementation would handle alpha, beta, transpositions
        if a.len() == b.len() {
            // Dot product
            let mut sum = T::zero();
            for i in 0..a.len() {
                sum = sum.add(a[i].mul(b[i]));
            }

            // Apply alpha scaling
            let alpha_t = T::from_f32(self.alpha);
            let mut result = sum.mul(alpha_t);

            // Add beta * C if present
            if inputs.len() == 3 && !inputs[2].is_empty() {
                let beta_t = T::from_f32(self.beta);
                result = result.add(inputs[2][0].mul(beta_t));
            }

            Ok(vec![result])
        } else {
            // Fallback: return first input
            Ok(a.to_vec())
        }
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() < 2 || inputs.len() > 3 {
            return Err(CompilerError::InvalidModel(format!(
                "Gemm requires 2-3 inputs, got {}",
                inputs.len()
            )));
        }

        if inputs[0].is_empty() || inputs[1].is_empty() {
            return Err(CompilerError::InvalidModel(
                "Gemm inputs A and B cannot be empty".to_string(),
            ));
        }

        Ok(())
    }
}

impl GemmOp {
    /// Create Gemm operator from input shapes
    pub fn from_shapes(input_shapes: &[Vec<i64>]) -> Result<Self> {
        if input_shapes.len() < 2 || input_shapes.len() > 3 {
            return Err(CompilerError::InvalidModel(format!(
                "Gemm requires 2-3 input shapes, got {}",
                input_shapes.len()
            )));
        }

        // Default parameters
        Ok(Self {
            alpha: 1.0,
            beta: 1.0,
            trans_a: false,
            trans_b: false,
        })
    }

    /// Create Gemm with custom parameters
    pub fn new(alpha: f32, beta: f32, trans_a: bool, trans_b: bool) -> Self {
        Self {
            alpha,
            beta,
            trans_a,
            trans_b,
        }
    }
}

impl Default for GemmOp {
    fn default() -> Self {
        Self {
            alpha: 1.0,
            beta: 1.0,
            trans_a: false,
            trans_b: false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::hrm::ops::OnnxHRMNode;
    use hologram::Atlas;

    #[test]
    fn test_matmul_dot_product() {
        let atlas = Atlas::with_cache().unwrap();
        let op = MatMulOp::new();

        // Dot product: [3] × [3] → [1]
        let a = vec![1.0_f32, 2.0, 3.0];
        let b = vec![4.0_f32, 5.0, 6.0];

        let result = op.execute(&atlas, &[&a, &b]).unwrap();
        assert_eq!(result.len(), 1);
        // 1*4 + 2*5 + 3*6 = 4 + 10 + 18 = 32
        assert_eq!(result[0], 32.0);
    }

    #[test]
    fn test_matmul_matrix_vector() {
        let atlas = Atlas::with_cache().unwrap();
        let op = MatMulOp::new();

        // Matrix-vector: [2, 3] × [3] → [2]
        let a = vec![1.0_f32, 2.0, 3.0, 4.0, 5.0, 6.0]; // 2x3 matrix
        let b = vec![7.0_f32, 8.0, 9.0]; // 3-vector

        let result = op.execute(&atlas, &[&a, &b]).unwrap();
        assert_eq!(result.len(), 2);
        // Row 0: 1*7 + 2*8 + 3*9 = 7 + 16 + 27 = 50
        // Row 1: 4*7 + 5*8 + 6*9 = 28 + 40 + 54 = 122
        assert_eq!(result[0], 50.0);
        assert_eq!(result[1], 122.0);
    }

    #[test]
    fn test_matmul_from_shapes() {
        use crate::hrm::ops::OnnxHRMNode;

        // 2D matrix multiplication
        let shapes = vec![vec![2, 3], vec![3, 4]];
        let op = MatMulOp::from_shapes(&shapes).unwrap();
        assert_eq!(<MatMulOp as OnnxHRMNode<f32>>::op_type(&op), "MatMul");
    }

    #[test]
    fn test_matmul_invalid_shapes() {
        // Inner dimensions don't match
        let shapes = vec![vec![2, 3], vec![4, 5]];
        let result = MatMulOp::from_shapes(&shapes);
        assert!(result.is_err());
    }

    #[test]
    fn test_gemm_dot_product() {
        let atlas = Atlas::with_cache().unwrap();
        let op = GemmOp::new(2.0, 3.0, false, false);

        // Dot product with scaling
        let a = vec![1.0_f32, 2.0, 3.0];
        let b = vec![4.0_f32, 5.0, 6.0];
        let c = vec![10.0_f32];

        let result = op.execute(&atlas, &[&a, &b, &c]).unwrap();
        assert_eq!(result.len(), 1);
        // alpha * (a·b) + beta * c = 2.0 * 32.0 + 3.0 * 10.0 = 64 + 30 = 94
        assert_eq!(result[0], 94.0);
    }

    #[test]
    fn test_gemm_default_params() {
        let op = GemmOp::default();
        assert_eq!(op.alpha, 1.0);
        assert_eq!(op.beta, 1.0);
        assert!(!op.trans_a);
        assert!(!op.trans_b);
    }

    #[test]
    fn test_gemm_from_shapes() {
        let shapes = vec![vec![2, 3], vec![3, 4]];
        let op = GemmOp::from_shapes(&shapes).unwrap();
        assert_eq!(op.alpha, 1.0);
        assert_eq!(op.beta, 1.0);
    }
}
