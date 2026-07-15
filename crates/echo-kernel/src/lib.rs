pub mod dialetheic;
pub mod aperture;
pub mod contractivity;
pub mod identity;
pub mod braid;

pub use dialetheic::{LpTruth, DialetheicFilter};
pub use aperture::Aperture;
pub use contractivity::{enforce_contractivity, enforce_sovereign_contractivity, LambdaTraceAtom, MetricSpace, ContractivityError};
pub use identity::PrimeDecomposable;
pub use braid::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dialetheic_logic() {
        assert_eq!(LpTruth::True.not(), LpTruth::False);
        assert_eq!(LpTruth::Both.not(), LpTruth::Both);
        assert_eq!(LpTruth::Both.and(&LpTruth::False), LpTruth::False);
        assert_eq!(LpTruth::Both.or(&LpTruth::False), LpTruth::Both);
        assert!(LpTruth::Both.is_designated());
    }

    #[test]
    fn test_dialetheic_filter() {
        let success = || Ok(true);
        assert_eq!(DialetheicFilter::evaluate(success), LpTruth::True);

        let failure = || Err("Paradox".to_string());
        assert_eq!(DialetheicFilter::evaluate(failure), LpTruth::Both);
    }

    #[test]
    fn test_aperture() {
        let state = Aperture::new(42);
        assert_eq!(*state.state(), 42);
        assert!(state.acknowledge_openness());
    }

    struct MockMetric(f64);
    impl MetricSpace for MockMetric {
        fn distance(&self, other: &Self) -> f64 {
            (self.0 - other.0).abs()
        }
    }

    #[test]
    fn test_contractivity() {
        let s1 = MockMetric(1.0);
        let s2 = MockMetric(1.05);
        assert!(enforce_contractivity(&s1, &s2, 0.1).is_ok());
        assert!(enforce_contractivity(&s1, &s2, 0.01).is_err());
    }

    #[test]
    fn test_sovereign_contractivity_success() {
        let atom = LambdaTraceAtom {
            proof_digest: "digest".to_string(),
            state_root_hash: "hash".to_string(),
            timestamp: 12345,
            q: 0.98,
            tee_quote: Some("QUOTE".to_string()),
            trajectory_id: "ACTIVE".to_string(),
            protocol_v: 1,
            signer_id: Some("signer".to_string()),
        };

        let result = enforce_sovereign_contractivity(&atom, "ACTIVE", 0.995);
        assert!(result.is_ok());
    }

    #[test]
    fn test_sovereign_contractivity_dissonance() {
        let atom = LambdaTraceAtom {
            proof_digest: "digest".to_string(),
            state_root_hash: "hash".to_string(),
            timestamp: 12345,
            q: 0.98,
            tee_quote: Some("QUOTE".to_string()),
            trajectory_id: "INACTIVE".to_string(),
            protocol_v: 1,
            signer_id: Some("signer".to_string()),
        };

        let result = enforce_sovereign_contractivity(&atom, "ACTIVE", 0.995);
        assert!(matches!(result, Err(ContractivityError::TrajectoryDissonance { .. })));
    }

    #[test]
    fn test_sovereign_contractivity_provenance_gap() {
        let atom = LambdaTraceAtom {
            proof_digest: "digest".to_string(),
            state_root_hash: "hash".to_string(),
            timestamp: 12345,
            q: 0.98,
            tee_quote: None, // Missing TEE quote
            trajectory_id: "ACTIVE".to_string(),
            protocol_v: 1,
            signer_id: Some("signer".to_string()),
        };

        let result = enforce_sovereign_contractivity(&atom, "ACTIVE", 0.995);
        assert!(matches!(result, Err(ContractivityError::ProvenanceGap)));
    }

    #[test]
    fn test_sovereign_contractivity_drift_exceeded() {
        let atom = LambdaTraceAtom {
            proof_digest: "digest".to_string(),
            state_root_hash: "hash".to_string(),
            timestamp: 12345,
            q: 0.996, // Exceeds threshold of 0.995
            tee_quote: Some("QUOTE".to_string()),
            trajectory_id: "ACTIVE".to_string(),
            protocol_v: 1,
            signer_id: Some("signer".to_string()),
        };

        let result = enforce_sovereign_contractivity(&atom, "ACTIVE", 0.995);
        assert!(matches!(result, Err(ContractivityError::DriftExceeded { .. })));
    }
}

