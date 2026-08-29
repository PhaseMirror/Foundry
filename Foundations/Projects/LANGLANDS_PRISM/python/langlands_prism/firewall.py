"""Ethical Entanglement Firewall and Automated Recursion Collapse Protocol."""

import math
from .core import LAMBDA_M
from .cascade import TensorNode, PrismTensorState

ETHICAL_THRESHOLD = 0.75

def compute_ethical_metric(st: PrismTensorState) -> float:
    if not st.nodes:
        return 0.0
    total_power = 0.0
    for n in st.nodes:
        state_power = n.weight * n.energy
        phase_skew = (n.phase % 1.57) / 1.57 * 0.2
        total_power += state_power + phase_skew
    return max(0.0, min(1.0, total_power / len(st.nodes)))

def execute_automated_collapse(st: PrismTensorState) -> PrismTensorState:
    collapsed_nodes = []
    for node in st.nodes:
        quenched_w = node.weight * LAMBDA_M * LAMBDA_M
        harmonic_ph = (node.prime * 0.4) % math.pi
        quenched_e = node.energy * 0.3
        collapsed_nodes.append(TensorNode(node.prime, min(1.0, quenched_w), harmonic_ph, min(1.0, quenched_e)))
    collapsed_st = PrismTensorState(st.time, st.lambda_m, collapsed_nodes, 0.9, True)
    collapsed_st.recompute_metrics()
    return collapsed_st

def firewall_gate(st: PrismTensorState) -> tuple[PrismTensorState, bool]:
    metric = compute_ethical_metric(st)
    if metric > ETHICAL_THRESHOLD:
        return execute_automated_collapse(st), True
    return st, False
