//! Error types for the ONNX compiler

use std::io;
use thiserror::Error;

/// Result type for compiler operations
pub type Result<T> = std::result::Result<T, CompilerError>;

/// Errors that can occur during ONNX model compilation
#[derive(Debug, Error)]
pub enum CompilerError {
    #[error("Failed to parse ONNX model: {0}")]
    ParseError(String),

    #[error("Unsupported operation: {0}")]
    UnsupportedOp(String),

    #[error("Invalid model structure: {0}")]
    InvalidModel(String),

    #[error("Shape inference failed: {0}")]
    ShapeInferenceError(String),

    #[error("Graph optimization failed: {0}")]
    OptimizationError(String),

    #[error("Binary generation failed: {0}")]
    BinaryGenerationError(String),

    #[error("Weight extraction failed: {0}")]
    WeightExtractionError(String),

    #[error("IO error: {0}")]
    IoError(#[from] io::Error),

    #[error("Hologram error: {0}")]
    HologramError(String),

    #[error("Safetensors error: {0}")]
    SafetensorsError(String),

    #[error("Missing required attribute: {0}")]
    MissingAttribute(String),

    #[error("Invalid attribute value: {0}")]
    InvalidAttribute(String),

    #[error("Missing hash entry: {0}")]
    MissingHashEntry(u64),

    #[error("Invalid address: {0}")]
    InvalidAddress(String),

    #[error("Serialization error: {0}")]
    SerializationError(String),

    #[error("Protobuf decode error: {0}")]
    DecodeError(#[from] prost::DecodeError),

    #[error("Graph error: {0}")]
    AnyhowError(String),
}

// Manual From implementations for error types
impl From<anyhow::Error> for CompilerError {
    fn from(err: anyhow::Error) -> Self {
        CompilerError::AnyhowError(err.to_string())
    }
}

impl From<hologram::Error> for CompilerError {
    fn from(err: hologram::Error) -> Self {
        CompilerError::HologramError(err.to_string())
    }
}

impl From<serde_json::Error> for CompilerError {
    fn from(err: serde_json::Error) -> Self {
        CompilerError::SerializationError(err.to_string())
    }
}
