import numpy as np
from typing import List, Optional, Tuple


def _riemann_siegel_theta(t: float) -> float:
    """Asymptotic expansion of the Riemann-Siegel theta function."""
    t = max(t, 1e-6)
    half_t = t / 2.0
    log_t_2pi = np.log(t / (2.0 * np.pi))
    theta = half_t * log_t_2pi - half_t - np.pi / 8.0 + 1.0 / (48.0 * t)
    return theta


def _riemann_siegel_theta_prime(t: float) -> float:
    """Derivative of the Riemann-Siegel theta function."""
    t = max(t, 1e-6)
    return 0.5 * np.log(t / (2.0 * np.pi)) - 0.5 - 1.0 / (48.0 * t * t)


def hardy_z_block(t: float, N: Optional[int] = None) -> float:
    """
    Compute the Hardy Z function Z(t) via the Riemann-Siegel formula.

    Z(t) = 2 * sum_{n=1}^{m} n^{-1/2} * cos(theta(t) - t*log(n)) + R(t)

    Args:
        t: Height on the critical line.
        N: Optional truncation rank. Defaults to floor(sqrt(t / (2*pi))).

    Returns:
        Approximation of Z(t).
    """
    if t <= 0:
        return 0.0

    theta = _riemann_siegel_theta(t)

    if N is None:
        m = int(np.sqrt(t / (2.0 * np.pi)))
    else:
        m = max(1, int(N))

    total = 0.0
    for n in range(1, m + 1):
        total += np.cos(theta - t * np.log(n)) / np.sqrt(n)

    z = 2.0 * total

    # Simplified remainder approximation
    m_f = float(m)
    remainder = (
        2.0
        * ((-1.0) ** (m_f - 1.0))
        / (np.sqrt(t) * np.pi)
        * np.cos(theta + t * np.log(m_f) - np.pi / 4.0)
    )
    z += remainder

    return z


def hardy_z_block_prime(t: float, N: Optional[int] = None) -> float:
    """
    Derivative of the Hardy Z function with respect to t.

    Z'(t) = 2 * sum_{n=1}^{m} n^{-1/2} * (-t/(2n) - theta'(t)) * sin(theta(t) - t*log(n)) + R'(t)
    """
    if t <= 0:
        return 0.0

    theta = _riemann_siegel_theta(t)
    theta_p = _riemann_siegel_theta_prime(t)

    if N is None:
        m = int(np.sqrt(t / (2.0 * np.pi)))
    else:
        m = max(1, int(N))

    total = 0.0
    for n in range(1, m + 1):
        total += (-t / (2.0 * n) - theta_p) * np.sin(theta - t * np.log(n)) / np.sqrt(n)

    dz = 2.0 * total

    # Simplified remainder derivative
    m_f = float(m)
    remainder_p = (
        2.0
        * ((-1.0) ** (m_f - 1.0))
        / (np.sqrt(t) * np.pi)
        * (-(np.sqrt(m_f) / t) + 0.5 / np.sqrt(t))
        * np.sin(theta + t * np.log(m_f) - np.pi / 4.0)
    )
    dz += remainder_p

    return dz


def _newton_refine(t_low: float, t_high: float, iters: int = 8) -> float:
    """Newton refinement of a zero of Z(t) bracketed by t_low and t_high."""
    t = (t_low + t_high) / 2.0
    for _ in range(iters):
        z = hardy_z_block(t)
        zp = hardy_z_block_prime(t)
        if abs(zp) < 1e-12:
            break
        t -= z / zp
        t = max(t_low, min(t_high, t))
    return t


def find_zeros_refined(
    t_start: float,
    t_end: float,
    search_step: float = 0.1,
    newton_iters: int = 8,
) -> List[float]:
    """
    Find zeros of Z(t) in [t_start, t_end] via sign-change detection + Newton refinement.

    Args:
        t_start: Lower bound of search window.
        t_end: Upper bound of search window.
        search_step: Step size for coarse sign-change scan.
        newton_iters: Newton refinement iterations per zero.

    Returns:
        Sorted list of refined zero ordinates.
    """
    zeros: List[float] = []
    t_prev = t_start
    z_prev = hardy_z_block(t_prev)

    t = t_start + search_step
    while t <= t_end:
        z = hardy_z_block(t)
        if z_prev * z < 0.0:
            t_zero = _newton_refine(t_prev, t, newton_iters)
            if t_start <= t_zero <= t_end:
                zeros.append(t_zero)
        t_prev = t
        z_prev = z
        t += search_step

    zeros.sort()
    return zeros


def compute_zero_shadow_metrics(
    t_start: float = 14.0,
    t_end: float = 50.0,
    search_step: float = 0.1,
) -> Tuple[float, float, float]:
    """
    Compute analytic-shadow metrics from refined zeros of Z(t).

    Returns:
        (first_zero_approx, mean_spacing, gue_deviation)
        gue_deviation is a lightweight outlier-fraction proxy on normalized
        nearest-neighbor spacings (stand-in for a full Montgomery/GUE histogram).
    """
    zeros = find_zeros_refined(t_start, t_end, search_step)
    if len(zeros) < 2:
        return (float(zeros[0]) if zeros else 0.0, 1.0, 0.0)

    spacings = np.diff(zeros)
    mean_spacing = float(np.mean(spacings))
    if mean_spacing <= 0:
        mean_spacing = 1.0

    normalized = spacings / mean_spacing
    median_sp = float(np.median(normalized))
    mad = float(np.median(np.abs(normalized - median_sp)))
    outlier_threshold = 1.4826 * mad * 3.0  # ~3-sigma equivalent for normal-like data
    outlier_count = float(np.sum(np.abs(normalized - median_sp) > outlier_threshold))
    gue_deviation = outlier_count / max(len(normalized), 1)

    return (float(zeros[0]), mean_spacing, gue_deviation)
