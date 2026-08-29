use std::f64;

/// CSL loss: average absolute difference between model output matrix `A`
/// and a reference scalar function `f` applied to `A`.
pub fn csl_loss<F>(a: &Vec<Vec<f64>>, f: F) -> f64
where
    F: Fn(&Vec<Vec<f64>>) -> f64,
{
    let p = a.len();
    let mut sum = 0.0f64;
    for i in 0..p {
        for j in 0..p {
            sum += (a[i][j] - f(a)).abs();
        }
    }
    sum / ((p * p) as f64)
}

#[cfg(test)]
mod tests {
    use super::*;
    #[kani::proof]
    fn test_csl_nonneg() {
        let p = 2usize;
        let a = vec![vec![1.0, 2.0], vec![3.0, 4.0]];
        // reference function returns constant 0.0
        let f = |_: &Vec<Vec<f64>>| 0.0f64;
        let loss = csl_loss(&a, f);
        assert!(loss >= 0.0);
    }
}
