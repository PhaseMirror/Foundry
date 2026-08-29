use std::f64::consts::PI;

// Default parameters
pub const U_MIN: f64 = -3.0;
pub const U_MAX: f64 = 7.0;

/// Alpha master function (discrete approximation)
pub fn alpha_master(x: f64, theta0: f64, c_k: &[f64], rho_k: &[f64]) -> f64 {
    let series_term: f64 = c_k.iter().zip(rho_k.iter())
        .map(|(&c, &rho)| c * x.powf(rho))
        .sum();
    series_term
}

/// Discrete series term: Σ c_k x^{ρ_k}
pub fn discrete_series(c_k: &[f64], rho_k: &[f64], x: f64) -> f64 {
    c_k.iter().zip(rho_k.iter())
        .map(|(&c, &rho)| c * x.powf(rho))
        .sum()
}

/// Riemann zeta (real slice): Σ_{n≥1} n^{-s}
pub fn zeta_slice(s: f64, n: usize) -> f64 {
    if s > 1.0 {
        (1..=n).map(|i| 1.0 / (i as f64).powf(s)).sum()
    } else {
        0.0
    }
}

/// Soft-thresholding projection
pub fn soft_threshold(w_tilde: &[f64], b: &[f64], t: f64) -> Vec<f64> {
    let lambda = 0.1;
    let b0 = b.first().copied().unwrap_or(1.0);
    w_tilde.iter().map(|&w| {
        let threshold = lambda * b0;
        if w.abs() > threshold {
            (w.abs() - threshold) * w.signum()
        } else {
            0.0
        }
    }).collect()
}

/// Kernel G1: baseline G(t) = 1
pub fn kernel_g1(_t: f64, _theta: f64) -> f64 {
    1.0
}

/// Kernel G2: exp-shift G(t) = e^{a t}
pub fn kernel_g2(a: f64, t: f64, _theta: f64) -> f64 {
    (a * t).exp()
}

/// Kernel G3: polynomial G(t) = (1 + c t)^m
pub fn kernel_g3(c: f64, m: f64, t: f64, _theta: f64) -> f64 {
    (1.0 + c * t).powf(m)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_discrete_series() {
        let c_k = vec![1.0, 2.0];
        let rho_k = vec![2.0, 3.0];
        let result = discrete_series(&c_k, &rho_k, 2.0);
        assert!((result - 20.0).abs() < 1e-10);
    }

    #[test]
    fn test_zeta_slice() {
        let result = zeta_slice(2.0, 1000);
        assert!(result > 0.0);
    }

    #[test]
    fn test_soft_threshold() {
        let w = vec![1.0, -2.0, 3.0];
        let b = vec![1.0];
        let result = soft_threshold(&w, &b, 1.0);
        assert_eq!(result.len(), 3);
    }

    #[test]
    fn test_kernels_at_zero() {
        assert_eq!(kernel_g1(0.0, 0.0), 1.0);
        assert_eq!(kernel_g2(0.5, 0.0, 0.0), 1.0);
        assert_eq!(kernel_g3(0.1, 2.0, 0.0, 0.0), 1.0);
    }
}
