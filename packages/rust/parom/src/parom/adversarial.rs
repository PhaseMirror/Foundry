use nalgebra::{DMatrix, DVector};
use crate::{Parom, ParomConfig, PrimeAssignmentStrategy};
use rand::prelude::*;
use rand_distr::{StandardNormal, Cauchy, Distribution};

pub struct StressTestConfig {
    pub dimension: usize,
    pub noise_level: f64,
    pub crosstalk_level: f64,
    pub shock_magnitude: f64,
    pub steps: usize,
}

pub struct StressTestResult {
    pub parom_recovery_steps: usize,
    pub dense_recovery_steps: usize,
    pub parom_violations: usize,
    pub dense_violations: usize,
}

pub fn run_adversarial_test(config: StressTestConfig) -> StressTestResult {
    let mut rng = thread_rng();
    
    // Setup PAROM: Purely linear contraction for recovery test
    let parom_cfg = ParomConfig {
        dimension: config.dimension,
        num_primes: config.dimension,
        epsilon: 0.1, // 1 - 0.1 = 0.9 baseline
        delta: 1e-6,
        lambda_m: 0.0, 
        strategy: PrimeAssignmentStrategy::Sequential,
    };
    let t_op = Box::new(|x: &DVector<f64>| x.clone());
    let parom = Parom::new(parom_cfg, t_op);
    
    // Setup Dense Baseline: Matched parameter count (Diagonal)
    // We add crosstalk to the dense baseline to simulate "pollution"
    let dense_diag = DVector::from_element(config.dimension, 0.9);
    let mut dense_op = DMatrix::from_diagonal(&dense_diag);
    let crosstalk = DMatrix::from_fn(config.dimension, config.dimension, |r, c| {
        if r != c {
            rng.sample::<f64, _>(StandardNormal) * config.crosstalk_level
        } else {
            0.0
        }
    });
    dense_op += crosstalk;

    // 1. Shock Resilience Test
    // Apply a large displacement and count steps to return to ||x|| < 0.1
    let mut x_parom = DVector::from_element(config.dimension, config.shock_magnitude);
    let mut x_dense = DVector::from_element(config.dimension, config.shock_magnitude);
    
    let mut p_rec = config.steps;
    let mut d_rec = config.steps;
    
    for i in 0..config.steps {
        if x_parom.norm() < 0.1 && p_rec == config.steps {
            p_rec = i;
        }
        if x_dense.norm() < 0.1 && d_rec == config.steps {
            d_rec = i;
        }
        
        x_parom = parom.evolve(&x_parom);
        x_dense = &dense_op * &x_dense;
        
        // Safety break to prevent infinite loops if diverging
        if x_parom.norm() > 1e6 || x_dense.norm() > 1e6 { break; }
    }

    // 2. Heavy-Tailed Stability Test
    // Count how many times the next state norm increases significantly under Cauchy noise
    let mut p_viols = 0;
    let mut d_viols = 0;
    let cauchy = Cauchy::new(0.0, config.noise_level).unwrap();
    
    let mut xp = DVector::from_element(config.dimension, 1.0);
    let mut xd = DVector::from_element(config.dimension, 1.0);
    
    for _ in 0..config.steps {
        let noise = DVector::from_fn(config.dimension, |_, _| cauchy.sample(&mut rng));
        
        // Evolve current state with additive noise
        let next_xp = parom.evolve(&(&xp + &noise));
        let next_xd = &dense_op * &(&xd + &noise);
        
        // Invariant: Next norm should be less than current norm (modulo noise scale)
        if next_xp.norm() > xp.norm() + config.noise_level * 5.0 { p_viols += 1; }
        if next_xd.norm() > xd.norm() + config.noise_level * 5.0 { d_viols += 1; }
        
        xp = next_xp.map(|v| v.max(-2.0).min(2.0));
        xd = next_xd.map(|v| v.max(-2.0).min(2.0));
    }

    StressTestResult {
        parom_recovery_steps: p_rec,
        dense_recovery_steps: d_rec,
        parom_violations: p_viols,
        dense_violations: d_viols,
    }
}
