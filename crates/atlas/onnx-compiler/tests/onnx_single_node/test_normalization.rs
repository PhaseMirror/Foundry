//! Single-Node Tests for Normalization Operators
//!
//! Tests the following ONNX normalization operators in isolation:
//! - LayerNormalization: Normalize along axis with scale and bias
//! - SkipLayerNormalization: Add skip connection then normalize
//! - BiasGelu: GELU activation with bias
//! - Attention: Scaled dot-product attention (simplified)

use crate::onnx_single_node::*;
use hologram::Atlas;
use hologram_onnx_compiler::hrm::ops::{
    AttentionOp, BiasGeluOp, LayerNormalizationOp, OnnxHRMNode, SkipLayerNormalizationOp,
};

#[cfg(test)]
mod test_layer_normalization {
    use super::*;

    #[test]
    fn test_layer_norm_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let layer_norm_op = LayerNormalizationOp::new(1e-5, -1);

        // Simple input
        let input = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let result = layer_norm_op.execute(&atlas, &[&input]).unwrap();

        // After normalization, mean should be ~0 and variance ~1
        let mean: f32 = result.iter().sum::<f32>() / result.len() as f32;
        assert!(mean.abs() < 1e-5_f32, "Mean should be near 0, got {}", mean);

        // Check all finite
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
    }

    #[test]
    fn test_layer_norm_with_scale() {
        let atlas = Atlas::with_cache().unwrap();
        let layer_norm_op = LayerNormalizationOp::new(1e-5, -1);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let scale = vec![2.0, 2.0, 2.0, 2.0]; // Scale by 2
        let result = layer_norm_op.execute(&atlas, &[&input, &scale]).unwrap();

        // Result should be scaled normalized values
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
        assert_eq!(result.len(), input.len());
    }

    #[test]
    fn test_layer_norm_with_scale_and_bias() {
        let atlas = Atlas::with_cache().unwrap();
        let layer_norm_op = LayerNormalizationOp::new(1e-5, -1);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let scale = vec![1.0, 1.0, 1.0, 1.0];
        let bias = vec![1.0, 1.0, 1.0, 1.0]; // Shift by 1
        let result = layer_norm_op
            .execute(&atlas, &[&input, &scale, &bias])
            .unwrap();

        // All values should be shifted up by bias
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
        assert_eq!(result.len(), input.len());
    }

    #[test]
    fn test_layer_norm_zero_mean() {
        let atlas = Atlas::with_cache().unwrap();
        let layer_norm_op = LayerNormalizationOp::new(1e-5, -1);

        // Input already centered around zero
        let input = vec![-2.0, -1.0, 0.0, 1.0, 2.0];
        let result = layer_norm_op.execute(&atlas, &[&input]).unwrap();

        // Mean should be near 0
        let mean: f32 = result.iter().sum::<f32>() / result.len() as f32;
        assert!(mean.abs() < 1e-5_f32);
    }

    #[test]
    fn test_layer_norm_constant_input() {
        let atlas = Atlas::with_cache().unwrap();
        let layer_norm_op = LayerNormalizationOp::new(1e-5, -1);

        // Constant input (zero variance)
        let input = vec![5.0, 5.0, 5.0, 5.0];
        let result = layer_norm_op.execute(&atlas, &[&input]).unwrap();

        // With epsilon, should not have NaN/Inf
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
    }

    #[test]
    fn test_layer_norm_various_sizes() {
        let atlas = Atlas::with_cache().unwrap();
        let layer_norm_op = LayerNormalizationOp::new(1e-5, -1);

        // Different input sizes
        for size in [3, 5, 10, 100].iter() {
            let input: Vec<f32> = (0..*size).map(|i| i as f32).collect();
            let result = layer_norm_op.execute(&atlas, &[&input]).unwrap();

            assert_eq!(result.len(), *size);
            assert!(result.iter().all(|&x: &f32| x.is_finite()));
        }
    }
}

#[cfg(test)]
mod test_skip_layer_normalization {
    use super::*;

