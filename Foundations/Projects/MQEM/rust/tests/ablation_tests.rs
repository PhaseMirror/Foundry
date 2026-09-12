use mqem::ablation::AblationHarness;
use mqem::metapopulation::MetapopulationBenchmark;
use mqem::optimization::ReserveDesignProblem;
use mqem::types::{DispersalEdge, HabitatGraph};

#[test]
fn test_reserve_design_simulated_annealing() {
    let edges = vec![
        DispersalEdge {
            source: 0,
            target: 1,
            weight: 0.5,
        },
        DispersalEdge {
            source: 1,
            target: 2,
            weight: 0.5,
        },
    ];
    let graph = HabitatGraph::new(3, edges);
    let costs = vec![2.0, 3.0, 1.0];
    let risks = vec![0.5, 0.4, 0.6];
    let problem = ReserveDesignProblem::new(graph, costs, risks, 4.0);

    let mut rng = rand::thread_rng();
    let (solution, score) = problem.solve_simulated_annealing(500, &mut rng);
    assert_eq!(solution.len(), 3);
    assert!(score.is_finite());

    let qubo = problem.formulate_qubo_matrix();
    assert_eq!(qubo.len(), 3);
    assert_eq!(qubo[0][1], qubo[1][0], "QUBO matrix must be symmetric");
}

#[test]
fn test_ablation_suite_execution() {
    let (graph, _) = MetapopulationBenchmark::build_aland_islands_graph();
    let config = mqem::types::ModelConfig::default();
    let mut rng = rand::thread_rng();
    let (survey_obs, _) = MetapopulationBenchmark::generate_survey_data(&graph, &config, 3, &mut rng);

    let results = AblationHarness::run_ablation_suite(&graph, &survey_obs, &mut rng);
    assert_eq!(results.len(), 4, "Must evaluate 4 ablation candidates");
    for r in &results {
        assert!(r.log_likelihood.is_finite());
        assert!(r.mean_prediction_error >= 0.0);
    }
}
