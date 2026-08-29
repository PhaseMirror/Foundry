"""Semantic stabilization functional S_Lambda[psi], dynamic operator Xi(t), and shock recovery."""

import math
from dataclasses import dataclass
from .core import LAMBDA_M, PHI

@dataclass
class SemanticVector:
    components: list[float]

    @classmethod
    def zeros(cls, dim: int) -> "SemanticVector":
        return cls([0.0] * dim)

    @classmethod
    def equilibrium(cls, dim: int) -> "SemanticVector":
        return cls([0.5] * dim)

    def norm_sq(self) -> float:
        return sum(c * c for c in self.components)

    def norm(self) -> float:
        return math.sqrt(self.norm_sq())

    def dist_sq(self, other: "SemanticVector") -> float:
        return sum((a - b) ** 2 for a, b in zip(self.components, other.components))

    def dist(self, other: "SemanticVector") -> float:
        return math.sqrt(self.dist_sq(other))

@dataclass
class DynamicOperator:
    dim: int
    matrix: list[list[float]]

    @classmethod
    def identity(cls, dim: int) -> "DynamicOperator":
        mat = [[1.0 if i == j else 0.0 for j in range(dim)] for i in range(dim)]
        return cls(dim, mat)

    def apply(self, v: SemanticVector) -> SemanticVector:
        res = []
        for row in self.matrix:
            s = sum(m * c for m, c in zip(row, v.components))
            res.append(s)
        return SemanticVector(res)

    def step_commutator(self, t: int, lambda_m: float = LAMBDA_M) -> "DynamicOperator":
        next_mat = []
        for i in range(self.dim):
            row = []
            for j in range(self.dim):
                osc = math.sin((i + j + 1) * PHI * (t + 1) * 0.1)
                comm_perturb = osc * 0.02 if i != j else 0.0
                base = 1.0 if i == j else 0.0
                val = max(-1.0, min(1.0, base + comm_perturb))
                row.append(val)
            next_mat.append(row)
        return DynamicOperator(self.dim, next_mat)

def project_lambda_m(v: SemanticVector, bound: float = 0.65) -> SemanticVector:
    return SemanticVector([max(-bound, min(bound, c)) for c in self_components(v)])

def self_components(v: SemanticVector) -> list[float]:
    return v.components

def semantic_evolution_step(psi: SemanticVector, op: DynamicOperator, target: SemanticVector, lambda_m: float = LAMBDA_M) -> SemanticVector:
    diff = SemanticVector([p - tgt for p, tgt in zip(psi.components, target.components)])
    dynamic_diff = op.apply(diff)
    next_comp = [max(0.0, min(1.0, tgt + lambda_m * d_diff)) for tgt, d_diff in zip(target.components, dynamic_diff.components)]
    return SemanticVector(next_comp)

def simulate_shock_recovery(initial_shock: SemanticVector, target: SemanticVector, steps: int = 12) -> list[tuple[int, float]]:
    curr_psi = SemanticVector(list(initial_shock.components))
    curr_op = DynamicOperator.identity(len(initial_shock.components))
    trajectory = []
    for step in range(steps):
        dist = curr_psi.dist(target)
        trajectory.append((step, dist))
        curr_psi = semantic_evolution_step(curr_psi, curr_op, target, LAMBDA_M)
        curr_op = curr_op.step_commutator(step, LAMBDA_M)
    return trajectory
