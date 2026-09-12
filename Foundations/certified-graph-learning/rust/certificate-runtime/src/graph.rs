#![forbid(unsafe_code)]

//! # Graph representation
//!
//! Undirected weighted graph stored as a square adjacency matrix plus
//! its graph Laplacian. All validation is performed at construction
//! time so that runtime operations on `Graph` are total.
//!
//! ## Invariants
//!
//! Every `Graph` satisfies:
//! 1. `n ≥ 1` (at least one vertex)
//! 2. `weights` is `n × n` and symmetric
//! 3. `weights[i][i] == 0` (no self-loops)
//! 4. `weights[i][j] >= 0` for all `i, j` (non-negative edges)
//! 5. `laplacian[i][j] = -weights[i][j]` for `i ≠ j`
//! 6. `laplacian[i][i] = Σ_{j≠i} weights[i][j]`  (row sums zero)

/// Error produced while constructing a `Graph`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum GraphError {
    /// Zero-sized graphs are not supported.
    EmptyGraph,
    /// Row length differs from the number of vertices.
    InvalidDimensions,
    /// The weight matrix is not symmetric.
    NotSymmetric,
    /// A diagonal entry is non-zero (self-loop).
    SelfLoop,
    /// A weight is negative.
    NegativeWeight,
}

impl core::fmt::Display for GraphError {
    fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::EmptyGraph => write!(f, "graph must have at least one vertex"),
            Self::InvalidDimensions => write!(f, "weight matrix must be n x n"),
            Self::NotSymmetric => write!(f, "weight matrix must be symmetric"),
            Self::SelfLoop => write!(f, "diagonal entries must be zero"),
            Self::NegativeWeight => write!(f, "edge weights must be non-negative"),
        }
    }
}

impl core::error::Error for GraphError {}

/// An undirected weighted graph with `n` vertices.
#[derive(Debug)]
pub struct Graph {
    /// Number of vertices.
    n: usize,
    /// Symmetric weight (adjacency) matrix.
    weights: Vec<Vec<f64>>,
    /// Graph Laplacian `L = D - A`.
    laplacian: Vec<Vec<f64>>,
}

impl Graph {
    /// Construct a validated graph from a symmetric weight matrix.
    ///
    /// # Errors
    ///
    /// Returns [`GraphError`] if any invariant is violated.
    pub fn from_weights(weights: Vec<Vec<f64>>) -> Result<Self, GraphError> {
        let n = weights.len();
        if n == 0 {
            return Err(GraphError::EmptyGraph);
        }
        for row in &weights {
            if row.len() != n {
                return Err(GraphError::InvalidDimensions);
            }
        }
        // Symmetry and diagonal/negativity checks (double loop, verified by Kani for n ≤ 8).
        for i in 0..n {
            for j in 0..n {
                if weights[i][j] != weights[j][i] {
                    return Err(GraphError::NotSymmetric);
                }
                if i == j && weights[i][j] != 0.0 {
                    return Err(GraphError::SelfLoop);
                }
                if weights[i][j] < 0.0 {
                    return Err(GraphError::NegativeWeight);
                }
            }
        }

        // Build the Laplacian: L[i][i] = Σ_{j≠i} w[i][j], L[i][j] = -w[i][j].
        let mut laplacian = vec![vec![0.0; n]; n];
        for i in 0..n {
            let mut deg = 0.0;
            for j in 0..n {
                if i != j {
                    deg += weights[i][j];
                }
            }
            for j in 0..n {
                laplacian[i][j] = if i == j {
                    deg
                } else {
                    -weights[i][j]
                };
            }
        }

        Ok(Self { n, weights, laplacian })
    }

    /// Number of vertices.
    #[inline]
    pub fn len(&self) -> usize {
        self.n
    }

    /// Returns true when the graph has zero vertices.
    #[inline]
    pub fn is_empty(&self) -> bool {
        self.n == 0
    }

    /// Access the weight at `(i, j)`.
    #[inline]
    pub fn weight(&self, i: usize, j: usize) -> f64 {
        self.weights[i][j]
    }

    /// Access the Laplacian entry at `(i, j)`.
    #[inline]
    pub fn laplacian(&self, i: usize, j: usize) -> f64 {
        self.laplacian[i][j]
    }

    /// A slice view over row `i` of the Laplacian.
    #[inline]
    pub fn laplacian_row(&self, i: usize) -> &[f64] {
        &self.laplacian[i]
    }

    /// True if every vertex has at least one neighbor (no isolated vertices).
    pub fn connected(&self) -> bool {
        (0..self.n).all(|i| {
            (0..self.n)
                .filter(|&j| j != i)
                .any(|j| self.weights[i][j] > 0.0)
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn path_graph(n: usize) -> Vec<Vec<f64>> {
        let mut w = vec![vec![0.0; n]; n];
        for i in 0..n.saturating_sub(1) {
            w[i][i + 1] = 1.0;
            w[i + 1][i] = 1.0;
        }
        w
    }

    #[test]
    fn empty_rejected() {
        assert!(matches!(
            Graph::from_weights(Vec::new()),
            Err(GraphError::EmptyGraph)
        ));
    }

    #[test]
    fn non_square_rejected() {
        let w = vec![vec![0.0, 1.0], vec![1.0]];
        assert!(matches!(
            Graph::from_weights(w),
            Err(GraphError::InvalidDimensions)
        ));
    }

    #[test]
    fn self_loop_rejected() {
        let w = vec![vec![1.0, 0.0], vec![0.0, 0.0]];
        assert!(matches!(
            Graph::from_weights(w),
            Err(GraphError::SelfLoop)
        ));
    }

    #[test]
    fn negative_rejected() {
        let w = vec![vec![0.0, -1.0], vec![-1.0, 0.0]];
        assert!(matches!(
            Graph::from_weights(w),
            Err(GraphError::NegativeWeight)
        ));
    }

    #[test]
    fn asymmetry_rejected() {
        let w = vec![vec![0.0, 1.0], vec![2.0, 0.0]];
        assert!(matches!(
            Graph::from_weights(w),
            Err(GraphError::NotSymmetric)
        ));
    }

    #[test]
    fn laplacian_row_sums_zero() {
        let g = Graph::from_weights(path_graph(4)).unwrap();
        for i in 0..g.len() {
            let row_sum: f64 = g.laplacian_row(i).iter().sum();
            assert!(row_sum.abs() < 1e-12, "row {} sum = {}", i, row_sum);
        }
    }

    #[test]
    fn laplacian_off_diagonal_is_negative_weight() {
        let g = Graph::from_weights(path_graph(3)).unwrap();
        assert!((g.laplacian(0, 1) + 1.0).abs() < 1e-12);
        assert!((g.laplacian(1, 2) + 1.0).abs() < 1e-12);
        assert!((g.laplacian(0, 0) - 1.0).abs() < 1e-12);
    }

    #[test]
    fn path3_connected() {
        let g = Graph::from_weights(path_graph(3)).unwrap();
        assert!(g.connected());
    }

    #[test]
    fn disconnected_detected() {
        let w = vec![
            vec![0.0, 1.0, 0.0],
            vec![1.0, 0.0, 0.0],
            vec![0.0, 0.0, 0.0],
        ];
        let g = Graph::from_weights(w).unwrap();
        assert!(!g.connected());
    }
}