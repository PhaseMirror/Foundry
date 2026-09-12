"""
Recursive Feedback Eigenvalue Refinement.
Implements:
    λ_{t+1} = λ_t + α_t ∑ p_i e^{-β_i t}
"""

from typing import List
import math


class RecursiveFeedbackSolver:
    """Recursive feedback loop on eigenvalue estimates."""

    def __init__(self, primes: List[int], beta_scales: List[float], learning_rate: float = 0.05):
        if len(primes) != len(beta_scales):
            raise ValueError("Primes and beta_scales must have equal length.")
        self.primes = list(primes)
        self.beta_scales = list(beta_scales)
        self.learning_rate = learning_rate

    def step(self, lambda_t: float, t: int) -> float:
        """Advance one feedback iteration."""
        prime_sum = sum(p * math.exp(-b * t) for p, b in zip(self.primes, self.beta_scales))
        return lambda_t + self.learning_rate * prime_sum

    def run(self, lambda_0: float, steps: int) -> List[float]:
        """Run feedback trajectory for given number of steps."""
        trajectory = [lambda_0]
        current_lambda = lambda_0
        for t in range(steps):
            current_lambda = self.step(current_lambda, t)
            trajectory.append(current_lambda)
        return trajectory
