//! Error types and recovery strategies for MERSENNE_503.
//!
//! All error variants carry structured metadata for programmatic recovery.

use thiserror::Error;

/// Result type alias for MERSENNE_503 operations.
pub type Result<T> = std::result::Result<T, Error>;

/// Primary error type for MERSENNE_503 verification failures.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum Error {
    /// Mersenne field arithmetic overflow or invalid operation.
    #[error("mersenne field error: {message}")]
    MersenneField { message: String },

    /// Leech lattice code violation.
    #[error("leech lattice error: {message}")]
    LeechLattice { message: String },

    /// Tensor field invariant violation.
    #[error("tensor invariant violated: {message}")]
    TensorInvariant { message: String },

    /// PSL(2,R) group operation error.
    #[error("PSL(2,R) error: {message}")]
    PSL2R { message: String },

    /// AdS geometry constraint violation.
    #[error("AdS geometry error: {message}")]
    AdSGeometry { message: String },

    /// Bayesian crystallization failure.
    #[error("crystallization error: {message}")]
    Crystallization { message: String },

    /// Cryptographic primitive verification failed.
    #[error("crypto verification failed: {proof_name}")]
    CryptoVerification { proof_name: &'static str },

    /// Serialization round-trip verification failed.
    #[error("serialization round-trip failed for type {ty}")]
    SerializationRoundTrip { ty: &'static str },

    /// Configuration or environment error.
    #[error("configuration error: {message}")]
    Configuration { message: String },
}

impl Error {
    /// Create a Mersenne field error.
    pub fn mersenne_field(message: impl Into<String>) -> Self {
        Self::MersenneField { message: message.into() }
    }

    /// Create a Leech lattice error.
    pub fn leech_lattice(message: impl Into<String>) -> Self {
        Self::LeechLattice { message: message.into() }
    }

    /// Create a tensor invariant error.
    pub fn tensor_invariant(message: impl Into<String>) -> Self {
        Self::TensorInvariant { message: message.into() }
    }

    /// Create a PSL(2,R) error.
    pub fn psl2r(message: impl Into<String>) -> Self {
        Self::PSL2R { message: message.into() }
    }

    /// Create an AdS geometry error.
    pub fn ads_geometry(message: impl Into<String>) -> Self {
        Self::AdSGeometry { message: message.into() }
    }

    /// Create a crystallization error.
    pub fn crystallization(message: impl Into<String>) -> Self {
        Self::Crystallization { message: message.into() }
    }

    /// Create a crypto verification error.
    pub fn crypto_verification(proof_name: &'static str) -> Self {
        Self::CryptoVerification { proof_name }
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
        let err = Error::mersenne_field("modular overflow");
        assert!(err.to_string().contains("modular overflow"));
    }

    #[test]
    fn test_crypto_error() {
        let err = Error::crypto_verification("zeno_lock");
        assert!(err.to_string().contains("zeno_lock"));
    }
}
