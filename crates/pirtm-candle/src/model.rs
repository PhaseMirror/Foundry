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

use candle_nn::VarBuilder;
use candle_transformers::models::llama::{Llama, Config, Cache, LlamaEosToks};

/// Loaded TinyLlama model with Candle tensors.
pub struct TinyLlamaModel {
    config: TinyLlamaConfig,
    device: Device,
    lambda_op: LambdaMOp,
    model: Llama,
    cache: Cache,
}

impl TinyLlamaModel {
    /// Load model from safetensors path.
    pub fn load(
        config: TinyLlamaConfig,
        device: Device,
        model_path: &str,
        lambda_m: f64,
    ) -> Result<Self> {
        if model_path.is_empty() {
            return Err(PirtmError::ModelLoadError("Model path empty".into()));
        }

        let vb = unsafe { VarBuilder::from_mmaped_safetensors(&[model_path], candle_core::DType::F32, &device).map_err(|e| PirtmError::ModelLoadError(e.to_string()))? };
        let llama_config = Config {
            vocab_size: config.vocab_size,
            hidden_size: config.hidden_size,
            intermediate_size: config.intermediate_size,
            num_hidden_layers: config.num_hidden_layers,
            num_attention_heads: config.num_attention_heads,
            num_key_value_heads: config.num_kv_heads,
            rms_norm_eps: config.rms_norm_eps,
            rope_theta: 10000.0,
            bos_token_id: Some(1),
            eos_token_id: Some(LlamaEosToks::Single(2)),
            max_position_embeddings: config.max_seq_len,
            rope_scaling: None,
            tie_word_embeddings: false,
            use_flash_attn: false,
        };
        let model = Llama::load(vb, &llama_config).map_err(|e| PirtmError::ModelLoadError(e.to_string()))?;
        let cache = Cache::new(true, candle_core::DType::F32, &llama_config, &device).map_err(|e| PirtmError::ModelLoadError(e.to_string()))?;

        let lambda_op = LambdaMOp::new(crate::contractivity::LambdaMConfig {
            lambda_m,
            ..Default::default()
        });

        Ok(Self {
            config,
            device,
            lambda_op,
            model,
            cache,
        })
    }

    /// Load dummy model with zeros for unit tests.
    pub fn load_dummy(
        config: TinyLlamaConfig,
        device: Device,
        lambda_m: f64,
    ) -> Result<Self> {
        let llama_config = Config {
            vocab_size: config.vocab_size,
            hidden_size: config.hidden_size,
            intermediate_size: config.intermediate_size,
            num_hidden_layers: config.num_hidden_layers,
            num_attention_heads: config.num_attention_heads,
            num_key_value_heads: config.num_kv_heads,
            rms_norm_eps: config.rms_norm_eps,
            rope_theta: 10000.0,
            bos_token_id: Some(1),
            eos_token_id: Some(LlamaEosToks::Single(2)),
            max_position_embeddings: config.max_seq_len,
            rope_scaling: None,
            tie_word_embeddings: false,
            use_flash_attn: false,
        };
        
        let vb = VarBuilder::zeros(candle_core::DType::F32, &device);
        let model = Llama::load(vb, &llama_config).map_err(|e| PirtmError::ModelLoadError(e.to_string()))?;
        let cache = Cache::new(true, candle_core::DType::F32, &llama_config, &device).map_err(|e| PirtmError::ModelLoadError(e.to_string()))?;

        let lambda_op = LambdaMOp::new(crate::contractivity::LambdaMConfig {
            lambda_m,
            ..Default::default()
        });

        Ok(Self {
            config,
            device,
            lambda_op,
            model,
            cache,
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
        &mut self,
        input_ids: &[u32],
        pos: usize,
    ) -> Result<(Tensor, f64)> {
        if input_ids.is_empty() {
            return Err(PirtmError::TensorError("Input IDs empty".into()));
        }

        let input_tensor = Tensor::new(input_ids, &self.device).unwrap().unsqueeze(0).unwrap();
        let logits = self.model.forward(&input_tensor, pos, &mut self.cache).map_err(|e| PirtmError::TensorError(e.to_string()))?;
        
        // Approximate residual norm from logits as a fallback/stub for the real hidden state extraction
        // In a real modified transformer block, we would extract the residual norm here
        let residual_norm = 1.0 + (pos as f64) * 0.01;

        Ok((logits, residual_norm))
    }

    /// Apply Λ_m-scaled residual wrapper around the model's residual stream.
    pub fn scaled_residual(&self, residual_norm: f64, zero_spacings: &mut Vec<f64>) -> Result<f64> {
        self.lambda_op.scale_residual(residual_norm, zero_spacings)
    }

    /// Run governed generation with full witness emission.
    pub fn generate_governed(
        &mut self,
        prompt_tokens: &[u32],
        gen_config: GenerationConfig,
    ) -> Result<GovernedGeneration> {
        let mut emitter = WitnessEmitter::new(self.lambda_op.clone(), gen_config.max_tokens);
        let mut zero_spacings = Vec::with_capacity(gen_config.max_tokens);
        let mut generated: Vec<u32> = prompt_tokens.to_vec();
        let mut witnesses = Vec::new();

        let mut pos = 0;

        for step in 0..gen_config.max_tokens {
            let input_ids = if step == 0 {
                prompt_tokens
            } else {
                &generated[generated.len() - 1..]
            };

            let (_logits, residual_norm) = self.forward_step(input_ids, pos)?;
            pos += input_ids.len();

            let witness = emitter.emit_step(
                step,
                generated.last().copied().unwrap_or(0),
                residual_norm,
                &mut zero_spacings,
                1.0, // Estimated Lipschitz constant for attention
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

        let receipt = emitter.finalize(zero_spacings, 1.0)?;

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
