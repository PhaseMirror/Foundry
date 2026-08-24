"""
Constitutional Stress Test — Red Team the GICD Gate
Adversarial inputs designed to probe every failure mode of the constitutional runtime.

Test categories:
  A. Single-marker FAIL (4 tests)
  B. Multi-marker FAIL (6 combinations)
  C. All-clear PASS baseline
  D. pre_nucleation_check blocking behavior
  E. Recovery after FAIL
  F. Edge cases (empty, partial)
"""
import sys
import json
import time
import requests

sys.path.insert(0, 'Z:\\helix-hamiltonian\\src')
from helix_hamiltonian.ttd_bridge import pre_nucleation_check

GICD_URL = "https://gicd-scanner-231586465188.us-central1.run.app/gicd-scan"
TOKEN_IDS = [1, 2, 3]
RESULTS = []


def run_test(name, payload, expect_status, category):
    start = time.time()
    try:
        resp = requests.post(GICD_URL, json=payload, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        actual = data.get("status")
        passed = actual == expect_status
        elapsed = round((time.time() - start) * 1000, 1)
        result = {
            "category": category,
            "name": name,
            "payload": payload,
            "expected": expect_status,
            "actual": actual,
            "reason": data.get("reason"),
            "passed": passed,
            "elapsed_ms": elapsed
        }
    except Exception as e:
        result = {
            "category": category,
            "name": name,
            "payload": payload,
            "expected": expect_status,
            "actual": "ERROR",
            "reason": str(e),
            "passed": False,
            "elapsed_ms": -1
        }
    RESULTS.append(result)
    status = "✅" if result["passed"] else "❌"
    print(f"{status} [{category}] {name} — {result['actual']} ({result['elapsed_ms']}ms)")
    return result


def run_nucleation_test(name, gicd_payload, expect_nucleation_pass, category):
    start = time.time()
    try:
        result = pre_nucleation_check(gicd_payload, TOKEN_IDS)
        actual = result.get("status")
        passed = (actual == "PASS") == expect_nucleation_pass
        elapsed = round((time.time() - start) * 1000, 1)
        r = {
            "category": category,
            "name": name,
            "payload": gicd_payload,
            "expected_nucleation": "PASS" if expect_nucleation_pass else "FAIL",
            "actual": actual,
            "passed": passed,
            "elapsed_ms": elapsed,
            "full_result": result
        }
    except Exception as e:
        r = {
            "category": category,
            "name": name,
            "payload": gicd_payload,
            "expected_nucleation": "PASS" if expect_nucleation_pass else "FAIL",
            "actual": "ERROR",
            "passed": False,
            "elapsed_ms": -1,
            "error": str(e)
        }
    RESULTS.append(r)
    status = "✅" if r["passed"] else "❌"
    print(f"{status} [{category}] {name} — nucleation={r['actual']} ({r['elapsed_ms']}ms)")
    return r


print("\n=== HELIX CONSTITUTIONAL STRESS TEST ===\n")

# ── A. Single-marker FAIL ─────────────────────────────────────────────
print("--- A. Single-marker FAIL ---")
CLEAR = {"authority_ambiguity": False, "incentive_misalignment": False,
         "cost_externalization": False, "governance_capture": False}

for marker in ["authority_ambiguity", "incentive_misalignment",
               "cost_externalization", "governance_capture"]:
    payload = {**CLEAR, marker: True}
    run_test(f"single_{marker}", payload, "FAIL", "A")

# ── B. Multi-marker combinations ─────────────────────────────────────
print("\n--- B. Multi-marker FAIL ---")
from itertools import combinations
markers = ["authority_ambiguity", "incentive_misalignment",
           "cost_externalization", "governance_capture"]
for r in range(2, 5):
    for combo in combinations(markers, r):
        payload = {**CLEAR}
        for m in combo: payload[m] = True
        name = f"combo_{'_'.join(m[:4] for m in combo)}"
        run_test(name, payload, "FAIL", "B")

# ── C. All-clear PASS baseline ────────────────────────────────────────
print("\n--- C. All-clear PASS ---")
run_test("all_clear", CLEAR, "PASS", "C")

# ── D. pre_nucleation_check blocking ─────────────────────────────────
print("\n--- D. Nucleation blocking ---")
run_nucleation_test("nucleation_blocked_authority",
                    {**CLEAR, "authority_ambiguity": True}, False, "D")
run_nucleation_test("nucleation_blocked_all_markers",
                    {m: True for m in markers}, False, "D")
run_nucleation_test("nucleation_permitted_all_clear",
                    CLEAR, True, "D")

# ── E. Recovery after FAIL ────────────────────────────────────────────
print("\n--- E. Recovery ---")
run_nucleation_test("fail_then_pass_1",
                    {**CLEAR, "governance_capture": True}, False, "E")
run_nucleation_test("fail_then_pass_2", CLEAR, True, "E")

# ── F. Edge cases ─────────────────────────────────────────────────────
print("\n--- F. Edge cases ---")
run_test("all_true", {m: True for m in markers}, "FAIL", "F")
run_test("all_false", CLEAR, "PASS", "F")

# ── Summary ───────────────────────────────────────────────────────────
total  = len(RESULTS)
passed = sum(1 for r in RESULTS if r["passed"])
failed = total - passed

print(f"\n=== RESULTS: {passed}/{total} passed ===")
if failed:
    print("\nFAILED TESTS:")
    for r in RESULTS:
        if not r["passed"]:
            print(f"  ❌ [{r['category']}] {r['name']} — expected={r.get('expected', r.get('expected_nucleation'))} actual={r['actual']}")

# Write artifact
import pathlib
pathlib.Path("Z:/checksums").mkdir(exist_ok=True)
with open("Z:/checksums/stress_test_results.json", "w") as f:
    json.dump({
        "total": total, "passed": passed, "failed": failed,
        "pass_rate": round(passed/total*100, 1),
        "results": RESULTS
    }, f, indent=2)

print(f"\nArtifact: Z:/checksums/stress_test_results.json")
print(f"Pass rate: {round(passed/total*100, 1)}%")
