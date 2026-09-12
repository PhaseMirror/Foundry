//! Error types and recovery strategies for MEA.

use thiserror::Error;

/// Result type alias for MEA operations.
pub type Result<T> = std::result::Result<T, Error>;

/// Primary error type for MEA verification failures.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum Error {
    /// Monoidal category invariant violation.
    #[error("monoidal invariant violated: {message}")]
    MonoidalInvariant { message: String },

    /// Ensemble combination error.
    #[error("ensemble error: {message}")]
    Ensemble { message: String },

    /// Aggregation operation error.
    #[error("aggregation error: {message}")]
    Aggregation { message: String },

    /// Algebraic law verification failed.
    #[error("law verification failed: {law}")]
    LawVerification { law: &'static str },

    /// Kani proof failure.
    #[error("kani proof failed: {proof_name}")]
    KaniProofFailed { proof_name: &'static str },

    /// Serialization round-trip failed.
    #[error("serialization round-trip failed for type {ty}")]
    SerializationRoundTrip { ty: &'static str },

    /// Configuration error.
    #[error("configuration error: {message}")]
    Configuration { message: String },
}

impl Error {
    /// Create a monoidal invariant error.
    pub fn monoidal_invariant(message: impl Into<String>) -> Self {
        Self::MonoidalInvariant { message: message.into() }
    }

    /// Create an ensemble error.
    pub fn ensemble(message: impl Into<String>) -> Self {
        Self::Ensemble { message: message.into() }
    }

    /// Create an aggregation error.
    pub fn aggregation(message: impl Into<String>) -> Self {
        Self::Aggregation { message: message.into() }
    }

    /// Create a law verification error.
    pub fn law_verification(law: &'static str) -> Self {
        Self::LawVerification { law }
    }

    /// Create a Kani proof error.
    pub fn kani_proof_failed(proof_name: &'static str) -> Self {
        Self::KaniProofFailed { proof_name }
    }

    /// Create a serialization round-trip error.
    pub fn serialization_round_trip(ty: &'static str) -> Self {
        Self::SerializationRoundTrip { ty }
    }

    /// Create a configuration error.
    pub fn configuration(message: impl Into<String>) -> Self {
        Self::Configuration { message: message.into() }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_display() {
        let err = Error::monoidal_invariant("associativity violation");
        assert!(err.to_string().contains("associativity violation"));
    }

    #[test]
    fn test_law_verification_error() {
        let err = Error::law_verification("associativity");
        assert!(err.to_string().contains("associativity"));
    }
}
