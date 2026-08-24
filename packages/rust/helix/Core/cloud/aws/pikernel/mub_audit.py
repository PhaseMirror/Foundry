"""
MUB (Mutually Unbiased Bases) drift audit using Walsh-Hadamard transform.

Detects energy concentration inconsistent with uniform spread, which could
indicate spoofing or anomalous behavior.
"""

import numpy as np
from typing import Dict, Any


def mub_drift_audit(
    x: np.ndarray, 
    threshold: float = 3.0,
    use_hadamard: bool = True
) -> Dict[str, Any]:
    """
    Walsh-Hadamard MUB audit on raw state vector.
    
    Under uniform energy spread, the concentration metric D_t should be small.
    Large D_t indicates anomalous concentration.
    
    The concentration metric is:
        D_t = ||Ux||_∞² - (1/n) * ||Ux||²₂ * n
    
    where U is a unitary complementary to the standard basis (e.g., Hadamard).
    
    Args:
        x: State vector
        threshold: Alarm threshold (typical range: [2.5, 4.0])
        use_hadamard: Whether to use Hadamard transform (if False, use DFT)
    
    Returns:
        Dictionary with:
        - D_t: Concentration metric
        - threshold: Threshold used
        - alarm: Boolean indicating if D_t > threshold
        - action: Recommended action ("accept" or "shrink_tau")
    """
    x = np.asarray(x, dtype=float)
    n = x.size
    
    if use_hadamard and (n & (n-1)) == 0:
        # Use Fast Walsh-Hadamard Transform for power-of-2 dimensions
        Ux = fast_walsh_hadamard(x)
    else:
        # Fallback: DFT as a complementary unitary
        Ux = np.fft.fft(x)
        Ux = np.real(Ux)  # Use real part as the audit basis
    
    # Compute energy in complementary basis
    energy = np.abs(Ux)**2
    
    # Concentration metric: excess of max over mean energy
    max_energy = np.max(energy)
    mean_energy = np.mean(energy)
    D_t = max_energy - mean_energy
    
    # Alternative formulation (equivalent):
    # D_t = max_energy - mean_energy
    
    # Check alarm condition
    alarm = D_t > threshold
    
    return {
        "D_t": float(D_t),
        "max_energy": float(max_energy),
        "mean_energy": float(mean_energy),
        "threshold": threshold,
        "alarm": bool(alarm),
        "action": "shrink_tau" if alarm else "accept",
    }


def fast_walsh_hadamard(x: np.ndarray) -> np.ndarray:
    """
    Fast Walsh-Hadamard Transform (FWHT).
    
    Computes the Hadamard transform in O(n log n) time for n = 2^k.
    
    Args:
        x: Input vector (length must be power of 2)
    
    Returns:
        Transformed vector
    """
    x = np.asarray(x, dtype=float).copy()
    n = len(x)
    
    # Check that n is a power of 2
    if n & (n - 1) != 0:
        raise ValueError("Length must be a power of 2 for FWHT")
    
    # In-place FWHT
    h = 1
    while h < n:
        for i in range(0, n, h * 2):
            for j in range(i, i + h):
                a = x[j]
                b = x[j + h]
                x[j] = a + b
                x[j + h] = a - b
        h *= 2
    
    # Normalization
    return x / np.sqrt(n)


def hadamard_matrix(n: int) -> np.ndarray:
    """
    Construct Hadamard matrix of size n × n.
    
    Only works for n = power of 2.
    
    Args:
        n: Size (must be power of 2)
    
    Returns:
        Normalized Hadamard matrix (orthogonal)
    """
    if n == 1:
        return np.array([[1.0]])
    
    if n & (n - 1) != 0:
        raise ValueError("n must be a power of 2")
    
    # Recursive construction
    H = np.array([[1.0, 1.0], [1.0, -1.0]])
    
    while H.shape[0] < n:
        H = np.block([[H, H], [H, -H]])
    
    return H / np.sqrt(n)
