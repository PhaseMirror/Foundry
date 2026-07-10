pub mod l0_invariants;
pub mod validator;

pub use l0_invariants::*;
pub use validator::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_l0_invariants_pass() {
        let state = State {
            schema_version: "1.0.0".to_string(),
            schema_hash: "f7a8b9c0d1e2f3g4".to_string(),
            permission_bits: 0,
            drift_magnitude: 0.1,
            nonce: Nonce {
                value: "a".repeat(64),
                issued_at: chrono::Utc::now().timestamp_millis(),
            },
            contraction_witness_score: Some(1.0),
        };
        let result = check_l0_invariants(&state, None);
        assert!(result.passed);
    }

    #[test]
    fn test_validator_drift() {
        let config = L0ValidatorConfig::default();
        let validator = L0Validator::new(config);
        let result = validator.validate_drift_magnitude(10.0, 8.0);
        // (10-8)/8 = 0.25 <= 0.5
        assert!(result.passed);
        assert!(result.message.contains("25.0%"));
    }
}
