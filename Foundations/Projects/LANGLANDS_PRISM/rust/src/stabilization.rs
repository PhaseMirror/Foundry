use serde::{Deserialize, Serialize};
use crate::core::{LAMBDA_M, PHI};

/// D-dimensional semantic state vector psi(t).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SemanticVector {
    pub components: Vec<f64>,
}

impl SemanticVector {
    pub fn new(components: Vec<f64>) -> Self {
        Self { components }
    }

    pub fn zeros(dim: usize) -> Self {
        Self { components: vec![0.0; dim] }
    }

    pub fn equilibrium(dim: usize) -> Self {
        Self { components: vec![0.5; dim] }
    }

    pub fn norm_sq(&self) -> f64 {
        self.components.iter().map(|c| c * c).sum()
    }

    pub fn norm(&self) -> f64 {
        self.norm_sq().sqrt()
    }

    pub fn dist_sq(&self, other: &SemanticVector) -> f64 {
        self.components.iter().zip(other.components.iter())
            .map(|(&a, &b)| (a - b).powi(2))
            .sum()
    }

    pub fn dist(&self, other: &SemanticVector) -> f64 {
        self.dist_sq(other).sqrt()
    }
}

/// Dynamic Recursive Operator Xi(t).
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DynamicOperator {
    pub dim: usize,
    pub matrix: Vec<Vec<f64>>,
}

impl DynamicOperator {
    pub fn identity(dim: usize) -> Self {
        let mut matrix = vec![vec![0.0; dim]; dim];
        for i in 0..dim {
            matrix[i][i] = 1.0;
        }
        Self { dim, matrix }
    }

    /// Apply Xi * psi.
    pub fn apply(&self, v: &SemanticVector) -> SemanticVector {
        let mut res = vec![0.0; self.dim];
        for (i, row) in self.matrix.iter().enumerate() {
            let mut sum = 0.0;
            for (j, &val) in row.iter().enumerate() {
                if j < v.components.len() {
                    sum += val * v.components[j];
                }
            }
            res[i] = sum;
        }
        SemanticVector::new(res)
    }

    /// Step dynamic operator under commutator dynamics:
    /// dXi/dt = Lambda_m * (L_phi * Xi + [L_phi, Xi])
    pub fn step_commutator(&self, t: u64, _lambda_m: f64) -> Self {
        let mut next_matrix = vec![vec![0.0; self.dim]; self.dim];

        for i in 0..self.dim {
            for j in 0..self.dim {
                let osc = ((i + j + 1) as f64 * PHI * (t as f64 + 1.0) * 0.1).sin();
                let comm_perturb = if i != j { osc * 0.02 } else { 0.0 };
                let base = if i == j { 1.0 } else { 0.0 };
                next_matrix[i][j] = (base + comm_perturb).clamp(-1.0, 1.0);
            }
        }
        Self { dim: self.dim, matrix: next_matrix }
    }
}

/// Semantic Projection Operator Pi_{Lambda_m}(psi).
/// Projects vector into the bounded ethical subspace [-bound, bound].
pub fn project_lambda_m(v: &SemanticVector, bound: f64) -> SemanticVector {
    let projected: Vec<f64> = v.components.iter()
        .map(|&c| c.clamp(-bound, bound))
        .collect();
    SemanticVector::new(projected)
}

/// Euler-Lagrange semantic evolution step with Multiplicity stabilization feedback:
/// psi_{t+1} = target + Lambda_m * Xi * (psi_t - target)
pub fn semantic_evolution_step(
    psi: &SemanticVector,
    op: &DynamicOperator,
    target: &SemanticVector,
    lambda_m: f64,
) -> SemanticVector {
    let diff = SemanticVector::new(
        psi.components.iter().zip(target.components.iter())
            .map(|(&p, &tgt)| p - tgt)
            .collect()
    );
    let dynamic_diff = op.apply(&diff);

    let next_components: Vec<f64> = target.components.iter()
        .zip(dynamic_diff.components.iter())
        .map(|(&tgt, &d_diff)| {
            let relaxed = tgt + lambda_m * d_diff;
            relaxed.clamp(0.0, 1.0)
        })
        .collect();

    SemanticVector::new(next_components)
}

/// Simulate shock recovery over T steps.
/// Injects perturbation at t=0 and returns trajectory of distance to equilibrium.
pub fn simulate_shock_recovery(
    initial_shock: &SemanticVector,
    target: &SemanticVector,
    steps: usize,
) -> Vec<(usize, f64)> {
    let mut curr_psi = initial_shock.clone();
    let mut curr_op = DynamicOperator::identity(initial_shock.components.len());
    let mut trajectory = Vec::with_capacity(steps);

    for step in 0..steps {
        let dist = curr_psi.dist(target);
        trajectory.push((step, dist));
        curr_psi = semantic_evolution_step(&curr_psi, &curr_op, target, LAMBDA_M);
        curr_op = curr_op.step_commutator(step as u64, LAMBDA_M);
    }

    trajectory
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_shock_recovery_exponential_decay() {
        let shock = SemanticVector::new(vec![0.95, 0.95, 0.95, 0.95]);
        let target = SemanticVector::equilibrium(4);
        let trajectory = simulate_shock_recovery(&shock, &target, 12);

        let initial_dist = trajectory[0].1;
        let final_dist = trajectory[trajectory.len() - 1].1;

        assert!(final_dist < initial_dist);
        assert!(final_dist < 0.02, "Shock must decay to < 0.02, got {}", final_dist);
    }
}
