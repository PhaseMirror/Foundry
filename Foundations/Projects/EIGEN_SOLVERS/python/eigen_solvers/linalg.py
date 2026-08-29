"""
Robust pure Python linear algebra routines (Zero external dependencies).
Implements exact symmetric tridiagonal eigensolver via stable Givens rotations / Jacobi sweeps.
"""

import math
from typing import List, Tuple

Vector = List[float]
Matrix = List[List[float]]


def dot(u: Vector, v: Vector) -> float:
    """Euclidean dot product."""
    return sum(a * b for a, b in zip(u, v))


def norm(v: Vector) -> float:
    """Euclidean 2-norm."""
    return math.sqrt(dot(v, v))


def normalize(v: Vector) -> Vector:
    """Normalize vector to unit length."""
    n = norm(v)
    if n < 1e-15:
        return [0.0] * len(v)
    return [x / n for x in v]


def matvec(A: Matrix, v: Vector) -> Vector:
    """Matrix-vector product A @ v."""
    return [dot(row, v) for row in A]


def is_symmetric(A: Matrix, tol: float = 1e-9) -> bool:
    """Check if matrix is symmetric."""
    n = len(A)
    for i in range(n):
        for j in range(i + 1, n):
            if abs(A[i][j] - A[j][i]) > tol:
                return False
    return True


def tridiagonal_eigenvalues(alphas: Vector, effective_betas: Vector, max_iter: int = 200, tol: float = 1e-12) -> Tuple[Vector, Matrix]:
    """
    Computes eigenvalues and eigenvectors of a symmetric tridiagonal matrix using robust symmetric Jacobi iteration.
    Guarantees stability, orthogonality, and non-divergence.
    """
    n = len(alphas)
    if n == 0:
        return [], []
    if n == 1:
        return [alphas[0]], [[1.0]]

    # Build dense symmetric matrix
    A = [[0.0] * n for _ in range(n)]
    for i in range(n):
        A[i][i] = alphas[i]
    for i in range(len(effective_betas)):
        b = effective_betas[i]
        A[i][i + 1] = b
        A[i + 1][i] = b

    V = [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]

    for _ in range(max_iter):
        # Find maximum off-diagonal element
        max_val = 0.0
        p, q = 0, 1
        for i in range(n):
            for j in range(i + 1, n):
                if abs(A[i][j]) > max_val:
                    max_val = abs(A[i][j])
                    p, q = i, j

        if max_val < tol:
            break

        # Compute Jacobi rotation angle
        app = A[p][p]
        aqq = A[q][q]
        apq = A[p][q]

        if abs(app - aqq) < 1e-15:
            theta = math.pi / 4.0 if apq > 0 else -math.pi / 4.0
        else:
            tau = (aqq - app) / (2.0 * apq)
            t = math.copysign(1.0 / (abs(tau) + math.sqrt(1.0 + tau * tau)), tau)
            theta = math.atan(t)

        c = math.cos(theta)
        s = math.sin(theta)

        # Apply rotation to A
        # Update elements
        A_pp = c * c * app - 2.0 * s * c * apq + s * s * aqq
        A_qq = s * s * app + 2.0 * s * c * apq + c * c * aqq
        A[p][p] = A_pp
        A[q][q] = A_qq
        A[p][q] = 0.0
        A[q][p] = 0.0

        for k in range(n):
            if k != p and k != q:
                a_kp = A[k][p]
                a_kq = A[k][q]
                A[k][p] = c * a_kp - s * a_kq
                A[p][k] = A[k][p]
                A[k][q] = s * a_kp + c * a_kq
                A[q][k] = A[k][q]

            # Update eigenvectors
            v_kp = V[k][p]
            v_kq = V[k][q]
            V[k][p] = c * v_kp - s * v_kq
            V[k][q] = s * v_kp + c * v_kq

    eigvals = [A[i][i] for i in range(n)]

    # Sort eigenvalues in ascending order
    order = sorted(range(n), key=lambda i: eigvals[i])
    sorted_eigvals = [eigvals[i] for i in order]
    sorted_V = [[V[row][col] for col in order] for row in range(n)]

    return sorted_eigvals, sorted_V


def lanczos_sane(ritz: Vector, resid: Vector, dim: int, energy_scale: float = 1e3) -> bool:
    """
    Ritz-explosion guard:
    Fails closed if Ritz values overflow or residual bounds diverge.
    """
    if any(abs(x) > energy_scale * dim for x in ritz):
        return False
    if any(math.isnan(r) or math.isinf(r) or r > energy_scale for r in resid):
        return False
    return True
