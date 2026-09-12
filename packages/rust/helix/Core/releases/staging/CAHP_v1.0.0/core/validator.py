# ~/helix_ledger/core/validator.py
# A standalone, dependency-free utility to validate cognitive outputs
# against the HCS-01 Epistemic Marker Protocol.

import re
import sys

# HCS-01 Mandatory Regex Pattern
PRIMARY_STATE_PATTERN = re.compile(r"^\[(FACT|REASONED|HYPOTHESIS|UNCERTAIN)\]")

# HCS-01 Error Codes
EC_401_EPISTEMIC_NULL = "EC-401: Epistemic Null"
EC_402_FAILURE_TO_CONVERGE = "EC-402: Failure to Converge"

def validate_output(text_input: str) -> str:
    """
    Validates a string against the HCS-01 Epistemic Marker Protocol.

    Returns:
        A string indicating the validation result or an error code.
    """
    match = PRIMARY_STATE_PATTERN.match(text_input)

    if not match:
        return EC_401_EPISTEMIC_NULL

    marker = match.group(1)

    if marker == "UNCERTAIN":
        return EC_402_FAILURE_TO_CONVERGE
    
    return f"VALID: Marker [{marker}] detected."

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # If input is provided as a command-line argument
        input_string = " ".join(sys.argv[1:])
        result = validate_output(input_string)
        print(result)
        if "EC-" in result:
            sys.exit(1)
    else:
        # Otherwise, run a standard test suite
        print("--- Running HCS-01 Validator Test Suite ---")
        
        test_cases = {
            "[FACT] This is a valid fact.": "VALID: Marker [FACT] detected.",
            "[REASONED] This is a valid conclusion.": "VALID: Marker [REASONED] detected.",
            "[HYPOTHESIS] This is a valid hypothesis.": "VALID: Marker [HYPOTHESIS] detected.",
            "Invalid input with no marker.": EC_401_EPISTEMIC_NULL,
            "[UNCERTAIN] This must fail to converge.": EC_402_FAILURE_TO_CONVERGE,
            " [FACT] Marker not at the beginning.": EC_401_EPISTEMIC_NULL,
        }
        
        all_passed = True
        for test_input, expected_output in test_cases.items():
            actual_output = validate_output(test_input)
            if actual_output == expected_output:
                print(f"PASS: Input '{test_input[:30]}...' -> '{actual_output}'")
            else:
                print(f"FAIL: Input '{test_input[:30]}...' -> Expected '{expected_output}', Got '{actual_output}'")
                all_passed = False
        
        print("--- Test Suite Complete ---")
        if not all_passed:
            sys.exit(1)
