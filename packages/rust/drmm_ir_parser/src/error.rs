use serde_json::Error as JsonError;
use std::io::Error as IoError;
use thiserror::Error;

/// Errors that can occur during IR parsing, validation, and canonicalization.
#[derive(Error, Debug)]
pub enum IrError {
    /// Failed to read the input file.
    #[error("IO error: {0}")]
    Io(#[from] IoError),

    /// Failed to parse JSON input.
    #[error("JSON parse error: {0}")]
    Json(#[from] JsonError),

    /// IR version mismatch.
    #[error("Unsupported IR version: {0}, expected 1.0.0")]
    UnsupportedVersion(String),

    /// Schema version mismatch.
    #[error("Unsupported schema_version: {0}, expected 1.0.0")]
    UnsupportedSchema(String),

    /// Node identifier violates the `^[a-z]+_[0-9]{6}$` pattern.
    #[error("Invalid id format: {0}")]
    InvalidId(String),

    /// Duplicate node identifier within its scope.
    #[error("Duplicate id: {0}")]
    DuplicateId(String),

    /// Tensor shape length does not match its declared rank.
    #[error("Tensor shape length mismatch rank")]
    TensorShapeMismatch,

    /// Tensor dimension is zero or negative.
    #[error("Tensor dimension must be positive")]
    TensorDimensionNonPositive,

    /// Iteration count is zero.
    #[error("Iteration count must be > 0")]
    IterationCountZero,

    /// Convergence tolerance is non-positive.
    #[error("Tolerance must be positive")]
    ToleranceNonPositive,

    /// Maximum iteration count is zero.
    #[error("max_iter must be > 0")]
    MaxIterZero,

    /// Branch expression has no conditions.
    #[error("Branch must have at least one condition")]
    EmptyBranch,

    /// Output references an undefined node identifier.
    #[error("Output references undefined node id: {0}")]
    UndefinedReference(String),
}

pub type Result<T> = std::result::Result<T, IrError>;
