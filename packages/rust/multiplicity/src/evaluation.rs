use crate::meta_ensemble::MetaEnsemble;
use crate::gate::EntropyInverseGate;
use crate::strata::StratumState;
use crate::jensen_shannon_coherence;
use ndarray::{Array1, array};
use rand::prelude::*;
use rand_chacha::ChaCha8Rng;

pub struct EvaluationResult {
    pub seed: u64,
    pub mse: f64,
    pub coherence: f64,
    pub stability_passed: bool,
}

pub fn run_evaluation_protocol(num_seeds: usize) -> Vec<EvaluationResult> {
    let mut results = Vec::new();
    
    for i in 0..num_seeds {
        let seed = i as u64;
        let mut rng = ChaCha8Rng::seed_from_u64(seed);
        
        let result = evaluate_single_seed(&mut rng, seed);
        results.push(result);
    }
    
    results
}

fn evaluate_single_seed(rng: &mut ChaCha8Rng, seed: u64) -> EvaluationResult {
    // 1. Initialize Strata
    let mut s0 = StratumState::new_s0(vec![2, 3, 5], 10);
    let mut s2 = StratumState::new_s2(2.5, 11.0, 10);
    
    // 2. Generate Synthetic "Ground Truth" Signal
    let target = Array1::from_shape_fn(10, |_| rng.gen_range(0.0..1.0));
    
    // 3. Recursive Update Loop (10 iterations)
    let gate = EntropyInverseGate::new(0.5);
    let mut current_mse = 0.0;
    
    for _ in 0..10 {
        let prev_s0 = s0.state_vector.clone();
        let noise = Array1::from_shape_fn(10, |_| rng.gen_range(-0.1..0.1));
        let input = &target + &noise;
        
        let raw_update = &input - &s0.state_vector;
        let next_state_candidate = &s0.state_vector + &raw_update;
        
        let gated_update = gate.apply(&prev_s0, &next_state_candidate, &raw_update);
        s0.state_vector = s0.state_vector + gated_update;
        
        s2.recursive_update(&s0.state_vector);
        
        current_mse += (s0.state_vector.clone() - target.clone()).mapv(|x| x.powi(2)).sum() / 10.0;
    }
    
    let final_coherence = jensen_shannon_coherence(&s0.state_vector, &s2.state_vector);
    
    EvaluationResult {
        seed,
        mse: current_mse / 10.0,
        coherence: final_coherence,
        stability_passed: current_mse < 1.0, // Basic stability threshold
    }
}

pub fn run_babylonian_evaluation() -> EvaluationResult {
    let mut rng = ChaCha8Rng::seed_from_u64(42);
    let mut s0 = StratumState::new_s0(vec![2, 3, 5], 10);
    let mut s2 = StratumState::new_s2(2.5, 11.0, 10);
    let target = Array1::from_shape_fn(10, |_| rng.gen_range(0.0..1.0));
    
    let gate = EntropyInverseGate::new(0.5);
    let pack = crate::packs::BabylonianPack { modulus: 1.0, period: 1 };
    let mut current_mse = 0.0;
    
    for _ in 0..10 {
        let prev_s0 = s0.state_vector.clone();
        let noise = Array1::from_shape_fn(10, |_| rng.gen_range(-0.1..0.1));
        let input = &target + &noise;
        
        let raw_update = &input - &s0.state_vector;
        let next_state_candidate = &s0.state_vector + &raw_update;
        
        let gated_update = gate.apply(&prev_s0, &next_state_candidate, &raw_update);
        s0.state_vector = s0.state_vector + gated_update;
        
        // Apply Babylonian periodicity constraint
        pack.apply(&mut s0.state_vector);
        
        s2.recursive_update(&s0.state_vector);
        current_mse += (s0.state_vector.clone() - target.clone()).mapv(|x| x.powi(2)).sum() / 10.0;
    }
    
    EvaluationResult {
        seed: 42,
        mse: current_mse / 10.0,
        coherence: jensen_shannon_coherence(&s0.state_vector, &s2.state_vector),
        stability_passed: current_mse < 1.0,
    }
}
