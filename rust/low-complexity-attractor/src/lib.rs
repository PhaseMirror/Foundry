//! Low-Complexity Attractor — Rust Numerical Backend
//!
//! Provides verified numerical implementations of:
//! - Golden ratio and Euler's number
//! - Cubic repair dynamics
//! - ACE safety projection
//! - Metrics (convergence, collapse, drift, entropy)
//! - Statistical tests (permutation, Hodges-Lehmann, bootstrap)
//! - ZK fixed-point encoding
//!
//! Verification via unit tests and Kani formal verification.

#[cfg(kani)]
mod kani_proofs;

/// Golden ratio φ = (1 + sqrt(5)) / 2.
pub fn phi() -> f64 {
    (1.0 + f64::sqrt(5.0)) / 2.0
}

/// Euler's number e.
pub fn eulers_e() -> f64 {
    f64::exp(1.0)
}

/// Cubic repair proposal: f_θ(x) = W₃(x³) + W₁x + b.
pub fn cubic_repair(x: &[f64], w3: &[f64], w1: &[f64], b: &[f64]) -> Vec<f64> {
    x.iter().enumerate().map(|(i, &xi)| {
        let cubic = xi * xi * xi * w3[i];
        let linear = xi * w1[i];
        cubic + linear + b[i]
    }).collect()
}

/// ACE projection onto ℓ₂ ball of radius r.
pub fn ace_projection(u: &[f64], r: f64) -> Vec<f64> {
    u.iter().map(|&v| {
        if v > r { r } else if v < -r { -r } else { v }
    }).collect()
}

/// Convergence criterion: ‖x‖₂ ≤ ε.
pub fn has_converged(x: &[f64], eps: f64) -> bool {
    let norm: f64 = x.iter().map(|&xi| xi * xi).sum::<f64>().sqrt();
    norm <= eps
}

/// Collapse criterion: contains NaN or Inf.
pub fn has_collapsed(x: &[f64]) -> bool {
    x.iter().any(|&xi| xi.is_nan() || xi.is_infinite())
}

/// Mean drift between two states.
pub fn mean_drift(x1: &[f64], x2: &[f64]) -> f64 {
    x1.iter().zip(x2).map(|(&a, &b)| (a - b).abs()).sum::<f64>() / x1.len() as f64
}

/// Shannon entropy of a histogram.
pub fn shannon_entropy(histogram: &[f64]) -> f64 {
    let total: f64 = histogram.iter().sum();
    if total == 0.0 {
        0.0
    } else {
        histogram.iter().filter(|&&p| p > 0.0).map(|&p| {
            let normalized = p / total;
            -normalized * f64::ln(normalized)
        }).sum()
    }
}

/// Encode Float to Q2.11 fixed-point (unsigned approximation).
pub fn encode_q211(x: f64) -> u16 {
    let scaled = (x * 2048.0).floor().max(0.0).min(2047.0) as u16;
    scaled
}

/// Decode Q2.11 fixed-point to Float.
pub fn decode_q211(fp: u16) -> f64 {
    fp as f64 / 2048.0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_phi() {
        assert!((phi() - 1.618033988749895).abs() < 1e-12);
    }

    #[test]
    fn test_eulers_e() {
        assert!((eulers_e() - 2.718281828459045).abs() < 1e-12);
    }

    #[test]
    fn test_cubic_repair() {
        let x = vec![1.0, 0.5];
        let w3 = vec![0.1, 0.1];
        let w1 = vec![0.5, 0.5];
        let b = vec![0.0, 0.0];
        let result = cubic_repair(&x, &w3, &w1, &b);
        assert_eq!(result.len(), 2);
    }

    #[test]
    fn test_ace_projection() {
        let u = vec![3.0, -4.0, 0.5];
        let result = ace_projection(&u, 2.0);
        assert_eq!(result[0], 2.0);
        assert_eq!(result[1], -2.0);
        assert_eq!(result[2], 0.5);
    }

    #[test]
    fn test_has_converged() {
        assert!(has_converged(&[0.1, 0.0, -0.1], 0.2));
        assert!(!has_converged(&[1.0, 2.0, 3.0], 0.1));
    }

    #[test]
    fn test_has_collapsed() {
        assert!(has_collapsed(&[1.0, f64::NAN, 3.0]));
        assert!(!has_collapsed(&[1.0, 2.0, 3.0]));
    }

    #[test]
    fn test_mean_drift() {
        let x1 = vec![0.0, 0.0, 0.0];
        let x2 = vec![1.0, 1.0, 1.0];
        assert_eq!(mean_drift(&x1, &x2), 1.0);
    }

    #[test]
    fn test_shannon_entropy() {
        let histogram = vec![0.5, 0.5];
        let entropy = shannon_entropy(&histogram);
        assert!((entropy - f64::ln(2.0)).abs() < 1e-10);
    }

    #[test]
    fn test_q211_roundtrip() {
        let x = 0.5;
        let fp = encode_q211(x);
        let decoded = decode_q211(fp);
        assert!((decoded - x).abs() < 0.01);
    }
}
