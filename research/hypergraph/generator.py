# hypergraph/generator.py
import random

class HypergraphState:
    def __init__(self, id_val):
        self.id = id_val
        self.produced_by = []
        
    def add_producer(self, producer_id):
        self.produced_by.append(producer_id)
        if len(self.produced_by) > 1:
            # Patch A: Fail-fast on ambiguous causal linkage
            raise ValueError(f"State {self.id} has ambiguous causal linkage: {self.produced_by}")

def step_zero_walk(valid_edges):
    # Patch C: Uniformly sample valid outward edges instead of degenerate [0]
    if not valid_edges:
        return None
    return random.choice(valid_edges)
