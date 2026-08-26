"""
pirtm/test_csc.py
=================
Unit tests for the PIRTMDecoderParser EBNF parser.
"""

import unittest
from pirtm.csc import (
    PIRTMDecoderParser,
    TensorDeclaration,
    OperatorApplication,
    ContractivityAssertion,
    parse_pirtm,
)


class TestPIRTMDecoderParser(unittest.TestCase):
    def test_tensor_declaration_parsing(self):
        code = "tensor T_0 [p_2, p_3, p_5];"
        statements = parse_pirtm(code)
        self.assertEqual(len(statements), 1)
        stmt = statements[0]
        self.assertIsInstance(stmt, TensorDeclaration)
        self.assertEqual(stmt.identifier, "T_0")
        self.assertEqual(stmt.primes, ["p_2", "p_3", "p_5"])

    def test_operator_application_without_lambda(self):
        code = "T_0 |> p_2 * p_7;"
        statements = parse_pirtm(code)
        self.assertEqual(len(statements), 1)
        stmt = statements[0]
        self.assertIsInstance(stmt, OperatorApplication)
        self.assertEqual(stmt.identifier, "T_0")
        self.assertFalse(stmt.has_lambda)
        self.assertEqual(stmt.prime_chain, ["p_2", "p_7"])

    def test_operator_application_with_lambda(self):
        code = "T_1 |> \\Lambda_m * p_11 * p_13;"
        statements = parse_pirtm(code)
        self.assertEqual(len(statements), 1)
        stmt = statements[0]
        self.assertIsInstance(stmt, OperatorApplication)
        self.assertEqual(stmt.identifier, "T_1")
        self.assertTrue(stmt.has_lambda)
        self.assertEqual(stmt.prime_chain, ["p_11", "p_13"])

    def test_contractivity_assertion(self):
        code = "assert_contractive(T_0) < 0.85;"
        statements = parse_pirtm(code)
        self.assertEqual(len(statements), 1)
        stmt = statements[0]
        self.assertIsInstance(stmt, ContractivityAssertion)
        self.assertEqual(stmt.identifier, "T_0")
        self.assertEqual(stmt.bound, 0.85)

    def test_composite_program(self):
        code = """
        # Program header
        tensor Alpha [p_2, p_3];
        Alpha |> \\Lambda_m * p_5 * p_7;
        assert_contractive(Alpha) < 0.60;
        """
        statements = parse_pirtm(code)
        self.assertEqual(len(statements), 3)
        self.assertIsInstance(statements[0], TensorDeclaration)
        self.assertIsInstance(statements[1], OperatorApplication)
        self.assertIsInstance(statements[2], ContractivityAssertion)


if __name__ == "__main__":
    unittest.main()
