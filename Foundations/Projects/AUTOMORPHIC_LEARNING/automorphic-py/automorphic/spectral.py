"""Eigen-phase extraction, Sato-Tate comparison, and BCa bootstrap."""

import numpy as np
from typing import Tuple, Callable, Optional
from dataclasses import dataclass


@dataclass
class SatotTateResult:
    """Result of Sato-Tate comparison."""
    w2: float
    ks: float
    cvm: float
    w2_lower: float
    w2_upper: float
    w2_median: float
    w2_width: float
    passes: bool


def satot_tate_cdf(theta: float) -> float:
    """Sato-Tate CDF: (theta - sin(theta)*cos(theta)) / pi."""
    t = np.clip(theta, 0.0, np.pi)
    return (t - np.sin(t) * np.cos(t)) / np.pi


def satot_tate_pdf(theta: float) -> float:
    """Sato-Tate PDF: 2*sin^2(theta) / pi."""
    t = np.clip(theta, 0.0, np.pi)
    return 2.0 * np.sin(t)**2 / np.pi


def sample_satot_tate(n: int, rng: Optional[np.random.Generator] = None) -> np.ndarray:
    """Sample from Sato-Tate distribution using rejection sampling."""
    if rng is None:
        rng = np.random.default_rng()
    
    samples = []
    while len(samples) < n:
        theta = rng.uniform(0.0, np.pi)
        u = rng.uniform()
        if u < satot_tate_pdf(theta) / (2.0 / np.pi):
            samples.append(theta)
    return np.array(samples)


def wasserstein_2(samples_a: np.ndarray, samples_b: np.ndarray) -> float:
    """Compute 2-Wasserstein distance between two 1D distributions."""
    a = np.sort(samples_a)
    b = np.sort(samples_b)
    
    # Resample to same size
    n = max(len(a), len(b))
    a = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(a)), a)
    b = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(b)), b)
    
    return float(np.sqrt(np.mean((a - b)**2)))


def ks_statistic(samples_a: np.ndarray, samples_b: np.ndarray) -> float:
    """Kolmogorov-Smirnov test statistic."""
    a = np.sort(samples_a)
    b = np.sort(samples_b)
    
    all_vals = np.sort(np.concatenate([a, b]))
    all_vals = np.unique(all_vals)
    
    def ecdf(x, s):
        return np.searchsorted(s, x, side='right') / len(s)
    
    ks = max(abs(ecdf(x, a) - ecdf(x, b)) for x in all_vals)
    return float(ks)


def cvm_statistic(samples_a: np.ndarray, samples_b: np.ndarray) -> float:
    """Cramér-von Mises statistic."""
    a = np.sort(samples_a)
    b = np.sort(samples_b)
    
    all_vals = np.sort(np.concatenate([a, b]))
    all_vals = np.unique(all_vals)
    
    def ecdf(x, s):
        return np.searchsorted(s, x, side='right') / len(s)
    
    cvm = sum((ecdf(x, a) - ecdf(x, b))**2 for x in all_vals) / len(all_vals)
    return float(cvm)


def bca_bootstrap(
    samples: np.ndarray,
    statistic_fn: Callable[[np.ndarray], float],
    resamples: int = 1000,
    confidence: float = 0.95,
    rng: Optional[np.random.Generator] = None
) -> Tuple[float, float, float, float]:
    """BCa bootstrap confidence interval.
    
    Returns (lower, upper, median, width).
    """
    if rng is None:
        rng = np.random.default_rng()
    
    n = len(samples)
    theta_hat = statistic_fn(samples)
    
    # Bootstrap resamples
    boot_stats = np.array([
        statistic_fn(rng.choice(samples, size=n, replace=True))
        for _ in range(resamples)
    ])
    boot_stats = np.sort(boot_stats)
    
    # BCa acceleration (jackknife)
    jack_stats = np.array([
        statistic_fn(np.delete(samples, i))
        for i in range(n)
    ])
    jack_mean = jack_stats.mean()
    num = np.sum((jack_mean - jack_stats)**3)
    den = np.sum((jack_mean - jack_stats)**2)
    accel = num / (6.0 * den**1.5) if den > 0 else 0.0
    
    # Percentile method with BCa adjustment
    from scipy.stats import norm
    alpha = (1.0 - confidence) / 2.0
    z0 = norm.ppf(np.mean(boot_stats <= theta_hat))
    za = norm.ppf(alpha)
    zb = norm.ppf(1.0 - alpha)
    
    lower_idx = int(np.round(resamples * norm.cdf(z0 + (z0 + za) / (1 - accel * (z0 + za)))))
    upper_idx = int(np.round(resamples * norm.cdf(z0 + (z0 + zb) / (1 - accel * (z0 + zb)))))
    
    lower_idx = np.clip(lower_idx, 0, resamples - 1)
    upper_idx = np.clip(upper_idx, 0, resamples - 1)
    
    lower = boot_stats[lower_idx]
    upper = boot_stats[upper_idx]
    median = boot_stats[resamples // 2]
    width = upper - lower
    
    return float(lower), float(upper), float(median), float(width)


def compare_satot_tate(
    phases: np.ndarray,
    st_samples: np.ndarray,
    w2_max: float = 0.03,
    bca_width_max: float = 0.05,
    bootstrap_resamples: int = 1000,
    rng: Optional[np.random.Generator] = None
) -> SatotTateResult:
    """Full Sato-Tate comparison."""
    if rng is None:
        rng = np.random.default_rng()
    
    w2 = wasserstein_2(phases, st_samples)
    ks = ks_statistic(phases, st_samples)
    cvm = cvm_statistic(phases, st_samples)
    
    w2_lower, w2_upper, w2_median, w2_width = bca_bootstrap(
        phases,
        lambda s: wasserstein_2(s, st_samples),
        resamples=bootstrap_resamples,
        rng=rng
    )
    
    passes = w2_median <= w2_max and w2_width <= bca_width_max
    
    return SatotTateResult(
        w2=w2,
        ks=ks,
        cvm=cvm,
        w2_lower=w2_lower,
        w2_upper=w2_upper,
        w2_median=w2_median,
        w2_width=w2_width,
        passes=passes
    )
