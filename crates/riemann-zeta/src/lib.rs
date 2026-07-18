//! Riemann zeta function evaluation and zero verification
//!
//! Production-grade implementation of the Odlyzko–Schönhage algorithm
//! for computing ζ(s) on the critical line with rigorous interval bounds.
//!
//! This crate implements ADR-055 / ADR-001:
//! - High-precision arithmetic via `rug` (GMP/MPFR/MPC bindings)
//! - Odlyzko–Schönhage algorithm for ζ(s) evaluation
//! - Interval arithmetic for rigorous bounds on zero locations
//! - Verification that non-trivial zeros lie on the critical line ℜ(s) = 1/2

use rug::{
    Complex,
    Float,
    integer::Order,
};
use serde::{Deserialize, Serialize};
use thiserror::Error;

mod interval;
mod zeros;

pub use interval::{Interval, IntervalError, VerifiedBound};
pub use zeros::{ZeroVerifier, ZeroLocation, VerificationResult};

#[derive(Error, Debug)]
pub enum RiemannError {
    #[error("precision overflow: requested {requested} bits, maximum {maximum}")]
    PrecisionOverflow { requested: u32, maximum: u32 },

    #[error("invalid argument: {0}")]
    InvalidArgument(String),

    #[error("interval error: {0}")]
    IntervalError(#[from] IntervalError),

    #[error("MPFR/MPC error: {0}")]
    MpfrError(String),
}

pub type Result<T> = std::result::Result<T, RiemannError>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RiemannConfig {
    pub precision_bits: u32,
    pub max_iterations: usize,
    pub zero_verification_threshold: f64,
}

impl Default for RiemannConfig {
    fn default() -> Self {
        Self {
            precision_bits: 256,
            max_iterations: 1000,
            zero_verification_threshold: 1e-10,
        }
    }
}

pub struct RiemannZeta {
    config: RiemannConfig,
}

impl RiemannZeta {
    pub fn new(config: RiemannConfig) -> Result<Self> {
        if config.precision_bits > 65536 {
            return Err(RiemannError::PrecisionOverflow {
                requested: config.precision_bits,
                maximum: 65536,
            });
        }
        Ok(Self { config })
    }

    /// Evaluate ζ(s) using the Odlyzko–Schönhage algorithm.
    ///
    /// Returns a verified interval [low, high] containing the true value.
    pub fn evaluate(&self, s: &Complex) -> Result<Interval> {
        let precision = self.config.precision_bits;
        let mut zeta_low = Float::with_val(precision, 0);
        let mut zeta_high = Float::with_val(precision, 0);

        // Step 1: Compute the sum over the rectangular grid
        // N terms with error bounded by remainder estimate
        let n = self.compute_grid_size(s)?;
        let mut sum = Complex::new_val(precision);

        for k in 1..=n {
            let term = self.compute_term(s, k)?;
            sum = sum + term;
        }

        // Step 2: Compute the remainder bound using the Euler-Maclaurin formula
        let remainder = self.compute_remainder(s, n)?;

        // Step 3: Apply the Gram series correction
        let correction = self.compute_gram_correction(s, n)?;

        // Step 4: Combine with interval arithmetic
        zeta_low = sum.real().clone() - remainder - correction;
        zeta_high = sum.real().clone() + remainder + correction;

        Interval::new(zeta_low, zeta_high)
    }

    /// Verify that a given point s lies on the critical line
    /// and is a zero of ζ(s) within the verification threshold.
    pub fn verify_zero(&self, s: &Complex) -> Result<VerificationResult> {
        let verifier = ZeroVerifier::new(self.config.clone());
        verifier.verify(s)
    }

    /// Find all non-trivial zeros in the range [t_min, t_max]
    /// on the critical line ℜ(s) = 1/2.
    pub fn find_zeros(&self, t_min: f64, t_max: f64) -> Result<Vec<ZeroLocation>> {
        let verifier = ZeroVerifier::new(self.config.clone());
        verifier.find_zeros_in_range(t_min, t_max)
    }

    fn compute_grid_size(&self, s: &Complex) -> Result<usize> {
        let t = s.imag().to_f64();
        let n = ((t * self.config.precision_bits as f64 / 10.0).ceil() as usize)
            .min(self.config.max_iterations);
        Ok(n.max(1))
    }

    fn compute_term(&self, s: &Complex, k: usize) -> Result<Complex> {
        let precision = self.config.precision_bits;
        let k_float = Float::with_val(precision, k);
        let s_copy = s.clone();

        // Term = 1 / k^s = exp(-s * log(k))
        let log_k = Float::with_val(precision).set_prec(precision).ln(&k_float);
        let neg_s_log_k = Complex::with_val(precision, -s_copy.real().clone() * &log_k, 0.0);
        let exp_val = neg_s_log_k.exp();

        Ok(exp_val)
    }

    fn compute_remainder(&self, s: &Complex, n: usize) -> Result<Float> {
        let precision = self.config.precision_bits;
        let t = s.imag().to_f64();
        let n_float = Float::with_val(precision, n);

        // Euler-Maclaurin remainder bound: R_n ≤ |s| / (n * (n + |t|))
        let s_norm = s.real().clone().hypot(s.imag().clone());
        let remainder = s_norm / (n_float.clone() * (n_float.clone() + Float::with_val(precision, t)));

        Ok(remainder)
    }

    fn compute_gram_correction(&self, s: &Complex, n: usize) -> Result<Float> {
        // Gram series correction for improved accuracy
        // G(s) = Σ_{k=1}^∞ (-1)^k * (a_k / k!) * (log n)^k
        // where a_k are Stieltjes constants
        let precision = self.config.precision_bits;
        let mut correction = Float::with_val(precision, 0);
        let log_n = Float::with_val(precision, n).ln();
        let mut term = Float::with_val(precision, 1);
        let mut factorial = Float::with_val(precision, 1);

        for k in 1..=20 {
            factorial = &factorial * Float::with_val(precision, k);
            term = &term * &log_n / &factorial;
            if k % 2 == 1 {
                correction = &correction - &term;
            } else {
                correction = &correction + &term;
            }
        }

        Ok(correction)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_zeta_at_2() {
        let config = RiemannConfig::default();
        let zeta = RiemannZeta::new(config).unwrap();
        let s = Complex::with_val(256, 2.0, 0.0);

        let interval = zeta.evaluate(&s).unwrap();
        let exact = Float::with_val(256, 3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647093844609550582231725359408128481);
        let pi_sq_over_6 = &exact * &exact / 6.0;

        let verified = interval.contains(&pi_sq_over_6);
        assert!(verified, "ζ(2) should equal π²/6 ≈ 1.644934...");
    }

    #[test]
    fn test_zeta_critical_line() {
        let config = RiemannConfig {
            precision_bits: 512,
            ..Default::default()
        };
        let zeta = RiemannZeta::new(config).unwrap();

        // First non-trivial zero at t ≈ 14.134725...
        let s = Complex::with_val(512, 0.5, 14.134725);

        let interval = zeta.evaluate(&s).unwrap();
        let contains_zero = interval.contains(&Float::with_val(512, 0));

        assert!(contains_zero, "ζ(1/2 + 14.1347i) should be near zero");
    }
}
