"""
experiments/recursive.py
========================
Mode C — Recursive Transformation and Drift Dynamics Experiment.
Computes:
- Trajectory: S_0 -> S_1 -> ... -> S_N where S_{n+1} = Ξ(S_n)
- Drift: D_n = d(S_0, S_n)
- Discrete first derivative: ΔD_n / Δn
- Discrete second derivative: Δ²D_n / Δn²
- Dynamics classification: Linear, Exponential, Saturation, or Threshold
"""

from __future__ import annotations
import math
from typing import Any, Callable, Dict, List, Optional, Tuple
from binary_fragmentation.core.state import State
from binary_fragmentation.core.operators import (
    BinaryOperator,
    QuantizationOperator,
    TruncationOperator,
    SerializeDeserializeOperator,
    CascadeOperator,
)
from binary_fragmentation.core.encoder import BinaryScalarEncoder
from binary_fragmentation.core.decoder import BinaryScalarDecoder
from binary_fragmentation.metrics.vector import MetricCalculator, FragmentationVector


class RecursiveDriftExperiment:
    """Mode C: Recursive Transformation Drift Analyzer."""

    def __init__(
        self,
        operator: Optional[BinaryOperator] = None,
        iterations: int = 15,
    ):
        self.iterations = iterations
        # Default recursive step: slight precision truncation + quantization
        self.operator = operator or CascadeOperator(
            operators=[
                QuantizationOperator(bits=10),
                TruncationOperator(decimals=4),
            ],
            name="DefaultRecursiveStep",
        )

    def run(self, initial_state: State) -> Dict[str, Any]:
        trajectory: List[State] = [initial_state.clone()]
        vectors: List[FragmentationVector] = []
        drift_values: List[float] = [0.0]

        current_state = initial_state.clone()
        for step in range(1, self.iterations + 1):
            next_state, _ = self.operator.apply(current_state)
            trajectory.append(next_state.clone())
            
            vec = MetricCalculator.evaluate(initial_state, next_state)
            vectors.append(vec)
            drift_values.append(vec.l2_norm)
            
            current_state = next_state

        # Compute derivatives
        d1: List[float] = []
        for i in range(1, len(drift_values)):
            d1.append(drift_values[i] - drift_values[i - 1])

        d2: List[float] = []
        for i in range(1, len(d1)):
            d2.append(d1[i] - d1[i - 1])

        # Curve classification
        classification = self._classify_dynamics(drift_values, d1, d2)

        return {
            "mode": "Mode C (Recursive Transformation)",
            "iterations": self.iterations,
            "drift_trajectory": drift_values,
            "first_derivative": d1,
            "second_derivative": d2,
            "final_vector": vectors[-1].to_dict() if vectors else {},
            "dynamics_classification": classification,
            "step_vectors": [v.to_dict() for v in vectors],
        }

    def _classify_dynamics(
        self, drift: List[float], d1: List[float], d2: List[float]
    ) -> Dict[str, Any]:
        """Classifies drift curve into Linear, Exponential, Saturation, or Threshold."""
        if len(drift) < 3:
            return {"type": "Indeterminate", "confidence": 0.0}

        max_drift = max(drift)
        final_drift = drift[-1]
        
        # Check saturation: d1 approaches zero while drift > 0
        if len(d1) >= 4 and abs(d1[-1]) < 0.005 and final_drift > 0.05:
            return {
                "type": "Saturation",
                "description": "Drift reaches a stable attractor D_max.",
                "asymptotic_drift": final_drift,
            }

        # Check threshold behavior: early d1 near 0, then sudden spike
        threshold_idx = None
        for i in range(1, len(d1)):
            if d1[i] > 3.0 * (sum(d1[:i]) / max(i, 1) + 1e-4) and d1[i] > 0.1:
                threshold_idx = i
                break
        if threshold_idx is not None:
            return {
                "type": "Threshold (Critical Point)",
                "description": f"Stable until generation n_c={threshold_idx}, followed by rapid breakdown.",
                "n_c": threshold_idx,
            }

        # Check linear vs exponential
        if len(d1) >= 3:
            var_d1 = max(d1) - min(d1)
            if var_d1 < 0.05:
                slope = sum(d1) / len(d1)
                return {
                    "type": "Linear",
                    "description": "Drift accumulates steadily at constant rate.",
                    "rate_k": slope,
                }
            elif d1[-1] > d1[0]:
                return {
                    "type": "Exponential / Accelerating",
                    "description": "Information loss accelerates with recursion depth.",
                }

        return {
            "type": "Monotonic Drift",
            "description": "Progressive cumulative divergence.",
            "final_drift": final_drift,
        }
