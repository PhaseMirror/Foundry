use ndarray::{Array1, Array2};
use pirtm_rs::prime_recursive::{DecoupledSolver, generate_primes, static_skeleton};
use std::time::Instant;

fn main() {
    let dim = 128;
    let k = 0.5;
    let epsilon = 0.05;
    let trials = 1000;
    
    // Prime weights
    let primes = generate_primes(dim);
    let mut p_weights = Array1::zeros(dim);
    let mut p_sum = 0.0;
    for (i, &p) in primes.iter().enumerate() {
        p_weights[i] = 1.0 / static_skeleton(p);
        p_sum += p_weights[i];
    }
    p_weights /= p_sum;
    
    // Random weights
    let mut r_weights = Array1::from_elem(dim, 1.0 / dim as f64); // Uniform as a baseline
    
    let solver = DecoupledSolver::new(k, dim, epsilon).unwrap();
    
    println!("--- Solver Trace for dim={} ---", dim);
    
    let mut p_total_iters = 0;
    let mut r_total_iters = 0;
    
    let start = Instant::now();
    for _ in 0..trials {
        let t_initial = Array1::from_elem(dim, 0.5); // Fixed initial state for comparison
        let f = Array1::from_elem(dim, 1.0);
        
        // Prime trace
        let p_diag_weights = Array2::from_diag(&p_weights);
        let p_f = p_diag_weights.dot(&f);
        let (_, p_telemetry) = solver.simulate(&t_initial, &p_f, 500, 1e-6, None);
        p_total_iters += p_telemetry.len();
        
        // Random trace (using uniform baseline here)
        let r_diag_weights = Array2::from_diag(&r_weights);
        let r_f = r_diag_weights.dot(&f);
        let (_, r_telemetry) = solver.simulate(&t_initial, &r_f, 500, 1e-6, None);
        r_total_iters += r_telemetry.len();
    }
    let duration = start.elapsed();
    
    println!("Total trials: {}", trials);
    println!("Prime average iterations:  {:.3}", p_total_iters as f64 / trials as f64);
    println!("Random average iterations: {:.3}", r_total_iters as f64 / trials as f64);
    println!("Total time: {:?}", duration);
    
    // Spectral gap statistics (qualitative from iteration count delta)
    let delta = (p_total_iters as f64 - r_total_iters as f64) / trials as f64;
    println!("Iteration delta (Prime - Random): {:.3}", delta);
}
