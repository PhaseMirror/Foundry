mod simulator;
mod engine;

use simulator::Hamiltonian;
use engine::SimulationEngine;
use ndarray::Array1;
use num_complex::Complex64;

fn main() {
    let primes = vec![2.0, 3.0, 5.0, 7.0, 11.0];
    let n = primes.len();
    let h_engine = Hamiltonian::new(primes, 1.0, 0.3);
    let engine = SimulationEngine::new(h_engine, 0.01);
    
    // Initial state: uniform superposition
    let mut psi = Array1::from_elem(n, Complex64::new(1.0 / (n as f64).sqrt(), 0.0));
    
    let zero_freqs = vec![14.13, 21.02];
    let gammas = vec![0.1, 0.07];
    let phases = vec![0.0, 0.0];
    
    let mut t = 0.0;
    let t_max = 1.0;
    
    while t < t_max {
        psi = engine.step(t, &psi, &zero_freqs, &gammas, &phases);
        t += engine.dt;
    }
    
    println!("Final state at t={}: {:?}", t, psi);
    let norm = psi.mapv(|c| c.norm_sqr()).sum();
    println!("Final norm: {}", norm);
}
