from typing import List
import numpy as np

def compute_tau(
    coverage: float,
    required_coverage: float,
    drift_norm: float,
    epsilon_x: float
) -> float:
    """
    Computes the tether tension τ (ADR-002, ADR-006).
    """
    if required_coverage <= 0:
        return 0.0
    
    coverage_ratio = coverage / required_coverage
    
    # Avoid negative values if drift exceeds epsilon
    drift_factor = max(0.0, 1.0 - (drift_norm / epsilon_x))
    
    return coverage_ratio * drift_factor

def can_builder_advance(tau: float, threshold: float = 0.70) -> bool:
    return tau >= threshold
