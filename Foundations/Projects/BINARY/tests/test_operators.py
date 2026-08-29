"""
tests/test_operators.py
=======================
Unit tests for operational transformations and provenance generation.
"""

import unittest
from binary_fragmentation.core.state import State, Node, Edge
from binary_fragmentation.core.operators import (
    IdentityOperator,
    QuantizationOperator,
    TruncationOperator,
    HashingOperator,
    CascadeOperator,
)


class TestOperators(unittest.TestCase):
    def setUp(self):
        self.state = State()
        self.state.add_node(Node(id="n1", value=3.1415926535))
        self.state.add_node(Node(id="n2", value=2.7182818284))

    def test_identity_operator(self):
        op = IdentityOperator()
        new_st, rec = op.apply(self.state)
        self.assertEqual(new_st.compute_checksum(), self.state.compute_checksum())
        self.assertTrue(rec.reversible)

    def test_truncation_operator(self):
        op = TruncationOperator(decimals=2)
        new_st, rec = op.apply(self.state)
        self.assertEqual(new_st.nodes["n1"].value, 3.14)
        self.assertEqual(new_st.nodes["n2"].value, 2.72)

    def test_quantization_operator(self):
        op = QuantizationOperator(bits=4)
        new_st, rec = op.apply(self.state)
        self.assertNotEqual(new_st.compute_checksum(), self.state.compute_checksum())

    def test_hashing_operator(self):
        op = HashingOperator()
        new_st, rec = op.apply(self.state)
        self.assertFalse(rec.reversible)
        self.assertEqual(len(str(new_st.nodes["n1"].value)), 16)


if __name__ == "__main__":
    unittest.main()
