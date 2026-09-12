//! Graph Laplacian and Algebraic Connectivity (Fiedler Value λ_2)

use crate::types::HabitatGraph;

/// Graph spectral analysis and Laplacian operator.
pub struct GraphSpectralAnalyzer;

impl GraphSpectralAnalyzer {
    /// Compute unnormalized graph Laplacian L = D - A.
    pub fn compute_laplacian(graph: &HabitatGraph) -> Vec<Vec<f64>> {
        let n = graph.num_nodes;
        let mut laplacian = vec![vec![0.0; n]; n];

        for i in 0..n {
            let mut degree = 0.0;
            for j in 0..n {
                if i != j {
                    let w = graph.adjacency_matrix[i][j];
                    degree += w;
                    laplacian[i][j] = -w;
                }
            }
            laplacian[i][i] = degree;
        }

        laplacian
    }

    /// Computes algebraic connectivity (Fiedler eigenvalue lambda_2(L)) using shifted inverse power iteration.
    pub fn compute_fiedler_value(graph: &HabitatGraph) -> f64 {
        let n = graph.num_nodes;
        if n <= 1 {
            return 0.0;
        }

        let l = Self::compute_laplacian(graph);

        // Find maximum eigenvalue bound using Gershgorin circle theorem
        let mut max_deg: f64 = 0.0;
        for i in 0..n {
            if l[i][i] > max_deg {
                max_deg = l[i][i];
            }
        }
        let mu = 2.0 * max_deg.max(1.0);

        // Shift matrix M = mu * I - L (its largest eigenvalue is mu, second largest is mu - lambda_2)
        let mut m = vec![vec![0.0; n]; n];
        for i in 0..n {
            for j in 0..n {
                if i == j {
                    m[i][j] = mu - l[i][j];
                } else {
                    m[i][j] = -l[i][j];
                }
            }
        }

        // Deflate out trivial consensus eigenvector (1, 1, ..., 1) / sqrt(n)
        let inv_sqrt_n = 1.0 / (n as f64).sqrt();
        let e1 = vec![inv_sqrt_n; n];

        // Power iteration for second largest eigenvalue of M
        let mut v: Vec<f64> = (0..n).map(|i| if i % 2 == 0 { 1.0 } else { -1.0 }).collect();
        // Project orthogonal to e1
        let dot: f64 = v.iter().sum::<f64>() * inv_sqrt_n;
        for i in 0..n {
            v[i] -= dot * e1[i];
        }

        let mut norm = v.iter().map(|&x| x * x).sum::<f64>().sqrt();
        if norm > 1e-9 {
            for i in 0..n {
                v[i] /= norm;
            }
        }

        let mut lambda_m2 = 0.0;
        for _ in 0..150 {
            // v_next = M * v
            let mut v_next = vec![0.0; n];
            for i in 0..n {
                for j in 0..n {
                    v_next[i] += m[i][j] * v[j];
                }
            }

            // Deflate orthogonal to e1
            let d: f64 = v_next.iter().sum::<f64>() * inv_sqrt_n;
            for i in 0..n {
                v_next[i] -= d * e1[i];
            }

            norm = v_next.iter().map(|&x| x * x).sum::<f64>().sqrt();
            if norm < 1e-9 {
                break;
            }
            for i in 0..n {
                v[i] = v_next[i] / norm;
            }
            lambda_m2 = norm;
        }

        (mu - lambda_m2).max(0.0)
    }
}
