//! Stub interfaces for hologram-onnx integration
//!
//! These types define the interface that hologram-onnx will implement.
//! Currently provides stub implementations for development.

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::path::Path;

use crate::{Error, Result};

/// Tensor data type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum DType {
    Float32,
    Float16,
    Int32,
    Int64,
    UInt8,
}

/// A multi-dimensional array for model input/output
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tensor {
    pub shape: Vec<usize>,
    pub dtype: DType,
    pub data: Vec<u8>,
}

impl Tensor {
    pub fn from_f32(shape: Vec<usize>, data: Vec<f32>) -> Self {
        let bytes: Vec<u8> = data.iter().flat_map(|f| f.to_le_bytes()).collect();
        Self {
            shape,
            dtype: DType::Float32,
            data: bytes,
        }
    }
}

/// Information about a loaded model
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OnnxModelInfo {
    pub name: String,
    pub parameters: u64,
    pub context_length: usize,
    pub embedding_size: usize,
}

/// Configuration for the ONNX runtime
#[derive(Debug, Clone)]
pub struct RuntimeConfig {
    pub num_threads: usize,
    pub use_gpu: bool,
}

impl Default for RuntimeConfig {
    fn default() -> Self {
        Self {
            num_threads: num_cpus::get(),
            use_gpu: false,
        }
    }
}

/// Quantization options for model compilation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Quantization {
    #[default]
    None,
    Q4_0,
    Q4_1,
    Q5_0,
    Q5_1,
    Q8_0,
}

/// Options for compiling models to .holo format
#[derive(Debug, Clone, Default)]
pub struct CompileOptions {
    pub quantization: Quantization,
    pub optimize: bool,
}

/// Trait for inference engines
/// This will be implemented by hologram-onnx when available
#[async_trait]
pub trait InferenceEngine: Send + Sync {
    /// Generate tokens from input IDs
    async fn generate(&self, input_ids: &[u32], max_tokens: usize) -> Result<Vec<u32>>;

    /// Get model information
    fn model_info(&self) -> &OnnxModelInfo;

    /// Unload the model from memory
    async fn unload(&self) -> Result<()>;
}

/// Stub ONNX runtime - will be replaced by hologram-onnx
pub struct OnnxRuntime {
    config: RuntimeConfig,
}

impl OnnxRuntime {
    pub fn new(config: RuntimeConfig) -> Result<Self> {
        Ok(Self { config })
    }

    pub fn with_defaults() -> Result<Self> {
        Self::new(RuntimeConfig::default())
    }

    pub fn config(&self) -> &RuntimeConfig {
        &self.config
    }

    /// Load a .holo model (stub - returns error)
    pub async fn load_holo(&self, path: &Path) -> Result<StubModel> {
        tracing::warn!("OnnxRuntime::load_holo is a stub - hologram-onnx not yet integrated");
        Err(Error::Onnx(format!(
            "Cannot load model at {}: hologram-onnx not yet integrated",
            path.display()
        )))
    }

    /// Load an ONNX model (stub - returns error)
    pub async fn load_onnx(&self, path: &Path) -> Result<StubModel> {
        tracing::warn!("OnnxRuntime::load_onnx is a stub - hologram-onnx not yet integrated");
        Err(Error::Onnx(format!(
            "Cannot load model at {}: hologram-onnx not yet integrated",
            path.display()
        )))
    }
}

/// Stub compiler - will be replaced by hologram-onnx
pub struct HoloCompiler;

impl HoloCompiler {
    /// Compile ONNX to .holo format (stub - returns error)
    pub async fn compile(
        onnx_path: &Path,
        output_path: &Path,
        _options: CompileOptions,
    ) -> Result<()> {
        tracing::warn!("HoloCompiler::compile is a stub - hologram-onnx not yet integrated");
        Err(Error::Compilation(format!(
            "Cannot compile {} to {}: hologram-onnx not yet integrated",
            onnx_path.display(),
            output_path.display()
        )))
    }

    /// Convert SafeTensors to .holo format (stub - returns error)
    pub async fn from_safetensors(
        safetensors_dir: &Path,
        output_path: &Path,
        _options: CompileOptions,
    ) -> Result<()> {
        tracing::warn!(
            "HoloCompiler::from_safetensors is a stub - hologram-onnx not yet integrated"
        );
        Err(Error::Compilation(format!(
            "Cannot convert {} to {}: hologram-onnx not yet integrated",
            safetensors_dir.display(),
            output_path.display()
        )))
    }
}

/// Stub model - placeholder until hologram-onnx is integrated
pub struct StubModel {
    info: OnnxModelInfo,
}

#[async_trait]
impl InferenceEngine for StubModel {
    async fn generate(&self, _input_ids: &[u32], _max_tokens: usize) -> Result<Vec<u32>> {
        Err(Error::Inference(
            "StubModel cannot perform inference - hologram-onnx not yet integrated".to_string(),
        ))
    }

    fn model_info(&self) -> &OnnxModelInfo {
        &self.info
    }

    async fn unload(&self) -> Result<()> {
        Ok(())
    }
}
