use pirtm_engine::spectral::{self, Ensemble};

#[test]
fn test_small_gain_pipeline_accepted() {
    // 3-stage linear feedforward pipeline (strictly upper triangular, ρ = 0)
    let ensemble = Ensemble::new(
        "pipeline_3",
        vec![
            vec![0.0, 1.0, 0.0],
            vec![0.0, 0.0, 1.0],
            vec![0.0, 0.0, 0.0],
        ],
        vec![0.8, 0.8, 0.8],
    );

    let rho = spectral::check_small_gain(&ensemble, 1e-6).expect("Pipeline should pass");
    assert!(rho < 1e-5, "Pipeline spectral radius should be 0, got {}", rho);
}

#[test]
fn test_small_gain_contractive_feedback_accepted() {
    // Cyclic 2-node feedback loop with contractive loop gain:
    // A_01 = 0.5, A_10 = 0.5, λ_0 = 0.8, λ_1 = 0.8
    // G = [[0, 0.4], [0.4, 0]]
    // ρ(G) = 0.4 < 1.0
    let ensemble = Ensemble::new(
        "contractive_loop",
        vec![
            vec![0.0, 0.5],
            vec![0.5, 0.0],
        ],
        vec![0.8, 0.8],
    );

    let rho = spectral::check_small_gain(&ensemble, 1e-4).expect("Contractive feedback loop should pass");
    assert!((rho - 0.4).abs() < 1e-4, "Expected rho = 0.4, got {}", rho);
}

#[test]
fn test_small_gain_resonant_feedback_rejected() {
    // Resonant 2-node feedback loop:
    // A_01 = 1.2, A_10 = 1.0, λ_0 = 0.95, λ_1 = 0.95
    // G = [[0, 1.14], [0.95, 0]]
    // ρ(G) = sqrt(1.14 * 0.95) = sqrt(1.083) = 1.04067 >= 1.0
    let ensemble = Ensemble::new(
        "resonant_loop",
        vec![
            vec![0.0, 1.2],
            vec![1.0, 0.0],
        ],
        vec![0.95, 0.95],
    );

    let res = spectral::check_small_gain(&ensemble, 1e-4);
    assert!(res.is_err(), "Resonant loop must be rejected");
    let err = res.unwrap_err();
    assert!(err.contains("SIG_GOV_KILL"));
}

#[test]
fn test_runtime_validate_and_certify() {
    let ensemble = Ensemble::new(
        "certified_ensemble",
        vec![
            vec![0.0, 0.3],
            vec![0.3, 0.0],
        ],
        vec![0.5, 0.5],
    );

    let receipt = spectral::validate_and_certify(&ensemble, 1e-6).expect("Validation must succeed");
    assert!(receipt.is_stable);
    assert_eq!(receipt.dimension, 2);
    assert!(!receipt.hash.is_empty());
}
