"""
Prime-Weighted Lanczos Solver.
Self-contained pure Python implementation with zero external dependencies.
"""

from dataclasses import dataclass
from typing import List, Optional, Tuple
import math
from .linalg import dot, norm, normalize, matvec, is_symmetric, tridiagonal_eigenvalues, Vector, Matrix


@dataclass
class LanczosResult:
    """Structured output from Prime-Weighted Lanczos."""
    alphas: List[float]
    raw_betas: List[float]
    effective_betas: List[float]
    primes: List[int]
    T: Matrix
    V: Matrix
    ritz_values: List[float]
    ritz_vectors: Matrix
    residual_bounds: List[float]
    gershgorin_disks: List[Tuple[float, float]]
    iterations: int
    early_termination: bool


class PrimeWeightedLanczos:
    """
    Prime-Weighted Lanczos procedure for Hermitian / symmetric matrices.
    """

    STANDARD_PRIMES = [
        2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
        73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151
    ]

    def __init__(self, A: Matrix, primes: Optional[List[int]] = None, tol: float = 1e-12):
        if not is_symmetric(A):
            raise ValueError("Matrix A must be symmetric.")
        self.A = A
        self.n = len(A)
        self.primes = primes if primes is not None else self.STANDARD_PRIMES
        self.tol = tol

    def decompose(self, v1: Optional[Vector] = None, m_max: Optional[int] = None) -> LanczosResult:
        """
        Run prime-weighted Lanczos up to depth m_max.
        """
        if m_max is None:
            m_max = min(self.n, len(self.primes))
        else:
            m_max = min(m_max, self.n, len(self.primes))

        if v1 is None:
            v1 = [1.0] * self.n
        v1 = normalize(v1)

        # Basis vectors stored as columns: V[row][col]
        V = [[0.0] * m_max for _ in range(self.n)]
        for i in range(self.n):
            V[i][0] = v1[i]

        alphas: List[float] = [0.0] * m_max
        raw_betas: List[float] = [0.0] * (m_max - 1)
        effective_betas: List[float] = [0.0] * (m_max - 1)

        col0 = [V[i][0] for i in range(self.n)]
        w = matvec(self.A, col0)
        alphas[0] = dot(col0, w)

        early_term = False
        m_actual = m_max

        for k in range(m_max - 1):
            col_k = [V[i][k] for i in range(self.n)]
            col_prev = [V[i][k - 1] for i in range(self.n)] if k > 0 else [0.0] * self.n
            Aw = matvec(self.A, col_k)

            if k > 0:
                w = [Aw[i] - alphas[k] * col_k[i] - raw_betas[k - 1] * col_prev[i] for i in range(self.n)]
            else:
                w = [Aw[i] - alphas[k] * col_k[i] for i in range(self.n)]

            norm_w = norm(w)
            p_k = self.primes[k]

            raw_betas[k] = norm_w
            effective_betas[k] = norm_w * p_k

            if norm_w < self.tol:
                m_actual = k + 1
                early_term = True
                alphas = alphas[:m_actual]
                raw_betas = raw_betas[:m_actual - 1]
                effective_betas = effective_betas[:m_actual - 1]
                V = [[V[row][col] for col in range(m_actual)] for row in range(self.n)]
                break

            for i in range(self.n):
                V[i][k + 1] = w[i] / norm_w

            col_next = [V[i][k + 1] for i in range(self.n)]
            alphas[k + 1] = dot(col_next, matvec(self.A, col_next))

        # Build tridiagonal matrix T_m
        T = [[0.0] * m_actual for _ in range(m_actual)]
        for k in range(m_actual):
            T[k][k] = alphas[k]
        for k in range(len(effective_betas)):
            off = effective_betas[k]
            T[k][k + 1] = off
            T[k + 1][k] = off

        # Compute Ritz values and Ritz vectors
        eigvals, eigvecs_T = tridiagonal_eigenvalues(alphas, effective_betas)

        # Ritz vectors: V @ eigvecs_T
        ritz_vectors = [[0.0] * m_actual for _ in range(self.n)]
        for i in range(self.n):
            for j in range(m_actual):
                ritz_vectors[i][j] = sum(V[i][k] * eigvecs_T[k][j] for k in range(m_actual))

        # Residual bounds: ||r_j|| = |beta_m * p_m| * |e_m^T y_j|
        last_beta_eff = effective_betas[-1] if len(effective_betas) > 0 else 0.0
        residual_bounds = [abs(last_beta_eff * eigvecs_T[-1][j]) if len(eigvecs_T) > 0 else 0.0 for j in range(m_actual)]

        # Gershgorin disks: |theta - alpha_k| <= beta_{k-1}*p_{k-1} + beta_k*p_k
        gershgorin = []
        for k in range(m_actual):
            r_left = effective_betas[k - 1] if k > 0 else 0.0
            r_right = effective_betas[k] if k < len(effective_betas) else 0.0
            radius = r_left + r_right
            gershgorin.append((alphas[k], radius))

        return LanczosResult(
            alphas=alphas,
            raw_betas=raw_betas,
            effective_betas=effective_betas,
            primes=self.primes[:m_actual],
            T=T,
            V=V,
            ritz_values=eigvals,
            ritz_vectors=ritz_vectors,
            residual_bounds=residual_bounds,
            gershgorin_disks=gershgorin,
            iterations=m_actual,
            early_termination=early_term,
        )
