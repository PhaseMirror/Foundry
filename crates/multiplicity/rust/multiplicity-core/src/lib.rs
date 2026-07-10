use ndarray::{Array1, Array2, Axis};
use std::f64::consts::PI;
use num_complex::Complex64;

pub mod xi_system;

pub struct MocOperators;

impl MocOperators {
    /// Zero-order hold subdivision: repeat each sample mod^r times.
    pub fn subdivision(x: &Array1<f64>, mod_factor: usize, r: u32) -> Array1<f64> {
        let factor = mod_factor.pow(r);
        let n = x.len();
        let mut y = Array1::zeros(n * factor);
        for i in 0..n {
            for j in 0..factor {
                y[i * factor + j] = x[i];
            }
        }
        y
    }

    /// Additive accent at t ≡ 0 mod d on channel ch.
    pub fn accent(x: &Array1<f64>, d: usize, alpha: f64) -> Array1<f64> {
        let mut y = x.clone();
        for i in (0..y.len()).step_by(d) {
            y[i] += alpha;
        }
        y
    }

    /// Within-cell permutation of size mod.
    pub fn permutation(x: &Array1<f64>, mod_factor: usize, perm: &[usize]) -> Result<Array1<f64>, String> {
        let n = x.len();
        if n % mod_factor != 0 {
            return Err("Length not multiple of modulus".to_string());
        }
        let mut y = x.clone();
        for c in (0..n).step_by(mod_factor) {
            for (i, &p) in perm.iter().enumerate() {
                y[c + i] = x[c + p];
            }
        }
        Ok(y)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use ndarray::array;

    #[test]
    fn test_subdivision() {
        let x = array![1.0, 2.0];
        let y = MocOperators::subdivision(&x, 2, 1);
        assert_eq!(y, array![1.0, 1.0, 2.0, 2.0]);
    }

    #[test]
    fn test_accent() {
        let x = array![0.0, 0.0, 0.0, 0.0];
        let y = MocOperators::accent(&x, 2, 1.0);
        assert_eq!(y, array![1.0, 0.0, 1.0, 0.0]);
    }

    #[test]
    fn test_permutation() {
        let x = array![1.0, 2.0, 3.0, 4.0];
        let perm = vec![1, 0];
        let y = MocOperators::permutation(&x, 2, &perm).unwrap();
        assert_eq!(y, array![2.0, 1.0, 4.0, 3.0]);
    }
}
