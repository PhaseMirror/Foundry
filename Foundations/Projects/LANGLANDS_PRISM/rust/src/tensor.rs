use serde::{Deserialize, Serialize};
use std::f64::consts::PI;
use crate::core::PHI;

/// Prime-indexed Tensor Node.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TensorNode {
    pub prime: u64,
    pub weight: f64,
    pub phase: f64,
    pub energy: f64,
}

impl TensorNode {
    pub fn new(prime: u64, weight: f64, phase: f64, energy: f64) -> Self {
        Self { prime, weight, phase, energy }
    }

    /// Action operator A_p(T_t) on node.
    pub fn apply_action(&self, t: u64, lambda_m: f64, alpha: f64) -> Self {
        let p = self.prime as f64;
        // Frequency modulation: theta_p(t) = (2 * pi * p * phi * t) mod 2pi
        let delta_phase = (2.0 * PI * p * PHI * (t as f64 + 1.0)) % (2.0 * PI);
        let new_phase = (self.phase + delta_phase) % (2.0 * PI);

        // Harmonic decay weight p^{-alpha}
        let harmonic_scale = p.powf(-alpha);
        let raw_weight = self.weight * harmonic_scale * lambda_m;
        let new_weight = raw_weight.clamp(0.0, 1.0);

        // Conservative damping of node energy
        let new_energy = (self.energy * lambda_m).clamp(0.0, 1.0);

        TensorNode {
            prime: self.prime,
            weight: new_weight,
            phase: new_phase,
            energy: new_energy,
        }
    }
}

/// Global Prism Tensor State.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PrismTensorState {
    pub time: u64,
    pub lambda_m: f64,
    pub nodes: Vec<TensorNode>,
    pub coherence: f64,
    pub is_stable: bool,
}

impl PrismTensorState {
    /// Initialize with standard prime sequence.
    pub fn new_with_primes(primes: &[u64], lambda_m: f64) -> Self {
        let nodes = primes.iter().enumerate().map(|(idx, &p)| {
            let weight = 1.0 - (idx as f64) * 0.1;
            let phase = (idx as f64) * 0.5;
            let energy = 0.5 - (idx as f64) * 0.05;
            TensorNode::new(p, weight.clamp(0.1, 1.0), phase, energy.clamp(0.1, 1.0))
        }).collect();

        let mut st = PrismTensorState {
            time: 0,
            lambda_m,
            nodes,
            coherence: 1.0,
            is_stable: true,
        };
        st.recompute_metrics();
        st
    }

    /// Compute total energy: sum_i E_i.
    pub fn total_energy(&self) -> f64 {
        self.nodes.iter().map(|n| n.energy).sum()
    }

    /// Recompute spectral coherence and stability.
    pub fn recompute_metrics(&mut self) {
        if self.nodes.is_empty() {
            self.coherence = 0.0;
            self.is_stable = false;
            return;
        }

        // Circular mean coherence of phases
        let sum_cos: f64 = self.nodes.iter().map(|n| (n.phase).cos()).sum();
        let sum_sin: f64 = self.nodes.iter().map(|n| (n.phase).sin()).sum();
        let r = ((sum_cos.powi(2) + sum_sin.powi(2)).sqrt() / (self.nodes.len() as f64)).clamp(0.0, 1.0);

        self.coherence = r * self.lambda_m;
        self.is_stable = !self.coherence.is_nan() && self.total_energy() <= (self.nodes.len() as f64);
    }

    /// Step the tensor state using PIRTM cascade.
    pub fn step(&self) -> Self {
        let next_time = self.time + 1;
        let updated_nodes: Vec<TensorNode> = self.nodes.iter()
            .map(|n| n.apply_action(self.time, self.lambda_m, 1.0))
            .collect();

        let mut next_st = PrismTensorState {
            time: next_time,
            lambda_m: self.lambda_m,
            nodes: updated_nodes,
            coherence: self.coherence,
            is_stable: self.is_stable,
        };
        next_st.recompute_metrics();
        next_st
    }

    /// Evolve for N iterations.
    pub fn iterate(&self, steps: usize) -> Self {
        let mut curr = self.clone();
        for _ in 0..steps {
            curr = curr.step();
        }
        curr
    }

    /// Compute spectral Shannon entropy: S = - sum_i p_i ln p_i.
    pub fn spectral_entropy(&self) -> f64 {
        let total_w: f64 = self.nodes.iter().map(|n| n.weight).sum();
        if total_w <= 1e-12 {
            return 0.0;
        }
        let mut entropy = 0.0;
        for n in &self.nodes {
            let prob = n.weight / total_w;
            if prob > 1e-12 {
                entropy -= prob * prob.ln();
            }
        }
        entropy
    }

    /// Apply Quantum Fractal Recursion F_phi(T) up to depth K.
    pub fn fractal_superposition(&self, depth: usize) -> Self {
        let mut fractal_nodes = Vec::with_capacity(self.nodes.len());
        for node in &self.nodes {
            let mut total_w = node.weight;
            let mut total_phase = node.phase;
            let mut scale = 1.0;

            for k in 1..=depth {
                scale *= 1.0 / PHI;
                let layer_w = node.weight * scale;
                let layer_phase = (node.phase + (k as f64) * 0.2) % (2.0 * PI);
                total_w += layer_w;
                total_phase = (total_phase + layer_phase) % (2.0 * PI);
            }

            fractal_nodes.push(TensorNode {
                prime: node.prime,
                weight: total_w.clamp(0.0, 2.0),
                phase: total_phase,
                energy: node.energy,
            });
        }

        let mut st = PrismTensorState {
            time: self.time,
            lambda_m: self.lambda_m,
            nodes: fractal_nodes,
            coherence: self.coherence,
            is_stable: self.is_stable,
        };
        st.recompute_metrics();
        st
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::core::LAMBDA_M;

    #[test]
    fn test_tensor_cascade_evolution() {
        let primes = [2, 3, 5, 7, 11];
        let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
        assert_eq!(st0.nodes.len(), 5);
        assert_eq!(st0.time, 0);

        let st1 = st0.step();
        assert_eq!(st1.time, 1);
        assert!(st1.coherence <= 1.0);
        assert!(st1.total_energy() <= 5.0);

        let st5 = st0.iterate(5);
        assert_eq!(st5.time, 5);
        assert!(st5.is_stable);
    }

    #[test]
    fn test_fractal_superposition() {
        let primes = [2, 3, 5];
        let st0 = PrismTensorState::new_with_primes(&primes, LAMBDA_M);
        let fractal_st = st0.fractal_superposition(3);
        assert_eq!(fractal_st.nodes.len(), 3);
        assert!(fractal_st.nodes[0].weight >= st0.nodes[0].weight);
    }
}
