"""
experiments/rollback.py
=======================
Section 11 — Rollback and Computational Irreversibility Experiment.
Tests state reversibility S_n -> S_{n-1} across generation trajectories.
"""

from __future__ import annotations
from typing import Any, Dict, List, Tuple
from binary_fragmentation.core.state import State
from binary_fragmentation.core.operators import (
    BinaryOperator,
    QuantizationOperator,
    TruncationOperator,
    HashingOperator,
    SerializeDeserializeOperator,
    CascadeOperator,
)
from binary_fragmentation.metrics.vector import MetricCalculator


class RollbackExperiment:
    """Evaluates computational reversibility and rollback failure."""

    def __init__(self, steps: int = 5):
        self.steps = steps

    def run(self, initial_state: State) -> Dict[str, Any]:
        # Construct pipeline containing both reversible and irreversible steps
        operators = [
            ("Step 1: Quantization (Lossy)", QuantizationOperator(bits=6)),
            ("Step 2: Precision Truncation (Lossy)", TruncationOperator(decimals=2)),
            ("Step 3: One-Way Hashing (Strictly Irreversible)", HashingOperator(hash_values=True)),
        ]

        history: List[State] = [initial_state.clone()]
        rollback_results: List[Dict[str, Any]] = []

        current = initial_state.clone()
        for name, op in operators:
            next_st, rec = op.apply(current)
            history.append(next_st.clone())

            # Attempt rollback: Can we reconstruct previous state checksum?
            can_rollback = (rec.checksum_before == rec.checksum_after)
            rollback_results.append({
                "step": name,
                "operator": op.name,
                "checksum_before": rec.checksum_before[:12],
                "checksum_after": rec.checksum_after[:12],
                "rollback_successful": can_rollback,
                "reversible_flag": rec.reversible,
                "notes": rec.reversibility_notes,
            })
            current = next_st

        # Empirical computational irreversibility index: fraction of failed rollbacks
        failed_rollbacks = sum(1 for r in rollback_results if not r["rollback_successful"])
        irreversibility_index = failed_rollbacks / len(rollback_results)

        return {
            "experiment": "Section 11 Rollback Experiment",
            "total_steps": len(operators),
            "failed_rollbacks": failed_rollbacks,
            "computational_irreversibility_index": irreversibility_index,
            "step_audit": rollback_results,
        }
