#!/usr/bin/env python3
"""
Test suite for PWEH DecisionAssure Adapter.
"""

import json
import unittest
from pweh_adapter import PWEHValidator, DecisionAssureAdapter


class TestPWEHValidator(unittest.TestCase):
    """Test the PWEH validator against known-good and known-bad checkpoints."""

    def setUp(self):
        self.validator = PWEHValidator()
        self.adapter = DecisionAssureAdapter()

    def test_known_good_checkpoint(self):
        """Test a valid checkpoint passes validation."""
        valid_checkpoint = {
            "s_integrity": "1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            "last_prime_move": 43,
            "policy_root_hash": "abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
            "crmf_certificate": "1111111111111111111111111111111111111111111111111111111111111111",
            "lambda_m_resonance_score": 0.992
        }
        result = self.adapter.verify_checkpoint(valid_checkpoint)
        self.assertEqual(result["continuity_result"], "PASS")

    def test_invalid_hash_length(self):
        """Test a checkpoint with invalid hash length is rejected."""
        invalid = {
            "s_integrity": "short",
            "last_prime_move": 3,
            "policy_root_hash": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
        }
        result = self.adapter.verify_checkpoint(invalid)
        self.assertEqual(result["continuity_result"], "FAIL")
        self.assertTrue(any("length is" in err for err in result["violation_details"]))

    def test_resonance_score_out_of_bounds(self):
        """Test a checkpoint with resonance score out of bounds is rejected."""
        invalid = {
            "s_integrity": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "last_prime_move": 3,
            "policy_root_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "lambda_m_resonance_score": 1.5
        }
        result = self.adapter.verify_checkpoint(invalid)
        self.assertEqual(result["continuity_result"], "FAIL")
        self.assertTrue(any("between 0.0 and 1.0" in err for err in result["violation_details"]))

    def test_invalid_hash_characters(self):
        """Test a checkpoint with uppercase or prefixed hashes is rejected."""
        invalid = {
            "s_integrity": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab",
            "last_prime_move": 43,
            "policy_root_hash": "ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890",
            "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "lambda_m_resonance_score": 0.5
        }
        result = self.adapter.verify_checkpoint(invalid)
        self.assertEqual(result["continuity_result"], "FAIL")
        self.assertTrue(any("invalid characters" in err for err in result["violation_details"]))

    def test_prime_validation(self):
        """Test that non-prime numbers are rejected."""
        invalid = {
            "s_integrity": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            "last_prime_move": 4,  # Not prime
            "policy_root_hash": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
            "crmf_certificate": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
            "lambda_m_resonance_score": 0.5
        }
        result = self.adapter.verify_checkpoint(invalid)
        self.assertEqual(result["continuity_result"], "FAIL")
        self.assertTrue(any("prime" in err for err in result["violation_details"]))


if __name__ == "__main__":
    unittest.main()