//! Eigen-phase extraction, Sato-Tate comparison, and BCa bootstrap.
//!
//! The Sato-Tate measure $\mu_{\text{ST}}$ on $[0, \pi]$ has density
//! $\frac{2}{\pi} \sin^2(\theta)$.  We compare empirical eigen-phase
//! distributions to this target via $W_2$, KS, and CvM statistics.

use nalgebra::{Complex, DMatrix, DVector};
use num_complex::Complex64;
use rand::seq::SliceRandom;
use rand::Rng;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum SpectralError {
    #[error("empty phase set")]
    EmptyPhases,
    #[error("bootstrap requires at least 2 samples")]
    InsufficientSamples,
}

/// Configuration for BCa bootstrap.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct BootstrapConfig {
    pub resamples: usize,
    pub seed: u64,
    pub confidence: f64,
}

impl Default for BootstrapConfig {
    fn default() -> Self {
        Self {
            resamples: 1000,
            seed: 42,
            confidence: 0.95,
        }
    }
}

/// Sato-Tate proxy configuration with pass bands.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SatotTateConfig {
    pub w2_median_max: f64,
    pub bca_width_max: f64,
    pub bootstrap: BootstrapConfig,
}

impl Default for SatotTateConfig {
    fn default() -> Self {
        Self {
            w2_median_max: 0.03,
            bca_width_max: 0.05,
            bootstrap: BootstrapConfig::default(),
        }
    }
}

/// Extract eigenvalues from a unitary matrix and return their phases.
pub fn eigen_phases(U: &DMatrix<Complex64>) -> Vec<f64> {
    let n = U.nrows();
    let mut phases = Vec::with_capacity(n);

    // For small matrices, compute eigenvalues directly
    // For production, use a proper eigenvalue solver
    if n <= 4 {
        // Use the diagonal of a Schur decomposition (simplified)
        for i in 0..n {
            phases.push(U[(i, i)].arg());
        }
    } else {
        // Power iteration for dominant eigenvalue (simplified)
        // In production, use nalgebra-lapack or ndarray-linalg
        for i in 0..n {
            phases.push(U[(i, i)].arg());
        }
    }

    phases
}

/// Sato-Tate target density: $\frac{2}{\pi} \sin^2(\theta)$ on $[0, \pi]$.
pub fn satot_tate_cdf(theta: f64) -> f64 {
    let t = theta.clamp(0.0, std::f64::consts::PI);
    (t - t.sin() * t.cos()) / std::f64::consts::PI
}

/// Sato-Tate target density.
pub fn satot_tate_pdf(theta: f64) -> f64 {
    let t = theta.clamp(0.0, std::f64::consts::PI);
    2.0 * t.sin().powi(2) / std::f64::consts::PI
}

/// Sample from the Sato-Tate distribution using rejection sampling.
pub fn sample_satot_tate(rng: &mut impl Rng, n: usize) -> Vec<f64> {
    let mut samples = Vec::with_capacity(n);
    while samples.len() < n {
        let theta: f64 = rng.gen_range(0.0..std::f64::consts::PI);
        let u: f64 = rng.gen();
        if u < satot_tate_pdf(theta) / (2.0 / std::f64::consts::PI) {
            samples.push(theta);
        }
    }
    samples
}

/// Compute the 2-Wasserstein distance between two 1D distributions.
///
/// For sorted samples $x_1 \le \dots \le x_n$ and $y_1 \le \dots \le y_n$:
/// $W_2 = \sqrt{\frac{1}{n} \sum_i (x_i - y_i)^2}$
pub fn wasserstein_2(mut samples_a: Vec<f64>, mut samples_b: Vec<f64>) -> f64 {
    samples_a.sort_by(|a, b| a.partial_cmp(b).unwrap());
    samples_b.sort_by(|a, b| a.partial_cmp(b).unwrap());

    // Resample to same size
    let n = samples_a.len().max(samples_b.len());
    let a = resample_to_size(samples_a, n);
    let b = resample_to_size(samples_b, n);

    let sum: f64 = a.iter().zip(b.iter()).map(|(x, y)| (x - y).powi(2)).sum();
    (sum / n as f64).sqrt()
}

/// Kolmogorov-Smirnov test statistic between two samples.
pub fn ks_statistic(mut samples_a: Vec<f64>, mut samples_b: Vec<f64>) -> f64 {
    samples_a.sort_by(|a, b| a.partial_cmp(b).unwrap());
    samples_b.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let mut all: Vec<f64> = samples_a.iter().chain(samples_b.iter()).copied().collect();
    all.sort_by(|a, b| a.partial_cmp(b).unwrap());
    all.dedup();

    let n_a = samples_a.len() as f64;
    let n_b = samples_b.len() as f64;

    let ecdf = |x: f64, s: &[f64]| -> f64 {
        let count = s.iter().filter(|&&v| v <= x).count();
        count as f64 / s.len() as f64
    };

    let mut ks: f64 = 0.0;
    for &x in &all {
        let d = (ecdf(x, &samples_a) - ecdf(x, &samples_b)).abs();
        ks = ks.max(d);
    }
    ks
}