    #[test]
    fn test_skip_layer_norm_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let skip_norm_op = SkipLayerNormalizationOp::new(1e-5);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let skip = vec![0.5, 0.5, 0.5, 0.5];
        let result = skip_norm_op.execute(&atlas, &[&input, &skip]).unwrap();

        // Should have normalized (input + skip)
        assert_eq!(result.len(), input.len());
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
    }

    #[test]
    fn test_skip_layer_norm_with_gamma_beta() {
        let atlas = Atlas::with_cache().unwrap();
        let skip_norm_op = SkipLayerNormalizationOp::new(1e-5);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let skip = vec![1.0, 1.0, 1.0, 1.0];
        let gamma = vec![2.0, 2.0, 2.0, 2.0];
        let beta = vec![0.5, 0.5, 0.5, 0.5];

        let result = skip_norm_op
            .execute(&atlas, &[&input, &skip, &gamma, &beta])
            .unwrap();

        assert_eq!(result.len(), input.len());
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
    }

    #[test]
    fn test_skip_layer_norm_zero_skip() {
        let atlas = Atlas::with_cache().unwrap();
        let skip_norm_op = SkipLayerNormalizationOp::new(1e-5);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let skip = vec![0.0, 0.0, 0.0, 0.0]; // No skip
        let result = skip_norm_op.execute(&atlas, &[&input, &skip]).unwrap();

        // With zero skip, should be like layer norm on input alone
        assert_eq!(result.len(), input.len());
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
    }

    #[test]
    fn test_skip_layer_norm_equal_skip() {
        let atlas = Atlas::with_cache().unwrap();
        let skip_norm_op = SkipLayerNormalizationOp::new(1e-5);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let skip = input.clone(); // Skip equals input
        let result = skip_norm_op.execute(&atlas, &[&input, &skip]).unwrap();

        // Result should be normalized (input + input) = normalized (2 * input)
        assert_eq!(result.len(), input.len());
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
    }

    #[test]
    fn test_skip_layer_norm_mismatched_sizes() {
        let atlas = Atlas::with_cache().unwrap();
        let skip_norm_op = SkipLayerNormalizationOp::new(1e-5);

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let skip = vec![1.0, 2.0]; // Wrong size

        // Should error on mismatched sizes
        assert!(skip_norm_op.execute(&atlas, &[&input, &skip]).is_err());
    }
}

#[cfg(test)]
mod test_bias_gelu {
    use super::*;

    #[test]
    fn test_bias_gelu_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let bias_gelu_op = BiasGeluOp;

        let input = vec![0.0, 1.0, 2.0, 3.0];
        let bias = vec![0.0, 0.0, 0.0, 0.0]; // No bias
        let result = bias_gelu_op.execute(&atlas, &[&input, &bias]).unwrap();

        // GELU(0) ≈ 0, GELU(positive) > 0
        assert_eq!(result.len(), input.len());
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
        assert!(result[0].abs() < 0.1_f32); // GELU(0) ≈ 0
        assert!(result[1] > 0.0); // GELU(1) > 0
    }

    #[test]
    fn test_bias_gelu_with_bias() {
        let atlas = Atlas::with_cache().unwrap();
        let bias_gelu_op = BiasGeluOp;

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let bias = vec![0.5, 0.5, 0.5, 0.5];
        let result = bias_gelu_op.execute(&atlas, &[&input, &bias]).unwrap();

        // Should compute GELU(input + bias)
        assert_eq!(result.len(), input.len());
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
        assert!(result.iter().all(|&x| x > 0.0)); // All positive inputs → positive outputs
    }

    #[test]
    fn test_bias_gelu_negative_values() {
        let atlas = Atlas::with_cache().unwrap();
        let bias_gelu_op = BiasGeluOp;

        let input = vec![-3.0, -2.0, -1.0, 0.0];
        let bias = vec![0.0, 0.0, 0.0, 0.0];
        let result = bias_gelu_op.execute(&atlas, &[&input, &bias]).unwrap();

        // GELU preserves sign but dampens negative values
        assert_eq!(result.len(), input.len());
        assert!(result.iter().all(|&x: &f32| x.is_finite()));
    }

    #[test]
    fn test_bias_gelu_properties() {
        let atlas = Atlas::with_cache().unwrap();
        let bias_gelu_op = BiasGeluOp;

        let input = vec![-2.0, -1.0, 0.0, 1.0, 2.0];
        let bias = vec![0.0, 0.0, 0.0, 0.0, 0.0];
        let result = bias_gelu_op.execute(&atlas, &[&input, &bias]).unwrap();

        // GELU properties:
        // - GELU(0) ≈ 0
        // - GELU(x) ≈ x for large positive x
        // - GELU(-x) ≈ -GELU(x) approximately (not exactly)
        let r2: f32 = result[2];
        assert!(r2.abs() < 0.1_f32); // GELU(0) ≈ 0
        assert!(result[4] > 1.5); // GELU(2) ≈ 2 for large positive
    }

    #[test]
    fn test_bias_gelu_mismatched_sizes() {
        let atlas = Atlas::with_cache().unwrap();
        let bias_gelu_op = BiasGeluOp;

        let input = vec![1.0, 2.0, 3.0, 4.0];
        let bias = vec![0.5, 0.5]; // Wrong size

        // Should error on mismatched sizes
        assert!(bias_gelu_op.execute(&atlas, &[&input, &bias]).is_err());
    }
}

