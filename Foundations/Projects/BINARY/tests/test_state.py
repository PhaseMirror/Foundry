"""
tests/test_state.py
===================
Unit tests for core state models and serialization.
"""

import unittest
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge


class TestState(unittest.TestCase):
    def test_state_creation_and_cloning(self):
        st = State(context={"env": "test"})
        st.add_node(Node(id="n1", value=42.0, attributes={"label": "A"}))
        st.add_node(Node(id="n2", value=100.0, attributes={"label": "B"}))
        st.add_edge(Edge(source_id="n1", target_id="n2", relation_type="links", weight=2.5))
        st.add_hyperedge(HyperEdge(node_ids=["n1", "n2"], relation_type="group"))

        self.assertEqual(len(st.nodes), 2)
        self.assertEqual(len(st.edges), 1)
        self.assertEqual(len(st.hyperedges), 1)

        # Check clone
        cloned = st.clone()
        self.assertEqual(cloned.state_id, st.state_id)
        self.assertEqual(cloned.compute_checksum(), st.compute_checksum())

        # Modify clone, verify original is untouched
        cloned.nodes["n1"].value = 999.0
        self.assertNotEqual(cloned.compute_checksum(), st.compute_checksum())
        self.assertEqual(st.nodes["n1"].value, 42.0)

    def test_deterministic_checksum(self):
        st1 = State(state_id="fixed_id", generation=0)
        st1.add_node(Node(id="a", value=1.0))
        st1.add_node(Node(id="b", value=2.0))

        st2 = State(state_id="fixed_id", generation=0)
        st2.add_node(Node(id="b", value=2.0))
        st2.add_node(Node(id="a", value=1.0))

        # Checksums should be identical despite different insertion orders
        self.assertEqual(st1.compute_checksum(), st2.compute_checksum())


if __name__ == "__main__":
    unittest.main()
