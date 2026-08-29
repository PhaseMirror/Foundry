"""AGL(1,p) group actions, CRT embeddings, and Legendre symbol."""

import numpy as np
from typing import List, Tuple


def legendre_symbol(a: int, p: int) -> int:
    """Compute the Legendre symbol χ_p(a).
    
    Returns:
        1 if a is a quadratic residue mod p (and a != 0)
        -1 if a is a quadratic non-residue mod p
        0 if a == 0
    """
    a_mod = a % p
    if a_mod == 0:
        return 0
    # Euler's criterion
    result = pow(a_mod, (p - 1) // 2, p)
    return 1 if result == 1 else -1


class AglElement:
    """A single AGL(1,p) element: i -> u*i + k (mod p)."""
    
    def __init__(self, u: int, k: int, p: int):
        assert p >= 2 and p % 2 == 1, "p must be odd and >= 2"
        self.u = u % p
        self.k = k % p
        self.p = p
    
    def apply(self, i: int) -> int:
        return (self.u * i + self.k) % self.p
    
    def compose(self, other: 'AglElement') -> 'AglElement':
        assert self.p == other.p
        return AglElement(
            (self.u * other.u) % self.p,
            (self.u * other.k + self.k) % self.p,
            self.p
        )
    
    def inverse(self) -> 'AglElement':
        u_inv = pow(self.u, self.p - 2, self.p)
        k_inv = (self.p - (u_inv * self.k) % self.p) % self.p
        return AglElement(u_inv, k_inv, self.p)
    
    def permutation_matrix(self, n: int) -> np.ndarray:
        P = np.zeros((n, n))
        for i in range(n):
            j = self.apply(i)
            if j < n:
                P[j, i] = 1.0
        return P


class AglGroup:
    """Full AGL(1,p) group."""
    
    def __init__(self, p: int):
        assert p >= 2 and p % 2 == 1, "p must be odd and >= 2"
        self.p = p
        self.elements = [AglElement(u, k, p) for u in range(1, p) for k in range(p)]
    
    @property
    def order(self) -> int:
        return len(self.elements)
    
    def conjugate(self, g: AglElement, A: np.ndarray) -> np.ndarray:
        """Compute A -> P_g A P_g^T."""
        P = g.permutation_matrix(A.shape[0])
        return P @ A @ P.T


class CrtEmbedding:
    """CRT embedding: phi: {1,...,n} -> F_p1 x F_p2."""
    
    def __init__(self, p1: int, p2: int, n: int):
        assert p1 * p2 >= n, f"p1*p2={p1*p2} < n={n}"
        self.p1 = p1
        self.p2 = p2
        self.n = n
    
    def embed(self, i: int) -> Tuple[int, int]:
        return (i % self.p1, i % self.p2)
    
    def residue_mask(self) -> np.ndarray:
        """Compute the residue mask M[i,j] = prod_k 1{chi_pk(phi_k(i)-phi_k(j))=+1}."""
        n = self.n
        M = np.zeros((n, n))
        for i in range(n):
            for j in range(n):
                a1, b1 = self.embed(i)
                a2, b2 = self.embed(j)
                chi1 = legendre_symbol((a1 - a2) % self.p1, self.p1)
                chi2 = legendre_symbol((a2 - b2) % self.p2, self.p2)
                M[i, j] = 1.0 if chi1 == 1 and chi2 == 1 else 0.0
        return M
