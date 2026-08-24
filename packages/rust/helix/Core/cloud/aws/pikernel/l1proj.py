"""
Weighted ℓ₁-ball projection (ACE safety set).

The ACE safety set is a weighted ℓ₁ ball: {x : Σ w_i|x_i| ≤ τ}.
Projection uses bisection to find the soft-threshold parameter λ such that
the projected point lies exactly on the ball boundary.
"""

import numpy as np
from typing import Tuple


def project_weighted_l1_ball(
    v: np.ndarray, 
    w: np.ndarray, 
    tau: float, 
    atol: float = 1e-12, 
    maxit: int = 10000
) -> Tuple[np.ndarray, float]:
    """
    Project vector v onto weighted ℓ₁ ball {x : Σ w_i|x_i| ≤ τ}.
    
    Uses bisection to find λ such that the soft-thresholded solution
        x_i = sign(v_i) * max(|v_i| - λw_i, 0)
    satisfies Σ w_i|x_i| = τ.
    
    Args:
        v: Input vector to project
        w: Weight vector (same shape as v, all positive)
        tau: ℓ₁ ball radius (budget)
        atol: Absolute tolerance for bisection
        maxit: Maximum bisection iterations
    
    Returns:
        (x, lambda) where x is the projected vector and lambda is the
        soft-threshold parameter found by bisection
    """
    v = np.asarray(v, dtype=float)
    w = np.asarray(w, dtype=float)
    
    assert v.shape == w.shape, "v and w must have same shape"
    assert np.all(w > 0), "Weights must be positive"
    assert tau > 0, "Ball radius must be positive"
    
    # Check if already inside the ball
    current_norm = np.sum(w * np.abs(v))
    if current_norm <= tau + atol:
        return v.copy(), 0.0
    
    # Bisection search for λ
    lam_lo = 0.0
    lam_hi = np.max(np.abs(v) / (w + 1e-30))
    
    def shrink(lam: float) -> np.ndarray:
        """Apply soft-thresholding with parameter λ."""
        return np.sign(v) * np.maximum(np.abs(v) - lam * w, 0.0)
    
    for iteration in range(maxit):
        lam = 0.5 * (lam_lo + lam_hi)
        x = shrink(lam)
        val = np.sum(w * np.abs(x))
        
        if abs(val - tau) < atol:
            return x, lam
        
        if val > tau:
            lam_lo = lam
        else:
            lam_hi = lam
    
    # Return best approximation if didn't converge
    return shrink(lam_hi), lam_hi


def project_l1_ball_simple(v: np.ndarray, tau: float) -> np.ndarray:
    """
    Simple (unweighted) ℓ₁ ball projection.
    
    Args:
        v: Input vector
        tau: ℓ₁ ball radius
    
    Returns:
        Projected vector
    """
    w = np.ones_like(v)
    x, _ = project_weighted_l1_ball(v, w, tau)
    return x
