"""Prime-Indexed Recursive Tensor Mathematics (PIRTM) and Hyperprime Cascades."""

import math
from dataclasses import dataclass
from .core import LAMBDA_M, PHI

@dataclass
class TensorNode:
    prime: int
    weight: float
    phase: float
    energy: float

    def apply_action(self, t: int, lambda_m: float = LAMBDA_M, alpha: float = 1.0) -> "TensorNode":
        p = float(self.prime)
        delta_phase = (2.0 * math.pi * p * PHI * (t + 1)) % (2.0 * math.pi)
        new_phase = (self.phase + delta_phase) % (2.0 * math.pi)

        harmonic_scale = p ** (-alpha)
        new_weight = max(0.0, min(1.0, self.weight * harmonic_scale * lambda_m))
        new_energy = max(0.0, min(1.0, self.energy * lambda_m))

        return TensorNode(self.prime, new_weight, new_phase, new_energy)

@dataclass
class PrismTensorState:
    time: int
    lambda_m: float
    nodes: list[TensorNode]
    coherence: float
    is_stable: bool

    @classmethod
    def new_with_primes(cls, primes: list[int], lambda_m: float = LAMBDA_M) -> "PrismTensorState":
        nodes = []
        for idx, p in enumerate(primes):
            weight = max(0.1, min(1.0, 1.0 - idx * 0.1))
            phase = (idx * 0.5) % (2.0 * math.pi)
            energy = max(0.1, min(1.0, 0.5 - idx * 0.05))
            nodes.append(TensorNode(p, weight, phase, energy))

        st = cls(0, lambda_m, nodes, 1.0, True)
        st.recompute_metrics()
        return st

    def total_energy(self) -> float:
        return sum(n.energy for n in self.nodes)

    def recompute_metrics(self) -> None:
        if not self.nodes:
            self.coherence = 0.0
            self.is_stable = False
            return
        sum_cos = sum(math.cos(n.phase) for n in self.nodes)
        sum_sin = sum(math.sin(n.phase) for n in self.nodes)
        r = math.sqrt(sum_cos**2 + sum_sin**2) / len(self.nodes)
        self.coherence = min(1.0, max(0.0, r * self.lambda_m))
        self.is_stable = not math.isnan(self.coherence) and self.total_energy() <= len(self.nodes)

    def step(self) -> "PrismTensorState":
        updated_nodes = [n.apply_action(self.time, self.lambda_m, 1.0) for n in self.nodes]
        next_st = PrismTensorState(self.time + 1, self.lambda_m, updated_nodes, self.coherence, self.is_stable)
        next_st.recompute_metrics()
        return next_st

    def iterate(self, steps: int) -> "PrismTensorState":
        curr = self
        for _ in range(steps):
            curr = curr.step()
        return curr

    def fractal_superposition(self, depth: int) -> "PrismTensorState":
        fractal_nodes = []
        for node in self.nodes:
            total_w = node.weight
            total_ph = node.phase
            scale = 1.0
            for k in range(1, depth + 1):
                scale /= PHI
                total_w += node.weight * scale
                total_ph = (total_ph + node.phase + k * 0.2) % (2.0 * math.pi)
            fractal_nodes.append(TensorNode(node.prime, min(2.0, total_w), total_ph, node.energy))
        next_st = PrismTensorState(self.time, self.lambda_m, fractal_nodes, self.coherence, self.is_stable)
        next_st.recompute_metrics()
        return next_st
