pub mod primes;
pub mod logging;
pub mod scoring;
pub mod phase_mirror;

pub use primes::*;
pub use logging::*;
pub use scoring::*;
pub use phase_mirror::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_prime_id() {
        assert!(is_prime_id("factorize"));
        assert!(!is_prime_id("not_a_prime"));
    }

    #[test]
    fn test_cohen_kappa() {
        let rater1 = vec!["reframe".to_string(), "invert".to_string()];
        let rater2 = vec!["reframe".to_string(), "factorize".to_string()];
        let kappa = cohen_kappa(&rater1, &rater2).unwrap();
        assert!(kappa > 0.0);
    }

    #[test]
    fn test_phase_mirror_model() {
        let mut model = PhaseMirrorModel::new(None);
        let entry = SessionLogEntry {
            id: "test-1".to_string(),
            context: SessionContext {
                domain: "test".to_string(),
                problem: "test".to_string(),
                goal: None,
                constraints: None,
                tags: None,
            },
            moves: vec![PrimeMove {
                prime: "reframe".to_string(),
                note: None,
                context: None,
                timestamp: "2026-05-23T00:00:00Z".to_string(),
            }],
            metrics: ImpactVector {
                novelty: 0.8,
                coherence: 0.4,
                transferability: 0.5,
                external_impact: None,
            },
            external_signals: None,
            created_at: "2026-05-23T00:00:00Z".to_string(),
        };

        let breakdown = model.ingest(entry);
        assert!(breakdown.score >= 0.0);

        let recommendations = model.recommend(None, None, 3);
        assert_eq!(recommendations.len(), 3);
    }
}
