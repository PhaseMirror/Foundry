use std::f64;

/// Compute additive logits for query `Q`, key `K`, and mask `M`.
/// All matrices are represented as `Vec<Vec<f64>>` of size `p × p`.
pub fn additive_logits(
    q: &Vec<Vec<f64>>,
    k: &Vec<Vec<f64>>,
    m: &Vec<Vec<bool>>,
    alpha: f64,
    beta: f64,
) -> Vec<Vec<f64>> {
    let p = q.len();
    let mut out = vec![vec![0.0; p]; p];
    for i in 0..p {
        for j in 0..p {
            out[i][j] = alpha * q[i][j] + beta * k[i][j] + if m[i][j] { 1.0 } else { 0.0 };
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    #[kani::proof]
    fn test_additive_logits_nonneg() {
        let p = 3usize;
        let q = vec![vec![0.0; p]; p];
        let k = vec![vec![0.0; p]; p];
        let m = vec![vec![true; p]; p];
        let alpha = 1.0f64;
        let beta = 2.0f64;
        let out = additive_logits(&q, &k, &m, alpha, beta);
        for i in 0..p {
            for j in 0..p {
                assert!(out[i][j] >= 0.0);
            }
        }
    }
}
