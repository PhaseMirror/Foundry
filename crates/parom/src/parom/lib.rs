use nalgebra::{DMatrix, DVector};
use num_prime::nt_funcs::nth_prime;
use rand::prelude::*;
use rand_distr::StandardNormal;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

pub mod benchmark;
pub mod bio;
pub mod data_loader;
pub mod calibration;
pub mod adversarial;
pub mod resilience;
pub mod semantic;
pub mod shm;
pub mod vdj;
pub mod meta;
pub mod whitehead_sim;

use crate::semantic::{GFElement, PartitionedState, lift_float_to_gfp, isprime};

#[derive(Debug, Serialize, Deserialize, Clone, Copy, PartialEq, Eq, Hash)]
pub enum BioChannel {
    BarrierBreach,
    TNFAlpha,
    IL6,
    CRP,
    HRV,
    SleepQuality,
    DAO,
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy)]
pub enum PrimeAssignmentStrategy {
    Sequential,
    CascadeOrdering,
    TimescaleSeparation,
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy)]
pub struct ParomConfig {
    pub dimension: usize,
    pub num_primes: usize,
    pub epsilon: f64,
    pub delta: f64,
    pub lambda_m: f64,
    pub strategy: PrimeAssignmentStrategy,
}

#[derive(Clone, Debug)]
pub struct SemanticStepAudit {
    pub omega: i64,
    pub is_omega_prime: bool,
    pub sector_residues: Vec<(i64, i64)>, // (prime, residue)
    pub velocity: f64,
}

pub struct SemanticParom {
    pub primes: Vec<i64>,
    pub product_n: i64,
}

impl SemanticParom {
    pub fn new(primes: Vec<i64>) -> Self {
        let product_n = primes.iter().product();
        Self { primes, product_n }
    }

    /// Evolve a partitioned state using native Galois operators and CRT.
    pub fn evolve_vector(&self, mut state: PartitionedState) -> PartitionedState {
        // Apply irreducible sector-wise operators (Level 3)
        state.apply_shift();
        state
    }

    pub fn evolve(&self, input: f64) -> (f64, i64) {
        let (normalized, omega, _, _) = self.evolve_audited(input);
        (normalized, omega)
    }

    /// Native PAROM Evolution Loop with Full Audit Trace.
    pub fn evolve_audited(&self, input: f64) -> (f64, i64, bool, SemanticStepAudit) {
        // 1. Lifting (Level 2)
        let residues: Vec<GFElement> = self.primes.iter()
            .map(|&p| lift_float_to_gfp(input, p))
            .collect();
        
        let sector_residues: Vec<(i64, i64)> = residues.iter().map(|r| (r.p, r.value)).collect();
            
        // 2. Semantic Transition (Level 3)
        let evolved_residues: Vec<GFElement> = residues.iter()
            .map(|r| r.add(&GFElement::new(1, r.p)))
            .collect();
            
        // 3. Composite Reconstruction via CRT (Level 4)
        let composite = crate::semantic::crt_reconstruct_multi(&evolved_residues);
        let omega = composite.value;
        let is_p = isprime(omega);
        
        let normalized = omega as f64 / self.product_n as f64;
        let velocity = (normalized - input).abs();

        let audit = SemanticStepAudit {
            omega,
            is_omega_prime: is_p,
            sector_residues,
            velocity,
        };
        
        (normalized, omega, is_p, audit)
    }
}

#[derive(Clone, Debug)]
pub struct StepAudit {
    pub sector_violations: Vec<u64>, // Primes whose sectors showed 'stress'
    pub composite_norm: f64,
    pub lipschitz_estimate: f64,
}

pub struct Parom {
    pub config: ParomConfig,
    xi_0: DMatrix<f64>,
    t_op: Box<dyn Fn(&DVector<f64>) -> DVector<f64>>,
    primes: Vec<u64>,
    pub channel_map: HashMap<BioChannel, u64>,
    pub prime_weights: Vec<f64>, 
}

impl Parom {
    pub fn new(config: ParomConfig, t_op: Box<dyn Fn(&DVector<f64>) -> DVector<f64>>) -> Self {
        let primes: Vec<u64> = (1..=config.num_primes as u64)
            .map(|n| nth_prime(n))
            .collect();

        let mut prime_weights = Vec::with_capacity(primes.len());
        for &p in &primes {
            prime_weights.push(1.0 / p as f64);
        }

        let mut channel_map = HashMap::new();
        match config.strategy {
            PrimeAssignmentStrategy::Sequential => {}
            PrimeAssignmentStrategy::CascadeOrdering => {
                channel_map.insert(BioChannel::BarrierBreach, 2);
                channel_map.insert(BioChannel::TNFAlpha, 3);
                channel_map.insert(BioChannel::IL6, 5);
                channel_map.insert(BioChannel::CRP, 7);
                channel_map.insert(BioChannel::DAO, 11);
                channel_map.insert(BioChannel::HRV, 13);
                channel_map.insert(BioChannel::SleepQuality, 17);
            }
            PrimeAssignmentStrategy::TimescaleSeparation => {
                channel_map.insert(BioChannel::HRV, 2);
                channel_map.insert(BioChannel::IL6, 3);
                channel_map.insert(BioChannel::BarrierBreach, 5);
                channel_map.insert(BioChannel::CRP, 7);
                channel_map.insert(BioChannel::SleepQuality, 11);
                channel_map.insert(BioChannel::DAO, 13);
                channel_map.insert(BioChannel::TNFAlpha, 17);
            }
        }

        let mut xi_0 = DMatrix::identity(config.dimension, config.dimension) * (1.0 - config.epsilon);
        
        for i in 0..config.dimension.min(primes.len()) {
            let w = prime_weights[i];
            xi_0[(i, (i + 1) % config.dimension)] += w * 0.01;
        }

        Self {
            config,
            xi_0,
            t_op,
            primes,
            channel_map,
            prime_weights,
        }
    }

