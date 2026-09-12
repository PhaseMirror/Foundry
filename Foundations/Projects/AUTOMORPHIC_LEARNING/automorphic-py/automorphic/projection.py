"""Weighted-ℓ₁ projection with KKT certificates and Lipschitz bounds."""

import numpy as np
from typing import Tuple
from dataclasses import dataclass


@dataclass
class ProjectionCertificate:
    """Certificate from weighted-ℓ₁ projection."""
    feasible: bool
    tau: float
    gaplb: float
    primal: float
    dual: float
    mass: float
    budget: float
    complementary_slackness: bool


def project_weighted_l1(
    v: np.ndarray,
    omega: np.ndarray,
    T: float,
    tol: float = 1e-8,
    max_iter: int = 80
) -> Tuple[np.ndarray, ProjectionCertificate]:
    """Project v onto {x: sum_i w_i |x_i| <= T}.
    
    Returns (x, certificate) where x is the projected vector and
    certificate contains KKT diagnostics.
    """
    assert np.all(omega > 0), "weights must be positive"
    assert T >= 0, "budget must be non-negative"
    
    v = np.asarray(v, dtype=float)
    omega = np.asarray(omega, dtype=float)
    
    # Check if v is already feasible
    mass = np.sum(omega * np.abs(v))
    if mass <= T:
        return v.copy(), ProjectionCertificate(
            feasible=True, tau=0.0, gaplb=0.0,
            primal=0.0, dual=0.0, mass=float(mass),
            budget=T, complementary_slackness=True
        )
    
    def shrink(x, tau_w):
        return np.sign(x) * np.maximum(np.abs(x) - tau_w, 0.0)
    
    # Bisection on tau
    max_v_over_w = np.max(np.abs(v) / omega)
    tau_lo, tau_hi = 0.0, max_v_over_w
    
    for _ in range(max_iter):
        tau = 0.5 * (tau_lo + tau_hi)
        x = shrink(v, tau * omega)
        mass = np.sum(omega * np.abs(x))
        
        if mass > T:
            tau_lo = tau
        else:
            tau_hi = tau
        
        if abs(mass - T) <= tol:
            break
    
    # Final projection with tau_hi (ensures feasibility)
    tau = tau_hi
    x = shrink(v, tau * omega)
    mass = np.sum(omega * np.abs(x))
    feasible = mass <= T + tol
    
    # Primal: 0.5 * ||x - v||^2
    primal = 0.5 * np.sum((x - v)**2)
    
    # Dual: tau * T - sum (|v_k| - tau*omega_k)_+^2 / (2*omega_k)
    shrink_amount = np.maximum(np.abs(v) - tau * omega, 0.0)
    dual = tau * T - np.sum(shrink_amount**2 / (2.0 * omega))
    
    gaplb = max(0.0, primal - dual)
    
    # Complementary slackness: tau * (T - sum omega_k |x_k|) = 0
    cs_violation = abs(tau * (T - mass))
    
    return x, ProjectionCertificate(
        feasible=feasible,
        tau=float(tau),
        gaplb=float(gaplb),
        primal=float(primal),
        dual=float(dual),
        mass=float(mass),
        budget=T,
        complementary_slackness=cs_violation <= tol
    )


def softmax(x: np.ndarray, axis: int = -1) -> np.ndarray:
    """Numerically stable softmax."""
    z = x - x.max(axis=axis, keepdims=True)
    ex = np.exp(z)
    return ex / ex.sum(axis=axis, keepdims=True)


def softmax_ub(logits: np.ndarray) -> float:
    """Softmax Jacobian upper bound: max_i 2*s_i*(1-s_i)."""
    s = softmax(logits, axis=-1)
    return float(np.max(2.0 * s * (1.0 - s)))


def slopeub(linear_norms: list, softmax_ubs: list) -> float:
    """End-to-end ℓ₁-Lipschitz upper bound.
    
    SlopeUB = prod(B_ℓ) * prod(SoftmaxUB)
    """
    result = 1.0
    for n in linear_norms:
        result *= n
    for u in softmax_ubs:
        result *= u
    return float(result)
