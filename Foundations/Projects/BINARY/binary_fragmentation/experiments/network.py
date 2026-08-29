"""
experiments/network.py
======================
Mode D — Network Fragmentation Experiment.
Splits state across distributed nodes and measures cross-boundary relational loss.
"""

from __future__ import annotations
from typing import Any, Dict
from binary_fragmentation.core.state import State
from binary_fragmentation.fragmentation.splitting import NetworkShardingOperator
from binary_fragmentation.fragmentation.recombination import NetworkRecombinationOperator
from binary_fragmentation.metrics.vector import MetricCalculator


class NetworkFragmentationExperiment:
    """Mode D: Distributed Network Sharding & Cross-Node Fragmentation."""

    def __init__(self, num_shards: int = 4):
        self.num_shards = num_shards
        self.sharder = NetworkShardingOperator(num_shards=num_shards, preserve_cross_edges=False)
        self.recombiner = NetworkRecombinationOperator()

    def run(self, initial_state: State) -> Dict[str, Any]:
        shards = self.sharder.split(initial_state)
        recombined = self.recombiner.recombine(shards, original_state=initial_state)
        vector = MetricCalculator.evaluate(initial_state, recombined)

        return {
            "mode": "Mode D (Network Fragmentation)",
            "shards_count": len(shards),
            "shard_sizes": [len(s.nodes) for s in shards],
            "initial_edges": len(initial_state.edges),
            "recombined_edges": len(recombined.edges),
            "cross_edges_lost": len(initial_state.edges) - len(recombined.edges),
            "vector": vector.to_dict(),
        }
