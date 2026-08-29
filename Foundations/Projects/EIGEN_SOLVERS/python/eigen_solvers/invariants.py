"""
Spectral and Dynamical Invariants for Prime-Weighted Lanczos Flow.
"""

from dataclasses import dataclass
from typing import List
import math
from .prime_lanczos import LanczosResult


@dataclass
class InvariantSummary:
    trace: float
    off_diagonal_energy: float
    coupling_ratios: List[float]
    exponent_signature: float


class SpectralInvariants:
    """Computes categorical invariants on Lanczos results."""

    @staticmethod
    def trace(res: LanczosResult) -> float:
        """Trace functor: Tr(M_m) = sum(alpha_k)."""
        return sum(res.alphas)

    @staticmethod
    def off_diagonal_energy(res: LanczosResult) -> float:
        """Prime-weighted energy: E(M_m) = sum((beta_k * p_k)^2)."""
        return sum(b ** 2 for b in res.effective_betas)

    @staticmethod
    def scale_free_coupling_ratios(res: LanczosResult) -> List[float]:
        """Scale-free coupling ratios: r_k = (beta_k * p_k) / (beta_{k-1} * p_{k-1})."""
        ratios = []
        eff = res.effective_betas
        for k in range(1, len(eff)):
            if abs(eff[k - 1]) > 1e-15:
                ratios.append(eff[k] / eff[k - 1])
            else:
                ratios.append(0.0)
        return ratios

    @staticmethod
    def prime_exponent_signature(res: LanczosResult) -> float:
        """Exponent signature: s_m = sum(log_{p_k} |beta_k * p_k|)."""
        s = 0.0
        for b_eff, p in zip(res.effective_betas, res.primes):
            if abs(b_eff) > 1e-15 and p > 1:
                s += math.log(abs(b_eff)) / math.log(p)
        return s

    @classmethod
    def analyze(cls, res: LanczosResult) -> InvariantSummary:
        """Compute all spectral and dynamical invariants."""
        return InvariantSummary(
            trace=cls.trace(res),
            off_diagonal_energy=cls.off_diagonal_energy(res),
            coupling_ratios=cls.scale_free_coupling_ratios(res),
            exponent_signature=cls.prime_exponent_signature(res),
        )
