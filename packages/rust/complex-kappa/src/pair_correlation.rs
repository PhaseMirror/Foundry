use crate::{Result, ComplexKappaError};

/// Verify two vectors are element-wise equal within tolerance.
pub fn verify_equal_vectors(
    a: &[f64],
    b: &[f64],
    tol: f64,
) -> Result<()> {
    if a.len() != b.len() {
        return Err(ComplexKappaError::InvalidParameter(
            format!("vector lengths differ: {} vs {}", a.len(), b.len())
        ));
    }
    for (i, (x, y)) in a.iter().zip(b.iter()).enumerate() {
        if (x - y).abs() > tol {
            return Err(ComplexKappaError::NumericalInstability(
                format!("mismatch at index {}: {} vs {}", i, x, y)
            ));
        }
    }
    Ok(())
}

/// Compute the empirical pair correlation from a list of beat frequencies.
///
/// Given beat frequencies f_1, f_2, ..., f_M (where M = N*(N-1)/2 for N zeros),
/// the empirical pair correlation is:
///   R_2^(emp)(u) = (1/(M * delta)) * Σ_i indicator(|f_i - u| < delta)
///
/// This is compared against the GUE prediction:
///   R_2(u) = 1 - (sin(pi*u) / (pi*u))^2
pub fn empirical_pair_correlation(
    beat_freqs: &[f64],
    u: f64,
    delta: f64,
) -> f64 {
    if beat_freqs.is_empty() {
        return 0.0;
    }
    let count = beat_freqs.iter().filter(|&&f| (f - u).abs() < delta).count();
    count as f64 / (beat_freqs.len() as f64 * delta)
}

/// GUE pair correlation function: R_2(u) = 1 - (sin(pi*u) / (pi*u))^2
pub fn gue_pair_correlation(u: f64) -> f64 {
    if u.abs() < 1e-10 {
        return 0.0; // limit u→0 gives 0
    }
    1.0 - (num_complex::Complex::new(std::f64::consts::PI * u, 0.0).sin().norm_sqr()
        / (std::f64::consts::PI.powi(2) * u.powi(2)))
}

/// Compute all pairwise beat frequencies from a list of gamma values.
pub fn compute_beat_frequencies(gammas: &[f64]) -> Vec<f64> {
    let mut beats = Vec::new();
    for i in 0..gammas.len() {
        for j in (i + 1)..gammas.len() {
            beats.push((gammas[i] - gammas[j]).abs());
        }
    }
    beats
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_gue_pair_correlation_limit() {
        // As u -> 0, R_2(u) -> 0
        assert!(gue_pair_correlation(1e-6).abs() < 1e-6);
    }

    #[test]
    fn test_gue_pair_correlation_unity() {
        // R_2(0) = 0
        assert!((gue_pair_correlation(0.0) - 0.0).abs() < 1e-10);
    }

    #[test]
    fn test_empirical_pair_correlation() {
        let beats = vec![0.5, 1.0, 1.5, 2.0];
        let r2 = empirical_pair_correlation(&beats, 1.0, 0.5);
        assert!(r2.is_finite());
    }

    #[test]
    fn test_compute_beat_frequencies() {
        let gammas = vec![14.13, 21.02, 25.01];
        let beats = compute_beat_frequencies(&gammas);
        assert_eq!(beats.len(), 3); // C(3,2) = 3
    }
}
