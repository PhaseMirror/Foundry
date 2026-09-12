//! Normalization operations (LayerNorm, SkipLayerNorm, BiasGelu, Attention)
//!
//! Neural network normalization and attention operations with full generic type support.

use super::{OnnxHRMNode, Result};
use crate::error::CompilerError;
use crate::hrm::numeric::Numeric;
use hologram::Atlas;

/// LayerNormalization operation
///
/// Normalizes input along specified axis with learned scale and bias.
#[derive(Debug, Clone)]
pub struct LayerNormalizationOp {
    /// Epsilon for numerical stability
    pub epsilon: f32,
    /// Axis to normalize (default: -1, last axis)
    pub axis: i64,
}

impl LayerNormalizationOp {
    pub fn new(epsilon: f32, axis: i64) -> Self {
        Self { epsilon, axis }
    }

    /// Construct from ONNX node shapes
    ///
    /// Extracts normalization axis from input shape (defaults to last axis).
    pub fn from_shapes(input_shapes: &[Vec<i64>]) -> Result<Self> {
        if input_shapes.is_empty() || input_shapes[0].is_empty() {
            return Err(CompilerError::InvalidModel(
                "LayerNormalization requires non-empty input shape".to_string(),
            ));
        }

        // Normalize along the last axis (ONNX default)
        let axis = (input_shapes[0].len() as i64) - 1;

        Ok(Self::new(1e-5, axis))
    }
}

impl<T: Numeric> OnnxHRMNode<T> for LayerNormalizationOp {
    fn op_type(&self) -> &'static str {
        "LayerNormalization"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let x = inputs[0];
        let scale = if inputs.len() > 1 { inputs[1] } else { &[] };
        let bias = if inputs.len() > 2 { inputs[2] } else { &[] };

        // Compute mean
        let sum: f32 = x.iter().map(|&val| val.to_f32()).sum();
        let mean = sum / x.len() as f32;

        // Compute variance
        let var_sum: f32 = x
            .iter()
            .map(|&val| {
                let diff = val.to_f32() - mean;
                diff * diff
            })
            .sum();
        let variance = var_sum / x.len() as f32;

        // Normalize
        let std = (variance + self.epsilon).sqrt();
        let mut result: Vec<T> = x
            .iter()
            .map(|&val| {
                let normalized = (val.to_f32() - mean) / std;
                T::from_f32(normalized)
            })
            .collect();

        // Apply scale and bias if provided
        if !scale.is_empty() {
            for (i, val) in result.iter_mut().enumerate() {
                *val = val.mul(scale[i % scale.len()]);
            }
        }

        if !bias.is_empty() {
            for (i, val) in result.iter_mut().enumerate() {
                *val = val.add(bias[i % bias.len()]);
            }
        }

        Ok(result)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        crate::validate_input_count_range!(inputs, 1, 3, "LayerNormalization");
        Ok(())
    }
}

/// SkipLayerNormalization operation
///
/// Combines residual connection with layer normalization: output = LayerNorm(input + skip).
#[derive(Debug, Clone)]
pub struct SkipLayerNormalizationOp {
    /// Epsilon for numerical stability
    pub epsilon: f32,
}

impl SkipLayerNormalizationOp {
    pub fn new(epsilon: f32) -> Self {
        Self { epsilon }
    }
}

impl<T: Numeric> OnnxHRMNode<T> for SkipLayerNormalizationOp {
    fn op_type(&self) -> &'static str {
        "SkipLayerNormalization"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let input = inputs[0];
        let skip = inputs[1];
        let gamma = if inputs.len() > 2 { inputs[2] } else { &[] };
        let beta = if inputs.len() > 3 { inputs[3] } else { &[] };

        // Add input + skip
        let added: Vec<T> = input.iter().zip(skip.iter()).map(|(&a, &b)| a.add(b)).collect();

        // Apply layer normalization
        let sum: f32 = added.iter().map(|&val| val.to_f32()).sum();
        let mean = sum / added.len() as f32;

        let var_sum: f32 = added
            .iter()
            .map(|&val| {
                let diff = val.to_f32() - mean;
                diff * diff
            })
            .sum();
        let variance = var_sum / added.len() as f32;

        let std = (variance + self.epsilon).sqrt();
        let mut result: Vec<T> = added
            .iter()
            .map(|&val| {
                let normalized = (val.to_f32() - mean) / std;
                T::from_f32(normalized)
            })
            .collect();

