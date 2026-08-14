#!/usr/bin/env python3
"""
PWEH Checkpoint Adapter for DecisionAssure
Validates PWEH checkpoint receipts and produces DecisionAssure verification output.

Usage:
    python pweh_adapter.py <checkpoint.json>
"""

import json
import re
import sys
from typing import Dict, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class PWEHCheckpoint:
    """PWEH checkpoint receipt structure."""
    s_integrity: str
    last_prime_move: int
    policy_root_hash: str
    crmf_certificate: str
    lambda_m_resonance_score: float
    is_valid: bool = False
    validation_errors: list = field(default_factory=list)


class PWEHValidator:
    """Validates PWEH checkpoint receipts against the specification."""

    @staticmethod
    def validate_hash(value: str, field_name: str) -> tuple[bool, str]:
        """Validate a 64-character lowercase hex hash."""
        if not value:
            return False, f"{field_name} is empty"
        if len(value) != 64:
            return False, f"{field_name} length is {len(value)} (expected 64)"
        if not re.match(r'^[a-f0-9]{64}$', value):
            return False, f"{field_name} contains invalid characters (must be lowercase hex)"
        return True, ""

    @staticmethod
    def validate_prime(value: int) -> tuple[bool, str]:
        """Validate that a number is prime."""
        if value < 2:
            return False, f"last_prime_move must be a prime number >= 2 (got {value})"
        if value == 2:
            return True, ""
        if value % 2 == 0:
            return False, f"{value} is not prime (divisible by 2)"
        for i in range(3, int(value ** 0.5) + 1, 2):
            if value % i == 0:
                return False, f"{value} is not prime (divisible by {i})"
        return True, ""

    @staticmethod
    def validate_resonance_score(value: float) -> tuple[bool, str]:
        """Validate resonance score is between 0.0 and 1.0."""
        if not isinstance(value, (int, float)):
            return False, f"lambda_m_resonance_score must be a number (got {type(value).__name__})"
        if value < 0.0 or value > 1.0:
            return False, f"lambda_m_resonance_score must be between 0.0 and 1.0 (got {value})"
        return True, ""

    @classmethod
    def validate(cls, data: Dict[str, Any]) -> PWEHCheckpoint:
        """Validate a checkpoint receipt."""
        errors = []
        checkpoint = PWEHCheckpoint(
            s_integrity=data.get('s_integrity', ''),
            last_prime_move=data.get('last_prime_move', 0),
            policy_root_hash=data.get('policy_root_hash', ''),
            crmf_certificate=data.get('crmf_certificate', ''),
            lambda_m_resonance_score=data.get('lambda_m_resonance_score', 0.0)
        )

        # Validate s_integrity
        valid, msg = cls.validate_hash(checkpoint.s_integrity, 's_integrity')
        if not valid:
            errors.append(msg)

        # Validate policy_root_hash
        valid, msg = cls.validate_hash(checkpoint.policy_root_hash, 'policy_root_hash')
        if not valid:
            errors.append(msg)

        # Validate crmf_certificate
        valid, msg = cls.validate_hash(checkpoint.crmf_certificate, 'crmf_certificate')
        if not valid:
            errors.append(msg)

        # Validate last_prime_move
        valid, msg = cls.validate_prime(checkpoint.last_prime_move)
        if not valid:
            errors.append(msg)

        # Validate resonance score
        valid, msg = cls.validate_resonance_score(checkpoint.lambda_m_resonance_score)
        if not valid:
            errors.append(msg)

        checkpoint.is_valid = len(errors) == 0
        checkpoint.validation_errors = errors
        return checkpoint


class DecisionAssureAdapter:
    """Adapter that consumes PWEH checkpoints and produces DecisionAssure verification output."""

    def __init__(self):
        self.validator = PWEHValidator()

    def verify_checkpoint(self, checkpoint_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Verify a PWEH checkpoint and produce DecisionAssure-compatible output.
        """
        checkpoint = self.validator.validate(checkpoint_data)

        result = {
            "receipt_hash": checkpoint.s_integrity if checkpoint.s_integrity else "",
            "continuity_result": "PASS" if checkpoint.is_valid else "FAIL",
            "violation_details": checkpoint.validation_errors,
            "timestamp": datetime.utcnow().isoformat() + "Z"
        }

        return result


def main():
    if len(sys.argv) < 2:
        print("Usage: python pweh_adapter.py <checkpoint.json>")
        sys.exit(1)

    with open(sys.argv[1], 'r') as f:
        data = json.load(f)

    adapter = DecisionAssureAdapter()
    result = adapter.verify_checkpoint(data)

    print(json.dumps(result, indent=2))

    # Exit with appropriate code
    sys.exit(0 if result["continuity_result"] == "PASS" else 1)


if __name__ == "__main__":
    main()