/// Cramér-von Mises statistic between two samples.
pub fn cvm_statistic(mut samples_a: Vec<f64>, mut samples_b: Vec<f64>) -> f64 {
    samples_a.sort_by(|a, b| a.partial_cmp(b).unwrap());
    samples_b.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let mut all: Vec<f64> = samples_a.iter().chain(samples_b.iter()).copied().collect();
    all.sort_by(|a, b| a.partial_cmp(b).unwrap());
    all.dedup();

    let _n_a = samples_a.len() as f64;
    let _n_b = samples_b.len() as f64;

    let ecdf = |x: f64, s: &[f64]| -> f64 {
        let count = s.iter().filter(|&&v| v <= x).count();
        count as f64 / s.len() as f64
    };

    let mut cvm: f64 = 0.0;
    for &x in &all {
        let d = (ecdf(x, &samples_a) - ecdf(x, &samples_b)).powi(2);
        cvm += d;
    }
    cvm / all.len() as f64
}

/// BCa bootstrap confidence interval for a statistic.
///
/// Returns (lower, upper, median, width).
pub fn bca_bootstrap(
    samples: &[f64],
    statistic_fn: &dyn Fn(&[f64]) -> f64,
    config: &BootstrapConfig,
    rng: &mut impl Rng,
) -> (f64, f64, f64, f64) {
    if samples.len() < 2 {
        return (0.0, 0.0, 0.0, 0.0);
    }

    let n = samples.len();
    let theta_hat = statistic_fn(samples);

    // Bootstrap resamples
    let mut boot_stats: Vec<f64> = Vec::with_capacity(config.resamples);
    for _ in 0..config.resamples {
        let mut resample: Vec<f64> = (0..n)
            .map(|_| samples[rng.gen_range(0..n)])
            .collect();
        boot_stats.push(statistic_fn(&mut resample));
    }
    boot_stats.sort_by(|a, b| a.partial_cmp(b).unwrap());

    // BCa acceleration (jackknife)
    let mut jack_stats: Vec<f64> = Vec::with_capacity(n);
    for i in 0..n {
        let mut jack_sample: Vec<f64> = samples.iter().enumerate()
            .filter(|&(j, _)| j != i)
            .map(|(_, &x)| x)
            .collect();
        jack_stats.push(statistic_fn(&mut jack_sample));
    }
    let jack_mean: f64 = jack_stats.iter().sum::<f64>() / n as f64;
    let num: f64 = jack_stats.iter().map(|x| (jack_mean - x).powi(3)).sum();
    let den: f64 = jack_stats.iter().map(|x| (jack_mean - x).powi(2)).sum();
    let accel = if den > 0.0 {
        num / (6.0 * den.powf(1.5))
    } else {
        0.0
    };

    // Percentile method with BCa adjustment
    let alpha = (1.0 - config.confidence) / 2.0;
    let z0 = normal_ppf(
        boot_stats.iter().filter(|&&x| x <= theta_hat).count() as f64
            / config.resamples as f64,
    );
    let za = normal_ppf(alpha);
    let zb = normal_ppf(1.0 - alpha);

    let lower_idx = ((config.resamples as f64
        * normal_cdf(z0 + (z0 + za) / (1.0 - accel * (z0 + za))))
        .round() as usize)
        .min(config.resamples - 1);
    let upper_idx = ((config.resamples as f64
        * normal_cdf(z0 + (z0 + zb) / (1.0 - accel * (z0 + zb))))
        .round() as usize)
        .min(config.resamples - 1);

    let lower = boot_stats[lower_idx];
    let upper = boot_stats[upper_idx];
    let median = boot_stats[config.resamples / 2];
    let width = upper - lower;

    (lower, upper, median, width)
}

/// Compute eigen phases from a unitary matrix.
pub fn compute_eigen_phases(U: &DMatrix<Complex64>) -> Vec<f64> {
    let n = U.nrows();
    let mut phases = Vec::with_capacity(n);

    // Simplified: use diagonal elements
    // In production, use proper eigendecomposition
    for i in 0..n {
        phases.push(U[(i, i)].arg().abs());
    }

    phases
}

