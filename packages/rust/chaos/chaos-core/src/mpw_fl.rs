use std::collections::HashMap;
use ndarray::{Array1, ArrayView1};
use num_traits::Float;

pub type Profile = HashMap<i32, i32>;

pub fn multiplicity_weight(profile: &Profile, gamma: Option<&dyn Fn(i32) -> f64>) -> f64 {
    let default_gamma = |p: i32| (p as f64 + 1.0).ln();
    let g = gamma.unwrap_or(&default_gamma);
    
    profile.iter().map(|(&p, &k)| k as f64 * g(p)).sum()
}

pub fn normalize_weights(profiles: &[Profile], gamma: Option<&dyn Fn(i32) -> f64>) -> Array1<f64> {
    let raw: Vec<f64> = profiles.iter().map(|mi| multiplicity_weight(mi, gamma)).collect();
    let total: f64 = raw.iter().sum();
    
    if total <= 0.0 {
        panic!("Multiplicity weights must have positive total.");
    }
    
    Array1::from_vec(raw.iter().map(|&w| w / total).collect())
}

pub struct MPWFL {
    pub weights: Array1<f64>,
    pub lambda0: f64,
    pub delta: f64,
    pub veto_threshold: f64,
    pub lam: f64,
}

impl MPWFL {
    pub fn new(profiles: &[Profile], lambda0: f64, delta: f64, veto_threshold: f64) -> Self {
        let weights = normalize_weights(profiles, None);
        let b: f64 = weights.iter().map(|&w| w * w).sum();
        let lam = (lambda0 + delta * (2.0 * b - 1.0)).clamp(0.0, 1.0);
        
        Self {
            weights,
            lambda0,
            delta,
            veto_threshold,
            lam,
        }
    }

    pub fn conjunction(&self, x: ArrayView1<f64>) -> f64 {
        if x.iter().any(|&xi| xi <= self.veto_threshold) {
            return 0.0;
        }
        
        let x_clipped: Vec<f64> = x.iter().map(|&xi| xi.max(1e-8).min(1.0)).collect();
        let log_x: Vec<f64> = x_clipped.iter().map(|&xi| xi.ln()).collect();
        
        let mut dot = 0.0;
        for i in 0..self.weights.len() {
            dot += self.weights[i] * log_x[i];
        }
        
        dot.exp()
    }

    pub fn disjunction(&self, x: ArrayView1<f64>) -> f64 {
        let x_inv: Vec<f64> = x.iter().map(|&xi| 1.0 - xi).collect();
        1.0 - self.conjunction(ArrayView1::from(&x_inv))
    }

    pub fn blend(&self, x: ArrayView1<f64>) -> f64 {
        let c_fwd = self.conjunction(x);
        let c_inv = self.disjunction(x);
        
        self.lam * c_fwd + (1.0 - self.lam) * c_inv
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;
    use ndarray::array;

    #[test]
    fn test_mpwfl_conjunction() {
        let mut p1 = HashMap::new();
        p1.insert(2, 1);
        let mut p2 = HashMap::new();
        p2.insert(3, 1);
        
        let mpw = MPWFL::new(&[p1, p2], 0.5, 0.0, 0.0);
        let x = array![0.8, 0.6];
        let res = mpw.conjunction(x.view());
        assert!(res > 0.0 && res < 1.0);
    }
}
