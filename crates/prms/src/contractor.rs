// prms/src/contractor.rs
use crate::petc::TensorSpaceType;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StabilityStatus {
    Nominal,
    Warning,
    CriticalBoundaryViolation,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub struct ContractorConfig {
    pub lambda_m: f64,
    pub alpha: f64,
    pub max_p_index: usize,
}

impl ContractorConfig {
    pub fn load_default() -> Self {
        let data = include_str!("../stability_params.json");
        serde_json::from_str(data).expect("Failed to parse stability_params.json")
    }
}

pub struct MultiplicityContractor {
    config: ContractorConfig,
    primes: Vec<u64>,
    lipschitz_k: f64,
}

impl MultiplicityContractor {
    pub fn new(config: ContractorConfig) -> Result<Self, &'static str> {
        if config.lambda_m <= 0.0 || config.lambda_m >= 1.0 {
            return Err("Contractor Init Failed: lambda_m must reside in the open interval (0, 1).");
        }
        if config.alpha >= -1.0 {
            return Err("Contractor Init Failed: Convergence requires alpha < -1.");
        }

        let primes = generate_prime_truncation(config.max_p_index);
        let lipschitz_k: f64 = primes.iter()
            .map(|&p| config.lambda_m * (p as f64).powf(config.alpha))
            .sum();

        if lipschitz_k >= 1.0 {
            return Err("Contractor Init Failed: Lipschitz constant k >= 1.0 violates Banach mapping criteria.");
        }

        Ok(Self { config, primes, lipschitz_k })
    }

    pub fn lipschitz_constant(&self) -> f64 {
        self.lipschitz_k
    }

    pub fn verify_structural_admissibility(&self, source: &TensorSpaceType, target: &TensorSpaceType) -> bool {
        source.evaluates_weak_equivalence(target)
    }

    /// Evaluates real-time matrix conditioning trajectories to issue pre-emptive safety alerts  
    pub fn evaluate_stability(&self, cond_number: f64, max_budget: f64) -> StabilityStatus {  
        if cond_number >= max_budget {  
            StabilityStatus::CriticalBoundaryViolation  
        } else if cond_number >= max_budget * 0.80 {  
            StabilityStatus::Warning  
        } else {  
            StabilityStatus::Nominal  
        }  
    }  
}

fn generate_prime_truncation(n: usize) -> Vec<u64> {
    let mut primes = Vec::with_capacity(n);
    let mut candidate = 2;
    while primes.len() < n {
        if primes.iter().all(|&p| candidate % p != 0) {
            primes.push(candidate);
        }
        candidate += 1;
    }
    primes
}
