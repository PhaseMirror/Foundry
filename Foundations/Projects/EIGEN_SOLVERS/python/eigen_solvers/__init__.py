"""
Prime-Encoded Eigen Solvers: Categorical Prime Flows
Production numerical package and solver suite.
"""

from .prime_lanczos import PrimeWeightedLanczos, LanczosResult
from .invariants import SpectralInvariants
from .prime_tensor import PrimeTensorModule, PrimeTensorState, QuantumPhaseEstimator
from .feedback import RecursiveFeedbackSolver
from .linalg import lanczos_sane

__all__ = [
    "PrimeWeightedLanczos",
    "LanczosResult",
    "SpectralInvariants",
    "PrimeTensorModule",
    "PrimeTensorState",
    "QuantumPhaseEstimator",
    "RecursiveFeedbackSolver",
    "lanczos_sane",
]
