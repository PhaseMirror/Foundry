import subprocess
import json
import re

def run_transpiler(nl_input):
    cmd = [".venv/bin/python3", "crates/pirtm-rs/scripts/nl_to_pirtm.py", nl_input]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout

def extract_attributes(output):
    epsilon = re.search(r"epsilon = ([\d\.]+) : f64", output)
    q_target = re.search(r"q_target = ([\d\.]+) : f64", output)
    mod = re.search(r"mod = ([\d]+) : i64", output)
    op_norm_t = re.search(r"op_norm_T = ([\d\.]+) : f64", output)
    
    return {
        "epsilon": float(epsilon.group(1)) if epsilon else None,
        "q_target": float(q_target.group(1)) if q_target else None,
        "mod": int(mod.group(1)) if mod else None,
        "op_norm_t": float(op_norm_t.group(1)) if op_norm_t else None
    }

test_vectors = [
    {
        "input": "guarantee convergence with a 10% margin",
        "expected": {"epsilon": 0.10}
    },
    {
        "input": "spectral radius < 0.92 and 5% stability margin",
        "expected": {"q_target": 0.92, "epsilon": 0.05}
    },
    {
        "input": "Ensure ε = 0.07 for p = 13",
        "expected": {"epsilon": 0.07, "mod": 13}
    },
    {
        "input": "operator norm of 0.4 with contraction coefficient of 0.88",
        "expected": {"op_norm_t": 0.4, "q_target": 0.88}
    },
    {
        "input": "nonlinear gain of 0.6 and 15% margin for prime index 19",
        "expected": {"op_norm_t": 0.6, "epsilon": 0.15, "mod": 19}
    }
]

print("=== PIRTM Transpiler Verification (Test Vectors) ===")
all_passed = True

for vec in test_vectors:
    print(f"\nTesting: '{vec['input']}'")
    output = run_transpiler(vec['input'])
    attrs = extract_attributes(output)
    
    passed = True
    for key, expected_val in vec['expected'].items():
        actual_val = attrs.get(key)
        if actual_val != expected_val:
            print(f"  FAILED: {key} expected {expected_val}, got {actual_val}")
            passed = False
            all_passed = False
    
    if passed:
        print(f"  PASSED: {attrs}")

print("\n" + "="*50)
if all_passed:
    print("ALL TEST VECTORS PASSED")
else:
    print("SOME TESTS FAILED")
print("="*50)
