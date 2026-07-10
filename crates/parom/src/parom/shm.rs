use nalgebra::DVector;
use rand::prelude::*;
use rand_distr::{StandardNormal, Distribution};
use crate::Parom;

pub struct Hypermutant {
    pub weights: Vec<f64>,
    pub mse: f64,
}

pub struct HypermutationEngine {
    pub eta: f64, // Mutation rate
}

impl HypermutationEngine {
    pub fn new(eta: f64) -> Self {
        Self { eta }
    }

    /// Generate a hypermutated candidate based on prime-local refinement.
    pub fn mutate(&self, parom: &Parom) -> Vec<f64> {
        let mut rng = thread_rng();
        let mut new_weights = parom.prime_weights.clone();
        
        for i in 0..new_weights.len() {
            let p = parom.get_primes()[i];
            // g(p) = nextprime(p) - p
            let next_p = num_prime::nt_funcs::next_prime(&p, None).unwrap();
            let gap = (next_p - p) as f64;
            
            // ADR-004: Mutation Step size tied to normalized prime gap g(p)/p
            let delta: f64 = StandardNormal.sample(&mut rng);
            let step = self.eta * (gap / p as f64) * delta;
            
            new_weights[i] += step;
            // Keep weights physical (positive)
            if new_weights[i] < 0.0 {
                new_weights[i] = 1e-9;
            }
        }
        
        new_weights
    }

    /// Run an affinity maturation cycle.
    pub fn run_cycle(
        &self, 
        parom: &mut Parom, 
        trajectories: &[Vec<DVector<f64>>],
        trials: usize
    ) -> bool {
        let mut best_mse = self.calculate_mse(parom, trajectories);
        let mut best_weights = parom.prime_weights.clone();
        let mut improved = false;

        println!("Initial MSE: {:.10}", best_mse);

        for _ in 0..trials {
            let candidate_weights = self.mutate(parom);
            
            // Create a temp parom to test candidate
            let mut temp_parom = Parom::new(parom.config.clone(), Box::new(|x| x.map(|v| v.tanh())));
            temp_parom.update_weights(candidate_weights.clone());
            
            // ADR-004 Selection Rule: Must pass Four-Gate (simplified to stability here)
            if temp_parom.verify_stability(100) {
                let candidate_mse = self.calculate_mse(&temp_parom, trajectories);
                if candidate_mse < best_mse {
                    best_mse = candidate_mse;
                    best_weights = candidate_weights;
                    improved = true;
                    println!("Improved MSE: {:.10}", best_mse);
                }
            }
        }

        if improved {
            parom.update_weights(best_weights);
        }
        
        improved
    }

    fn calculate_mse(&self, parom: &Parom, trajectories: &[Vec<DVector<f64>>]) -> f64 {
        let mut total_mse = 0.0;
        let mut count = 0;
        for traj in trajectories {
            for i in 0..traj.len().saturating_sub(1) {
                let pred = parom.evolve(&traj[i]);
                total_mse += (&pred - &traj[i+1]).norm_squared();
                count += 1;
            }
        }
        if count > 0 { total_mse / count as f64 } else { 0.0 }
    }
}
