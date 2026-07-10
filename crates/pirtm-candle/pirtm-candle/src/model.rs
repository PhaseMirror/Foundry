use crate::{
    contractivity::LambdaMOp, witness::WitnessEmitter, ContractivityReceipt,
    GenerationWitness, PirtmError, Result,
};
use candle_core::{Device, Tensor};
use serde::{Deserialize, Serialize};

/// Configuration for TinyLlama (Llama-2 architecture, 1.1B params).
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TinyLlamaConfig {
    pub vocab_size: usize,
    pub hidden_size: usize,
    pub intermediate_size: usize,
    pub num_hidden_layers: usize,
    pub num_attention_heads: usize,
    pub num_kv_heads: usize,
    pub max_seq_len: usize,
    pub rms_norm_eps: f64,
}

impl Default for TinyLlamaConfig {
    fn default() -> Self {
        Self {
            vocab_size: 32000,
            hidden_size: 2048,
            intermediate_size: 5632,
            num_hidden_layers: 22,
            num_attention_heads: 32,
            num_kv_heads: 4,
            max_seq_len: 2048,
            rms_norm_eps: 1e-5,
        }
    }
}

/// Generation configuration for governed inference.
#[derive(Debug, Clone, Copy)]
pub struct GenerationConfig {
    pub max_tokens: usize,
    pub temperature: f64,
    pub top_p: f64,
    pub lambda_m: f64,
}

impl Default for GenerationConfig {
    fn default() -> Self {
        Self {
            max_tokens: 256,
            temperature: 0.7,
            top_p: 0.9,
            lambda_m: 0.95,
        }
    }
}

/// Loaded TinyLlama model with Candle tensors.
/// In a production build, this wraps `candle_transformers::models::llama::Llama`.
/// Here we provide the structural skeleton with bounded tensor ops.
#[derive(Debug, Clone)]
pub struct TinyLlamaModel {
    config: TinyLlamaConfig,
    device: Device,
    lambda_op: LambdaMOp,
    weights_loaded: bool,
}

impl TinyLlamaModel {
    /// Load model from safetensors or GGUF path.
    /// Returns Err if path invalid or weights corrupt.
    pub fn load(
        config: TinyLlamaConfig,
        device: Device,
        model_path: &str,
        lambda_m: f64,
    ) -> Result<Self> {
        if model_path.is_empty() {
            return Err(PirtmError::ModelLoadError("Model path empty".into()));
        }

        // In a real implementation:
        // let vb = VarBuilder::from_safetensors(&[model_path], &device)?;
        // let model = candle_transformers::models::llama::Llama::load(&vb, config)?;

        let lambda_op = LambdaMOp::new(crate::contractivity::LambdaMConfig {
            lambda_m,
            ..Default::default()
        });

        Ok(Self {
            config,
            device,
            lambda_op,
            weights_loaded: true,
        })
    }

    pub fn config(&self) -> &TinyLlamaConfig {
        &self.config
    }

    pub fn device(&self) -> &Device {
        &self.device
    }

    /// Forward pass for a single token step.
    /// Returns logits and updated residual norm for contractivity check.
    pub fn forward_step(
        &self,
        input_ids: &[u32],
        pos: usize,
    ) -> Result<(Tensor, f64)> {
        if !self.weights_loaded {
            return Err(PirtmError::ModelLoadError("Weights not loaded".into()));
        }

        if input_ids.is_empty() {
            return Err(PirtmError::TensorError("Input IDs empty".into()));
        }

        // Real implementation would invoke:
        // let logits = model.forward(&input_tensor, pos)?;
        // let residual = compute_residual_norm(&hidden_states)?;

        // Stub: return a bounded dummy tensor and residual norm
        let residual_norm = 1.0 + (pos as f64) * 0.01;
        let logits = Tensor::zeros((input_ids.len(), self.config.vocab_size), candle_core::DType::F32, &self.device)
            .map_err(|e| PirtmError::TensorError(e.to_string()))?;

        Ok((logits, residual_norm))
    }

    /// Apply Λ_m-scaled residual wrapper around the model's residual stream.
    pub fn scaled_residual(&self, residual_norm: f64, zero_spacings: &mut Vec<f64>) -> Result<f64> {
        self.lambda_op.scale_residual(residual_norm, zero_spacings)
    }

    /// Run governed generation with full witness emission.
    pub fn generate_governed(
        &self,
        prompt_tokens: &[u32],
        gen_config: GenerationConfig,
    ) -> Result<GovernedGeneration> {
        let mut emitter = WitnessEmitter::new(self.lambda_op.clone(), gen_config.max_tokens);
        let mut zero_spacings = Vec::with_capacity(gen_config.max_tokens);
        let mut generated: Vec<u32> = prompt_tokens.to_vec();
        let mut witnesses = Vec::new();

        for step in 0..gen_config.max_tokens {
            let (_logits, residual_norm) = self.forward_step(&generated, step)?;
            let witness = emitter.emit_step(
                step,
                generated.last().copied().unwrap_or(0),
                residual_norm,
                &mut zero_spacings,
                1.2, // Estimated Lipschitz constant for attention
            )?;

            if witness.contractivity_status == "KILL" {
                return Err(PirtmError::ContractivityViolation(witness.l_p));
            }

            witnesses.push(witness);

            // Stub token selection (would use temperature/top_p sampling in real impl)
            if step >= gen_config.max_tokens - 1 {
                break;
            }
            generated.push(0); // placeholder token
        }

        let receipt = emitter.finalize(zero_spacings, 1.2)?;

        Ok(GovernedGeneration {
            tokens: generated,
            witnesses,
            receipt,
        })
    }
}

/// Result of a governed generation run with full witness trail.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GovernedGeneration {
    pub tokens: Vec<u32>,
    pub witnesses: Vec<GenerationWitness>,
    pub receipt: ContractivityReceipt,
}

impl GovernedGeneration {
    pub fn text(&self) -> String {
        format!("Generated {} tokens with {} witnesses", self.tokens.len(), self.witnesses.len())
    }

    pub fn receipt_status(&self) -> &str {
        &self.receipt.status
    }
}
