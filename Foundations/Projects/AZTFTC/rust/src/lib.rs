use std::f64::consts::PI;

// Fixed-point denominator for [0,1] valuations and potentials
pub const FP_DEN: u32 = 100;

// Default parameters from numerical paper
pub const DEFAULT_N_PRIMES: usize = 200;
pub const DEFAULT_M: usize = 1200;
pub const DEFAULT_SIGMA: f64 = 0.2;
pub const DEFAULT_G: f64 = 0.05;
pub const DEFAULT_ETA: f64 = 0.01;

// Log-coordinate bounds
pub const U_MIN: f64 = -3.0;
pub const U_MAX: f64 = 7.0;

/// Trial division primality test
pub fn is_prime(n: u32) -> bool {
    if n < 2 {
        return false;
    }
    if n == 2 {
        return true;
    }
    if n % 2 == 0 {
        return false;
    }
    let limit = (n as f64).sqrt() as u32;
    (3..=limit).step_by(2).all(|d| n % d != 0)
}

/// Prime-counting function π(n)
pub fn pi(n: u32) -> usize {
    (2..=n).filter(|&p| is_prime(p)).count()
}

/// First N primes
pub fn first_n_primes(n: usize) -> Vec<u32> {
    (2..)
        .filter(|&p| is_prime(p))
        .take(n)
        .collect()
}

/// Log-Gaussian mollifier h_σ(v)
pub fn log_gaussian(sigma: f64, v: f64) -> f64 {
    let norm = 1.0 / (f64::sqrt(2.0 * PI) * sigma);
    norm * f64::exp(-(v * v) / (2.0 * sigma * sigma))
}

/// Potency field Φ_σ on a grid
pub fn phi_sigma(primes: &[u32], alpha: &[f64], sigma: f64, u_grid: &[f64]) -> Vec<f64> {
    u_grid
        .iter()
        .map(|&uj| {
            primes
                .iter()
                .zip(alpha.iter())
                .map(|(&p, &a)| {
                    let v = uj - f64::ln(p as f64);
                    a * log_gaussian(sigma, v)
                })
                .sum()
        })
        .collect()
}

/// Geometry potential V_geo = g Φ_σ + η Φ_σ R
pub fn v_geo(phi: &[f64], g: f64, eta: f64, r: &[f64]) -> Vec<f64> {
    phi.iter()
        .zip(r.iter())
        .map(|(&phi_i, &r_i)| g * phi_i + eta * phi_i * r_i)
        .collect()
}

/// Build log-coordinate grid
pub fn build_u_grid(u_min: f64, u_max: f64, m: usize) -> Vec<f64> {
    let du = (u_max - u_min) / (m - 1) as f64;
    (0..m).map(|j| u_min + j as f64 * du).collect()
}

/// Discrete inner product
pub fn inner_prod(v: &[f64], w: &[f64]) -> f64 {
    v.iter().zip(w.iter()).map(|(&a, &b)| a * b).sum()
}

/// Norm squared
pub fn norm_sq(v: &[f64]) -> f64 {
    inner_prod(v, v)
}

/// Normalize vector to unit norm
pub fn normalize(v: &[f64]) -> Vec<f64> {
    let n = f64::sqrt(norm_sq(v));
    if n == 0.0 {
        v.to_vec()
    } else {
        v.iter().map(|&x| x / n).collect()
    }
}

/// Build universal operator U = A + B + E (tridiagonal approximation)
pub fn build_u(n: usize, m: usize, primes: &[u32]) -> Vec<Vec<f64>> {
    let dim = n * m;
    let mut mat = vec![vec![0.0; dim]; dim];

    for i in 0..dim {
        let p_block = i / m;
        // Diagonal from A + E
        let w = if p_block < primes.len() {
            f64::ln(primes[p_block] as f64)
        } else {
            1.0
        };
        mat[i][i] = w + 1.0;

        // Off-diagonal from B
        if i > 0 {
            mat[i][i - 1] = 0.1;
        }
        if i < dim - 1 {
            mat[i][i + 1] = 0.1;
        }
    }

    mat
}

/// Apply operator to vector: result_i = Σ_j mat[i][j] * v[j]
pub fn apply_op(mat: &[Vec<f64>], v: &[f64]) -> Vec<f64> {
    mat.iter().map(|row| inner_prod(v, row)).collect()
}

/// Power iteration to estimate dominant eigenvalue
pub fn power_iter(mat: &[Vec<f64>], v0: &[f64], iters: usize) -> f64 {
    let mut v = normalize(v0);
    for _ in 0..iters {
        let w = apply_op(mat, &v);
        v = normalize(&w);
    }
    let w = apply_op(mat, &v);
    inner_prod(&v, &w) / inner_prod(&v, &v)
}

/// Standard 1D Casimir force proxy
pub fn casimir_std(l_nm: f64) -> f64 {
    let l = l_nm * 1e-9;
    -(PI * PI) / (24.0 * l * l)
}

/// Zero-point energy
pub fn zpe(omegas: &[f64], hbar: f64) -> f64 {
    0.5 * hbar * omegas.iter().sum::<f64>()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_prime() {
        assert!(is_prime(2));
        assert!(is_prime(3));
        assert!(!is_prime(4));
        assert!(is_prime(5));
        assert!(!is_prime(9));
    }

    #[test]
    fn test_pi() {
        assert_eq!(pi(10), 4);
        assert_eq!(pi(20), 8);
    }

    #[test]
    fn test_first_n_primes() {
        let primes = first_n_primes(5);
        assert_eq!(primes, vec![2, 3, 5, 7, 11]);
    }

    #[test]
    fn test_normalize() {
        let v = vec![3.0, 4.0];
        let n = normalize(&v);
        assert!((norm_sq(&n) - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_power_iter() {
        let mat = vec![vec![2.0, 0.0], vec![0.0, 3.0]];
        let v0 = vec![1.0, 1.0];
        let rho = power_iter(&mat, &v0, 100);
        assert!((rho - 3.0).abs() < 1e-6);
    }
}
