use nalgebra::{DMatrix, DVector};
use crate::{Parom, ParomConfig, PrimeAssignmentStrategy};

pub struct BioSimulation {
    pub trajectory: Vec<DVector<f64>>,
}

impl BioSimulation {
    pub fn generate(steps: usize) -> Self {
        // Channels: 0:Barrier, 1:TNF, 2:IL6, 3:CRP, 4:HRV, 5:DAO
        let dim = 6;
        let mut x = DVector::from_element(dim, 1.0); // Initial healthy state
        let mut trajectory = Vec::with_capacity(steps);
        
        // Causal matrix (simplified)
        // LPS effect is external, we'll simulate a pulse at t=10
        for t in 0..steps {
            let lps = if t >= 10 && t <= 15 { 1.0 } else { 0.0 };
            
            let mut next_x = x.clone();
            // Barrier breach
            next_x[0] += -0.2 * lps + 0.1 * (1.0 - x[0]);
            // TNF Alpha responds to barrier breach
            next_x[1] += 0.3 * (1.0 - x[0]) - 0.2 * x[1];
            // IL-6 responds to TNF
            next_x[2] += 0.2 * x[1] - 0.1 * x[2];
            // CRP responds to IL-6
            next_x[3] += 0.1 * x[2] - 0.05 * x[3];
            // HRV drops with inflammation
            next_x[4] += -0.1 * x[2] + 0.05 * (1.0 - x[4]);
            // DAO (Barrier integrity marker)
            next_x[5] = x[0] * 0.9 + 0.1;

            x = next_x.map(|v: f64| v.max(0.0).min(2.0)); // Clip to physical range
            trajectory.push(x.clone());
        }
        
        Self { trajectory }
    }
}

pub fn run_bio_benchmark(steps: usize) -> (f64, f64) {
    let sim = BioSimulation::generate(steps);
    
    // Train PAROM with Cascade strategy
    let config = ParomConfig {
        dimension: 6,
        num_primes: 10,
        epsilon: 0.1,
        delta: 1e-6,
        lambda_m: 0.05,
        strategy: PrimeAssignmentStrategy::CascadeOrdering,
    };
    let t_op = Box::new(|x: &DVector<f64>| x.map(|v| v.tanh()));
    let parom = Parom::new(config, t_op);
    
    // Prediction task: predict next state
    let mut parom_mse = 0.0;
    for i in 0..steps-1 {
        let pred = parom.evolve(&sim.trajectory[i]);
        parom_mse += (&pred - &sim.trajectory[i+1]).norm_squared();
    }
    parom_mse /= (steps - 1) as f64;
    
    // Logistic-like baseline (Linear regression on current state)
    // We'll use a simple identity-ish matrix as a proxy for a non-prime model
    let mut dense_mse = 0.0;
    let dense_op = DMatrix::identity(6, 6) * 0.9;
    for i in 0..steps-1 {
        let pred = &dense_op * &sim.trajectory[i];
        dense_mse += (&pred - &sim.trajectory[i+1]).norm_squared();
    }
    dense_mse /= (steps - 1) as f64;
    
    (parom_mse, dense_mse)
}