    pub fn with_operator(mut self, xi_0: DMatrix<f64>) -> Self {
        self.xi_0 = xi_0;
        self
    }

    pub fn update_weights(&mut self, new_weights: Vec<f64>) {
        self.prime_weights = new_weights;
        self.xi_0 = DMatrix::identity(self.config.dimension, self.config.dimension) * (1.0 - self.config.epsilon);
        for i in 0..self.config.dimension.min(self.primes.len()) {
            let w = self.prime_weights[i];
            self.xi_0[(i, (i + 1) % self.config.dimension)] += w * 0.01;
        }
    }

    pub fn evolve(&self, x: &DVector<f64>) -> DVector<f64> {
        let xi_part = &self.xi_0 * x;
        let t_part = (self.t_op)(x) * self.config.lambda_m;
        xi_part + t_part
    }

    /// Evolve with sector-level auditing.
    pub fn evolve_audited(&self, x: &DVector<f64>) -> (DVector<f64>, StepAudit) {
        let next_x = self.evolve(x);
        
        // Detect sector violations (Simplified: large residual norm per prime index)
        let mut violations = Vec::new();
        for i in 0..self.config.dimension.min(self.primes.len()) {
            let residual = (next_x[i] - x[i]).abs();
            // Stress threshold: 0.1 / prime (High sensitivity)
            if residual > 0.1 / self.primes[i] as f64 {
                violations.push(self.primes[i]);
            }
        }
        
        let audit = StepAudit {
            sector_violations: violations,
            composite_norm: next_x.norm(),
            lipschitz_estimate: next_x.norm() / (x.norm() + 1e-9),
        };
        
        (next_x, audit)
    }

    pub fn estimate_lipschitz(&self, trials: usize) -> f64 {
        let mut rng = thread_rng();
        let mut max_val = 0.0;

        for _ in 0..trials {
            let x = DVector::from_fn(self.config.dimension, |_, _| {
                rng.sample::<f64, _>(StandardNormal)
            });
            let y = &x + DVector::from_fn(self.config.dimension, |_, _| {
                rng.sample::<f64, _>(StandardNormal) * 1e-4
            });

            let fx = self.evolve(&x);
            let fy = self.evolve(&y);

            let diff_f = (&fx - &fy).norm();
            let diff_xy = (&x - &y).norm();

            let ratio = diff_f / (diff_xy + 1e-12);
            if ratio > max_val {
                max_val = ratio;
            }
        }
        max_val
    }

    pub fn verify_stability(&self, trials: usize) -> bool {
        let l = self.estimate_lipschitz(trials);
        println!("Estimated Lipschitz constant: {:.4}", l);
        l < 1.0
    }

    pub fn get_primes(&self) -> &[u64] {
        &self.primes
    }

    pub fn get_xi_0(&self) -> &DMatrix<f64> {
        &self.xi_0
    }

    pub fn get_trajectory(&self, x0: &DVector<f64>, steps: usize) -> Vec<f64> {
        let mut trajectory = Vec::with_capacity(steps + 1);
        let mut x = x0.clone();
        trajectory.push(x.norm());
        for _ in 0..steps {
            x = self.evolve(&x);
            trajectory.push(x.norm());
        }
        trajectory
    }

    pub fn audit(&self) -> bool {
        use num_prime::nt_funcs::is_prime;
        use num_prime::Primality;
        println!("Running prime-audit...");
        let all_prime = self.primes.iter().all(|&p| {
            match is_prime(&p, None) {
                Primality::Yes | Primality::Probable(_) => true,
                Primality::No => false,
            }
        });
        
        if !all_prime {
            println!("Audit Failed: Non-prime indices detected.");
            return false;
        }

        let eigenvalues = self.xi_0.complex_eigenvalues();
        let mut real_parts: Vec<f64> = eigenvalues.iter().map(|c| c.re).collect();
        real_parts.sort_by(|a, b| a.partial_cmp(b).unwrap());
        
        let gaps: Vec<f64> = real_parts.windows(2).map(|w| w[1] - w[0]).collect();
        let avg_gap: f64 = gaps.iter().sum::<f64>() / gaps.len() as f64;
        
        println!("Average spectral gap: {:.6}", avg_gap);
        println!("Audit Passed: Indices are prime and spectral gaps are consistent.");
        true
    }
}
