//! Error types and recovery strategies for the MCPE verification framework.
//!
//! All error variants carry structured metadata for programmatic recovery.

use thiserror::Error;

/// Result type alias for MCPE operations.
pub type Result<T> = std::result::Result<T, Error>;

/// Primary error type for MCPE verification failures.
#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum Error {
    /// Protocol invariant violation during state transition.
    #[error("protocol invariant violated: {message}")]
    ProtocolInvariant { message: String },

    /// Bit-precision overflow in numeric operation.
    #[error("numeric overflow in {operation} with value {value}")]
    NumericOverflow { operation: &'static str, value: u64 },

    /// Serialization round-trip verification failed.
    #[error("serialization round-trip failed for type {ty}")]
    SerializationRoundTrip { ty: &'static str },

    /// Kani verification proof could not be discharged.
    #[error("kani proof failed: {proof_name}")]
    KaniProofFailed { proof_name: &'static str },

    /// Invalid state transition detected.
    #[error("invalid transition from {from:?} to {to:?}")]
    InvalidTransition { from: StateId, to: StateId },

    /// Configuration or environment error.
    #[error("configuration error: {message}")]
    Configuration { message: String },
}

/// State identifier for tracing transitions.
#[derive(Error, Debug, Clone, Copy, PartialEq, Eq, Hash)]
#[error("state {0}")]
pub struct StateId(pub u32);

impl StateId {
    /// Create a new state identifier.
    pub fn new(id: u32) -> Self {
        Self(id)
    }

    /// Get the underlying numeric identifier.
    pub fn value(&self) -> u32 {
        self.0
    }
}

impl Error {
    /// Create a protocol invariant error.
    pub fn protocol_invariant(message: impl Into<String>) -> Self {
        Self::ProtocolInvariant {
            message: message.into(),
        }
    }

    /// Create a numeric overflow error.
    pub fn numeric_overflow(operation: &'static str, value: u64) -> Self {
        Self::NumericOverflow { operation, value }
    }

    /// Create a serialization round-trip error.
    pub fn serialization_round_trip(ty: &'static str) -> Self {
        Self::SerializationRoundTrip { ty }
    }

    /// Create a Kani proof failure error.
    pub fn kani_proof_failed(proof_name: &'static str) -> Self {
        Self::KaniProofFailed { proof_name }
    }

    /// Create an invalid transition error.
    pub fn invalid_transition(from: StateId, to: StateId) -> Self {
        Self::InvalidTransition { from, to }
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
        let err = Error::protocol_invariant("test violation");
        assert!(err.to_string().contains("protocol invariant violated"));
    }

    #[test]
    fn test_state_id() {
        let id = StateId::new(42);
        assert_eq!(id.value(), 42);
    }
}
