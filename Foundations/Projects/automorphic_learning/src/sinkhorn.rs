/// Simplified ε‑stabilized Sinkhorn iteration.
/// For demonstration we perform `iters` rounds of row‑normalization
/// followed by column‑normalization on a non‑negative matrix.
/// The matrix is represented as `Vec<Vec<f64>>` of size `p × p`.
pub fn sinkhorn(m: &Vec<Vec<f64>>, eps: f64, iters: usize) -> Vec<Vec<f64>> {
    let p = m.len();
    let mut cur = m.clone();
    for _ in 0..iters {
        // Row normalize
        for i in 0..p {
            let row_sum: f64 = cur[i].iter().sum();
            if row_sum > eps {
                for j in 0..p {
                    cur[i][j] /= row_sum;
                }
            }
        }
        // Column normalize
        for j in 0..p {
            let mut col_sum = 0.0f64;
            for i in 0..p {
                col_sum += cur[i][j];
            }
            if col_sum > eps {
                for i in 0..p {
                    cur[i][j] /= col_sum;
                }
            }
        }
    }
    cur
}

#[cfg(test)]
mod tests {
    use super::*;
    #[kani::proof]
    fn test_sinkhorn_stochastic() {
        let p = 3usize;
        // simple positive matrix
        let m = vec![vec![1.0, 2.0, 1.0], vec![2.0, 1.0, 1.0], vec![1.0, 1.0, 2.0]];
        let eps = 1e-8f64;
        let iters = 5usize;
        let s = sinkhorn(&m, eps, iters);
        // each row should sum close to 1.0
        for i in 0..p {
            let row_sum: f64 = s[i].iter().sum();
            assert!((row_sum - 1.0).abs() < 1e-6);
        }
        // each column should sum close to 1.0
        for j in 0..p {
            let mut col_sum = 0.0f64;
            for i in 0..p {
                col_sum += s[i][j];
            }
            assert!((col_sum - 1.0).abs() < 1e-6);
        }
    }
}
