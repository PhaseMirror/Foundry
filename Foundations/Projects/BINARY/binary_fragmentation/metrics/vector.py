"""
metrics/vector.py
=================
Multidimensional Fragmentation Vector:
F = (F_v, F_s, F_r, F_p, F_i, F_t, F_c, F_q, F_sem)
where each metric ranges in [0.0, 1.0] (0 = fully preserved, 1 = fully lost).
"""

from __future__ import annotations
import math
from dataclasses import dataclass, asdict
from typing import Any, Dict, Optional

from binary_fragmentation.core.state import State
from binary_fragmentation.metrics.value import compute_value_loss
from binary_fragmentation.metrics.structure import compute_structure_loss
from binary_fragmentation.metrics.relation import compute_relation_loss
from binary_fragmentation.metrics.provenance import compute_provenance_loss
from binary_fragmentation.metrics.identity import compute_identity_loss
from binary_fragmentation.metrics.temporal import compute_temporal_loss
from binary_fragmentation.metrics.context import compute_context_loss
from binary_fragmentation.metrics.reversibility import compute_reversibility_loss
from binary_fragmentation.metrics.semantic import compute_semantic_loss


@dataclass
class FragmentationVector:
    """
    Multidimensional fragmentation metrics measuring information loss:
    F_v   : Value loss (numerical & attribute distortion)
    F_s   : Structural loss (graph topology & degree drift)
    F_r   : Relational loss (edge, hyperedge, & link fidelity)
    F_p   : Provenance loss (causal history & parentage degradation)
    F_i   : Identity loss (entity resolution & ID stability)
    F_t   : Temporal loss (chronological order inversion)
    F_c   : Contextual loss (metadata & frame preservation)
    F_q   : Reversibility loss (computational irreversibility)
    F_sem : Semantic loss (conservation of business / financial balance invariants)
    """

    F_v: float  # Value loss
    F_s: float  # Structural loss
    F_r: float  # Relational loss
    F_p: float  # Provenance loss
    F_i: float  # Identity loss
    F_t: float  # Temporal loss
    F_c: float  # Contextual loss
    F_q: float  # Reversibility loss
    F_sem: float = 0.0  # Semantic equivalence loss

    @property
    def l2_norm(self) -> float:
        """Euclidean magnitude of total information loss in 8D core space."""
        return math.sqrt(
            self.F_v**2
            + self.F_s**2
            + self.F_r**2
            + self.F_p**2
            + self.F_i**2
            + self.F_t**2
            + self.F_c**2
            + self.F_q**2
        ) / math.sqrt(8.0)

    @property
    def mean_loss(self) -> float:
        """Arithmetic mean across core 8 dimensions."""
        return (
            self.F_v
            + self.F_s
            + self.F_r
            + self.F_p
            + self.F_i
            + self.F_t
            + self.F_c
            + self.F_q
        ) / 8.0

    @property
    def value_preservation_pct(self) -> float:
        return max(0.0, (1.0 - self.F_v) * 100.0)

    @property
    def relational_preservation_pct(self) -> float:
        return max(0.0, (1.0 - self.F_r) * 100.0)

    @property
    def semantic_preservation_pct(self) -> float:
        return max(0.0, (1.0 - self.F_sem) * 100.0)

    def to_dict(self) -> Dict[str, Any]:
        d = asdict(self)
        d["l2_norm"] = self.l2_norm
        d["mean_loss"] = self.mean_loss
        d["value_preservation_pct"] = self.value_preservation_pct
        d["relational_preservation_pct"] = self.relational_preservation_pct
        d["semantic_preservation_pct"] = self.semantic_preservation_pct
        return d


class MetricCalculator:
    """Calculates the complete Fragmentation Vector between S_0 and S_n."""

    @staticmethod
    def evaluate(s0: State, sn: State) -> FragmentationVector:
        return FragmentationVector(
            F_v=compute_value_loss(s0, sn),
            F_s=compute_structure_loss(s0, sn),
            F_r=compute_relation_loss(s0, sn),
            F_p=compute_provenance_loss(s0, sn),
            F_i=compute_identity_loss(s0, sn),
            F_t=compute_temporal_loss(s0, sn),
            F_c=compute_context_loss(s0, sn),
            F_q=compute_reversibility_loss(s0, sn),
            F_sem=compute_semantic_loss(s0, sn),
        )
