use thiserror::Error;

#[derive(Error, Debug)]
pub enum RecursiveError {
    #[error("invalid argument: {0}")]
    InvalidArgument(String),
    #[error("proof verification failed: {0}")]
    ProofVerification(String),
}

pub type Result<T> = std::result::Result<T, RecursiveError>;
