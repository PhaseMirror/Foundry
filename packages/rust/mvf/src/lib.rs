use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use nalgebra::{DMatrix, DVector};
use num_complex::Complex64;
use chrono::Utc;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum MvfError {
    #[error("Governance Halt: Inadmissible coupling.")]
    InadmissibleCoupling,
    #[error("Governance Halt: Continuous norm violation.")]
    NormViolation,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PirtmGovernance {
    pub mu: usize,
    pub epsilon: f64,
    pub l_t: f64,
    pub gamma: f64,
    pub b_max: f64,
    pub delta: f64,
    pub stress_counter: usize,
    pub drift_counter: usize,
    pub max_rescales: usize,
}

impl PirtmGovernance {
    pub fn new(mu: usize, epsilon: f64, l_t: f64, gamma: Option<f64>, b_max: Option<f64>) -> Self {
        PirtmGovernance {
            mu,
            epsilon,
            l_t,
            gamma: gamma.unwrap_or(0.7),
            b_max: b_max.unwrap_or(10.0),
            delta: 0.05 * epsilon,
            stress_counter: 0,
            drift_counter: 0,
            max_rescales: 3,
        }
    }

    pub fn check_admissibility(&self, mut lambda_m: f64) -> (bool, f64) {
        let mut c_t = lambda_m.abs() * self.l_t;
        if c_t < self.epsilon {
            return (true, lambda_m);
        }

        for _ in 0..self.max_rescales {
            lambda_m *= 1.0 - self.delta;
            c_t = lambda_m.abs() * self.l_t;
            if c_t < self.epsilon {
                return (true, lambda_m);
            }
        }

        (false, lambda_m)
    }

    pub fn compute_pss(&mut self, m_weights: &HashMap<usize, f64>) -> f64 {
        let weights: Vec<f64> = m_weights.values().cloned().collect();
        if weights.len() < 2 {
            return 1.0;
        }

        let mut entropy = 0.0;
        for w in &weights {
            entropy -= w * (w + 1e-12).ln();
        }
        let max_entropy = (weights.len() as f64).ln();
        let pss = entropy / (max_entropy + 1e-12);

        if pss < 0.4 {
            self.drift_counter += 1;
        } else {
            self.drift_counter = 0;
        }

        pss
    }

    pub fn log_event(&self, event: &str, lambda_m: f64, norm_psi: f64, regime: &str, extra: Option<serde_json::Value>) {
        let mut log_entry = serde_json::json!({
            "timestamp": Utc::now().to_rfc3339(),
            "mu": self.mu,
            "lambda_m": lambda_m,
            "c_t": lambda_m.abs() * self.l_t,
            "norm_psi": norm_psi,
            "event": event,
            "regime": regime,
            "stress": self.stress_counter,
            "drift_steps": self.drift_counter,
        });

        if let Some(mut e) = extra {
            if let Some(obj) = e.as_object_mut() {
                log_entry.as_object_mut().unwrap().append(obj);
            }
        }

        // println!("[GOVERNANCE] {}", log_entry.to_string());
    }
}

pub struct MvfSimulator {
    pub gov: PirtmGovernance,
    pub dim: usize,
    pub psi: DVector<Complex64>,
    pub xi: DMatrix<Complex64>,
    pub primes: Vec<usize>,
    pub projectors: HashMap<usize, DMatrix<Complex64>>,
}

impl MvfSimulator {
    pub fn new(gov: PirtmGovernance, dim: usize) -> Self {
        // Init psi with some placeholder logic, or zeros
        let mut psi = DVector::from_element(dim, Complex64::new(1.0, 0.0));
        let norm = psi.norm();
        if norm > 1e-12 {
            psi /= Complex64::new(norm, 0.0);
        }

        let mut s = DMatrix::zeros(dim, dim);
        for i in 0..dim {
            s[(i, (i + 1) % dim)] = Complex64::new(1.0, 0.0);
        }
        
        let xi = s * Complex64::new(1.0 - gov.epsilon - 0.01, 0.0);
        
        let primes = Self::get_primes(gov.mu);
        let projectors = Self::build_projectors(&primes, dim);

        MvfSimulator {
            gov,
            dim,
            psi,
            xi,
            primes,
            projectors,
        }
    }

    fn get_primes(n: usize) -> Vec<usize> {
        let mut primes = Vec::new();
        let mut chk = 2;
        while primes.len() < n {
            let mut is_prime = true;
            for p in &primes {
                if chk % p == 0 {
                    is_prime = false;
                    break;
                }
            }
            if is_prime {
                primes.push(chk);
            }
            chk += 1;
        }
        primes
    }

    fn build_projectors(primes: &[usize], dim: usize) -> HashMap<usize, DMatrix<Complex64>> {
        let mut projectors = HashMap::new();
        for &p in primes {
            let idx = p % dim;
            let mut ep = DMatrix::zeros(dim, dim);
            ep[(idx, idx)] = Complex64::new(1.0, 0.0);
            projectors.insert(p, ep);
        }
        projectors
    }

    pub fn compute_sector_multiplicity(&self) -> HashMap<usize, f64> {
        let t_psi = self.psi.map(|v| v.tanh());
        let norm_t_sq = t_psi.norm_squared();
        
        let mut m_weights = HashMap::new();
        if norm_t_sq < 1e-12 {
            for &p in &self.primes {
                m_weights.insert(p, 1.0 / self.primes.len() as f64);
            }
            return m_weights;
        }

        for (&p, ep) in &self.projectors {
            let p_t_psi = ep * &t_psi;
            m_weights.insert(p, p_t_psi.norm_squared() / norm_t_sq);
        }
        m_weights
    }

    pub fn step(&mut self, raw_lambda_m: f64) -> Result<(), MvfError> {
        let (admissible, lambda_m) = self.gov.check_admissibility(raw_lambda_m);
        
        if !admissible {
            self.gov.log_event("INADMISSIBLE_HALT", lambda_m, self.psi.norm(), "THEOREM_SAFE", None);
            return Err(MvfError::InadmissibleCoupling);
        }

        let t_psi = self.psi.map(|v| v.tanh());
        let psi_new = &self.xi * &self.psi + t_psi * Complex64::new(lambda_m, 0.0);
        let norm_new = psi_new.norm();
        
        if norm_new > self.gov.b_max {
            self.gov.stress_counter += 1;
            self.gov.log_event("NORM_VIOLATION", lambda_m, norm_new, "THEOREM_SAFE", None);
            if self.gov.stress_counter >= 3 {
                self.gov.log_event("STRESS_HALT", lambda_m, norm_new, "THEOREM_SAFE", None);
                return Err(MvfError::NormViolation);
            }
            return Ok(());
        }
        
        self.gov.stress_counter = 0;
        self.psi = psi_new;
        
        let m_weights = self.compute_sector_multiplicity();
        let pss = self.gov.compute_pss(&m_weights);
        
        let diag = serde_json::json!({
            "prime_signature": m_weights,
            "pss": pss,
        });
        
        if self.gov.drift_counter > 0 {
            self.gov.log_event("ONTOLOGICAL_DRIFT", lambda_m, norm_new, "THEOREM_SAFE", Some(diag));
        } else {
            self.gov.log_event("ADMISSIBLE", lambda_m, norm_new, "THEOREM_SAFE", Some(diag));
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_admissibility() {
        let gov = PirtmGovernance::new(4, 0.1, 1.0, None, None);
        let (admissible, _) = gov.check_admissibility(0.09);
        assert!(admissible);
        
        let (adm2, _) = gov.check_admissibility(0.1001);
        assert!(adm2); // Should be true after rescales
    }

    #[test]
    fn test_simulator_step() {
        let gov = PirtmGovernance::new(4, 0.1, 1.0, None, None);
        let mut sim = MvfSimulator::new(gov, 8);
        assert!(sim.step(0.09).is_ok());
    }
}
