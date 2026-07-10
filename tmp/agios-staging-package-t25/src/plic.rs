use crate::audit::LambdaTraceAtom;
use thiserror::Error;
use std::time::{SystemTime, UNIX_EPOCH};

/// Maximum allowable time drift (in milliseconds) for transaction liveness validation.
pub const MAX_ALLOWED_DRIFT_MS: u64 = 300_000; // 5 minutes

/// Maximum allowable contraction witness value (1.0 - 10^-6).
pub const STABILITY_THRESHOLD: f64 = 0.999999;

#[derive(Error, Debug, Clone, PartialEq, Eq)]
pub enum PlicError {
    #[error("Silence Clause Triggered: SNARK proof digest '{0}' has invalid format (must be 64-character hex SHA-256).")]
    InvalidProofDigest(String),

    #[error("Silence Clause Triggered: State root hash '{0}' has invalid format (must be 64-character hex SHA-256).")]
    InvalidStateRoot(String),

    #[error("Silence Clause Triggered: Liveness check failed. Timestamp drift of {drift_ms}ms exceeds threshold of {threshold_ms}ms (liveness/replay check failed).")]
    TimestampDrift {
        drift_ms: u64,
        threshold_ms: u64,
    },

    #[error("Silence Clause Triggered: Contraction witness q = {q} violates stability threshold of {threshold} (system is unstable).")]
    StabilityEnvelopeViolation {
        q: String,
        threshold: String,
    },
}

pub struct PlicExecutionGate;

impl PlicExecutionGate {
    /// Authorizes system state updates only upon successful verification of the LambdaTraceAtom.
    /// Returns `Ok(())` on authorization, or `Err(PlicError)` which triggers the fail-closed "Silence Clause".
    pub fn verify_atom(atom: &LambdaTraceAtom) -> Result<(), PlicError> {
        // 1. Validate SNARK proof digest format (must be a valid 64-char hex SHA-256 hash)
        if atom.proof_digest.len() != 64 || !atom.proof_digest.chars().all(|c| c.is_ascii_hexdigit()) {
            return Err(PlicError::InvalidProofDigest(atom.proof_digest.clone()));
        }

        // 2. Validate State Root Hash format (must be a valid 64-char hex SHA-256 hash)
        if atom.state_root_hash.len() != 64 || !atom.state_root_hash.chars().all(|c| c.is_ascii_hexdigit()) {
            return Err(PlicError::InvalidStateRoot(atom.state_root_hash.clone()));
        }

        // 3. Liveness / Replay protection check
        let now_ms = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        let drift_ms = if now_ms >= atom.timestamp {
            now_ms - atom.timestamp
        } else {
            atom.timestamp - now_ms // Handle negative drift (future clock sync difference)
        };

        if drift_ms > MAX_ALLOWED_DRIFT_MS {
            return Err(PlicError::TimestampDrift {
                drift_ms,
                threshold_ms: MAX_ALLOWED_DRIFT_MS,
            });
        }

        // 4. Validate Contraction Witness (q < 1.0 - 10^-6)
        if atom.q >= STABILITY_THRESHOLD || !atom.q.is_finite() {
            return Err(PlicError::StabilityEnvelopeViolation {
                q: format!("{:.7}", atom.q),
                threshold: format!("{:.7}", STABILITY_THRESHOLD),
            });
        }

        println!("[INFO] [PLIC] LambdaTraceAtom verified. Actuation Authorized.");
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_atom_verification() {
        let valid_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855".to_string();
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        let atom = LambdaTraceAtom {
            proof_digest: valid_hash.clone(),
            state_root_hash: valid_hash,
            timestamp: now,
            q: 0.95,
        };

        assert!(PlicExecutionGate::verify_atom(&atom).is_ok());
    }

    #[test]
    fn test_invalid_proof_digest() {
        let valid_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855".to_string();
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        let atom = LambdaTraceAtom {
            proof_digest: "invalid_proof".to_string(),
            state_root_hash: valid_hash,
            timestamp: now,
            q: 0.95,
        };

        assert_eq!(
            PlicExecutionGate::verify_atom(&atom),
            Err(PlicError::InvalidProofDigest("invalid_proof".to_string()))
        );
    }

    #[test]
    fn test_invalid_state_root() {
        let valid_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855".to_string();
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        let atom = LambdaTraceAtom {
            proof_digest: valid_hash,
            state_root_hash: "invalid_state_root".to_string(),
            timestamp: now,
            q: 0.95,
        };

        assert_eq!(
            PlicExecutionGate::verify_atom(&atom),
            Err(PlicError::InvalidStateRoot("invalid_state_root".to_string()))
        );
    }

    #[test]
    fn test_timestamp_replay_drift() {
        let valid_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855".to_string();
        // 10 minutes ago
        let ten_minutes_ago = (SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64) - 600_000;

        let atom = LambdaTraceAtom {
            proof_digest: valid_hash.clone(),
            state_root_hash: valid_hash,
            timestamp: ten_minutes_ago,
            q: 0.95,
        };

        let result = PlicExecutionGate::verify_atom(&atom);
        assert!(matches!(result, Err(PlicError::TimestampDrift { .. })));
    }

    #[test]
    fn test_stability_envelope_violation() {
        let valid_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855".to_string();
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64;

        let atom = LambdaTraceAtom {
            proof_digest: valid_hash.clone(),
            state_root_hash: valid_hash,
            timestamp: now,
            q: 0.9999999, // Exceeds threshold (0.999999)
        };

        let result = PlicExecutionGate::verify_atom(&atom);
        assert_eq!(
            result,
            Err(PlicError::StabilityEnvelopeViolation {
                q: "0.9999999".to_string(),
                threshold: "0.9999990".to_string()
            })
        );
    }
}
