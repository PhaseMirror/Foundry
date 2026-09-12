use zetacell::ablations::AblationSuite;

#[test]
fn test_ablation_suite_execution() {
    let results = AblationSuite::run_ablation_experiment(4, 4, 2, 2, 10);
    assert_eq!(results.len(), 3);

    for res in results {
        assert!(res.is_stable);
        assert!(res.contraction_rate < 1.0);
    }
}
