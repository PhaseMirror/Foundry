pub mod evaluator;
pub mod conflict_resolver;

pub use evaluator::*;
pub use conflict_resolver::*;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_evaluation_order() {
        let artifacts = vec![
            ShellArtifact { module_id: "b".to_string(), domain_class: "d".to_string(), rank: 2 },
            ShellArtifact { module_id: "a".to_string(), domain_class: "d".to_string(), rank: 1 },
        ];
        let ordered = build_evaluation_order(&artifacts);
        assert_eq!(ordered[0].module_id, "a");
        assert_eq!(ordered[1].module_id, "b");
    }

    #[test]
    fn test_conflict_resolution() {
        let record = resolve_conflict("m1", "d1", "m2", "d2", 1, 2);
        assert_eq!(record.prevailing_module, "m1");
    }
}
