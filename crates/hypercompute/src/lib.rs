use serde::{Deserialize, Serialize};
use ndarray::{Array1, Array2};
use rand::SeedableRng;
use rand_distr::{Distribution, StandardNormal};
use sha2::{Sha256, Digest};
use std::collections::HashMap;

pub fn prime_sieve(n: usize) -> Vec<usize> {
    if n < 2 {
        return vec![];
    }
    let mut sieve = vec![true; n + 1];
    sieve[0] = false;
    sieve[1] = false;
    for i in 2..=(n as f64).sqrt() as usize {
        if sieve[i] {
            let mut j = i * i;
            while j <= n {
                sieve[j] = false;
                j += i;
            }
        }
    }
    sieve.iter().enumerate().filter(|&(_, &is_prime)| is_prime).map(|(i, _)| i).collect()
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationParams {
    pub seed: u64,
    pub num_primes: usize,
    pub num_steps: usize,
    pub dt: f64,
    pub lambda_m: f64,
    pub state_dim: usize,
    pub coupling_strength: f64,
}

impl Default for SimulationParams {
    fn default() -> Self {
        SimulationParams {
            seed: 42,
            num_primes: 8,
            num_steps: 100,
            dt: 0.01,
            lambda_m: 1.0,
            state_dim: 4,
            coupling_strength: 0.1,
        }
    }
}

pub struct ParameterConstraints {
    pub min_primes: usize,
    pub max_primes: usize,
    pub min_steps: usize,
    pub max_steps: usize,
    pub lambda_m_range: (f64, f64),
    pub dt_range: (f64, f64),
    pub dim_range: (usize, usize),
}

impl Default for ParameterConstraints {
    fn default() -> Self {
        ParameterConstraints {
            min_primes: 3,
            max_primes: 50,
            min_steps: 1,
            max_steps: 10000,
            lambda_m_range: (0.0, 10.0),
            dt_range: (1e-6, 1.0),
            dim_range: (2, 64),
        }
    }
}

impl ParameterConstraints {
    pub fn validate(&self, params: &SimulationParams) -> Vec<String> {
        let mut violations = Vec::new();
        if params.num_primes < self.min_primes || params.num_primes > self.max_primes {
            violations.push(format!("num_primes={} outside [{}, {}]", params.num_primes, self.min_primes, self.max_primes));
        }
        if params.num_steps < self.min_steps || params.num_steps > self.max_steps {
            violations.push(format!("num_steps={} outside [{}, {}]", params.num_steps, self.min_steps, self.max_steps));
        }
        if params.lambda_m < self.lambda_m_range.0 || params.lambda_m > self.lambda_m_range.1 {
            violations.push(format!("lambda_m={} outside [{}, {}]", params.lambda_m, self.lambda_m_range.0, self.lambda_m_range.1));
        }
        if params.dt < self.dt_range.0 || params.dt > self.dt_range.1 {
            violations.push(format!("dt={} outside [{}, {}]", params.dt, self.dt_range.0, self.dt_range.1));
        }
        if params.state_dim < self.dim_range.0 || params.state_dim > self.dim_range.1 {
            violations.push(format!("state_dim={} outside [{}, {}]", params.state_dim, self.dim_range.0, self.dim_range.1));
        }
        violations
    }
}

pub struct PrimeIndexedDynamicsCore {
    pub params: SimulationParams,
    pub primes: Vec<usize>,
    pub h: Array2<f64>,
    pub w: HashMap<usize, Array2<f64>>,
}

impl PrimeIndexedDynamicsCore {
    pub fn new(params: SimulationParams) -> Result<Self, String> {
        let constraints = ParameterConstraints::default();
        let violations = constraints.validate(&params);
        if !violations.is_empty() {
            return Err(format!("Parameter constraint violations:\n{}", violations.join("\n")));
        }

        let mut rng = rand::rngs::StdRng::seed_from_u64(params.seed);
        let primes: Vec<usize> = prime_sieve(200).into_iter().take(params.num_primes).collect();
        let dim = params.state_dim;

        let raw_h = Array2::from_shape_fn((dim, dim), |_| StandardNormal.sample(&mut rng));
        let h = (&raw_h + &raw_h.t()) / 2.0;

        let mut w = HashMap::new();
        for &p in &primes {
            let raw_w = Array2::from_shape_fn((dim, dim), |_| StandardNormal.sample(&mut rng));
            // simplified norm calculation for baseline
            let norm: f64 = 1.0; 
            w.insert(p, raw_w * (params.coupling_strength / norm.max(1.0)));
        }

        Ok(PrimeIndexedDynamicsCore {
            params,
            primes,
            h,
            w,
        })
    }

    pub fn initial_state(&self) -> Array1<f64> {
        let mut rng = rand::rngs::StdRng::seed_from_u64(self.params.seed);
        let state: Array1<f64> = Array1::from_shape_fn(self.params.state_dim, |_| StandardNormal.sample(&mut rng));
        let norm = state.dot(&state).sqrt();
        state / norm
    }

    pub fn step(&self, xi: &Array1<f64>) -> Array1<f64> {
        let mut dxi = self.h.dot(xi);
        
        for &p in &self.primes {
            let log_p = (p as f64).ln();
            dxi = dxi + (self.w[&p].dot(xi) * self.params.lambda_m * log_p);
        }

        xi + &(dxi * self.params.dt)
    }

    pub fn run(&self) -> SimulationResult {
        let mut xi = self.initial_state();
        let mut trajectory = vec![xi.clone()];
        let mut norms = vec![xi.dot(&xi).sqrt()];

        for _ in 0..self.params.num_steps {
            xi = self.step(&xi);
            trajectory.push(xi.clone());
            norms.push(xi.dot(&xi).sqrt());
        }

        let convergence_metric = if norms.len() >= 2 {
            (norms[norms.len() - 1] - norms[norms.len() - 2]).abs()
        } else {
            0.0
        };

        // Simplified std calculation for stability margin
        let stability_margin = if norms.len() >= 10 {
            let slice = &norms[norms.len() - 10..];
            let mean = slice.iter().sum::<f64>() / 10.0;
            let variance = slice.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / 10.0;
            variance.sqrt()
        } else {
            let mean = norms.iter().sum::<f64>() / norms.len() as f64;
            let variance = norms.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / norms.len() as f64;
            variance.sqrt()
        };

        let attractor_norm = *norms.last().unwrap();
        
        // Hash final state
        let mut hasher = Sha256::new();
        for val in &xi {
            hasher.update(val.to_le_bytes());
        }
        let hash_result = hasher.finalize();
        let final_state_hash = hex::encode(&hash_result[..8]); // taking first 8 bytes for 16 chars

        SimulationResult {
            params: self.params.clone(),
            primes_used: self.primes.clone(),
            convergence_metric,
            stability_margin,
            attractor_norm,
            final_state_hash,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationResult {
    pub params: SimulationParams,
    pub primes_used: Vec<usize>,
    pub convergence_metric: f64,
    pub stability_margin: f64,
    pub attractor_norm: f64,
    pub final_state_hash: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parameter_constraints() {
        let constraints = ParameterConstraints::default();
        let mut params = SimulationParams::default();
        assert!(constraints.validate(&params).is_empty());

        params.num_primes = 2; // Below min
        assert_eq!(constraints.validate(&params).len(), 1);
    }

    #[test]
    fn test_simulation_run() {
        let params = SimulationParams::default();
        let core = PrimeIndexedDynamicsCore::new(params).unwrap();
        let result = core.run();
        
        assert!(result.primes_used.len() == 8);
        assert!(result.attractor_norm > 0.0);
    }
}
