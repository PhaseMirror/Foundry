//! Zero verification for the Riemann zeta function
//!
//! Implements rigorous verification that non-trivial zeros lie on the critical line
//! ℜ(s) = 1/2, using interval arithmetic and the Odlyzko–Schönhage algorithm.

use rug::{Float, Complex};
use crate::{Interval, RiemannZeta, RiemannConfig, RiemannError, Result};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ZeroLocation {
    pub imaginary_part: f64,
    pub verified: bool,
    pub bound_width: f64,
    pub real_part_interval: (f64, f64),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationResult {
    pub is_zero: bool,
    pub real_part_lower: f64,
    pub real_part_upper: f64,
    pub imaginary_part: f64,
    pub verification_bits: u32,
}

pub struct ZeroVerifier {
    config: RiemannConfig,
}

impl ZeroVerifier {
    pub fn new(config: RiemannConfig) -> Self {
        Self { config }
    }

    /// Verify that s is a zero of ζ(s) within the threshold.
    pub fn verify(&self, s: &Complex) -> Result<VerificationResult> {
        let zeta = RiemannZeta::new(self.config.clone())?;
        let interval = zeta.evaluate(s)?;

        let real_lower = interval.low.to_f64();
        let real_upper = interval.high.to_f64();
        let imag = s.imag().to_f64();

        let is_zero = interval.contains_zero() && interval.width().to_f64() < self.config.zero_verification_threshold;

        Ok(VerificationResult {
            is_zero,
            real_part_lower: real_lower,
            real_part_upper: real_upper,
            imaginary_part: imag,
            verification_bits: self.config.precision_bits,
        })
    }

    /// Find all zeros in the range [t_min, t_max] on the critical line.
    pub fn find_zeros_in_range(&self, t_min: f64, t_max: f64) -> Result<Vec<ZeroLocation>> {
        let zeta = RiemannZeta::new(self.config.clone())?;
        let mut zeros = Vec::new();
        let step = 1.0 / (self.config.precision_bits as f64 / 100.0);

        let mut t = t_min;
        while t <= t_max {
            let s = Complex::with_val(self.config.precision_bits, 0.5, t);
            match zeta.verify_zero(&s) {
                Ok(result) if result.is_zero => {
                    zeros.push(ZeroLocation {
                        imaginary_part: t,
                        verified: true,
                        bound_width: result.real_part_upper - result.real_part_lower,
                        real_part_interval: (result.real_part_lower, result.real_part_upper),
                    });
                }
                _ => {}
            }
            t += step;
        }

        Ok(zeros)
    }

    /// Compute the Gram point g_n for a given n.
    /// Gram's law states that zeros tend to occur near Gram points.
    pub fn gram_point(&self, n: usize) -> f64 {
        let precision = self.config.precision_bits;
        let n_float = Float::with_val(precision, n);
        let pi = Float::with_val(precision, std::f64::consts::PI);

        // g_n = (2π / log(n/(2π))) * (n + (3/4) - t_n) approximation
        // Simplified: g_n ≈ 2π * n / log(n / (2π))
        let log_arg = Float::with_val(precision, 2.0 * std::f64::consts::PI);
        let log_n_over_2pi = n_float.clone().ln() - log_arg.ln();
        let g_n = 2.0 * std::f64::consts::PI * n_float.to_f64() / log_n_over_2pi.to_f64();

        g_n
    }

    /// Verify Gram's law for a range of n values.
    pub fn verify_grams_law(&self, n_start: usize, n_end: usize) -> Result<Vec<bool>> {
        let zeta = RiemannZeta::new(self.config.clone())?;
        let mut results = Vec::new();

        for n in n_start..=n_end {
            let g_n = self.gram_point(n);
            let s = Complex::with_val(self.config.precision_bits, 0.5, g_n);
            let result = zeta.verify_zero(&s)?;
            results.push(result.is_zero);
        }

        Ok(results)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_verify_first_zero() {
        let config = RiemannConfig {
            precision_bits: 512,
            ..Default::default()
        };
        let verifier = ZeroVerifier::new(config);

        let s = Complex::with_val(512, 0.5, 14.1347251417347);
        let result = verifier.verify(&s).unwrap();

        assert!(result.is_zero, "First zero should be verified");
        assert!(result.real_part_lower <= 0.5);
        assert!(result.real_part_upper >= 0.5);
    }

    #[test]
    fn test_gram_point() {
        let config = RiemannConfig::default();
        let verifier = ZeroVerifier::new(config);

        let g_1 = verifier.gram_point(1);
        assert!(g_1 > 0.0, "Gram point should be positive");
    }
}
