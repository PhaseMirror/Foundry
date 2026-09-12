use multiplicity_meta_ensemble::meta_ensemble::MetaEnsemble;
use multiplicity_meta_ensemble::jensen_shannon_coherence;
use multiplicity_meta_ensemble::packs::{BabylonianPack, AfricanPack};
use multiplicity_meta_ensemble::strata::StratumState;
use multiplicity_meta_ensemble::evaluation::{run_evaluation_protocol, run_babylonian_evaluation};
use multiplicity_meta_ensemble::zk_trace::ZkTracer;
use ndarray::array;

#[test]
fn test_meta_ensemble_folding() {
    let e1 = array![1.0, 0.0, 0.0];
    let e2 = array![0.0, 1.0, 0.0];
    let me = MetaEnsemble::new(vec![e1.clone(), e2.clone()]);
    
    let weighted_folded = me.weighted_fold(&[0.8, 0.2]);
    assert_eq!(weighted_folded, array![0.8, 0.2, 0.0]);
    // Binding multiplicity should be 0.0 for orthogonal vectors
    assert!(me.mu < 0.0001);
}

#[test]
fn test_strata_coherence() {
    let mut s0 = StratumState::new_s0(vec![2, 3, 5], 2);
    let mut s2 = StratumState::new_s2(2.5, 11.0, 2);
    
    // Perform updates that should align the states
    let input = array![0.9, 0.1];
    s0.recursive_update(&input);
    s2.recursive_update(&input);
    
    let coherence = jensen_shannon_coherence(&s0.state_vector, &s2.state_vector);
    assert!(coherence < 0.05);
}

#[test]
fn test_js_coherence() {
    let p = array![0.9, 0.1];
    let q = array![0.1, 0.9];
    let coherence = jensen_shannon_coherence(&p, &q);
    assert!(coherence > 0.0);
}

#[test]
fn test_recursion_coefficient() {
    let primes = vec![2, 3, 5];
    let k = multiplicity_meta_ensemble::calculate_recursion_coefficient(&primes);
    assert!(k < 1.0);
    assert!(k > 0.3);
}

#[test]
fn test_babylonian_pack() {
    let mut state = array![10.5, 5.0];
    let pack = BabylonianPack { modulus: 3.0, period: 1 };
    pack.apply(&mut state);
    assert!((state[0] - 1.5).abs() < 1e-6);
    assert!((state[1] - 2.0).abs() < 1e-6);
}

#[test]
fn test_evaluation_protocol() {
    let results = run_evaluation_protocol(5);
    assert_eq!(results.len(), 5);
    for result in results {
        assert!(result.stability_passed);
        assert!(result.mse < 0.5);
    }
}

#[test]
fn test_babylonian_bench() {
    let baseline = run_evaluation_protocol(1);
    let babylonian = run_babylonian_evaluation();
    
    println!("Baseline MSE: {:.6}", baseline[0].mse);
    println!("Babylonian MSE: {:.6}", babylonian.mse);
    
    assert!(babylonian.stability_passed);
}

#[test]
fn test_zk_trace_generation() {
    let mut tracer = ZkTracer::new();
    let s0 = StratumState::new_s0(vec![2, 3, 5], 2);
    let prev_state = array![0.0, 0.0];
    let update = array![0.1, 0.2];
    
    tracer.record_step(1, &s0, &prev_state, &update, 0.5, false);
    
    assert_eq!(tracer.traces.len(), 1);
    let commitment = tracer.generate_commitment();
    assert!(!commitment.is_empty());
}