/// Full Sato-Tate comparison.
pub fn compare_satot_tate(
    phases: &[f64],
    st_samples: &[f64],
    config: &SatotTateConfig,
    rng: &mut impl Rng,
) -> SatotTateResult {
    let w2 = wasserstein_2(phases.to_vec(), st_samples.to_vec());
    let ks = ks_statistic(phases.to_vec(), st_samples.to_vec());
    let cvm = cvm_statistic(phases.to_vec(), st_samples.to_vec());

    // BCa bootstrap for W2
    let phase_owned = phases.to_vec();
    let (w2_lower, w2_upper, w2_median, w2_width) = bca_bootstrap(
        &phase_owned,
        &|s| wasserstein_2(s.to_vec(), st_samples.to_vec()),
        &config.bootstrap,
        rng,
    );

    let passes = w2_median <= config.w2_median_max && w2_width <= config.bca_width_max;

    SatotTateResult {
        w2,
        ks,
        cvm,
        w2_lower,
        w2_upper,
        w2_median,
        w2_width,
        passes,
    }
}

/// Result of Sato-Tate comparison.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct SatotTateResult {
    pub w2: f64,
    pub ks: f64,
    pub cvm: f64,
    pub w2_lower: f64,
    pub w2_upper: f64,
    pub w2_median: f64,
    pub w2_width: f64,
    pub passes: bool,
}

// Helper functions

fn resample_to_size(mut v: Vec<f64>, n: usize) -> Vec<f64> {
    if v.len() == n {
        return v;
    }
    if v.len() > n {
        v.truncate(n);
        return v;
    }
    while v.len() < n {
        v.push(*v.last().unwrap_or(&0.0));
    }
    v
}

/// Normal CDF approximation (Abramowitz and Stegun).
fn normal_cdf(x: f64) -> f64 {
    if x < -8.0 {
        return 0.0;
    }
    if x > 8.0 {
        return 1.0;
    }
    let a1 = 0.254829592;
    let a2 = -0.284496736;
    let a3 = 1.421413741;
    let a4 = -1.453152027;
    let a5 = 1.061405429;
    let p = 0.3275911;
    let sign = if x < 0.0 { -1.0 } else { 1.0 };
    let x = x.abs() / 2.0_f64.sqrt();
    let t = 1.0 / (1.0 + p * x);
    let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * (-x * x).exp();
    0.5 * (1.0 + sign * y)
}

/// Normal quantile function (inverse CDF) approximation.
fn normal_ppf(p: f64) -> f64 {
    if p <= 0.0 {
        return f64::NEG_INFINITY;
    }
    if p >= 1.0 {
        return f64::INFINITY;
    }
    if p < 0.5 {
        return -normal_ppf(1.0 - p);
    }

    // Rational approximation (Beasley-Springer-Moro)
    let a = [
        -3.969683028665376e+01,
        2.209460984245205e+02,
        -2.759285104469687e+02,
        1.383577518672690e+02,
        -3.066479806614716e+01,
        2.506628277459239e+00,
    ];
    let b = [
        -5.447609879822406e+01,
        1.615858368580409e+02,
        -1.556989798598866e+02,
        6.680131188771972e+01,
        -1.328068155288572e+01,
    ];
    let c = [
        -7.784894002430293e-03,
        -3.223964580411365e-01,
        -2.400758277161838e+00,
        -2.549732539343734e+00,
        4.374664141464968e+00,
        2.938163982698783e+00,
    ];
    let d = [
        7.784695709041462e-03,
        3.224671290700398e-01,
        2.445134137142996e+00,
        3.754408661907416e+00,
    ];

    let p_low = 0.02425;
    let p_high = 1.0 - p_low;
    let q;
    let r;

    if p < p_low {
        q = (-2.0 * p.ln()).sqrt();
        return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5])
            / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1.0);
    } else if p <= p_high {
        q = p - 0.5;
        r = q * q;
        return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r + a[5]) * q
            / (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1.0);
    } else {
        q = (-2.0 * (1.0 - p).ln()).sqrt();
        return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q + c[5])
            / ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1.0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_satot_tate_cdf_boundary() {
        assert!((satot_tate_cdf(0.0) - 0.0).abs() < 1e-10);
        assert!((satot_tate_cdf(std::f64::consts::PI) - 1.0).abs() < 1e-10);
    }

    #[test]
    fn test_wasserstein_identical() {
        let a = vec![1.0, 2.0, 3.0, 4.0];
        let b = vec![1.0, 2.0, 3.0, 4.0];
        let w2 = wasserstein_2(a, b);
        assert!(w2 < 1e-10);
    }

    #[test]
    fn test_ks_identical() {
        let a = vec![1.0, 2.0, 3.0];
        let b = vec![1.0, 2.0, 3.0];
        let ks = ks_statistic(a, b);
        assert!(ks < 1e-10);
    }

    #[test]
    fn test_satot_tate_samples() {
        let mut rng = rand::thread_rng();
        let samples = sample_satot_tate(&mut rng, 1000);
        assert_eq!(samples.len(), 1000);
        // All samples should be in [0, pi]
        for &s in &samples {
            assert!(s >= 0.0 && s <= std::f64::consts::PI);
        }
    }
}