#[cfg(test)]
mod test_attention {
    use super::*;

    #[test]
    fn test_attention_basic() {
        let atlas = Atlas::with_cache().unwrap();
        let attention_op = AttentionOp::new(8, 512);

        let query = vec![1.0, 2.0, 3.0, 4.0];
        let key = vec![5.0, 6.0, 7.0, 8.0];
        let result = attention_op.execute(&atlas, &[&query, &key]).unwrap();

        // Simplified implementation returns input
        assert_tensors_equal(&result, &query, 1e-6);
    }

    #[test]
    fn test_attention_with_value() {
        let atlas = Atlas::with_cache().unwrap();
        let attention_op = AttentionOp::new(8, 512);

        let query = vec![1.0, 2.0, 3.0, 4.0];
        let key = vec![5.0, 6.0, 7.0, 8.0];
        let value = vec![9.0, 10.0, 11.0, 12.0];
        let result = attention_op
            .execute(&atlas, &[&query, &key, &value])
            .unwrap();

        // Simplified implementation returns input
        assert_tensors_equal(&result, &query, 1e-6);
    }

    #[test]
    fn test_attention_various_heads() {
        let atlas = Atlas::with_cache().unwrap();

        let test_cases = vec![
            (AttentionOp::new(1, 64), "single head"),
            (AttentionOp::new(8, 512), "8 heads"),
            (AttentionOp::new(12, 768), "12 heads"),
            (AttentionOp::new(16, 1024), "16 heads"),
        ];

        let query = vec![1.0, 2.0, 3.0, 4.0];
        let key = vec![5.0, 6.0, 7.0, 8.0];

        for (attention_op, _desc) in test_cases {
            let result = attention_op.execute(&atlas, &[&query, &key]).unwrap();
            assert_tensors_equal(&result, &query, 1e-6);
        }
    }

    #[test]
    fn test_attention_preserves_input() {
        let atlas = Atlas::with_cache().unwrap();
        let attention_op = AttentionOp::new(8, 512);

        let query = vec![1.5, 2.7, 3.9, 4.2];
        let key = vec![5.1, 6.3, 7.5, 8.7];
        let result = attention_op.execute(&atlas, &[&query, &key]).unwrap();

        // Simplified implementation preserves query exactly
        assert_eq!(result.len(), query.len());
        for i in 0..query.len() {
            assert_eq!(result[i], query[i]);
        }
    }

    #[test]
    fn test_attention_insufficient_inputs() {
        let atlas = Atlas::with_cache().unwrap();
        let attention_op = AttentionOp::new(8, 512);

        let query = vec![1.0, 2.0, 3.0, 4.0];

        // Should error with only 1 input
        assert!(attention_op.execute(&atlas, &[&query]).is_err());
    }
}
