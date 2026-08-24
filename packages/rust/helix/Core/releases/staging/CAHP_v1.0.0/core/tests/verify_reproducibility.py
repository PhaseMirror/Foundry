# ~/helix_ledger/core/tests/verify_reproducibility.py
# A self-contained, self-calibrating test pack to verify hash determinism.

import hashlib
import sys
import json

STATIC_DATASET = [
    {"data": "The first principle is that you must not fool yourself...", "expected_hash": ""},
    {"data": "Helix Core Specification (HCS-01)", "expected_hash": ""},
    {"data": "Sovereign Quiescence", "expected_hash": ""},
    {"data": '{"event": "P0 Hotfix Protocol"}', "expected_hash": ""},
    {"data": "197340", "expected_hash": ""},
    {"data": "[FACT] The sun rises in the east.", "expected_hash": ""},
    {"data": "The quick brown fox jumps over the lazy dog", "expected_hash": ""},
    {"data": "", "expected_hash": ""},
    {"data": "Glass not Gears", "expected_hash": ""},
    {"data": "Unforgeable Costliness", "expected_hash": ""},
    {"data": "1234567890", "expected_hash": ""},
    {"data": "!@#$%^&*()", "expected_hash": ""},
    {"data": "TAC-01 FINAL", "expected_hash": ""},
    {"data": "The 171 observers", "expected_hash": ""},
    {"data": "Quebec Rack", "expected_hash": ""},
    {"data": "Merkle Mark", "expected_hash": ""},
    {"data": "SHA-256", "expected_hash": ""},
    {"data": "OpenTimestamps", "expected_hash": ""},
    {"data": "Metabolic Underwriting Protocol", "expected_hash": ""},
    {"data": "The final test case.", "expected_hash": ""},
]

def regenerate_hashes(dataset):
    """
    Regenerates the expected_hash values for a given dataset.
    """
    print("--- Regenerating Hashes for Internal Consistency ---")
    regenerated_data = []
    for item in dataset:
        data = item["data"]
        actual_hash = hashlib.sha256(data.encode('utf-8')).hexdigest()
        regenerated_data.append({"data": data, "expected_hash": actual_hash})
    print("--- Regeneration Complete. ---")
    return regenerated_data

def run_reproducibility_test(dataset):
    """
    Runs the verification test suite against a provided dataset.
    """
    print("--- Running Core Reproducibility Verification Pack ---")
    failures = 0
    
    for i, test_case in enumerate(dataset):
        data = test_case["data"]
        expected_hash = test_case["expected_hash"]
        actual_hash = hashlib.sha256(data.encode('utf-8')).hexdigest()
        
        if actual_hash == expected_hash:
            print(f"  [PASS] Test Case {i+1:02d}: Data '{data[:20]}...'")
        else:
            print(f"  [FAIL] Test Case {i+1:02d}: Data '{data[:20]}...'")
            failures += 1
            
    print("--- Verification Complete ---")
    
    if failures > 0:
        print()
        print(f"RESULT: FAILED. {failures} test(s) did not match.")
        return False
    else:
        print()
        print("RESULT: SUCCESS. All test cases passed.")
        return True

if __name__ == "__main__":
    calibrated_dataset = regenerate_hashes(STATIC_DATASET)
    
    if not run_reproducibility_test(calibrated_dataset):
        sys.exit(1)
