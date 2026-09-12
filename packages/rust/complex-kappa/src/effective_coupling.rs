use num_complex::Complex;
use crate::{ComplexKappaError, Result};

/// Compute the effective gravitational coupling:
///   κ_eff(k) = κ / (1 - κ * D_R(k) / O(k))
///
/// This is the central resummation formula from the influence functional.
/// The dissipation kernel D_R(k) and operator O(k) are complex-valued.
pub fn effective_coupling(
    kappa: Complex<f64>,
    d_r: Complex<f64>,
    o: Complex<f64>,
) -> Result<Complex<f64>> {
    if o.re == 0.0 && o.im == 0.0 {
        return Err(ComplexKappaError::InvalidParameter(
            "operator O(k) must be non-zero".into()
        ));
    }

    let denominator = Complex::new(1.0, 0.0) - kappa * d_r / o;
    if denominator.re == 0.0 && denominator.im == 0.0 {
        return Err(ComplexKappaError::NumericalInstability(
            "denominator near zero: κ_eff would diverge".into()
        ));
    }

    Ok(kappa / denominator)
}

/// Compute the Zeta-Comb noise kernel:
///   N(k) = Σ_n a_n * cos(γ_n * ln(k/k_*))
///
/// Uses the precomputed zero table from `zeta_zeros`.
pub fn noise_kernel_zeta(
    k: f64,
    k_star: f64,
    epsilon: f64,
    sigma: f64,
) -> Result<f64> {
    if k <= 0.0 || k_star <= 0.0 {
        return Err(ComplexKappaError::InvalidParameter(
            "k and k_star must be positive".into()
        ));
    }
    if epsilon <= 0.0 || sigma <= 0.0 {
        return Err(ComplexKappaError::InvalidParameter(
            "epsilon and sigma must be positive".into()
        ));
    }

    let log_ratio = (k / k_star).ln();
    let mut sum: f64 = 0.0;

    for n in 1..=32 {
        let (gamma_n, a_n) = crate::zeta_zeros::zeta_zero(n, epsilon, sigma)?;
        sum += a_n * (gamma_n * log_ratio).cos();
    }

    Ok(sum)
}

/// Compute the complex effective coupling with Zeta-Comb noise.
pub fn complex_kappa_eff(
    kappa: Complex<f64>,
    k: f64,
    k_star: f64,
    epsilon: f64,
    sigma: f64,
) -> Result<Complex<f64>> {
    let n_k = noise_kernel_zeta(k, k_star, epsilon, sigma)?;
    let d_r = Complex::new(n_k, 0.0);
    let o = Complex::new(1.0, 0.0); // Simplified: O(k) = 1 for scaffolding
    effective_coupling(kappa, d_r, o)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_effective_coupling_identity() {
        // If D_R = 0, κ_eff = κ
        let kappa = Complex::new(1.0, 0.5);
        let result = effective_coupling(kappa, Complex::new(0.0, 0.0), Complex::new(1.0, 0.0)).unwrap();
        assert!((result.re - kappa.re).abs() < 1e-10);
        assert!((result.im - kappa.im).abs() < 1e-10);
    }

    #[test]
    fn test_noise_kernel_converges() {
        let n = noise_kernel_zeta(1.0, 1.0, 1e-2, 1e-3).unwrap();
        assert!(n.is_finite());
    }

    #[test]
    fn test_complex_kappa_eff() {
        let kappa = Complex::new(1.0, 0.0);
        let result = complex_kappa_eff(kappa, 1.0, 1.0, 1e-2, 1e-3).unwrap();
        assert!(result.re.is_finite());
        assert!(result.im.is_finite());
    }
}