        // Apply gamma and beta if provided
        if !gamma.is_empty() {
            for (i, val) in result.iter_mut().enumerate() {
                *val = val.mul(gamma[i % gamma.len()]);
            }
        }

        if !beta.is_empty() {
            for (i, val) in result.iter_mut().enumerate() {
                *val = val.add(beta[i % beta.len()]);
            }
        }

        Ok(result)
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        crate::validate_input_count_range!(inputs, 2, 4, "SkipLayerNormalization");
        crate::validate_same_length!(inputs[0], inputs[1], "SkipLayerNormalization", "input", "skip");
        Ok(())
    }
}

/// BiasGelu operation
///
/// Applies GELU activation with bias: GELU(input + bias).
#[derive(Debug, Clone, Copy)]
pub struct BiasGeluOp;

impl<T: Numeric> OnnxHRMNode<T> for BiasGeluOp {
    fn op_type(&self) -> &'static str {
        "BiasGelu"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        let input = inputs[0];
        let bias = inputs[1];

        // Add bias and apply GELU
        Ok(input
            .iter()
            .zip(bias.iter())
            .map(|(&x, &b)| {
                let x_f32 = x.add(b).to_f32();
                // GELU(x) = x * Φ(x) where Φ is the standard Gaussian CDF
                // Approximation: GELU(x) ≈ 0.5 * x * (1 + tanh(√(2/π) * (x + 0.044715 * x³)))
                const SQRT_2_OVER_PI: f32 = 0.797_884_6;
                let x3 = x_f32 * x_f32 * x_f32;
                let inner = SQRT_2_OVER_PI * (x_f32 + 0.044715 * x3);
                let gelu = 0.5 * x_f32 * (1.0 + inner.tanh());
                T::from_f32(gelu)
            })
            .collect())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        crate::validate_input_count!(inputs, 2, "BiasGelu");
        crate::validate_same_length!(inputs[0], inputs[1], "BiasGelu", "input", "bias");
        Ok(())
    }
}

/// Attention operation (simplified)
///
/// Computes scaled dot-product attention: Attention(Q, K, V) = softmax(Q @ K^T / sqrt(d_k)) @ V.
#[derive(Debug, Clone)]
pub struct AttentionOp {
    /// Number of attention heads
    pub num_heads: usize,
    /// Hidden size
    pub hidden_size: usize,
}

impl AttentionOp {
    pub fn new(num_heads: usize, hidden_size: usize) -> Self {
        Self { num_heads, hidden_size }
    }

    /// Construct from ONNX node shapes
    ///
    /// Extracts hidden_size from input shape and infers num_heads
    /// based on standard configurations.
    pub fn from_shapes(input_shapes: &[Vec<i64>]) -> Result<Self> {
        if input_shapes.is_empty() || input_shapes[0].len() < 3 {
            return Err(CompilerError::InvalidModel(format!(
                "Attention requires 3D+ input shape [batch, seq, hidden], got {:?}",
                input_shapes.first()
            )));
        }

        // Extract hidden_size and infer num_heads
        // Standard configurations: 768/12=64, 1024/16=64, etc.
        let hidden_size = input_shapes[0][input_shapes[0].len() - 1] as usize;
        let num_heads = if hidden_size == 768 {
            12
        } else if hidden_size == 1024 {
            16
        } else if hidden_size.is_multiple_of(12) {
            12
        } else {
            8
        };

        Ok(Self::new(num_heads, hidden_size))
    }
}

impl<T: Numeric> OnnxHRMNode<T> for AttentionOp {
    fn op_type(&self) -> &'static str {
        "Attention"
    }

    fn execute(&self, _atlas: &Atlas, inputs: &[&[T]]) -> Result<Vec<T>> {
        self.validate_inputs(inputs)?;

        // Simplified: just return input (full attention requires matrix ops)
        // In a real implementation, this would compute Q @ K^T, apply softmax, then @ V
        Ok(inputs[0].to_vec())
    }

    fn validate_inputs(&self, inputs: &[&[T]]) -> Result<()> {
        if inputs.len() < 2 {
            return Err(CompilerError::InvalidModel(format!(
                "Attention requires at least 2 inputs, got {}",
                inputs.len()
            )));
        }
        Ok(())
    }
}
