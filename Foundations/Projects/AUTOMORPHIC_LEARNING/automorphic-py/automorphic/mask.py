"""Residue masks, additive logits, and ε-stabilized Sinkhorn."""

import numpy as np
from typing import Optional, Tuple


class ResidueMask:
    """Residue mask from Legendre symbol."""
    
    def __init__(self, mask: np.ndarray):
        self.mask = mask
    
    @classmethod
    def from_crt(cls, p1: int, p2: int, n: int) -> 'ResidueMask':
        from .group import CrtEmbedding
        crt = CrtEmbedding(p1, p2, n)
        return cls(crt.residue_mask())


class AdditiveLogits:
    """Additive logits: L = QK^T/sqrt(d) + alpha*M - beta*(1-M)."""
    
    def __init__(self, alpha: float = 0.0, beta: float = 20.0, normalize_logits: bool = False):
        self.alpha = alpha
        self.beta = beta
        self.normalize_logits = normalize_logits
    
    def compute(self, Q: np.ndarray, K: np.ndarray, mask: ResidueMask) -> np.ndarray:
        """Compute additive logits from Q, K, and the residue mask."""
        d = Q.shape[-1]
        n = Q.shape[0]
        assert Q.shape == K.shape, f"Q and K must have same shape, got {Q.shape} and {K.shape}"
        assert mask.mask.shape == (n, n), f"mask shape {mask.mask.shape} != ({n}, {n})"
        
        L = Q @ K.T / np.sqrt(d)
        M = mask.mask
        L = L + self.alpha * M - self.beta * (1 - M)
        
        if self.normalize_logits:
            L = L - L.max(axis=-1, keepdims=True)
        
        return L
    
    def softmax(self, L: np.ndarray) -> np.ndarray:
        """Row-wise softmax."""
        L_shifted = L - L.max(axis=-1, keepdims=True)
        exp_L = np.exp(L_shifted)
        return exp_L / exp_L.sum(axis=-1, keepdims=True)


def sinkhorn_eps(
    A: np.ndarray,
    epsilon: float = 1e-6,
    iters: int = 5,
    tol: float = 1e-3
) -> Tuple[np.ndarray, float]:
    """ε-stabilized Sinkhorn normalization.
    
    Returns (B, residual) where B is bistochastic and residual measures
    how far B is from exact bistochasticity.
    """
    B = np.maximum(A, 0.0) + epsilon
    
    for _ in range(iters):
        # Row normalization
        row_sums = B.sum(axis=1, keepdims=True)
        B = B / row_sums
        
        # Column normalization
        col_sums = B.sum(axis=0, keepdims=True)
        B = B / col_sums
    
    # Compute residual
    row_resid = np.abs(B.sum(axis=1) - 1).max()
    col_resid = np.abs(B.sum(axis=0) - 1).max()
    resid = max(row_resid, col_resid)
    
    return B, float(resid)
