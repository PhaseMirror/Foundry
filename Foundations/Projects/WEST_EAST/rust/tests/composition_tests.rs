use west_east::composition::BlockCompositionEngine;

#[test]
fn test_block_composition_valid() {
    let gaps = vec![0.30, 0.40]; // J=2, min_delta = 0.30 -> max_allowed = 0.30 / 8 = 0.0375
    let e_norm = 0.02;
    let res = BlockCompositionEngine::verify_block_composition(&gaps, e_norm);
    assert!(res.is_ok());
    let (comp_gap, _) = res.unwrap();
    assert!((comp_gap - 0.28).abs() < 1e-6);
}

#[test]
fn test_block_composition_excessive_perturbation_rejected() {
    let gaps = vec![0.30, 0.40];
    let e_norm_excess = 0.05; // > 0.0375
    let res = BlockCompositionEngine::verify_block_composition(&gaps, e_norm_excess);
    assert!(res.is_err(), "Excessive perturbation must fail composition");
}
