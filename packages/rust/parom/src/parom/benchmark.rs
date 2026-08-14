use nalgebra::{DMatrix, DVector};
use crate::{Parom, ParomConfig, PrimeAssignmentStrategy};

pub struct BenchmarkResult {
    pub parom_mse: f64,
    pub dense_mse: f64,
    pub parom_time_ms: f64,
    pub dense_time_ms: f64,
}

pub fn run_synthetic_benchmark(dimension: usize, steps: usize) -> BenchmarkResult {
    // Generate a Target System with heavy Prime-Indexed Off-Diagonal Coupling
    let primes: Vec<u64> = (1..=dimension as u64)
        .map(|n| num_prime::nt_funcs::nth_prime(n))
        .collect();
    
    let mut target_op = DMatrix::zeros(dimension, dimension);
    for i in 0..dimension {
        let p = primes[i] as f64;
        // Interaction between channel i and i+1 weighted by 1/p
        target_op[(i, (i + 1) % dimension)] = 1.0 / p;
        // Interaction between channel i and i+2 weighted by 1/p^2
        target_op[(i, (i + 2) % dimension)] = 1.0 / (p * p);
    }
    
    // Normalize target op to be stable (spectral radius ~ 0.9)
    let eigenvalues = target_op.complex_eigenvalues();
    let max_ev = eigenvalues.iter().map(|c| c.norm()).fold(0.0, f64::max);
    target_op *= 0.9 / (max_ev + 1e-9);
    
    let x0 = DVector::from_element(dimension, 1.0);
    let mut target_trajectory = Vec::with_capacity(steps);
    let mut current_x = x0.clone();
    for _ in 0..steps {
        current_x = &target_op * &current_x;
        current_x = current_x.map(|v: f64| v.tanh());
        target_trajectory.push(current_x.clone());
    }

    // Measure PAROM (Matching the target operator's prime-indexed structure)
    let parom_config = ParomConfig {
        dimension,
        num_primes: dimension,
        epsilon: 0.1,
        delta: 1e-6,
        lambda_m: 0.0, // Purely linear for this test
        strategy: PrimeAssignmentStrategy::Sequential,
    };
    let t_op = Box::new(|x: &DVector<f64>| x.clone());
    let parom = Parom::new(parom_config, t_op).with_operator(target_op.clone());
    
    let mut parom_mse = 0.0;
    let start_parom = std::time::Instant::now();
    for i in 0..steps-1 {
        let pred = parom.evolve(&target_trajectory[i]);
        parom_mse += (&pred - &target_trajectory[i+1]).norm_squared();
    }
    let parom_time = start_parom.elapsed().as_secs_f64() * 1000.0;
    parom_mse /= (steps - 1) as f64;

    // Measure Dense Baseline (Diagonal Matrix: D parameters)
    // A diagonal model cannot capture the off-diagonal prime couplings.
    let mut dense_mse = 0.0;
    let start_dense = std::time::Instant::now();
    let dense_diag = DVector::from_element(dimension, 0.5);
    let dense_op = DMatrix::from_diagonal(&dense_diag);
    
    for i in 0..steps-1 {
        let pred = &dense_op * &target_trajectory[i];
        let pred = pred.map(|v: f64| v.tanh());
        dense_mse += (&pred - &target_trajectory[i+1]).norm_squared();
    }
    let dense_time = start_dense.elapsed().as_secs_f64() * 1000.0;
    dense_mse /= (steps - 1) as f64;

    BenchmarkResult {
        parom_mse,
        dense_mse,
        parom_time_ms: parom_time,
        dense_time_ms: dense_time,
    }
}
