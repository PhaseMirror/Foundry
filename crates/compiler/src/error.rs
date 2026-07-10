use pirtm_mlir::PirtmOp;
use std::path::PathBuf;
use thiserror::Error;

/// Compile-time errors for the PIRTM compiler.
#[derive(Debug, Error)]
pub enum CompileError {
    #[error("PM001: Parse error at {location}: {message}")]
    ParseError { location: String, message: String },

    #[error("PM002: Validation failed for {item}: {message}")]
    ValidationError { item: String, message: String },

    #[error("PM003: MLIR emission failed: {message}")]
    MlirError { message: String },

    #[error("PM004: Proof verification failed: {message}")]
    ProofFailed { message: String },

    #[error("PM005: I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("PM006: Translation error: {message}")]
    TranslationError { message: String },

    #[error("PM007: Lean binary not found: {path}")]
    LeanNotFound { path: String },
}

/// Proof verification errors.
#[derive(Debug, Error)]
pub enum ProofError {
    #[error("PE001: Lean file not found: {0}")]
    FileNotFound(PathBuf),

    #[error("PE002: Lean execution failed: {stderr}")]
    LeanFailed { stderr: String },

    #[error("PE003: Invalid Lean output - proof did not complete")]
    InvalidOutput,

    #[error("PE004: Lean binary not in PATH")]
    LeanNotInstalled,

    #[error("PE005: Proof hash computation failed")]
    HashFailed,
}

/// Translation target errors.
#[derive(Debug, Error)]
pub enum TranslateError {
    #[error("TE001: Input file not found: {0}")]
    InputNotFound(String),

    #[error("TE002: Invalid target '{0}'. Use 'llvm' or 'wasm'.")]
    InvalidTarget(String),

    #[error("TE003: mlir-translate execution failed: {stderr}")]
    MlirTranslateFailed { stderr: String },

    #[error("TE004: No output produced")]
    NoOutput,
}

/// A valid proof receipt containing witness data.
#[derive(Debug, Clone)]
pub struct ProofReceipt {
    pub hash: String,
    pub lambda_p: f64,
    pub l_p: f64,
    pub zero_spacings: Vec<f64>,
    pub signature: String,
    pub signer_pubkey: String,
}

/// MLIR module representation.
#[derive(Debug, Clone)]
pub struct MlirModule {
    pub source: String,
    pub ops: Vec<PirtmOp>,
}
