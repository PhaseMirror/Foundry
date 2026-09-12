"""Permutation-equivariant unitarization via exp and Cayley paths."""

import numpy as np
from scipy.linalg import expm
from typing import Tuple


def exp_unitary(B: np.ndarray) -> np.ndarray:
    """Exp unitarization: U = exp(pi*i*(B - J)).
    
    Args:
        B: Bistochastic matrix (n x n)
    
    Returns:
        U: Unitary matrix (n x n, complex)
    """
    n = B.shape[0]
    J = np.ones((n, n)) / n
    S = (B - J) * np.pi
    return expm(1j * S)


def cayley_unitary(B: np.ndarray, safety_margin: float = 1e-6) -> Tuple[np.ndarray, bool]:
    """Cayley unitarization: U = (I-S)(I+S)^{-1} where S = (B-B^T)/2.
    
    Args:
        B: Bistochastic matrix (n x n)
        safety_margin: Minimum eigenvalue of I+S for safety
    
    Returns:
        (U, safe): Unitary matrix and whether the transform was safe
    """
    n = B.shape[0]
    S = (B - B.T) / 2.0
    I = np.eye(n)
    
    IP = I + S
    IM = I - S
    
    # Check eigenvalues of I+S
    eigvals = np.linalg.eigvalsh(IP)
    min_eigval = eigvals.min()
    
    if min_eigval < safety_margin:
        return np.eye(n, dtype=complex), False
    
    U = np.linalg.solve(IP, IM)
    return U.astype(complex), True


def unitary_residual(U: np.ndarray) -> float:
    """Compute ||U*U - I||_{1->1}."""
    n = U.shape[0]
    I = np.eye(n, dtype=complex)
    UU = U.conj().T @ U
    diff = UU - I
    
    # 1->1 norm: max column sum
    col_sums = np.abs(diff).sum(axis=0)
    return float(col_sums.max())


def compute_eigen_phases(U: np.ndarray) -> np.ndarray:
    """Extract eigenvalues from unitary matrix and return their phases."""
    eigvals = np.linalg.eigvals(U)
    phases = np.angle(eigvals)
    return phases


def permutation_ks(phases_a: np.ndarray, phases_b: np.ndarray, tol: float = 5e-6) -> Tuple[bool, float]:
    """KS test for permutation invariance of eigen phases."""
    a = np.sort(phases_a % (2 * np.pi))
    b = np.sort(phases_b % (2 * np.pi))
    
    grid = np.sort(np.concatenate([a, b]))
    grid = np.unique(grid)
    
    n_a = len(a)
    n_b = len(b)
    
    def ecdf(x, s):
        return np.searchsorted(s, x, side='right') / len(s)
    
    ks = max(abs(ecdf(x, a) - ecdf(x, b)) for x in grid)
    return ks <= tol, float(ks)
