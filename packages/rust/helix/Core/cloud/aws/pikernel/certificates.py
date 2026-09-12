"""
Contraction certificates: SlopeUB and GapLB.

These certificates verify that the dynamical system is contracting at every step.
The key inequality: GapLB = 1 - SlopeUB > 0 guarantees strict contraction.
"""

import numpy as np
from typing import Union


def slope_upper_bound(alphas: Union[np.ndarray, dict], K: np.ndarray) -> float:
    """
    Compute SlopeUB = ||A||_∞ where A = diag(1-α) + diag(α)|K|.
    
    This is the induced ∞-norm (maximum row sum) of the affine iteration matrix.
    
    Args:
        alphas: Per-atom mixing rates (array or dict keyed by pi_id)
        K: Coupling matrix (m × m) where m is number of atoms
    
    Returns:
        Upper bound on the slope (Lipschitz constant)
    """
    if isinstance(alphas, dict):
        # Convert dict to array in consistent order
        alphas = np.array(list(alphas.values()))
    else:
        alphas = np.asarray(alphas, dtype=float)
    
    K = np.asarray(K, dtype=float)
    
    assert alphas.ndim == 1, "alphas must be 1D"
    assert K.ndim == 2 and K.shape[0] == K.shape[1], "K must be square"
    assert len(alphas) == K.shape[0], "alphas and K dimensions must match"
    
    # Construct iteration matrix A = diag(1-α) + diag(α)|K|
    A = np.diag(1.0 - alphas) + np.diag(alphas) @ np.abs(K)
    
    # Compute ∞-norm (max row sum)
    row_sums = np.sum(np.abs(A), axis=1)
    slopeUB = float(np.max(row_sums))
    
    return slopeUB


def gap_lower_bound(slopeUB: float) -> float:
    """
    Compute GapLB = 1 - SlopeUB.
    
    When GapLB > 0, the dynamical system is a strict contraction with:
    - Unique bounded trajectory
    - Exponential convergence to fixed point
    - Stable rollback/replay
    
    Args:
        slopeUB: Upper bound on slope from slope_upper_bound()
    
    Returns:
        Lower bound on the contraction gap
    """
    return 1.0 - float(slopeUB)


def verify_contraction(alphas: Union[np.ndarray, dict], K: np.ndarray) -> dict:
    """
    Verify contraction properties and return certificate.
    
    Args:
        alphas: Per-atom mixing rates
        K: Coupling matrix
    
    Returns:
        Dictionary with:
        - slopeUB: Upper bound on slope
        - gapLB: Lower bound on contraction gap
        - is_contractive: Whether GapLB > 0
        - safety_margin: How far from the boundary (GapLB value)
    """
    slopeUB = slope_upper_bound(alphas, K)
    gapLB = gap_lower_bound(slopeUB)
    
    return {
        "slopeUB": slopeUB,
        "gapLB": gapLB,
        "is_contractive": gapLB > 0,
        "safety_margin": gapLB,
    }
