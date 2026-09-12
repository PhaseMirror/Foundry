"""
tests/test_metrics.py
=====================
Unit tests for the 8-dimensional fragmentation vector.
"""

import unittest
from binary_fragmentation.core.state import State, Node, Edge
from binary_fragmentation.metrics.vector import MetricCalculator


class TestMetrics(unittest.TestCase):
    def test_identical_states_zero_loss(self):
        st = State()
        st.add_node(Node(id="n1", value=10.0))
        st.add_node(Node(id="n2", value=20.0))
        st.add_edge(Edge(source_id="n1", target_id="n2", relation_type="links"))

        vec = MetricCalculator.evaluate(st, st.clone())
        self.assertEqual(vec.F_v, 0.0)
        self.assertEqual(vec.F_s, 0.0)
        self.assertEqual(vec.F_r, 0.0)
        self.assertEqual(vec.l2_norm, 0.0)

    def test_crucial_invariant_value_preserved_relations_lost(self):
        st0 = State()
        st0.add_node(Node(id="n1", value=10.0))
        st0.add_node(Node(id="n2", value=20.0))
        st0.add_edge(Edge(source_id="n1", target_id="n2", relation_type="links"))

        # Transformed state has exact same nodes and values, but ZERO edges
        st_flat = State()
        st_flat.add_node(Node(id="n1", value=10.0))
        st_flat.add_node(Node(id="n2", value=20.0))

        vec = MetricCalculator.evaluate(st0, st_flat)
        self.assertEqual(vec.F_v, 0.0)  # 100% Value preservation!
        self.assertEqual(vec.F_r, 1.0)  # 100% Relational loss!
        self.assertTrue(vec.F_s > 0.0)  # Structural divergence detected


if __name__ == "__main__":
    unittest.main()
