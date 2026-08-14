#!/usr/bin/env python3
import json
import sys
import re

def validate_receipt(receipt_path):
    with open(receipt_path, 'r') as f:
        data = json.load(f)

    # Validate Schema Basics
    required_keys = ["s_integrity", "last_prime_move", "policy_root_hash", "crmf_certificate", "lambda_m_resonance_score"]
    for k in required_keys:
        if k not in data:
            print(f"Discrepancy: Missing required key {k}")
            sys.exit(1)

    hash_pattern = re.compile(r"^0x[a-fA-F0-9]{64}$")
    if not hash_pattern.match(data["s_integrity"]):
        print("Discrepancy: Invalid s_integrity hash format")
        sys.exit(1)
        
    if not hash_pattern.match(data["policy_root_hash"]):
        print("Discrepancy: Invalid policy_root_hash format")
        sys.exit(1)

    print("DecisionAssure Parser: PWEH Receipt perfectly parsed with zero discrepancies.")
    sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: pweh_decision_assure_parser.py <receipt.json>")
        sys.exit(1)
    validate_receipt(sys.argv[1])
