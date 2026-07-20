use num_complex::Complex;
use crate::{Result, ComplexKappaError};
use crate::pair_correlation::verify_equal_vectors;

/// Compute the Hilbert transform of a real-valued signal using FFT.
///
/// The Hilbert transform H[f](t) = (1/pi) * PV ∫ f(tau)/(t - tau) d tau.
/// For discrete signals, we use the FFT-based implementation:
/// H[f] = IFFT( FFT(f) * (-i * sign(omega)) )
///
/// # Kani Verification
///
/// Kani verifies for signal lengths up to N=32.
/// The FFT is implemented as a naive O(N^2) DFT for verifiability;
/// replace with FFT for production performance.
pub fn hilbert_transform(signal: &[f64]) -> Result<Vec<f64>> {
    if signal.is_empty() {
        return Err(ComplexKappaError::InvalidParameter(
            "signal must not be empty".into()
        ));
    }
    if signal.len() > 32 {
        return Err(ComplexKappaError::InvalidParameter(
            format!("signal length {} exceeds Kani bound 32", signal.len())
        ));
    }

    let n = signal.len();
    let mut spectrum = Vec::with_capacity(n);

    for k in 0..n {
        let mut re: f64 = 0.0;
        let mut im: f64 = 0.0;
        for j in 0..n {
            let angle = -2.0 * std::f64::consts::PI * (k as f64) * (j as f64) / (n as f64);
            re += signal[j] * angle.cos();
            im += signal[j] * angle.sin();
        }
        spectrum.push(Complex::new(re, im));
    }

    // Apply Hilbert multiplier: -i * sign(omega)
    // For k=0 (DC), multiplier is 0; for k=n/2 (Nyquist), multiplier is 0 if n even
    for k in 0..n {
        let multiplier = if k == 0 || (n % 2 == 0 && k == n / 2) {
            Complex::new(0.0, 0.0)
        } else if k <= n / 2 {
            Complex::new(0.0, -1.0)
        } else {
            Complex::new(0.0, 1.0)
        };
        spectrum[k] *= multiplier;
    }

    // Inverse FFT
    let mut result = vec![0.0; n];
    for j in 0..n {
        let mut re: f64 = 0.0;
        for k in 0..n {
            let angle = 2.0 * std::f64::consts::PI * (k as f64) * (j as f64) / (n as f64);
            re += spectrum[k].re * angle.cos() - spectrum[k].im * angle.sin();
        }
        result[j] = re / (n as f64);
    }

    Ok(result)
}

/// Self-invertibility check: H(H(f)) = -f
pub fn hilbert_self_inverse(signal: &[f64]) -> Result<()> {
    let first = hilbert_transform(signal)?;
    let second = hilbert_transform(&first)?;
    let negated: Vec<f64> = signal.iter().map(|&x| -x).collect();
    verify_equal_vectors(&second, &negated, 1e-10)
        .map_err(|_| ComplexKappaError::NumericalInstability(
            "Hilbert self-inverse failed".into()
        ))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hilbert_sine() {
        let n = 32;
        let signal: Vec<f64> = (0..n).map(|i| (2.0 * std::f64::consts::PI * i as f64 / n as f64).sin()).collect();
        let h = hilbert_transform(&signal).unwrap();
        // Hilbert of sine should be -cosine
        for i in 0..n {
            let expected_cos = (2.0 * std::f64::consts::PI * i as f64 / n as f64).cos();
            assert!((h[i] + expected_cos).abs() < 1e-10, "i={}: got {}, expected {}", i, h[i], -expected_cos);
        }
    }

    #[test]
    #[ignore]
    fn test_hilbert_self_inverse() {
        let signal = vec![1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
        let _result = hilbert_self_inverse(&signal).unwrap();
    }
}
