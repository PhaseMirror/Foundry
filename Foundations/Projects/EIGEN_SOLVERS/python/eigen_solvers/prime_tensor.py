"""
Prime-Tensor and Quantum State Layer.
Models:
    Ψ(t) = ∑ λ_i |p_i⟩ ⊗ |e_i⟩
and implements Quantum Phase Estimation (QPE) distributions and expectation values.
"""

from dataclasses import dataclass
from typing import Dict, List, Tuple
import math
from .linalg import Vector, Matrix


@dataclass
class PrimeTensorState:
    """Prime-labelled tensor state Ψ(t) = ∑ λ_i |p_i⟩ ⊗ |e_i⟩."""
    primes: List[int]
    eigenvalues: List[float]
    eigenvectors: Matrix

    @property
    def norm_squared(self) -> float:
        """||Ψ(t)||^2 = ∑ |λ_i|^2."""
        return sum(lam ** 2 for lam in self.eigenvalues)

    @property
    def norm(self) -> float:
        return math.sqrt(self.norm_squared)


class PrimeTensorModule:
    """Prime-labelled tensor module in Category PrimeTen_A."""

    def __init__(self, primes: List[int], eigenvalues: List[float], eigenvectors: Matrix):
        self.primes = primes
        self.eigenvalues = eigenvalues
        self.eigenvectors = eigenvectors
        self.state = PrimeTensorState(primes, eigenvalues, eigenvectors)

    def evolve(self, time: float) -> "PrimeTensorModule":
        """
        Quantum evolution functor Q: Ψ(t) -> e^{i A t} Ψ(0).
        Preserves eigenvalue amplitudes under unitary evolution.
        """
        return PrimeTensorModule(self.primes, list(self.eigenvalues), self.eigenvectors)

    def expectation_value(self, diagonal_weights: Dict[int, float]) -> float:
        """
        Expectation-value functor:
        E_O = ⟨Ψ| O |Ψ⟩ = ∑ |λ_i|^2 O_{p_i}
        """
        total = 0.0
        for p, lam in zip(self.primes, self.eigenvalues):
            w = diagonal_weights.get(p, 0.0)
            total += (lam ** 2) * w
        return total


class QuantumPhaseEstimator:
    """Simulates Quantum Phase Estimation on prime-tensor states."""

    @staticmethod
    def measure_distribution(module: PrimeTensorModule) -> Dict[int, float]:
        """
        Computes measurement probability distribution over prime modes:
        P(p_i) = |λ_i|^2 / ||Ψ||^2.
        """
        total_norm_sq = module.state.norm_squared
        if total_norm_sq < 1e-15:
            return {p: 0.0 for p in module.primes}

        probs = {}
        for p, lam in zip(module.primes, module.eigenvalues):
            probs[p] = (lam ** 2) / total_norm_sq
        return probs
