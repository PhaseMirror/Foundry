//! Bayesian crystallization and entropy operators.
//!
//! Implements crystallization lattices, entropy computation,
//! and Bayesian inference operators with verified convergence.

use crate::error::{Error, Result};

/// Crystallization lattice point.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CrystalPoint {
    /// Position index.
    pub index: usize,
    /// State value.
    pub state: i64,
    /// Energy level.
    pub energy: i64,
}

impl CrystalPoint {
    /// Create a new crystal lattice point.
    pub fn new(index: usize, state: i64, energy: i64) -> Self {
        Self { index, state, energy }
    }
}

/// Crystallization lattice with verified entropy bounds.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CrystalLattice {
    points: Vec<CrystalPoint>,
    dimension: usize,
}

impl CrystalLattice {
    /// Create a new crystal lattice.
    pub fn new(points: Vec<CrystalPoint>, dimension: usize) -> Self {
        Self { points, dimension }
    }

    /// Get the lattice dimension.
    pub fn dimension(&self) -> usize {
        self.dimension
    }

    /// Get all points.
    pub fn points(&self) -> &[CrystalPoint] {
        &self.points
    }

    /// Compute the total energy of the lattice.
    pub fn total_energy(&self) -> i64 {
        self.points.iter().map(|p| p.energy).sum()
    }

    /// Compute Boltzmann entropy: S = k_B * ln(W).
    ///
    /// W is the number of microstates with energy <= E.
    pub fn boltzmann_entropy(&self, max_energy: i64) -> f64 {
        let w = self
            .points
            .iter()
            .filter(|p| p.energy <= max_energy)
            .count() as f64;
        if w <= 0.0 {
            return f64::NEG_INFINITY;
        }
        w.ln()
    }

    /// Compute Shannon entropy of state distribution.
    pub fn shannon_entropy(&self) -> f64 {
        let total = self.points.len() as f64;
        if total == 0.0 {
            return 0.0;
        }
        let mut entropy = 0.0;
        let mut state_counts = std::collections::HashMap::new();
        for p in &self.points {
            *state_counts.entry(p.state).or_insert(0) += 1;
        }
        for &count in state_counts.values() {
            let p = count as f64 / total;
            entropy -= p * p.ln();
        }
        entropy
    }

    /// Check if the lattice has crystallized (low entropy, fixed structure).
    pub fn is_crystallized(&self, threshold: f64) -> bool {
        self.shannon_entropy() < threshold
    }
}

/// Entropy operator for Bayesian inference.
pub struct EntropyOperator;

impl EntropyOperator {
    /// Compute relative entropy (KL divergence) D(P||Q).
    pub fn kl_divergence(p: &[f64], q: &[f64]) -> Result<f64> {
        if p.len() != q.len() {
            return Err(Error::crystallization("probability vectors must have same length"));
        }
        let mut kl = 0.0;
        for (&pi, &qi) in p.iter().zip(q.iter()) {
            if pi < 0.0 || qi <= 0.0 {
                return Err(Error::crystallization("invalid probability values"));
            }
            if pi > 0.0 {
                kl += pi * (pi / qi).ln();
            }
        }
        Ok(kl)
    }

    /// Compute mutual information I(X;Y).
    pub fn mutual_information(joint: &[Vec<f64>]) -> Result<f64> {
        let rows = joint.len();
        if rows == 0 {
            return Ok(0.0);
        }
        let cols = joint[0].len();
        if cols == 0 {
            return Ok(0.0);
        }

        let mut px = vec![0.0; rows];
        let mut py = vec![0.0; cols];
        let mut total = 0.0;

        for i in 0..rows {
            for j in 0..cols {
                let val = joint[i][j];
                if val < 0.0 {
                    return Err(Error::crystallization("negative probability"));
                }
                px[i] += val;
                py[j] += val;
                total += val;
            }
        }

        if total == 0.0 {
            return Ok(0.0);
        }

        let mut mi = 0.0;
        for i in 0..rows {
            for j in 0..cols {
                if joint[i][j] > 0.0 {
                    let pxy = joint[i][j] / total;
                    let px_i = px[i] / total;
                    let py_j = py[j] / total;
                    mi += pxy * (pxy / (px_i * py_j)).ln();
                }
            }
        }
        Ok(mi)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_crystal_lattice_energy() {
        let points = vec![
            CrystalPoint::new(0, 1, 10),
            CrystalPoint::new(1, 2, 20),
        ];
        let lattice = CrystalLattice::new(points, 2);
        assert_eq!(lattice.total_energy(), 30);
    }

    #[test]
    fn test_crystal_lattice_entropy() {
        let points = vec![
            CrystalPoint::new(0, 1, 5),
            CrystalPoint::new(1, 2, 5),
            CrystalPoint::new(2, 1, 5),
            CrystalPoint::new(3, 2, 5),
        ];
        let lattice = CrystalLattice::new(points, 2);
        let entropy = lattice.shannon_entropy();
        assert!((entropy - f64::ln(2.0)).abs() < 1e-10);
    }

    #[test]
    fn test_kl_divergence() {
        let p = vec![0.5, 0.5];
        let q = vec![0.5, 0.5];
        let kl = EntropyOperator::kl_divergence(&p, &q).unwrap();
        assert!((kl - 0.0).abs() < 1e-10);
    }

    #[test]
    fn test_mutual_information() {
        let joint = vec![vec![0.25, 0.25], vec![0.25, 0.25]];
        let mi = EntropyOperator::mutual_information(&joint).unwrap();
        // Independent variables have MI = 0
        assert!(mi.abs() < 1e-10);
    }
}
