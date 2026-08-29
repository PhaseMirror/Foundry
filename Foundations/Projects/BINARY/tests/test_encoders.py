"""
tests/test_encoders.py
======================
Unit tests for multimodal encoders and decoders.
"""

import unittest
from binary_fragmentation.core.state import State, Node, Edge, HyperEdge
from binary_fragmentation.core.encoder import (
    BinaryScalarEncoder,
    BinaryRecordEncoder,
    BinaryRelationalEncoder,
    PrimeIndexedEncoder,
)
from binary_fragmentation.core.decoder import (
    BinaryScalarDecoder,
    BinaryRecordDecoder,
    BinaryRelationalDecoder,
    PrimeIndexedDecoder,
)


class TestEncoders(unittest.TestCase):
    def setUp(self):
        self.state = State()
        self.state.add_node(Node(id="node_a", value=12.34))
        self.state.add_node(Node(id="node_b", value=56.78))
        self.state.add_edge(Edge(source_id="node_a", target_id="node_b", relation_type="connects"))

    def test_binary_relational_round_trip(self):
        enc = BinaryRelationalEncoder()
        dec = BinaryRelationalDecoder()
        raw = enc.encode(self.state)
        self.assertTrue(len(raw) > 0)
        reconstructed = dec.decode(raw)

        self.assertEqual(len(reconstructed.nodes), 2)
        self.assertEqual(len(reconstructed.edges), 1)
        self.assertAlmostEqual(reconstructed.nodes["node_a"].value, 12.34, places=4)
        self.assertEqual(reconstructed.edges[0].relation_type, "connects")

    def test_binary_scalar_encoder_drops_edges(self):
        enc = BinaryScalarEncoder()
        dec = BinaryScalarDecoder()
        raw = enc.encode(self.state)
        reconstructed = dec.decode(raw, template_state=self.state)

        # Values preserved, edges dropped by design
        self.assertEqual(len(reconstructed.nodes), 2)
        self.assertEqual(len(reconstructed.edges), 0)
        self.assertAlmostEqual(reconstructed.nodes["node_a"].value, 12.34, places=4)

    def test_prime_indexed_round_trip(self):
        enc = PrimeIndexedEncoder()
        dec = PrimeIndexedDecoder()
        raw = enc.encode(self.state)
        reconstructed = dec.decode(raw)

        self.assertEqual(len(reconstructed.nodes), 2)
        self.assertEqual(len(reconstructed.edges), 1)


if __name__ == "__main__":
    unittest.main()
